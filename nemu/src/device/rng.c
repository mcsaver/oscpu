/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <isa.h>
#include <memory/host.h>
#include <memory/paddr.h>

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <string.h>
#include <unistd.h>

// Ubuntu/systemd 长跑需要稳定熵源；这里实现最小 virtio-mmio rng，
// 让 Linux hwrng 官方驱动从 host /dev/urandom 获取随机字节。
#define VIRTIO_MMIO_MAGIC          0x000
#define VIRTIO_MMIO_VERSION        0x004
#define VIRTIO_MMIO_DEVICE_ID      0x008
#define VIRTIO_MMIO_VENDOR_ID      0x00c
#define VIRTIO_MMIO_DEVICE_FEATURES     0x010
#define VIRTIO_MMIO_DEVICE_FEATURES_SEL 0x014
#define VIRTIO_MMIO_DRIVER_FEATURES     0x020
#define VIRTIO_MMIO_DRIVER_FEATURES_SEL 0x024
#define VIRTIO_MMIO_QUEUE_SEL      0x030
#define VIRTIO_MMIO_QUEUE_NUM_MAX  0x034
#define VIRTIO_MMIO_QUEUE_NUM      0x038
#define VIRTIO_MMIO_QUEUE_READY    0x044
#define VIRTIO_MMIO_QUEUE_NOTIFY   0x050
#define VIRTIO_MMIO_INTERRUPT_STATUS 0x060
#define VIRTIO_MMIO_INTERRUPT_ACK  0x064
#define VIRTIO_MMIO_STATUS         0x070
#define VIRTIO_MMIO_QUEUE_DESC_LOW 0x080
#define VIRTIO_MMIO_QUEUE_DESC_HIGH 0x084
#define VIRTIO_MMIO_QUEUE_DRIVER_LOW 0x090
#define VIRTIO_MMIO_QUEUE_DRIVER_HIGH 0x094
#define VIRTIO_MMIO_QUEUE_DEVICE_LOW 0x0a0
#define VIRTIO_MMIO_QUEUE_DEVICE_HIGH 0x0a4
#define VIRTIO_MMIO_CONFIG_GENERATION 0x0fc

#define VIRTIO_RNG_DEVICE_ID 4u
#define VIRTIO_MMIO_VERSION_2 2u
#define VIRTIO_VENDOR_YSYX 0x58535959u
#define VIRTIO_F_VERSION_1 32
#define VIRTIO_RING_F_EVENT_IDX 29
#define VIRTIO_MMIO_INT_USED_BUFFER 0x1u
#define VIRTIO_STATUS_FEATURES_OK 0x08u
#define VRING_AVAIL_F_NO_INTERRUPT 0x1u
#define VIRTQ_DESC_F_NEXT  0x1u
#define VIRTQ_DESC_F_WRITE 0x2u
#define VIRTQ_DESC_F_INDIRECT 0x4u

#define VIRTIO_RNG_QUEUE_SIZE 8u
#define VIRTIO_RNG_MAX_CHAIN 16u
#define VIRTIO_RNG_IRQ 3u

typedef struct {
  paddr_t addr;
  uint32_t len;
  uint16_t flags;
  uint16_t next;
} VirtqDesc;

typedef struct {
  uint16_t num;
  bool ready;
  paddr_t desc;
  paddr_t driver;
  paddr_t device;
  uint16_t last_avail_idx;
} VirtqState;

static uint8_t *rng_base;
static uint32_t device_features_sel;
static uint32_t driver_features_sel;
static uint32_t driver_features[2];
static uint32_t interrupt_status;
static uint32_t device_status;
static uint32_t queue_sel;
static VirtqState queue0;
static int rng_fd = -1;
static uint64_t rng_fallback_state = 0x797379782d726e67ull;
static bool rng_fallback_logged;

static uint32_t virtio_rng_device_features(uint32_t sel) {
  if (sel == 0) {
    return 1u << VIRTIO_RING_F_EVENT_IDX;
  }
  if (sel == 1) {
    return 1u << (VIRTIO_F_VERSION_1 - 32);
  }
  return 0;
}

static bool virtio_rng_driver_features_supported(void) {
  for (uint32_t sel = 0; sel < 2; sel++) {
    uint32_t unsupported =
        driver_features[sel] & ~virtio_rng_device_features(sel);
    if (unsupported != 0) {
      Log("virtio-rng: unsupported driver features sel=%u bits=0x%08x",
          sel, unsupported);
      return false;
    }
  }
  return true;
}

static bool virtio_rng_driver_feature_enabled(uint32_t bit) {
  uint32_t sel = bit / 32;
  uint32_t off = bit % 32;
  return sel < 2 && (driver_features[sel] & (1u << off)) != 0;
}

static bool virtio_rng_event_idx_enabled(void) {
  return virtio_rng_driver_feature_enabled(VIRTIO_RING_F_EVENT_IDX);
}

static void virtio_rng_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv,
      isa_riscv_plic_set_irq(VIRTIO_RNG_IRQ, interrupt_status != 0));
}

static uint16_t guest_read16(paddr_t addr) {
  return paddr_read(addr, 2);
}

static uint32_t guest_read32(paddr_t addr) {
  return paddr_read(addr, 4);
}

static uint64_t guest_read64(paddr_t addr) {
  return paddr_read(addr, 8);
}

static void guest_write16(paddr_t addr, uint16_t value) {
  paddr_write(addr, 2, value);
}

static void guest_write32(paddr_t addr, uint32_t value) {
  paddr_write(addr, 4, value);
}

static bool guest_range_ok(paddr_t addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t end = addr + (paddr_t)len - 1;
  return end >= addr && in_pmem(addr) && in_pmem(end);
}

static paddr_t virtq_used_event_addr(void) {
  return queue0.driver + 4 + (paddr_t)queue0.num * 2;
}

static paddr_t virtq_avail_event_addr(void) {
  return queue0.device + 4 + (paddr_t)queue0.num * 8;
}

static bool virtq_need_event(uint16_t event_idx, uint16_t new_idx, uint16_t old_idx) {
  return (uint16_t)(new_idx - event_idx - 1) < (uint16_t)(new_idx - old_idx);
}

static void virtq_set_avail_event(uint16_t avail_idx) {
  if (virtio_rng_event_idx_enabled() && queue0.num != 0 &&
      guest_range_ok(virtq_avail_event_addr(), 2)) {
    // rng 和 blk/net 一样不主动抑制 driver kick，只把设备消费进度回写给 Linux。
    guest_write16(queue0.device, 0);
    guest_write16(virtq_avail_event_addr(), avail_idx);
  }
}

static bool virtq_aligned(paddr_t addr, uint32_t align) {
  return (addr & (paddr_t)(align - 1)) == 0;
}

static bool virtq_dma_range_valid(const char *name, paddr_t addr,
    uint32_t len, uint32_t align) {
  if (addr != 0 && virtq_aligned(addr, align) && guest_range_ok(addr, len)) {
    return true;
  }
  Log("virtio-rng: invalid %s ring addr=0x%" PRIx64 " len=%u align=%u",
      name, (uint64_t)addr, len, align);
  return false;
}

static bool virtq_validate_queue_layout(void) {
  if (queue0.num == 0 || queue0.num > VIRTIO_RNG_QUEUE_SIZE) {
    Log("virtio-rng: invalid QueueNum=%u max=%u",
        queue0.num, VIRTIO_RNG_QUEUE_SIZE);
    return false;
  }

  uint32_t desc_bytes = (uint32_t)queue0.num * 16u;
  uint32_t event_tail = virtio_rng_event_idx_enabled() ? 2u : 0u;
  uint32_t driver_bytes = 4u + (uint32_t)queue0.num * 2u + event_tail;
  uint32_t device_bytes = 4u + (uint32_t)queue0.num * 8u + event_tail;

  // QueueReady 是 hwrng 真正收发前的边界；提前拒绝坏 vring，避免异步熵请求卡死。
  return virtq_dma_range_valid("desc", queue0.desc, desc_bytes, 16) &&
         virtq_dma_range_valid("driver", queue0.driver, driver_bytes, 2) &&
         virtq_dma_range_valid("device", queue0.device, device_bytes, 4);
}

static bool guest_copy_to(paddr_t addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!guest_range_ok(addr, len)) return false;
  if (in_pmem(addr) && in_pmem(addr + len - 1)) {
    memcpy(guest_to_host(addr), buf, len);
    return true;
  }
  const uint8_t *in = buf;
  for (uint32_t i = 0; i < len; i++) {
    paddr_write(addr + i, 1, in[i]);
  }
  return true;
}

static bool virtq_read_desc(uint16_t idx, VirtqDesc *desc) {
  if (idx >= queue0.num || idx >= VIRTIO_RNG_QUEUE_SIZE) return false;
  paddr_t base = queue0.desc + (paddr_t)idx * 16;
  if (!guest_range_ok(base, 16)) return false;
  desc->addr = guest_read64(base);
  desc->len = guest_read32(base + 8);
  desc->flags = guest_read16(base + 12);
  desc->next = guest_read16(base + 14);
  return true;
}

static bool virtq_collect_chain(uint16_t head, VirtqDesc *out, int *out_count) {
  bool seen[VIRTIO_RNG_QUEUE_SIZE] = {};
  uint16_t idx = head;
  int count = 0;

  while (true) {
    if (idx >= queue0.num || idx >= VIRTIO_RNG_QUEUE_SIZE || seen[idx] ||
        count >= (int)VIRTIO_RNG_MAX_CHAIN) {
      return false;
    }
    seen[idx] = true;
    if (!virtq_read_desc(idx, &out[count])) return false;
    if (out[count].flags & VIRTQ_DESC_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQ_DESC_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }

  *out_count = count;
  return true;
}

static void rng_fallback_fill(uint8_t *buf, uint32_t len) {
  if (!rng_fallback_logged) {
    Log("virtio-rng: /dev/urandom unavailable, using deterministic fallback");
    rng_fallback_logged = true;
  }
  for (uint32_t i = 0; i < len; i++) {
    rng_fallback_state ^= rng_fallback_state << 13;
    rng_fallback_state ^= rng_fallback_state >> 7;
    rng_fallback_state ^= rng_fallback_state << 17;
    buf[i] = (uint8_t)(rng_fallback_state >> 56);
  }
}

static void rng_fill(uint8_t *buf, uint32_t len) {
  uint32_t done = 0;
  while (done < len && rng_fd >= 0) {
    ssize_t n = read(rng_fd, buf + done, len - done);
    if (n > 0) {
      done += (uint32_t)n;
      continue;
    }
    if (n < 0 && errno == EINTR) {
      continue;
    }
    close(rng_fd);
    rng_fd = -1;
    break;
  }
  if (done < len) {
    rng_fallback_fill(buf + done, len - done);
  }
}

static uint32_t virtio_rng_handle_chain(uint16_t head) {
  VirtqDesc descs[VIRTIO_RNG_MAX_CHAIN];
  int count = 0;
  if (!virtq_collect_chain(head, descs, &count)) return 0;

  uint32_t used_len = 0;
  uint8_t buf[256];
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) == 0) {
      return 0;
    }
    paddr_t addr = descs[i].addr;
    uint32_t left = descs[i].len;
    while (left > 0) {
      uint32_t chunk = left < sizeof(buf) ? left : sizeof(buf);
      rng_fill(buf, chunk);
      if (!guest_copy_to(addr, buf, chunk)) return used_len;
      addr += chunk;
      used_len += chunk;
      left -= chunk;
    }
  }
  return used_len;
}

static void virtio_rng_process_queue(void) {
  if (!queue0.ready || queue0.num == 0 || queue0.desc == 0 ||
      queue0.driver == 0 || queue0.device == 0) {
    return;
  }

  bool used_any = false;
  uint16_t avail_flags = guest_read16(queue0.driver);
  uint16_t avail_idx = guest_read16(queue0.driver + 2);
  uint16_t old_used_idx = guest_read16(queue0.device + 2);
  uint16_t used_idx = old_used_idx;
  while (queue0.last_avail_idx != avail_idx) {
    uint16_t ring_off = queue0.last_avail_idx % queue0.num;
    uint16_t head = guest_read16(queue0.driver + 4 + ring_off * 2);
    uint32_t used_len = virtio_rng_handle_chain(head);
    uint16_t used_off = used_idx % queue0.num;
    guest_write32(queue0.device + 4 + used_off * 8, head);
    guest_write32(queue0.device + 4 + used_off * 8 + 4, used_len);
    used_idx++;
    guest_write16(queue0.device + 2, used_idx);
    queue0.last_avail_idx++;
    used_any = true;
  }
  virtq_set_avail_event(queue0.last_avail_idx);

  if (used_any) {
    bool notify = true;
    if (virtio_rng_event_idx_enabled()) {
      uint16_t used_event = guest_range_ok(virtq_used_event_addr(), 2) ?
        guest_read16(virtq_used_event_addr()) : old_used_idx;
      notify = virtq_need_event(used_event, used_idx, old_used_idx);
    } else {
      notify = (avail_flags & VRING_AVAIL_F_NO_INTERRUPT) == 0;
    }
    if (notify) {
      // hwrng 驱动等待 used ring 完成；EVENT_IDX 协商后按 used_event 抑制多余 IRQ3。
      interrupt_status |= VIRTIO_MMIO_INT_USED_BUFFER;
      virtio_rng_raise_irq();
    }
  }
}

static void virtio_rng_reset(void) {
  memset(driver_features, 0, sizeof(driver_features));
  memset(&queue0, 0, sizeof(queue0));
  device_features_sel = 0;
  driver_features_sel = 0;
  interrupt_status = 0;
  device_status = 0;
  queue_sel = 0;
  virtio_rng_raise_irq();
}

static uint32_t virtio_rng_read_reg(uint32_t offset) {
  switch (offset) {
    case VIRTIO_MMIO_MAGIC: return 0x74726976u;
    case VIRTIO_MMIO_VERSION: return VIRTIO_MMIO_VERSION_2;
    case VIRTIO_MMIO_DEVICE_ID: return VIRTIO_RNG_DEVICE_ID;
    case VIRTIO_MMIO_VENDOR_ID: return VIRTIO_VENDOR_YSYX;
    case VIRTIO_MMIO_DEVICE_FEATURES:
      return virtio_rng_device_features(device_features_sel);
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL: return device_features_sel;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL: return driver_features_sel;
    case VIRTIO_MMIO_QUEUE_SEL: return queue_sel;
    case VIRTIO_MMIO_QUEUE_NUM_MAX:
      return queue_sel == 0 ? VIRTIO_RNG_QUEUE_SIZE : 0;
    case VIRTIO_MMIO_QUEUE_NUM: return queue0.num;
    case VIRTIO_MMIO_QUEUE_READY: return queue0.ready ? 1 : 0;
    case VIRTIO_MMIO_INTERRUPT_STATUS: return interrupt_status;
    case VIRTIO_MMIO_STATUS: return device_status;
    case VIRTIO_MMIO_QUEUE_DESC_LOW: return (uint32_t)queue0.desc;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      return (uint32_t)((uint64_t)queue0.desc >> 32);
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW: return (uint32_t)queue0.driver;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      return (uint32_t)((uint64_t)queue0.driver >> 32);
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW: return (uint32_t)queue0.device;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      return (uint32_t)((uint64_t)queue0.device >> 32);
    case VIRTIO_MMIO_CONFIG_GENERATION: return 0;
    default: return 0;
  }
}

static void virtio_rng_write_reg(uint32_t offset, uint32_t value) {
  switch (offset) {
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL:
      device_features_sel = value;
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES:
      if (driver_features_sel < 2) driver_features[driver_features_sel] = value;
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL:
      driver_features_sel = value;
      break;
    case VIRTIO_MMIO_QUEUE_SEL:
      queue_sel = value;
      break;
    case VIRTIO_MMIO_QUEUE_NUM:
      if (queue_sel == 0) {
        if (value <= VIRTIO_RNG_QUEUE_SIZE) {
          queue0.num = value;
        } else {
          // 不能静默 clamp QueueNum；坏驱动必须在配置阶段暴露，而不是假装队列可用。
          Log("virtio-rng: reject unsupported QueueNum=%u max=%u",
              value, VIRTIO_RNG_QUEUE_SIZE);
          queue0.num = 0;
          queue0.ready = false;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_READY:
      if (queue_sel == 0) {
        if ((value & 1u) == 0) {
          queue0.ready = false;
          queue0.last_avail_idx = 0;
        } else if (virtq_validate_queue_layout()) {
          queue0.ready = true;
          queue0.last_avail_idx = guest_read16(queue0.driver + 2);
          virtq_set_avail_event(queue0.last_avail_idx);
        } else {
          queue0.ready = false;
          queue0.last_avail_idx = 0;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_NOTIFY:
      if (value == 0) virtio_rng_process_queue();
      break;
    case VIRTIO_MMIO_INTERRUPT_ACK:
      interrupt_status &= ~value;
      virtio_rng_raise_irq();
      break;
    case VIRTIO_MMIO_STATUS:
      if (value == 0) {
        virtio_rng_reset();
      } else {
        device_status = value;
        if ((value & VIRTIO_STATUS_FEATURES_OK) &&
            !virtio_rng_driver_features_supported()) {
          device_status &= ~VIRTIO_STATUS_FEATURES_OK;
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_DESC_LOW:
      if (queue_sel == 0) queue0.desc = (queue0.desc & 0xffffffff00000000ull) | value;
      break;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      if (queue_sel == 0) queue0.desc = ((uint64_t)value << 32) | (uint32_t)queue0.desc;
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW:
      if (queue_sel == 0) queue0.driver = (queue0.driver & 0xffffffff00000000ull) | value;
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      if (queue_sel == 0) queue0.driver = ((uint64_t)value << 32) | (uint32_t)queue0.driver;
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW:
      if (queue_sel == 0) queue0.device = (queue0.device & 0xffffffff00000000ull) | value;
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      if (queue_sel == 0) queue0.device = ((uint64_t)value << 32) | (uint32_t)queue0.device;
      break;
    default:
      break;
  }
}

static void virtio_rng_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1 || len == 2 || len == 4 || len == 8);
  if (is_write) {
    if (len == 4) {
      virtio_rng_write_reg(offset, host_read(rng_base + offset, 4));
    } else if (len == 8) {
      virtio_rng_write_reg(offset, host_read(rng_base + offset, 4));
      virtio_rng_write_reg(offset + 4, host_read(rng_base + offset + 4, 4));
    }
    return;
  }

  if (len == 8) {
    host_write(rng_base + offset, 4, virtio_rng_read_reg(offset));
    host_write(rng_base + offset + 4, 4, virtio_rng_read_reg(offset + 4));
  } else {
    host_write(rng_base + offset, len, virtio_rng_read_reg(offset));
  }
}

void init_virtio_rng() {
  rng_base = new_space(0x1000);
  rng_fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
  if (rng_fd < 0) {
    Log("virtio-rng: cannot open /dev/urandom: %s", strerror(errno));
  }
  virtio_rng_reset();
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("virtio-rng", CONFIG_VIRTIO_RNG_MMIO, rng_base, 0x1000,
      virtio_rng_io_handler);
#else
  add_mmio_map("virtio-rng", CONFIG_VIRTIO_RNG_MMIO, rng_base, 0x1000,
      virtio_rng_io_handler);
#endif
}

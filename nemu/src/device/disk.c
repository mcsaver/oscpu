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
#include <inttypes.h>
#include <unistd.h>

// Linux rootfs gate 只需要一个最小 modern virtio-mmio block 设备：
// 单队列、512B sector、used-buffer interrupt，就足够把 ext4 镜像挂成 /dev/vda。
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
#define VIRTIO_MMIO_CONFIG         0x100

#define VIRTIO_BLK_DEVICE_ID 2u
#define VIRTIO_MMIO_VERSION_2 2u
#define VIRTIO_VENDOR_YSYX 0x58535959u
#define VIRTIO_F_VERSION_1 32
#define VIRTIO_MMIO_INT_USED_BUFFER 0x1u
#define VIRTIO_BLK_F_BLK_SIZE 6
#define VIRTIO_BLK_F_FLUSH 9
#define VIRTIO_BLK_F_TOPOLOGY 10
#define VIRTIO_BLK_F_CONFIG_WCE 11
#define VIRTIO_BLK_F_DISCARD 13
#define VIRTIO_BLK_F_WRITE_ZEROES 14
#define VIRTIO_RING_F_INDIRECT_DESC 28
#define VIRTIO_RING_F_EVENT_IDX 29
#define VRING_AVAIL_F_NO_INTERRUPT 0x1u
#define VIRTIO_STATUS_FEATURES_OK 0x08u
#define VIRTQ_DESC_F_NEXT  0x1u
#define VIRTQ_DESC_F_WRITE 0x2u
#define VIRTQ_DESC_F_INDIRECT 0x4u

#define VIRTIO_BLK_T_IN     0u
#define VIRTIO_BLK_T_OUT    1u
#define VIRTIO_BLK_T_FLUSH  4u
#define VIRTIO_BLK_T_GET_ID 8u
#define VIRTIO_BLK_T_DISCARD 11u
#define VIRTIO_BLK_T_WRITE_ZEROES 13u
#define VIRTIO_BLK_S_OK     0u
#define VIRTIO_BLK_S_IOERR  1u
#define VIRTIO_BLK_S_UNSUPP 2u

#define VIRTIO_BLK_SECTOR_SIZE 512u
#define VIRTIO_BLK_CONFIG_BLK_SIZE 20u
#define VIRTIO_BLK_CONFIG_PHYSICAL_BLOCK_EXP 24u
#define VIRTIO_BLK_CONFIG_ALIGNMENT_OFFSET 25u
#define VIRTIO_BLK_CONFIG_MIN_IO_SIZE 26u
#define VIRTIO_BLK_CONFIG_OPT_IO_SIZE 28u
#define VIRTIO_BLK_CONFIG_WCE 32u
#define VIRTIO_BLK_CONFIG_MAX_DISCARD_SECTORS 36u
#define VIRTIO_BLK_CONFIG_MAX_DISCARD_SEG 40u
#define VIRTIO_BLK_CONFIG_DISCARD_SECTOR_ALIGNMENT 44u
#define VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SECTORS 48u
#define VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SEG 52u
#define VIRTIO_BLK_CONFIG_WRITE_ZEROES_MAY_UNMAP 56u
#define VIRTIO_BLK_ID_BYTES 20u
#define VIRTIO_BLK_ID_STRING "ysyx-nemu-virtio-blk"
#define VIRTIO_BLK_QUEUE_SIZE 64u
#define VIRTIO_BLK_MAX_CHAIN 128u
#define VIRTIO_BLK_IRQ 2u
#define VIRTIO_BLK_DISCARD_WRITE_ZEROES_BYTES 16u
#define VIRTIO_BLK_WRITE_ZEROES_FLAG_UNMAP 0x00000001u
#define VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS 4096u
#define VIRTIO_BLK_MAX_ZERO_RANGE_SEG 1u

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

static uint8_t *virtio_base;
static const char *disk_image_path;
static FILE *disk_fp;
static bool disk_readonly;
static bool disk_writeback = true;
static uint64_t disk_size;
static uint32_t device_features_sel;
static uint32_t driver_features_sel;
static uint32_t driver_features[2];
static uint32_t interrupt_status;
static uint32_t device_status;
static uint32_t queue_sel;
static VirtqState queue0;
static int disk_log_budget = 16;

#ifdef CONFIG_RISCV_IRQ_DEBUG_LOG
static int virtio_irq_debug_budget = 256;
#define VIRTIO_IRQ_DEBUG_LOG(...) \
  do { \
    if (virtio_irq_debug_budget > 0) { \
      virtio_irq_debug_budget--; \
      Log(__VA_ARGS__); \
    } \
  } while (0)
#else
#define VIRTIO_IRQ_DEBUG_LOG(...) ((void)0)
#endif

static uint32_t virtio_blk_device_features(uint32_t sel) {
  if (sel == 0) {
    return (1u << VIRTIO_BLK_F_BLK_SIZE) |
           (1u << VIRTIO_BLK_F_FLUSH) |
           (1u << VIRTIO_BLK_F_TOPOLOGY) |
           (1u << VIRTIO_BLK_F_CONFIG_WCE) |
           (1u << VIRTIO_BLK_F_DISCARD) |
           (1u << VIRTIO_BLK_F_WRITE_ZEROES) |
           (1u << VIRTIO_RING_F_INDIRECT_DESC) |
           (1u << VIRTIO_RING_F_EVENT_IDX);
  }
  if (sel == 1) {
    return 1u << (VIRTIO_F_VERSION_1 - 32);
  }
  return 0;
}

static bool virtio_blk_driver_features_supported(void) {
  for (uint32_t sel = 0; sel < 2; sel++) {
    uint32_t unsupported = driver_features[sel] & ~virtio_blk_device_features(sel);
    if (unsupported != 0) {
      Log("virtio-blk: unsupported driver features sel=%u bits=0x%08x", sel, unsupported);
      return false;
    }
  }
  return true;
}

static bool virtio_blk_driver_feature_enabled(uint32_t bit) {
  uint32_t sel = bit / 32;
  uint32_t off = bit % 32;
  return sel < 2 && (driver_features[sel] & (1u << off)) != 0;
}

static bool virtio_blk_event_idx_enabled(void) {
  return virtio_blk_driver_feature_enabled(VIRTIO_RING_F_EVENT_IDX);
}

void disk_set_image(const char *path) {
  disk_image_path = path;
}

static void virtio_blk_raise_irq(void) {
  VIRTIO_IRQ_DEBUG_LOG("virtio-blk irq line=%u status=0x%08x last_avail=%u ready=%u",
      interrupt_status != 0, interrupt_status, queue0.last_avail_idx, queue0.ready);
  IFDEF(CONFIG_ISA_riscv, isa_riscv32_plic_set_irq(VIRTIO_BLK_IRQ, interrupt_status != 0));
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

static bool guest_range_ok(paddr_t addr, uint32_t len);

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
  if (virtio_blk_event_idx_enabled() && queue0.num != 0 &&
      guest_range_ok(virtq_avail_event_addr(), 2)) {
    // EVENT_IDX 协商后 used->flags 必须保持 0；avail_event 先设为下一次 avail idx，
    // 等价于不主动抑制 driver kick，保证同步解释器设备不会因缺通知饿死。
    guest_write16(queue0.device, 0);
    guest_write16(virtq_avail_event_addr(), avail_idx);
  }
}

static bool guest_range_ok(paddr_t addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t end = addr + (paddr_t)len - 1;
  return end >= addr && in_pmem(addr) && in_pmem(end);
}

static bool guest_copy_from(paddr_t addr, void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!guest_range_ok(addr, len)) return false;
  if (in_pmem(addr) && in_pmem(addr + len - 1)) {
    memcpy(buf, guest_to_host(addr), len);
    return true;
  }
  uint8_t *out = buf;
  for (uint32_t i = 0; i < len; i++) out[i] = paddr_read(addr + i, 1);
  return true;
}

static bool guest_copy_to(paddr_t addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!guest_range_ok(addr, len)) return false;
  if (in_pmem(addr) && in_pmem(addr + len - 1)) {
    memcpy(guest_to_host(addr), buf, len);
    return true;
  }
  const uint8_t *in = buf;
  for (uint32_t i = 0; i < len; i++) paddr_write(addr + i, 1, in[i]);
  return true;
}

static uint8_t *guest_host_buffer(paddr_t addr, uint32_t len) {
  if (len == 0 || !guest_range_ok(addr, len)) return NULL;
  return guest_to_host(addr);
}

static bool virtq_read_desc_from(paddr_t table, uint16_t table_num, uint16_t idx, VirtqDesc *desc) {
  if (idx >= table_num) return false;
  paddr_t base = table + (paddr_t)idx * 16;
  if (!guest_range_ok(base, 16)) return false;
  desc->addr = guest_read64(base);
  desc->len = guest_read32(base + 8);
  desc->flags = guest_read16(base + 12);
  desc->next = guest_read16(base + 14);
  return true;
}

static bool virtq_collect_table(paddr_t table, uint16_t table_num, uint16_t head,
    VirtqDesc *out, int *out_count) {
  if (table_num == 0 || table_num > VIRTIO_BLK_MAX_CHAIN) return false;

  bool seen[VIRTIO_BLK_MAX_CHAIN] = {};
  uint16_t idx = head;
  int count = 0;
  while (true) {
    if (idx >= table_num || seen[idx] || count >= (int)VIRTIO_BLK_MAX_CHAIN) return false;
    seen[idx] = true;
    if (!virtq_read_desc_from(table, table_num, idx, &out[count])) return false;
    // indirect 描述符只允许出现在主队列 head，不能在 indirect table 里再次嵌套。
    if (out[count].flags & VIRTQ_DESC_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQ_DESC_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }

  *out_count = count;
  return true;
}

static bool virtq_collect_chain(uint16_t head, VirtqDesc *out, int *out_count) {
  VirtqDesc first;
  if (!virtq_read_desc_from(queue0.desc, queue0.num, head, &first)) return false;

  if (first.flags & VIRTQ_DESC_F_INDIRECT) {
    if ((first.flags & (VIRTQ_DESC_F_NEXT | VIRTQ_DESC_F_WRITE)) ||
        first.len == 0 || (first.len % 16) != 0) {
      return false;
    }
    uint32_t indirect_num = first.len / 16;
    if (indirect_num == 0 || indirect_num > VIRTIO_BLK_MAX_CHAIN) return false;
    // Linux 可能在压力下启用 indirect descriptor；这里按规范解析而不是强行依赖直接三段链。
    return virtq_collect_table(first.addr, indirect_num, 0, out, out_count);
  }

  bool seen[VIRTIO_BLK_QUEUE_SIZE] = {};
  uint16_t idx = head;
  int count = 0;
  while (true) {
    if (idx >= queue0.num || idx >= VIRTIO_BLK_QUEUE_SIZE || seen[idx] ||
        count >= (int)VIRTIO_BLK_MAX_CHAIN) {
      return false;
    }
    seen[idx] = true;
    if (!virtq_read_desc_from(queue0.desc, queue0.num, idx, &out[count])) return false;
    if (out[count].flags & VIRTQ_DESC_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQ_DESC_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }

  *out_count = count;
  return true;
}

static bool disk_range64_ok(uint64_t offset, uint64_t len) {
  return offset <= disk_size && len <= disk_size - offset;
}

static bool disk_range_ok(uint64_t offset, uint32_t len) {
  return disk_range64_ok(offset, len);
}

static bool disk_pread_all(void *buf, uint32_t len, uint64_t offset) {
  uint8_t *out = buf;
  while (len > 0) {
    ssize_t got = pread(fileno(disk_fp), out, len, (off_t)offset);
    if (got < 0 && errno == EINTR) continue;
    if (got <= 0) return false;
    out += got;
    offset += got;
    len -= got;
  }
  return true;
}

static bool disk_pwrite_all(const void *buf, uint32_t len, uint64_t offset) {
  const uint8_t *in = buf;
  while (len > 0) {
    ssize_t done = pwrite(fileno(disk_fp), in, len, (off_t)offset);
    if (done < 0 && errno == EINTR) continue;
    if (done <= 0) return false;
    in += done;
    offset += done;
    len -= done;
  }
  return true;
}

static bool disk_sync_if_writethrough(void) {
  return disk_writeback || (fflush(disk_fp) == 0 && fsync(fileno(disk_fp)) == 0);
}

static bool disk_read_to_guest(paddr_t addr, uint32_t len, uint64_t *offset) {
  if (!guest_range_ok(addr, len) || !disk_range_ok(*offset, len)) return false;
  uint8_t *host_buf = guest_host_buffer(addr, len);
  if (host_buf != NULL) {
    // virtio-blk 的数据描述符来自 guest PMEM 时，直接把 pread 结果写入 guest buffer，
    // 避免每 4KiB 先落到宿主临时栈缓冲再 memcpy 一次。
    if (!disk_pread_all(host_buf, len, *offset)) return false;
    *offset += len;
    return true;
  }
  uint8_t buf[4096];
  uint32_t left = len;
  while (left > 0) {
    uint32_t chunk = left < sizeof(buf) ? left : sizeof(buf);
    if (!disk_pread_all(buf, chunk, *offset)) return false;
    if (!guest_copy_to(addr, buf, chunk)) return false;
    addr += chunk;
    *offset += chunk;
    left -= chunk;
  }
  return true;
}

static bool disk_write_from_guest(paddr_t addr, uint32_t len, uint64_t *offset) {
  if (disk_readonly) return false;
  if (!guest_range_ok(addr, len) || !disk_range_ok(*offset, len)) return false;
  uint8_t *host_buf = guest_host_buffer(addr, len);
  if (host_buf != NULL) {
    // OUT 请求同样可以直接从 guest PMEM buffer pwrite 到镜像；write-through 语义仍在末尾同步。
    if (!disk_pwrite_all(host_buf, len, *offset)) return false;
    *offset += len;
    return disk_sync_if_writethrough();
  }
  uint8_t buf[4096];
  uint32_t left = len;
  while (left > 0) {
    uint32_t chunk = left < sizeof(buf) ? left : sizeof(buf);
    if (!guest_copy_from(addr, buf, chunk)) return false;
    if (!disk_pwrite_all(buf, chunk, *offset)) return false;
    addr += chunk;
    *offset += chunk;
    left -= chunk;
  }
  if (!disk_sync_if_writethrough()) return false;
  return true;
}

static bool disk_zero_range(uint64_t offset, uint64_t len) {
  if (disk_readonly) return false;
  if (!disk_range64_ok(offset, len)) return false;
  uint8_t zeros[4096] = {};
  while (len > 0) {
    uint32_t chunk = len < sizeof(zeros) ? (uint32_t)len : (uint32_t)sizeof(zeros);
    if (!disk_pwrite_all(zeros, chunk, offset)) return false;
    offset += chunk;
    len -= chunk;
  }
  if (!disk_sync_if_writethrough()) return false;
  return true;
}

static bool virtio_blk_write_id(const VirtqDesc *descs, int status_desc,
    uint32_t *used_len) {
  uint8_t id[VIRTIO_BLK_ID_BYTES] = {};
  const char id_string[] = VIRTIO_BLK_ID_STRING;
  uint32_t id_len = sizeof(id_string) - 1u;
  if (id_len > VIRTIO_BLK_ID_BYTES) id_len = VIRTIO_BLK_ID_BYTES;
  memcpy(id, id_string, id_len);

  uint32_t done = 0;
  for (int i = 1; i < status_desc && done < VIRTIO_BLK_ID_BYTES; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) == 0) {
      return false;
    }
    uint32_t left = VIRTIO_BLK_ID_BYTES - done;
    uint32_t chunk = descs[i].len < left ? descs[i].len : left;
    if (chunk != 0 &&
        !guest_copy_to(descs[i].addr, id + done, chunk)) {
      return false;
    }
    done += chunk;
  }

  if (done != VIRTIO_BLK_ID_BYTES) {
    return false;
  }
  *used_len += done;
  return true;
}

static bool virtio_blk_zero_range_from_sector(uint64_t sector, uint32_t num_sectors) {
  if (num_sectors == 0) return true;
  if (sector > UINT64_MAX / VIRTIO_BLK_SECTOR_SIZE) return false;
  uint64_t offset = sector * VIRTIO_BLK_SECTOR_SIZE;
  uint64_t len = (uint64_t)num_sectors * VIRTIO_BLK_SECTOR_SIZE;
  return disk_zero_range(offset, len);
}

static bool virtio_blk_handle_zero_ranges(const VirtqDesc *descs, int status_desc,
    bool is_write_zeroes) {
  if (disk_readonly) return false;
  uint32_t range_count = 0;
  for (int i = 1; i < status_desc; i++) {
    if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
        (descs[i].len % VIRTIO_BLK_DISCARD_WRITE_ZEROES_BYTES) != 0 ||
        !guest_range_ok(descs[i].addr, descs[i].len)) {
      return false;
    }

    for (uint32_t off = 0; off < descs[i].len; off += VIRTIO_BLK_DISCARD_WRITE_ZEROES_BYTES) {
      paddr_t range = descs[i].addr + off;
      uint64_t sector = guest_read64(range);
      uint32_t num_sectors = guest_read32(range + 8);
      uint32_t flags = guest_read32(range + 12);
      range_count++;
      if (range_count > VIRTIO_BLK_MAX_ZERO_RANGE_SEG ||
          num_sectors > VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS) {
        return false;
      }
      if (is_write_zeroes) {
        if ((flags & ~VIRTIO_BLK_WRITE_ZEROES_FLAG_UNMAP) != 0) return false;
      } else if (flags != 0) {
        return false;
      }
      // raw image 后端没有 hole-punch 接口；DISCARD 与 WRITE_ZEROES 都采用确定性写零，
      // 既避免读取旧数据的不确定性，也为后续 async/multiqueue 复用同一 offset I/O 路径。
      if (!virtio_blk_zero_range_from_sector(sector, num_sectors)) return false;
    }
  }
  return true;
}

static uint32_t virtio_blk_handle_chain(uint16_t head) {
  VirtqDesc descs[VIRTIO_BLK_MAX_CHAIN];
  int count = 0;
  if (!virtq_collect_chain(head, descs, &count)) return 0;
  if (count < 2 || descs[0].len < 16) return 0;
  if (descs[0].flags & VIRTQ_DESC_F_WRITE) return 0;
  if (!guest_range_ok(descs[0].addr, 16)) return 0;

  uint32_t type = guest_read32(descs[0].addr);
  uint64_t sector = guest_read64(descs[0].addr + 8);
  uint8_t status = VIRTIO_BLK_S_OK;
  uint32_t used_len = 0;
  uint64_t offset = sector * VIRTIO_BLK_SECTOR_SIZE;
  int status_desc = count - 1;

  if ((descs[status_desc].flags & VIRTQ_DESC_F_WRITE) == 0 || descs[status_desc].len < 1) {
    return 0;
  }

  if (type == VIRTIO_BLK_T_IN) {
    for (int i = 1; i < status_desc; i++) {
      if ((descs[i].flags & VIRTQ_DESC_F_WRITE) == 0 ||
          !disk_read_to_guest(descs[i].addr, descs[i].len, &offset)) {
        status = VIRTIO_BLK_S_IOERR;
        break;
      }
      used_len += descs[i].len;
    }
  } else if (type == VIRTIO_BLK_T_OUT) {
    for (int i = 1; i < status_desc; i++) {
      if ((descs[i].flags & VIRTQ_DESC_F_WRITE) != 0 ||
          !disk_write_from_guest(descs[i].addr, descs[i].len, &offset)) {
        status = VIRTIO_BLK_S_IOERR;
        break;
      }
    }
  } else if (type == VIRTIO_BLK_T_FLUSH) {
    if (disk_fp != NULL &&
        (fflush(disk_fp) != 0 || fsync(fileno(disk_fp)) != 0)) {
      status = VIRTIO_BLK_S_IOERR;
    }
  } else if (type == VIRTIO_BLK_T_GET_ID) {
    // Linux 的 /sys/block/vda/serial 会触发 GET_ID；按规范写满固定 20B，
    // 即使未来请求被拆成多个 writable descriptor 也能返回稳定设备身份。
    if (!virtio_blk_write_id(descs, status_desc, &used_len)) {
      status = VIRTIO_BLK_S_IOERR;
    }
  } else if (type == VIRTIO_BLK_T_DISCARD) {
    if (!virtio_blk_driver_feature_enabled(VIRTIO_BLK_F_DISCARD)) {
      status = VIRTIO_BLK_S_UNSUPP;
    } else if (!virtio_blk_handle_zero_ranges(descs, status_desc, false)) {
      status = VIRTIO_BLK_S_IOERR;
    }
  } else if (type == VIRTIO_BLK_T_WRITE_ZEROES) {
    if (!virtio_blk_driver_feature_enabled(VIRTIO_BLK_F_WRITE_ZEROES)) {
      status = VIRTIO_BLK_S_UNSUPP;
    } else if (!virtio_blk_handle_zero_ranges(descs, status_desc, true)) {
      status = VIRTIO_BLK_S_IOERR;
    }
  } else {
    status = VIRTIO_BLK_S_UNSUPP;
  }

  if (!guest_copy_to(descs[status_desc].addr, &status, 1)) return 0;
  return used_len + 1;
}

static void virtio_blk_process_queue(void) {
  if (disk_fp == NULL || !queue0.ready || queue0.num == 0 ||
      queue0.desc == 0 || queue0.driver == 0 || queue0.device == 0) {
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
    uint32_t used_len = virtio_blk_handle_chain(head);
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
    if (virtio_blk_event_idx_enabled()) {
      uint16_t used_event = guest_range_ok(virtq_used_event_addr(), 2) ?
        guest_read16(virtq_used_event_addr()) : old_used_idx;
      notify = virtq_need_event(used_event, used_idx, old_used_idx);
    } else {
      notify = (avail_flags & VRING_AVAIL_F_NO_INTERRUPT) == 0;
    }

    if (notify) {
      // virtio-mmio 用 interrupt status bit 通知 used ring 更新，再由 PLIC IRQ2 送到 Linux。
      interrupt_status |= VIRTIO_MMIO_INT_USED_BUFFER;
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk used interrupt avail_idx=%u last_avail=%u old_used=%u new_used=%u event_idx=%u",
          avail_idx, queue0.last_avail_idx, old_used_idx, used_idx, virtio_blk_event_idx_enabled());
      virtio_blk_raise_irq();
    } else {
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk used interrupt suppressed avail_idx=%u last_avail=%u old_used=%u new_used=%u event_idx=%u",
          avail_idx, queue0.last_avail_idx, old_used_idx, used_idx, virtio_blk_event_idx_enabled());
    }
  }
}

static void virtio_blk_reset(void) {
  memset(driver_features, 0, sizeof(driver_features));
  memset(&queue0, 0, sizeof(queue0));
  device_features_sel = 0;
  driver_features_sel = 0;
  interrupt_status = 0;
  device_status = 0;
  queue_sel = 0;
  virtio_blk_raise_irq();
}

static uint32_t virtio_read_reg(uint32_t offset) {
  switch (offset) {
    case VIRTIO_MMIO_MAGIC: return 0x74726976u;
    case VIRTIO_MMIO_VERSION: return VIRTIO_MMIO_VERSION_2;
    case VIRTIO_MMIO_DEVICE_ID: return disk_fp != NULL ? VIRTIO_BLK_DEVICE_ID : 0;
    case VIRTIO_MMIO_VENDOR_ID: return VIRTIO_VENDOR_YSYX;
    case VIRTIO_MMIO_DEVICE_FEATURES:
      return virtio_blk_device_features(device_features_sel);
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL: return device_features_sel;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL: return driver_features_sel;
    case VIRTIO_MMIO_QUEUE_SEL: return queue_sel;
    case VIRTIO_MMIO_QUEUE_NUM_MAX: return queue_sel == 0 ? VIRTIO_BLK_QUEUE_SIZE : 0;
    case VIRTIO_MMIO_QUEUE_NUM: return queue0.num;
    case VIRTIO_MMIO_QUEUE_READY: return queue0.ready ? 1 : 0;
    case VIRTIO_MMIO_INTERRUPT_STATUS:
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk read interrupt status=0x%08x", interrupt_status);
      return interrupt_status;
    case VIRTIO_MMIO_STATUS: return device_status;
    case VIRTIO_MMIO_QUEUE_DESC_LOW: return (uint32_t)queue0.desc;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH: return (uint32_t)((uint64_t)queue0.desc >> 32);
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW: return (uint32_t)queue0.driver;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH: return (uint32_t)((uint64_t)queue0.driver >> 32);
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW: return (uint32_t)queue0.device;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH: return (uint32_t)((uint64_t)queue0.device >> 32);
    case VIRTIO_MMIO_CONFIG_GENERATION: return 0;
    case VIRTIO_MMIO_CONFIG: return (uint32_t)(disk_size / VIRTIO_BLK_SECTOR_SIZE);
    case VIRTIO_MMIO_CONFIG + 4: return (uint32_t)((disk_size / VIRTIO_BLK_SECTOR_SIZE) >> 32);
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_BLK_SIZE:
      // Linux virtio-blk 只有在协商 BLK_SIZE 后才读取这里；显式返回 512B，
      // 避免 guest 队列限制只是依赖内核默认值。
      return VIRTIO_BLK_SECTOR_SIZE;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_PHYSICAL_BLOCK_EXP:
      // TOPOLOGY 用最保守的 512B 物理块、0 对齐偏移和 512B minimum I/O，
      // 让 Linux 的 queue topology 走标准 virtio config 路径而不是默认猜测。
      return 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_ALIGNMENT_OFFSET:
      return 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MIN_IO_SIZE:
      return 1;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_OPT_IO_SIZE:
      return 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WCE:
      // CONFIG_WCE 让 Linux /sys/block/vda/cache_type 能读写缓存模式；
      // write-through 模式下写请求会在完成前同步落盘，避免该 sysfs 控制只是空壳。
      return disk_writeback ? 1 : 0;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_DISCARD_SECTORS:
      // 暴露保守的 2MiB 单段上限；后端按 offset 分块 pwrite 零化，不依赖 FILE seek 状态。
      return VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_DISCARD_SEG:
      return VIRTIO_BLK_MAX_ZERO_RANGE_SEG;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_DISCARD_SECTOR_ALIGNMENT:
      return 1;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SECTORS:
      return VIRTIO_BLK_MAX_ZERO_RANGE_SECTORS;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_MAX_WRITE_ZEROES_SEG:
      return VIRTIO_BLK_MAX_ZERO_RANGE_SEG;
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITE_ZEROES_MAY_UNMAP:
      return 0;
    default: return 0;
  }
}

static void virtio_write_reg(uint32_t offset, uint32_t value) {
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
    case VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WCE:
      disk_writeback = (value & 1u) != 0;
      break;
    case VIRTIO_MMIO_QUEUE_SEL:
      queue_sel = value;
      break;
    case VIRTIO_MMIO_QUEUE_NUM:
      if (queue_sel == 0) queue0.num = value <= VIRTIO_BLK_QUEUE_SIZE ? value : VIRTIO_BLK_QUEUE_SIZE;
      break;
    case VIRTIO_MMIO_QUEUE_READY:
      if (queue_sel == 0) {
        queue0.ready = (value & 1u) != 0;
        queue0.last_avail_idx = queue0.ready ? guest_read16(queue0.driver + 2) : 0;
        if (queue0.ready) virtq_set_avail_event(queue0.last_avail_idx);
      }
      break;
    case VIRTIO_MMIO_QUEUE_NOTIFY:
      // Linux 写 QueueNotify 后，设备同步消费当前 avail ring；解释器模型不需要后台线程。
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk queue notify value=%u ready=%u num=%u last_avail=%u avail_idx=%u",
          value, queue0.ready, queue0.num, queue0.last_avail_idx,
          queue0.driver != 0 ? guest_read16(queue0.driver + 2) : 0);
      if (value == 0) virtio_blk_process_queue();
      break;
    case VIRTIO_MMIO_INTERRUPT_ACK:
      VIRTIO_IRQ_DEBUG_LOG("virtio-blk interrupt ack value=0x%08x old_status=0x%08x",
          value, interrupt_status);
      interrupt_status &= ~value;
      virtio_blk_raise_irq();
      break;
    case VIRTIO_MMIO_STATUS:
      if (value == 0) {
        virtio_blk_reset();
      } else {
        // virtio 要求设备只在 driver 选择的 feature 全部受支持时保留 FEATURES_OK；
        // 否则后续 queue/IO 不能进入 DRIVER_OK，避免错误协商被 Linux 或 smoke 误当成功。
        device_status = value;
        if ((value & VIRTIO_STATUS_FEATURES_OK) &&
            !virtio_blk_driver_features_supported()) {
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

static void virtio_blk_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1 || len == 2 || len == 4 || len == 8);
  if (is_write) {
    if (len == 1 || len == 2 || len == 4) {
      virtio_write_reg(offset, host_read(virtio_base + offset, len));
    } else if (len == 8) {
      virtio_write_reg(offset, host_read(virtio_base + offset, 4));
      virtio_write_reg(offset + 4, host_read(virtio_base + offset + 4, 4));
    }
    return;
  }

  if (len == 8) {
    host_write(virtio_base + offset, 4, virtio_read_reg(offset));
    host_write(virtio_base + offset + 4, 4, virtio_read_reg(offset + 4));
  } else {
    host_write(virtio_base + offset, len, virtio_read_reg(offset));
  }
}

static void open_disk_image(void) {
  const char *path = disk_image_path;
  if ((path == NULL || path[0] == '\0') && strlen(CONFIG_DISK_IMG_PATH) > 0) {
    path = CONFIG_DISK_IMG_PATH;
  }
  if (path == NULL || path[0] == '\0') {
    Log("virtio-blk: no --block image, device id stays 0");
    return;
  }

  disk_fp = fopen(path, "r+b");
  if (disk_fp == NULL) {
    disk_fp = fopen(path, "rb");
    disk_readonly = true;
  }
  Assert(disk_fp != NULL, "Can not open block image '%s': %s", path, strerror(errno));
  Assert(fseeko(disk_fp, 0, SEEK_END) == 0, "Can not seek block image '%s'", path);
  off_t size = ftello(disk_fp);
  Assert(size > 0, "Invalid block image size for '%s'", path);
  disk_size = size;
  rewind(disk_fp);
  if (disk_log_budget > 0) {
    disk_log_budget--;
    Log("virtio-blk: image=%s size=%" PRIu64 " bytes%s",
        path, disk_size, disk_readonly ? " readonly" : "");
  }
}

void init_disk() {
  virtio_base = new_space(0x1000);
  virtio_blk_reset();
  open_disk_image();
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("virtio-blk", CONFIG_DISK_CTL_PORT, virtio_base, 0x1000, virtio_blk_io_handler);
#else
  add_mmio_map("virtio-blk", CONFIG_DISK_CTL_MMIO, virtio_base, 0x1000, virtio_blk_io_handler);
#endif
}

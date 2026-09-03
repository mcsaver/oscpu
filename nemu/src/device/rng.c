/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <device/virtio.h>
#include <isa.h>
#include <memory/host.h>
#include <memory/paddr.h>

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// Ubuntu/systemd 长跑需要稳定熵源；这里实现 Virtio 1.x entropy
// device 的设备语义，MMIO transport 与 split virtqueue 原语由 device/virtio.h 统一定义。
#define VIRTIO_RNG_QUEUE_SIZE 8u
#define VIRTIO_RNG_MAX_CHAIN 16u
#define VIRTIO_RNG_IRQ 3u

static uint8_t *rng_base;
static VirtioMmioTransportState transport;
static VirtqueueState queue0;
static int rng_fd = -1;
static bool rng_backend_failure_logged;

static const IoAccessPolicy virtio_rng_mmio_policy __attribute__((unused)) = {
  .parent = &virtio_mmio_transport_policy,
};

static uint32_t virtio_rng_device_features(uint32_t sel) {
  if (sel == 0) {
    return (1u << VIRTIO_RING_F_INDIRECT_DESC) |
           (1u << VIRTIO_RING_F_EVENT_IDX);
  }
  if (sel == 1) {
    return 1u << (VIRTIO_F_VERSION_1 - 32);
  }
  return 0;
}

static bool virtio_rng_driver_features_supported(void) {
  if (!virtio_driver_feature_enabled(&transport, VIRTIO_F_VERSION_1)) {
    return false;
  }
  for (uint32_t sel = 0; sel < 2; sel++) {
    uint32_t unsupported =
        transport.driver_features[sel] & ~virtio_rng_device_features(sel);
    if (unsupported != 0) return false;
  }
  return true;
}

static bool virtio_rng_driver_feature_enabled(uint32_t bit) {
  return virtio_driver_feature_enabled(&transport, bit);
}

static bool virtio_rng_event_idx_enabled(void) {
  return virtio_rng_driver_feature_enabled(VIRTIO_RING_F_EVENT_IDX);
}

static bool virtio_rng_indirect_desc_enabled(void) {
  return virtio_feature_negotiated(&transport, VIRTIO_RING_F_INDIRECT_DESC);
}

static const char *virtio_rng_backend_name(void) {
  return rng_fd >= 0 ? "host-urandom" : "unavailable";
}

static const char *json_bool(bool value) {
  return value ? "true" : "false";
}

static void virtio_rng_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv,
      isa_riscv_plic_set_irq(VIRTIO_RNG_IRQ, transport.interrupt_status != 0));
}

static uint16_t guest_read16(GuestDmaAddr addr) {
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, 2, &resolved) ?
      (uint16_t)paddr_dma_read_value(resolved, 2) : 0;
}

static uint32_t guest_read32(GuestDmaAddr addr) {
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, 4, &resolved) ?
      (uint32_t)paddr_dma_read_value(resolved, 4) : 0;
}

static uint64_t guest_read64(GuestDmaAddr addr) {
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, 8, &resolved) ?
      paddr_dma_read_value(resolved, 8) : 0;
}

static void guest_write16(GuestDmaAddr addr, uint16_t value) {
  paddr_t resolved;
  if (virtio_dma_resolve_span(addr, 2, &resolved)) {
    paddr_dma_write_value(resolved, 2, value);
  }
}

static void guest_write32(GuestDmaAddr addr, uint32_t value) {
  paddr_t resolved;
  if (virtio_dma_resolve_span(addr, 4, &resolved)) {
    paddr_dma_write_value(resolved, 4, value);
  }
}

static bool guest_range_ok(GuestDmaAddr addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t resolved;
  return virtio_dma_resolve_span(addr, len, &resolved);
}

static GuestDmaAddr virtq_used_event_addr(void) {
  return queue0.driver + 4 + (GuestDmaAddr)queue0.num * 2;
}

static GuestDmaAddr virtq_avail_event_addr(void) {
  return queue0.device + 4 + (GuestDmaAddr)queue0.num * 8;
}

static void virtq_set_avail_event(uint16_t avail_idx) {
  if (virtio_rng_event_idx_enabled() && queue0.num != 0 &&
      guest_range_ok(virtq_avail_event_addr(), 2)) {
    // rng 和 blk/net 一样不主动抑制 driver kick，只把设备消费进度回写给 Linux。
    guest_write16(queue0.device, 0);
    guest_write16(virtq_avail_event_addr(), avail_idx);
  }
}

static bool virtq_aligned(GuestDmaAddr addr, uint32_t align) {
  return (addr & (GuestDmaAddr)(align - 1)) == 0;
}

static bool virtq_dma_range_valid(const char *name, GuestDmaAddr addr,
    uint32_t len, uint32_t align) {
  if (addr != 0 && virtq_aligned(addr, align) && guest_range_ok(addr, len)) {
    return true;
  }
  Log("virtio-rng: invalid %s ring addr=0x%" PRIx64 " len=%u align=%u",
      name, (uint64_t)addr, len, align);
  return false;
}

static bool virtq_validate_queue_layout(void) {
  VirtioSplitRingSpan span;
  if (!virtio_split_ring_span(queue0.num, VIRTIO_RNG_QUEUE_SIZE,
      virtio_rng_event_idx_enabled(), &span)) {
    Log("virtio-rng: invalid QueueNum=%u max=%u",
        queue0.num, VIRTIO_RNG_QUEUE_SIZE);
    return false;
  }

  // QueueReady 是 hwrng 真正收发前的边界；提前拒绝坏 vring，避免异步熵请求卡死。
  return virtq_dma_range_valid("desc", queue0.desc, span.descriptor_bytes, 16) &&
         virtq_dma_range_valid("driver", queue0.driver, span.driver_bytes, 2) &&
         virtq_dma_range_valid("device", queue0.device, span.device_bytes, 4);
}

static bool guest_copy_to(GuestDmaAddr addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  paddr_t resolved;
  if (!virtio_dma_resolve_span(addr, len, &resolved)) return false;
  return paddr_dma_write(resolved, buf, len);
}

static bool virtq_read_desc_from(GuestDmaAddr table, uint16_t table_num,
    uint16_t idx, VirtqueueDescriptor *desc) {
  if (idx >= table_num) return false;
  GuestDmaAddr base;
  if (!virtio_guest_dma_add(table, (uint64_t)idx * 16, &base)) return false;
  if (!guest_range_ok(base, 16)) return false;
  desc->addr = guest_read64(base);
  desc->len = guest_read32(base + 8);
  desc->flags = guest_read16(base + 12);
  desc->next = guest_read16(base + 14);
  return true;
}

static bool virtq_collect_table(GuestDmaAddr table, uint16_t table_num, uint16_t head,
    VirtqueueDescriptor *out, int *out_count) {
  if (table_num == 0 || table_num > VIRTIO_RNG_MAX_CHAIN) return false;

  bool seen[VIRTIO_RNG_MAX_CHAIN] = {};
  uint16_t idx = head;
  int count = 0;

  while (true) {
    if (idx >= table_num || seen[idx] ||
        count >= (int)VIRTIO_RNG_MAX_CHAIN) {
      return false;
    }
    seen[idx] = true;
    if (!virtq_read_desc_from(table, table_num, idx, &out[count])) return false;
    // indirect 描述符只允许出现在主队列 head，二级表内禁止再次嵌套。
    if (out[count].flags & VIRTQUEUE_DESCRIPTOR_F_INDIRECT) return false;
    count++;
    if ((out[count - 1].flags & VIRTQUEUE_DESCRIPTOR_F_NEXT) == 0) break;
    idx = out[count - 1].next;
  }

  *out_count = count;
  return true;
}

static bool virtq_collect_chain(uint16_t head, VirtqueueDescriptor *out, int *out_count) {
  VirtqueueDescriptor first;
  if (!virtq_read_desc_from(queue0.desc, queue0.num, head, &first)) return false;

  if (first.flags & VIRTQUEUE_DESCRIPTOR_F_INDIRECT) {
    if (!virtio_rng_indirect_desc_enabled() ||
        (first.flags & (VIRTQUEUE_DESCRIPTOR_F_NEXT | VIRTQUEUE_DESCRIPTOR_F_WRITE)) ||
        first.len == 0 || (first.len % 16) != 0 ||
        !guest_range_ok(first.addr, first.len)) {
      return false;
    }
    uint32_t indirect_num = first.len / 16;
    if (indirect_num == 0 || indirect_num > VIRTIO_RNG_MAX_CHAIN) return false;
    // hwrng 小请求也可能经 virtio core 合并为 indirect table；按规范展开后再填熵。
    return virtq_collect_table(first.addr, indirect_num, 0, out, out_count);
  }

  return virtq_collect_table(queue0.desc, queue0.num, head, out, out_count);
}

static void virtio_rng_try_open_backend(void) {
  if (rng_fd >= 0) return;
  rng_fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
  if (rng_fd >= 0) {
    rng_backend_failure_logged = false;
  } else if (!rng_backend_failure_logged) {
    Log("virtio-rng: cannot open /dev/urandom: %s", strerror(errno));
    rng_backend_failure_logged = true;
  }
}

static void virtio_rng_backend_failed(const char *reason) {
  if (rng_fd >= 0) {
    close(rng_fd);
    rng_fd = -1;
  }
  if (!rng_backend_failure_logged) {
    Log("virtio-rng: entropy backend failed closed: %s", reason);
    rng_backend_failure_logged = true;
  }
  if (virtio_transport_set_needs_reset(&transport)) {
    virtio_rng_raise_irq();
  }
}

static bool rng_fill(uint8_t *buf, uint32_t len) {
  if (rng_fd < 0) {
    virtio_rng_backend_failed("/dev/urandom unavailable");
    return false;
  }
  uint32_t done = 0;
  while (done < len) {
    ssize_t n = read(rng_fd, buf + done, len - done);
    if (n > 0) {
      done += (uint32_t)n;
      continue;
    }
    if (n < 0 && errno == EINTR) {
      continue;
    }
    char reason[96];
    if (n == 0) {
      snprintf(reason, sizeof(reason), "/dev/urandom returned EOF");
    } else {
      snprintf(reason, sizeof(reason), "/dev/urandom read: %s", strerror(errno));
    }
    virtio_rng_backend_failed(reason);
    return false;
  }
  return true;
}

static uint32_t virtio_rng_handle_chain(uint16_t head) {
  VirtqueueDescriptor descs[VIRTIO_RNG_MAX_CHAIN];
  int count = 0;
  if (!virtq_collect_chain(head, descs, &count)) return 0;

  uint32_t used_len = 0;
  uint8_t buf[256];
  for (int i = 0; i < count; i++) {
    if ((descs[i].flags & VIRTQUEUE_DESCRIPTOR_F_WRITE) == 0) {
      return 0;
    }
    GuestDmaAddr addr = descs[i].addr;
    uint32_t left = descs[i].len;
    while (left > 0) {
      uint32_t chunk = left < sizeof(buf) ? left : sizeof(buf);
      if (!rng_fill(buf, chunk)) return used_len;
      if (!guest_copy_to(addr, buf, chunk)) return used_len;
      addr += chunk;
      used_len += chunk;
      left -= chunk;
    }
  }
  return used_len;
}

static void virtio_rng_process_queue(void) {
  if (!virtio_queue_notify_allowed(&transport, &queue0) ||
      queue0.num == 0 || queue0.desc == 0 ||
      queue0.driver == 0 || queue0.device == 0) {
    return;
  }
  if (rng_fd < 0) {
    virtio_rng_backend_failed("/dev/urandom unavailable");
    return;
  }

  bool used_any = false;
  uint16_t avail_flags = guest_read16(queue0.driver);
  uint16_t avail_idx = guest_read16(queue0.driver + 2);
  uint16_t pending_count = 0;
  if (!virtqueue_pending_count(queue0.last_avail_idx, avail_idx,
          queue0.num, &pending_count)) {
    Log("virtio-rng: invalid split-ring avail delta last=%u avail=%u num=%u",
        queue0.last_avail_idx, avail_idx, queue0.num);
    if (virtio_transport_set_needs_reset(&transport)) virtio_rng_raise_irq();
    return;
  }
  uint16_t old_used_idx = guest_read16(queue0.device + 2);
  uint16_t used_idx = old_used_idx;
  while (pending_count != 0) {
    uint16_t ring_off = queue0.last_avail_idx % queue0.num;
    uint16_t head = guest_read16(queue0.driver + 4 + ring_off * 2);
    uint32_t used_len = virtio_rng_handle_chain(head);
    if ((transport.device_status & VIRTIO_STATUS_DEVICE_NEEDS_RESET) != 0) {
      break;
    }
    uint16_t used_off = used_idx % queue0.num;
    guest_write32(queue0.device + 4 + used_off * 8, head);
    guest_write32(queue0.device + 4 + used_off * 8 + 4, used_len);
    used_idx++;
    guest_write16(queue0.device + 2, used_idx);
    queue0.last_avail_idx++;
    pending_count--;
    used_any = true;
  }
  virtq_set_avail_event(queue0.last_avail_idx);

  if (used_any) {
    bool notify = true;
    if (virtio_rng_event_idx_enabled()) {
      uint16_t used_event = guest_range_ok(virtq_used_event_addr(), 2) ?
        guest_read16(virtq_used_event_addr()) : old_used_idx;
      notify = virtqueue_event_needed(used_event, used_idx, old_used_idx);
    } else {
      notify =
          (avail_flags & VIRTQUEUE_AVAILABLE_F_NO_INTERRUPT) == 0;
    }
    if (notify) {
      // hwrng 驱动等待 used ring 完成；EVENT_IDX 协商后按 used_event 抑制多余 IRQ3。
      virtio_transport_raise_interrupt(
          &transport, VIRTIO_INTERRUPT_USED_BUFFER);
      virtio_rng_raise_irq();
    }
  }
}

static void virtio_rng_reset(void) {
  /* Status=0 performs the transport reset required by Virtio 1.x. */
  virtio_transport_reset(&transport);
  memset(&queue0, 0, sizeof(queue0));
  virtio_rng_try_open_backend();
  virtio_rng_raise_irq();
}

static uint32_t virtio_rng_read_reg(uint32_t offset) {
  switch (offset) {
    case VIRTIO_MMIO_MAGIC: return VIRTIO_MMIO_MAGIC_VALUE;
    case VIRTIO_MMIO_VERSION: return VIRTIO_MMIO_VERSION_MODERN;
    case VIRTIO_MMIO_DEVICE_ID: return VIRTIO_DEVICE_ID_ENTROPY;
    case VIRTIO_MMIO_VENDOR_ID: return VIRTIO_VENDOR_YSYX;
    case VIRTIO_MMIO_DEVICE_FEATURES:
      return virtio_rng_device_features(transport.device_features_select);
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL: return transport.device_features_select;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL: return transport.driver_features_select;
    case VIRTIO_MMIO_QUEUE_SEL: return transport.queue_select;
    case VIRTIO_MMIO_QUEUE_NUM_MAX:
      return transport.queue_select == 0 ? VIRTIO_RNG_QUEUE_SIZE : 0;
    case VIRTIO_MMIO_QUEUE_NUM: return queue0.num;
    case VIRTIO_MMIO_QUEUE_READY: return queue0.ready ? 1 : 0;
    case VIRTIO_MMIO_INTERRUPT_STATUS: return transport.interrupt_status;
    case VIRTIO_MMIO_STATUS: return transport.device_status;
    case VIRTIO_MMIO_QUEUE_DESC_LOW: return (uint32_t)queue0.desc;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      return (uint32_t)((uint64_t)queue0.desc >> 32);
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW: return (uint32_t)queue0.driver;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      return (uint32_t)((uint64_t)queue0.driver >> 32);
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW: return (uint32_t)queue0.device;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      return (uint32_t)((uint64_t)queue0.device >> 32);
    case VIRTIO_MMIO_CONFIG_GENERATION: return transport.config_generation;
    default: return 0;
  }
}

static void virtio_rng_write_reg(uint32_t offset, uint32_t value) {
  switch (offset) {
    case VIRTIO_MMIO_DEVICE_FEATURES_SEL:
      transport.device_features_select = value;
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES:
      if (transport.driver_features_select < 2 &&
          virtio_transport_driver_features_write_allowed(&transport)) {
        transport.driver_features[transport.driver_features_select] = value;
      }
      break;
    case VIRTIO_MMIO_DRIVER_FEATURES_SEL:
      transport.driver_features_select = value;
      break;
    case VIRTIO_MMIO_QUEUE_SEL:
      transport.queue_select = value;
      break;
    case VIRTIO_MMIO_QUEUE_NUM:
      if (transport.queue_select == 0) {
        if (!virtio_queue_config_write_allowed(&queue0)) {
          Log("virtio-rng: reject QueueNum write while QueueReady=1");
        } else if (virtio_split_queue_size_valid(value, VIRTIO_RNG_QUEUE_SIZE)) {
          queue0.num = value;
        } else {
          // 不能静默 clamp QueueNum；坏驱动必须在配置阶段暴露，而不是假装队列可用。
          Log("virtio-rng: reject unsupported QueueNum=%u max=%u",
              value, VIRTIO_RNG_QUEUE_SIZE);
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_READY:
      if (transport.queue_select == 0) {
        bool validate_layout = value == 1 && !queue0.ready;
        VirtioQueueReadyWriteResult result = virtio_queue_ready_decode(
            &queue0, value, !validate_layout || virtq_validate_queue_layout());
        if (result == VIRTIO_QUEUE_READY_DISABLED) {
          queue0.ready = false;
          queue0.last_avail_idx = 0;
        } else if (result == VIRTIO_QUEUE_READY_ENABLED) {
          queue0.ready = true;
          queue0.last_avail_idx = guest_read16(queue0.driver + 2);
          virtq_set_avail_event(queue0.last_avail_idx);
        } else if (result == VIRTIO_QUEUE_READY_INVALID_LAYOUT) {
          queue0.ready = false;
          queue0.last_avail_idx = 0;
        } else if (result == VIRTIO_QUEUE_READY_INVALID_VALUE) {
          Log("virtio-rng: reject invalid QueueReady value=%u", value);
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_NOTIFY:
      if (value == 0 && virtio_queue_notify_allowed(&transport, &queue0)) {
        virtio_rng_process_queue();
      } else if (value == 0) {
        Log("virtio-rng: reject QueueNotify before DRIVER_OK or QueueReady");
      }
      break;
    case VIRTIO_MMIO_INTERRUPT_ACK:
      virtio_transport_acknowledge_interrupt(&transport, value);
      virtio_rng_raise_irq();
      break;
    case VIRTIO_MMIO_STATUS:
      if (value == 0) {
        virtio_rng_reset();
      } else {
        VirtioStatusWriteResult result = virtio_transport_accept_status(
            &transport, value, virtio_rng_driver_features_supported());
        if (result == VIRTIO_STATUS_FEATURES_REJECTED) {
          Log("virtio-rng: reject unsupported negotiated features");
        } else if (result == VIRTIO_STATUS_INVALID_TRANSITION) {
          Log("virtio-rng: reject invalid Status progression value=0x%08x", value);
        }
        if (result == VIRTIO_STATUS_ACCEPTED && rng_fd < 0 &&
            (transport.device_status & VIRTIO_STATUS_DRIVER_OK) != 0) {
          virtio_rng_backend_failed("/dev/urandom unavailable");
        }
      }
      break;
    case VIRTIO_MMIO_QUEUE_DESC_LOW:
      if (transport.queue_select == 0 && virtio_queue_config_write_allowed(&queue0))
        virtqueue_write_address_low(&queue0.desc, value);
      break;
    case VIRTIO_MMIO_QUEUE_DESC_HIGH:
      if (transport.queue_select == 0 && virtio_queue_config_write_allowed(&queue0))
        virtqueue_write_address_high(&queue0.desc, value);
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_LOW:
      if (transport.queue_select == 0 && virtio_queue_config_write_allowed(&queue0))
        virtqueue_write_address_low(&queue0.driver, value);
      break;
    case VIRTIO_MMIO_QUEUE_DRIVER_HIGH:
      if (transport.queue_select == 0 && virtio_queue_config_write_allowed(&queue0))
        virtqueue_write_address_high(&queue0.driver, value);
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_LOW:
      if (transport.queue_select == 0 && virtio_queue_config_write_allowed(&queue0))
        virtqueue_write_address_low(&queue0.device, value);
      break;
    case VIRTIO_MMIO_QUEUE_DEVICE_HIGH:
      if (transport.queue_select == 0 && virtio_queue_config_write_allowed(&queue0))
        virtqueue_write_address_high(&queue0.device, value);
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
  virtio_rng_reset();
#ifdef NEMU_HAS_PORT_IO
  add_pio_map("virtio-rng", DEV_VIRTIO_RNG_MMIO, rng_base, 0x1000,
      virtio_rng_io_handler);
#else
  add_mmio_map_with_policy("virtio-rng", DEV_VIRTIO_RNG_MMIO, rng_base,
      0x1000, virtio_rng_io_handler, &virtio_rng_mmio_policy);
#endif
}

void virtio_rng_dump_machine_info(FILE *out) {
  // machine-info 导出真实后端和协商状态，避免 e2e 只看到“设备存在”却看不到 hwrng 能力边界。
  fprintf(out, "device.virtio_rng.model=virtio-rng-mmio\n");
  fprintf(out, "device.virtio_rng.backend=%s\n", virtio_rng_backend_name());
  fprintf(out, "device.virtio_rng.backend_source=%s\n",
      rng_fd >= 0 ? "/dev/urandom" : "unavailable");
  fprintf(out, "device.virtio_rng.mmio_version=%u\n", VIRTIO_MMIO_VERSION_MODERN);
  fprintf(out, "device.virtio_rng.device_id=%u\n", VIRTIO_DEVICE_ID_ENTROPY);
  fprintf(out, "device.virtio_rng.vendor_id=0x%08x\n", VIRTIO_VENDOR_YSYX);
  fprintf(out, "device.virtio_rng.queue_count=1\n");
  fprintf(out, "device.virtio_rng.queue_num_max=%u\n", VIRTIO_RNG_QUEUE_SIZE);
  fprintf(out, "device.virtio_rng.features.version_1=1\n");
  fprintf(out, "device.virtio_rng.features.indirect_desc=1\n");
  fprintf(out, "device.virtio_rng.features.event_idx=1\n");
  fprintf(out, "device.virtio_rng.driver_features.version_1=%d\n",
      virtio_rng_driver_feature_enabled(VIRTIO_F_VERSION_1) ? 1 : 0);
  fprintf(out, "device.virtio_rng.driver_features.indirect_desc=%d\n",
      virtio_rng_indirect_desc_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_rng.driver_features.event_idx=%d\n",
      virtio_rng_event_idx_enabled() ? 1 : 0);
  fprintf(out, "device.virtio_rng.queue_ready=%d\n", queue0.ready ? 1 : 0);
  fprintf(out, "device.virtio_rng.status=0x%08x\n", transport.device_status);
  fprintf(out, "device.virtio_rng.interrupt_status=0x%08x\n",
      transport.interrupt_status);
  fprintf(out, "device.virtio_rng.config_generation=%u\n",
      transport.config_generation);
}

void virtio_rng_qmp_query_rng(char *out, size_t out_size) {
  snprintf(out, out_size,
      "{\"return\":[{\"id\":\"rng0\",\"type\":\"virtio-rng\","
      "\"model\":\"virtio-rng-mmio\",\"backend\":\"%s\","
      "\"filename\":\"%s\",\"nemu\":{\"mmio\":\"0x%08x\",\"irq\":%u,"
      "\"device-id\":%u,\"vendor-id\":\"0x%08x\",\"version\":%u,"
      "\"queue-count\":1,\"queue-num-max\":%u,\"queue-ready\":%s,"
      "\"device-status\":%u,\"interrupt-status\":%u,"
      "\"features\":{\"version-1\":true,\"indirect-desc\":true,\"event-idx\":true},"
      "\"driver-features\":{\"version-1\":%s,\"indirect-desc\":%s,\"event-idx\":%s},"
      "\"last-avail-idx\":%u}}]}",
      virtio_rng_backend_name(),
      rng_fd >= 0 ? "/dev/urandom" : "unavailable",
      DEV_VIRTIO_RNG_MMIO, VIRTIO_RNG_IRQ,
      VIRTIO_DEVICE_ID_ENTROPY, VIRTIO_VENDOR_YSYX, VIRTIO_MMIO_VERSION_MODERN,
      VIRTIO_RNG_QUEUE_SIZE, json_bool(queue0.ready),
      transport.device_status, transport.interrupt_status,
      json_bool(virtio_rng_driver_feature_enabled(VIRTIO_F_VERSION_1)),
      json_bool(virtio_rng_indirect_desc_enabled()),
      json_bool(virtio_rng_event_idx_enabled()), queue0.last_avail_idx);
}

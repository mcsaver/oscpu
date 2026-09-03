/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/virtio.h>

#define VIRTIO_MMIO_REG32(reg_name, reg_offset, access) \
  { \
    .name = (reg_name), \
    .first_offset = (reg_offset), \
    .last_offset = (reg_offset) + 3u, \
    .stride = 4u, \
    .width_mask = IO_WIDTH_4, \
    .direction_mask = (access), \
    .naturally_aligned = true, \
  }

static const IoRegisterDescriptor virtio_mmio_transport_registers[] = {
  VIRTIO_MMIO_REG32("MagicValue", VIRTIO_MMIO_MAGIC, IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("Version", VIRTIO_MMIO_VERSION, IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("DeviceID", VIRTIO_MMIO_DEVICE_ID, IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("VendorID", VIRTIO_MMIO_VENDOR_ID, IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("DeviceFeatures", VIRTIO_MMIO_DEVICE_FEATURES,
      IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("DeviceFeaturesSel", VIRTIO_MMIO_DEVICE_FEATURES_SEL,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("DriverFeatures", VIRTIO_MMIO_DRIVER_FEATURES,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("DriverFeaturesSel", VIRTIO_MMIO_DRIVER_FEATURES_SEL,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueSel", VIRTIO_MMIO_QUEUE_SEL, IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueNumMax", VIRTIO_MMIO_QUEUE_NUM_MAX,
      IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("QueueNum", VIRTIO_MMIO_QUEUE_NUM, IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueReady", VIRTIO_MMIO_QUEUE_READY,
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueNotify", VIRTIO_MMIO_QUEUE_NOTIFY,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("InterruptStatus", VIRTIO_MMIO_INTERRUPT_STATUS,
      IO_TRANSACTION_READ),
  VIRTIO_MMIO_REG32("InterruptACK", VIRTIO_MMIO_INTERRUPT_ACK,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("Status", VIRTIO_MMIO_STATUS,
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueDescLow", VIRTIO_MMIO_QUEUE_DESC_LOW,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueDescHigh", VIRTIO_MMIO_QUEUE_DESC_HIGH,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueDriverLow", VIRTIO_MMIO_QUEUE_DRIVER_LOW,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueDriverHigh", VIRTIO_MMIO_QUEUE_DRIVER_HIGH,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueDeviceLow", VIRTIO_MMIO_QUEUE_DEVICE_LOW,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("QueueDeviceHigh", VIRTIO_MMIO_QUEUE_DEVICE_HIGH,
      IO_TRANSACTION_WRITE),
  VIRTIO_MMIO_REG32("ConfigGeneration", VIRTIO_MMIO_CONFIG_GENERATION,
      IO_TRANSACTION_READ),
};

const IoAccessPolicy virtio_mmio_transport_policy = {
  .registers = virtio_mmio_transport_registers,
  .register_count = ARRLEN(virtio_mmio_transport_registers),
};

#undef VIRTIO_MMIO_REG32

enum {
  VIRTIO_DRIVER_STATUS_MASK =
      VIRTIO_STATUS_ACKNOWLEDGE |
      VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_DRIVER_OK |
      VIRTIO_STATUS_FEATURES_OK |
      VIRTIO_STATUS_FAILED,
};

static VirtioStatusTransition virtio_status_invalid(
    uint32_t current_status, uint32_t rejected_bits) {
  return (VirtioStatusTransition) {
    .result = VIRTIO_STATUS_INVALID_TRANSITION,
    .next_status = current_status,
    .rejected_bits = rejected_bits,
  };
}

/*
 * Decode one non-legacy Status write without mutating transport state.
 * Non-zero writes set bits monotonically; zero is the only clearing/reset
 * operation.  Dependency checks express the initialization progression while
 * still permitting a driver to set several cumulative progress bits at once.
 */
VirtioStatusTransition virtio_status_decode(uint32_t current_status,
    uint32_t driver_status, bool driver_features_supported) {
  if (driver_status == 0) {
    return (VirtioStatusTransition) {
      .result = VIRTIO_STATUS_RESET_REQUESTED,
      .next_status = 0,
      .rejected_bits = 0,
    };
  }

  uint32_t new_driver_bits =
      (driver_status & VIRTIO_DRIVER_STATUS_MASK) & ~current_status;
  uint32_t invalid_bits = driver_status &
      ~(VIRTIO_DRIVER_STATUS_MASK | (current_status & VIRTIO_STATUS_DEVICE_NEEDS_RESET));
  if (invalid_bits != 0) {
    return virtio_status_invalid(current_status, invalid_bits);
  }

  /* FAILED is terminal until reset and takes priority over new init progress. */
  if ((new_driver_bits & VIRTIO_STATUS_FAILED) != 0) {
    return (VirtioStatusTransition) {
      .result = VIRTIO_STATUS_ACCEPTED,
      .next_status = current_status | VIRTIO_STATUS_FAILED,
      .rejected_bits = new_driver_bits & ~VIRTIO_STATUS_FAILED,
    };
  }
  if ((current_status & VIRTIO_STATUS_FAILED) != 0) {
    return new_driver_bits == 0 ?
        (VirtioStatusTransition) {
          .result = VIRTIO_STATUS_ACCEPTED,
          .next_status = current_status,
          .rejected_bits = 0,
        } : virtio_status_invalid(current_status, new_driver_bits);
  }

  uint32_t next_status = current_status |
      (driver_status & VIRTIO_DRIVER_STATUS_MASK);
  if ((next_status & VIRTIO_STATUS_DRIVER) != 0 &&
      (next_status & VIRTIO_STATUS_ACKNOWLEDGE) == 0) {
    return virtio_status_invalid(current_status, new_driver_bits);
  }
  if ((next_status & VIRTIO_STATUS_FEATURES_OK) != 0 &&
      (next_status & (VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER)) !=
          (VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER)) {
    return virtio_status_invalid(current_status, new_driver_bits);
  }

  if ((next_status & VIRTIO_STATUS_FEATURES_OK) != 0 &&
      !driver_features_supported) {
    uint32_t rejected = next_status &
        (VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK);
    next_status &= ~(VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK);
    return (VirtioStatusTransition) {
      .result = VIRTIO_STATUS_FEATURES_REJECTED,
      .next_status = next_status,
      .rejected_bits = rejected,
    };
  }

  if ((next_status & VIRTIO_STATUS_DRIVER_OK) != 0 &&
      (next_status & VIRTIO_STATUS_FEATURES_OK) == 0) {
    return virtio_status_invalid(current_status, new_driver_bits);
  }

  return (VirtioStatusTransition) {
    .result = VIRTIO_STATUS_ACCEPTED,
    .next_status = next_status,
    .rejected_bits = 0,
  };
}

VirtioStatusWriteResult virtio_transport_accept_status(
    VirtioMmioTransportState *transport, uint32_t driver_status,
    bool driver_features_supported) {
  VirtioStatusTransition transition = virtio_status_decode(
      transport->device_status, driver_status, driver_features_supported);
  if (transition.result == VIRTIO_STATUS_RESET_REQUESTED) {
    virtio_transport_reset(transport);
  } else {
    transport->device_status = transition.next_status;
  }
  return transition.result;
}

bool virtio_queue_config_write_allowed(const VirtqueueState *queue) {
  return queue != NULL && !queue->ready;
}

VirtioQueueReadyWriteResult virtio_queue_ready_decode(
    const VirtqueueState *queue, uint32_t value, bool layout_valid) {
  if (queue == NULL || value > 1) return VIRTIO_QUEUE_READY_INVALID_VALUE;
  if (value == 0) return queue->ready ?
      VIRTIO_QUEUE_READY_DISABLED : VIRTIO_QUEUE_READY_UNCHANGED;
  if (queue->ready) return VIRTIO_QUEUE_READY_UNCHANGED;
  return layout_valid ? VIRTIO_QUEUE_READY_ENABLED :
      VIRTIO_QUEUE_READY_INVALID_LAYOUT;
}

bool virtio_queue_notify_allowed(const VirtioMmioTransportState *transport,
    const VirtqueueState *queue) {
  uint32_t blocked = VIRTIO_STATUS_FAILED | VIRTIO_STATUS_DEVICE_NEEDS_RESET;
  return transport != NULL && queue != NULL && queue->ready &&
      (transport->device_status & VIRTIO_STATUS_DRIVER_OK) != 0 &&
      (transport->device_status & blocked) == 0;
}

bool virtqueue_pending_count(uint16_t last_avail_idx, uint16_t avail_idx,
    uint16_t queue_num, uint16_t *pending_count) {
  if (queue_num == 0 || pending_count == NULL) return false;
  uint16_t delta = (uint16_t)(avail_idx - last_avail_idx);
  if (delta > queue_num) return false;
  *pending_count = delta;
  return true;
}

bool virtio_transport_driver_features_write_allowed(
    const VirtioMmioTransportState *transport) {
  uint32_t frozen = VIRTIO_STATUS_FEATURES_OK |
      VIRTIO_STATUS_DRIVER_OK | VIRTIO_STATUS_FAILED;
  return transport != NULL && (transport->device_status & frozen) == 0;
}

void virtio_transport_note_config_change(VirtioMmioTransportState *transport) {
  transport->config_generation++;
}

bool virtio_transport_set_needs_reset(VirtioMmioTransportState *transport) {
  if ((transport->device_status & VIRTIO_STATUS_DEVICE_NEEDS_RESET) != 0) {
    return false;
  }
  transport->device_status |= VIRTIO_STATUS_DEVICE_NEEDS_RESET;
  if ((transport->device_status & VIRTIO_STATUS_DRIVER_OK) != 0) {
    virtio_transport_raise_interrupt(
        transport, VIRTIO_INTERRUPT_CONFIG_CHANGE);
    return true;
  }
  return false;
}

#ifndef __NEMU_DEVICE_VIRTIO_H__
#define __NEMU_DEVICE_VIRTIO_H__

#include <common.h>

/* Virtio 1.x MMIO transport register layout, section 4.2.2. */
typedef enum {
  VIRTIO_MMIO_MAGIC               = 0x000,
  VIRTIO_MMIO_VERSION             = 0x004,
  VIRTIO_MMIO_DEVICE_ID           = 0x008,
  VIRTIO_MMIO_VENDOR_ID           = 0x00c,
  VIRTIO_MMIO_DEVICE_FEATURES     = 0x010,
  VIRTIO_MMIO_DEVICE_FEATURES_SEL = 0x014,
  VIRTIO_MMIO_DRIVER_FEATURES     = 0x020,
  VIRTIO_MMIO_DRIVER_FEATURES_SEL = 0x024,
  VIRTIO_MMIO_QUEUE_SEL           = 0x030,
  VIRTIO_MMIO_QUEUE_NUM_MAX       = 0x034,
  VIRTIO_MMIO_QUEUE_NUM           = 0x038,
  VIRTIO_MMIO_QUEUE_READY         = 0x044,
  VIRTIO_MMIO_QUEUE_NOTIFY        = 0x050,
  VIRTIO_MMIO_INTERRUPT_STATUS    = 0x060,
  VIRTIO_MMIO_INTERRUPT_ACK       = 0x064,
  VIRTIO_MMIO_STATUS              = 0x070,
  VIRTIO_MMIO_QUEUE_DESC_LOW      = 0x080,
  VIRTIO_MMIO_QUEUE_DESC_HIGH     = 0x084,
  VIRTIO_MMIO_QUEUE_DRIVER_LOW    = 0x090,
  VIRTIO_MMIO_QUEUE_DRIVER_HIGH   = 0x094,
  VIRTIO_MMIO_QUEUE_DEVICE_LOW    = 0x0a0,
  VIRTIO_MMIO_QUEUE_DEVICE_HIGH   = 0x0a4,
  VIRTIO_MMIO_CONFIG_GENERATION   = 0x0fc,
  VIRTIO_MMIO_CONFIG              = 0x100,
} VirtioMmioRegister;

enum {
  VIRTIO_MMIO_MAGIC_VALUE = 0x74726976u,
  VIRTIO_MMIO_VERSION_MODERN = 2u,
  VIRTIO_VENDOR_YSYX = 0x58535959u,
};

typedef enum {
  VIRTIO_DEVICE_ID_NETWORK = 1,
  VIRTIO_DEVICE_ID_BLOCK = 2,
  VIRTIO_DEVICE_ID_ENTROPY = 4,
} VirtioDeviceId;

typedef enum {
  VIRTIO_F_VERSION_1 = 32,
  VIRTIO_RING_F_INDIRECT_DESC = 28,
  VIRTIO_RING_F_EVENT_IDX = 29,
} VirtioFeatureBit;

typedef enum {
  VIRTIO_INTERRUPT_USED_BUFFER = 1u << 0,
  VIRTIO_INTERRUPT_CONFIG_CHANGE = 1u << 1,
} VirtioInterruptStatus;

typedef enum {
  VIRTIO_STATUS_ACKNOWLEDGE       = 1u << 0,
  VIRTIO_STATUS_DRIVER            = 1u << 1,
  VIRTIO_STATUS_DRIVER_OK         = 1u << 2,
  VIRTIO_STATUS_FEATURES_OK       = 1u << 3,
  VIRTIO_STATUS_DEVICE_NEEDS_RESET = 1u << 6,
  VIRTIO_STATUS_FAILED            = 1u << 7,
} VirtioDeviceStatus;

typedef enum {
  VIRTQUEUE_DESCRIPTOR_F_NEXT = 1u << 0,
  VIRTQUEUE_DESCRIPTOR_F_WRITE = 1u << 1,
  VIRTQUEUE_DESCRIPTOR_F_INDIRECT = 1u << 2,
} VirtqueueDescriptorFlag;

typedef enum {
  VIRTQUEUE_AVAILABLE_F_NO_INTERRUPT = 1u << 0,
} VirtqueueAvailableFlag;

typedef enum {
  VIRTQUEUE_USED_F_NO_NOTIFY = 1u << 0,
} VirtqueueUsedFlag;

/* Split virtqueue descriptor, section 2.7.5. */
typedef struct {
  paddr_t addr;
  uint32_t len;
  uint16_t flags;
  uint16_t next;
} VirtqueueDescriptor;

/* Device-owned state associated with one configured split virtqueue. */
typedef struct {
  uint16_t num;
  bool ready;
  paddr_t desc;
  paddr_t driver;
  paddr_t device;
  uint16_t last_avail_idx;
} VirtqueueState;

/* Registers owned by the common virtio-mmio transport, not by a device type. */
typedef struct {
  uint32_t device_features_select;
  uint32_t driver_features_select;
  uint32_t driver_features[2];
  uint32_t interrupt_status;
  uint32_t device_status;
  uint32_t queue_select;
} VirtioMmioTransportState;

typedef enum {
  VIRTIO_STATUS_ACCEPTED,
  VIRTIO_STATUS_FEATURES_REJECTED,
} VirtioStatusWriteResult;

static inline bool virtio_driver_feature_enabled(
    const VirtioMmioTransportState *transport, uint32_t bit) {
  uint32_t select = bit / 32;
  uint32_t offset = bit % 32;
  return select < 2 &&
         (transport->driver_features[select] & (1u << offset)) != 0;
}

static inline void virtio_transport_reset(VirtioMmioTransportState *transport) {
  *transport = (VirtioMmioTransportState) {0};
}

/*
 * FEATURES_OK is the feature-negotiation commit point.  A device must clear
 * it when any driver-selected feature is unsupported; the driver confirms
 * acceptance by reading Status back before setting DRIVER_OK.
 */
static inline VirtioStatusWriteResult virtio_transport_accept_status(
    VirtioMmioTransportState *transport, uint32_t driver_status,
    bool driver_features_supported) {
  transport->device_status = driver_status;
  if ((driver_status & VIRTIO_STATUS_FEATURES_OK) != 0 &&
      !driver_features_supported) {
    transport->device_status &= ~VIRTIO_STATUS_FEATURES_OK;
    return VIRTIO_STATUS_FEATURES_REJECTED;
  }
  return VIRTIO_STATUS_ACCEPTED;
}

static inline void virtio_transport_raise_interrupt(
    VirtioMmioTransportState *transport, VirtioInterruptStatus cause) {
  transport->interrupt_status |= (uint32_t)cause;
}

static inline void virtio_transport_acknowledge_interrupt(
    VirtioMmioTransportState *transport, uint32_t acknowledged_causes) {
  transport->interrupt_status &= ~acknowledged_causes;
}

/* EVENT_IDX wrap-around comparison from the split virtqueue specification. */
static inline bool virtqueue_event_needed(
    uint16_t event_index, uint16_t new_index, uint16_t old_index) {
  return (uint16_t)(new_index - event_index - 1) <
         (uint16_t)(new_index - old_index);
}

static inline void virtqueue_write_address_low(
    paddr_t *address, uint32_t low_word) {
  *address = (paddr_t)(((uint64_t)*address & 0xffffffff00000000ull) |
                      low_word);
}

static inline void virtqueue_write_address_high(
    paddr_t *address, uint32_t high_word) {
  *address = (paddr_t)(((uint64_t)high_word << 32) | (uint32_t)*address);
}

static inline bool virtqueue_descriptor_has_flag(
    const VirtqueueDescriptor *descriptor, VirtqueueDescriptorFlag flag) {
  return (descriptor->flags & (uint16_t)flag) != 0;
}

#endif

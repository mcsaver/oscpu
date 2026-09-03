#ifndef __NEMU_DEVICE_VIRTIO_H__
#define __NEMU_DEVICE_VIRTIO_H__

#include <common.h>
#include <device/map.h>
#include <memory/paddr.h>

#include <stddef.h>

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

/* Virtio addresses are 64-bit guest DMA addresses regardless of guest XLEN. */
typedef uint64_t GuestDmaAddr;

typedef struct {
  uint32_t descriptor_bytes;
  uint32_t driver_bytes;
  uint32_t device_bytes;
} VirtioSplitRingSpan;

static inline bool virtio_guest_dma_add(
    GuestDmaAddr base, uint64_t offset, GuestDmaAddr *result) {
  if (result == NULL || offset > UINT64_MAX - base) return false;
  *result = base + offset;
  return true;
}

/*
 * Resolve one complete guest DMA span to NEMU's internal physical address.
 * The representability check is deliberately performed before the cast so an
 * RV32/high-address request cannot alias the low 32 bits of PMEM.
 */
static inline bool virtio_dma_resolve_span(
    GuestDmaAddr guest_addr, uint64_t len, paddr_t *resolved_addr) {
  if (resolved_addr == NULL) return false;
  GuestDmaAddr paddr_max = (GuestDmaAddr)(paddr_t)-1;
  if (guest_addr > paddr_max) return false;
  if (len == 0) {
    *resolved_addr = (paddr_t)guest_addr;
    return true;
  }
  if (len - 1 > UINT64_MAX - guest_addr) return false;
  GuestDmaAddr guest_last = guest_addr + len - 1;
  if (guest_last > paddr_max) return false;

  paddr_t first = (paddr_t)guest_addr;
  paddr_t last = (paddr_t)guest_last;
  if (!in_pmem(first) || !in_pmem(last)) return false;
  *resolved_addr = first;
  return true;
}

static inline bool virtio_split_queue_size_valid(
    uint32_t queue_num, uint32_t queue_num_max) {
  return queue_num != 0 && queue_num <= queue_num_max &&
         (queue_num & (queue_num - 1)) == 0;
}

/* Compute the three complete split-ring spans after validating QueueNum. */
static inline bool virtio_split_ring_span(
    uint32_t queue_num, uint32_t queue_num_max, bool event_idx,
    VirtioSplitRingSpan *span) {
  if (span == NULL ||
      !virtio_split_queue_size_valid(queue_num, queue_num_max)) {
    return false;
  }
  uint64_t event_tail = event_idx ? 2u : 0u;
  uint64_t descriptor_bytes = (uint64_t)queue_num * 16u;
  uint64_t driver_bytes = 4u + (uint64_t)queue_num * 2u + event_tail;
  uint64_t device_bytes = 4u + (uint64_t)queue_num * 8u + event_tail;
  if (descriptor_bytes > UINT32_MAX || driver_bytes > UINT32_MAX ||
      device_bytes > UINT32_MAX) {
    return false;
  }
  *span = (VirtioSplitRingSpan) {
    .descriptor_bytes = (uint32_t)descriptor_bytes,
    .driver_bytes = (uint32_t)driver_bytes,
    .device_bytes = (uint32_t)device_bytes,
  };
  return true;
}

/* Split virtqueue descriptor, section 2.7.5. */
typedef struct {
  GuestDmaAddr addr;
  uint32_t len;
  uint16_t flags;
  uint16_t next;
} VirtqueueDescriptor;

/* Virtio 1.2 split-ring wire layout is independent of the guest XLEN. */
_Static_assert(sizeof(GuestDmaAddr) == 8,
    "Virtio guest DMA addresses must remain 64-bit");
_Static_assert(sizeof(VirtqueueDescriptor) == 16,
    "Virtio split-ring descriptors must remain 16 bytes");
_Static_assert(offsetof(VirtqueueDescriptor, addr) == 0 &&
               offsetof(VirtqueueDescriptor, len) == 8 &&
               offsetof(VirtqueueDescriptor, flags) == 12 &&
               offsetof(VirtqueueDescriptor, next) == 14,
    "Virtio split-ring descriptor fields must match the wire layout");

/* Device-owned state associated with one configured split virtqueue. */
typedef struct {
  uint16_t num;
  bool ready;
  GuestDmaAddr desc;
  GuestDmaAddr driver;
  GuestDmaAddr device;
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
  uint32_t config_generation;
} VirtioMmioTransportState;

typedef enum {
  VIRTIO_STATUS_ACCEPTED,
  VIRTIO_STATUS_FEATURES_REJECTED,
  VIRTIO_STATUS_RESET_REQUESTED,
  VIRTIO_STATUS_INVALID_TRANSITION,
} VirtioStatusWriteResult;

typedef struct {
  VirtioStatusWriteResult result;
  uint32_t next_status;
  uint32_t rejected_bits;
} VirtioStatusTransition;

typedef enum {
  VIRTIO_QUEUE_READY_DISABLED,
  VIRTIO_QUEUE_READY_ENABLED,
  VIRTIO_QUEUE_READY_UNCHANGED,
  VIRTIO_QUEUE_READY_INVALID_VALUE,
  VIRTIO_QUEUE_READY_INVALID_LAYOUT,
} VirtioQueueReadyWriteResult;

/* Modern virtio-mmio transport registers are naturally aligned 32-bit words. */
extern const IoAccessPolicy virtio_mmio_transport_policy;

/*
 * Virtio 1.2 section 4.2.2.2 gives device-configuration fields their own
 * access grammar: u8 fields use byte transactions, le16 fields use aligned
 * 16-bit transactions, and le32/le64 fields use aligned 32-bit transactions.
 * A le64 field is therefore described as two independently accessible words.
 *
 * These constructors encode only the field's bus shape and direction.  A
 * device handler remains responsible for feature-negotiation and mutable
 * field semantics (for example, virtio-blk writeback mode).
 */
#define VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                               \
    _name, _offset, _bytes, _stride, _width, _direction)                   \
  {                                                                         \
    .name = (_name),                                                        \
    .first_offset = VIRTIO_MMIO_CONFIG + (_offset),                         \
    .last_offset = VIRTIO_MMIO_CONFIG + (_offset) + (_bytes) - 1u,          \
    .stride = (_stride),                                                    \
    .width_mask = (_width),                                                 \
    .direction_mask = (_direction),                                         \
    .naturally_aligned = true,                                              \
  }

#define VIRTIO_CONFIG_FIELD_RO_U8(_name, _offset)                           \
  VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                                      \
      (_name), (_offset), 1u, 1u, IO_WIDTH_1, IO_TRANSACTION_READ)

#define VIRTIO_CONFIG_FIELD_RO_U8_ARRAY(_name, _offset, _count)             \
  VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                                      \
      (_name), (_offset), (_count), 1u, IO_WIDTH_1, IO_TRANSACTION_READ)

#define VIRTIO_CONFIG_FIELD_RO_LE16(_name, _offset)                         \
  VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                                      \
      (_name), (_offset), 2u, 2u, IO_WIDTH_2, IO_TRANSACTION_READ)

#define VIRTIO_CONFIG_FIELD_RO_LE32(_name, _offset)                         \
  VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                                      \
      (_name), (_offset), 4u, 4u, IO_WIDTH_4, IO_TRANSACTION_READ)

#define VIRTIO_CONFIG_FIELD_RO_LE64_WORDS(_name, _offset)                   \
  VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                                      \
      (_name), (_offset), 8u, 4u, IO_WIDTH_4, IO_TRANSACTION_READ)

#define VIRTIO_CONFIG_FIELD_RW_U8(_name, _offset)                           \
  VIRTIO_CONFIG_FIELD_DESCRIPTOR_INIT(                                      \
      (_name), (_offset), 1u, 1u, IO_WIDTH_1,                               \
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE)

#define VIRTIO_CONFIG_FIELD_END(_offset, _bytes)                            \
  ((_offset) + (_bytes) - 1u)

#define VIRTIO_CONFIG_ASSERT_DISJOINT(                                      \
    _left_offset, _left_bytes, _right_offset)                              \
  _Static_assert(                                                           \
      VIRTIO_CONFIG_FIELD_END((_left_offset), (_left_bytes)) <             \
          (_right_offset),                                                  \
      "Virtio device-configuration fields overlap or are out of order")

#define VIRTIO_CONFIG_ASSERT_LAST_BYTE(_offset, _bytes, _last_byte)         \
  _Static_assert(                                                           \
      VIRTIO_CONFIG_FIELD_END((_offset), (_bytes)) == (_last_byte),         \
      "Virtio device-configuration last byte does not match its layout")

static inline bool virtio_driver_feature_enabled(
    const VirtioMmioTransportState *transport, uint32_t bit) {
  uint32_t select = bit / 32;
  uint32_t offset = bit % 32;
  return select < 2 &&
         (transport->driver_features[select] & (1u << offset)) != 0;
}

static inline bool virtio_feature_negotiated(
    const VirtioMmioTransportState *transport, uint32_t bit) {
  return (transport->device_status & VIRTIO_STATUS_FEATURES_OK) != 0 &&
         virtio_driver_feature_enabled(transport, bit);
}

static inline void virtio_transport_reset(VirtioMmioTransportState *transport) {
  *transport = (VirtioMmioTransportState) {0};
}

/* Pure MMIO Status decode; the caller can inspect the transition before commit. */
VirtioStatusTransition virtio_status_decode(uint32_t current_status,
    uint32_t driver_status, bool driver_features_supported);

/* Commit the decoded transport status transition. */
VirtioStatusWriteResult virtio_transport_accept_status(
    VirtioMmioTransportState *transport, uint32_t driver_status,
    bool driver_features_supported);

/* Pure queue-register validation used before device-specific state mutation. */
bool virtio_queue_config_write_allowed(const VirtqueueState *queue);
VirtioQueueReadyWriteResult virtio_queue_ready_decode(
    const VirtqueueState *queue, uint32_t value, bool layout_valid);
bool virtio_queue_notify_allowed(const VirtioMmioTransportState *transport,
    const VirtqueueState *queue);
bool virtqueue_pending_count(uint16_t last_avail_idx, uint16_t avail_idx,
    uint16_t queue_num, uint16_t *pending_count);
bool virtio_transport_driver_features_write_allowed(
    const VirtioMmioTransportState *transport);

/* Device-owned transport transitions. */
void virtio_transport_note_config_change(VirtioMmioTransportState *transport);
bool virtio_transport_set_needs_reset(VirtioMmioTransportState *transport);

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
    GuestDmaAddr *address, uint32_t low_word) {
  *address = (*address & 0xffffffff00000000ull) | low_word;
}

static inline void virtqueue_write_address_high(
    GuestDmaAddr *address, uint32_t high_word) {
  *address = ((GuestDmaAddr)high_word << 32) | (uint32_t)*address;
}

static inline bool virtqueue_descriptor_has_flag(
    const VirtqueueDescriptor *descriptor, VirtqueueDescriptorFlag flag) {
  return (descriptor->flags & (uint16_t)flag) != 0;
}

#endif

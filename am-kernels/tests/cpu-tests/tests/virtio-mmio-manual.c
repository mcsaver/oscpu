#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

#define VIRTIO_BLK_BASE                 ((uintptr_t)0x10001000u)
#define VIRTIO_RNG_BASE                 ((uintptr_t)0x10002000u)
#define VIRTIO_NET_BASE                 ((uintptr_t)0x10004000u)
#define VIRTIO_MMIO_MAGIC               0x000u
#define VIRTIO_MMIO_VERSION             0x004u
#define VIRTIO_MMIO_DEVICE_ID           0x008u
#define VIRTIO_MMIO_DEVICE_FEATURES     0x010u
#define VIRTIO_MMIO_DEVICE_FEATURES_SEL 0x014u
#define VIRTIO_MMIO_DRIVER_FEATURES     0x020u
#define VIRTIO_MMIO_DRIVER_FEATURES_SEL 0x024u
#define VIRTIO_MMIO_QUEUE_SEL           0x030u
#define VIRTIO_MMIO_QUEUE_NUM_MAX       0x034u
#define VIRTIO_MMIO_QUEUE_NUM           0x038u
#define VIRTIO_MMIO_QUEUE_READY         0x044u
#define VIRTIO_MMIO_QUEUE_NOTIFY        0x050u
#define VIRTIO_MMIO_INTERRUPT_STATUS    0x060u
#define VIRTIO_MMIO_INTERRUPT_ACK       0x064u
#define VIRTIO_MMIO_STATUS              0x070u
#define VIRTIO_MMIO_QUEUE_DESC_LOW      0x080u
#define VIRTIO_MMIO_QUEUE_DESC_HIGH     0x084u
#define VIRTIO_MMIO_QUEUE_DRIVER_LOW    0x090u
#define VIRTIO_MMIO_QUEUE_DRIVER_HIGH   0x094u
#define VIRTIO_MMIO_QUEUE_DEVICE_LOW    0x0a0u
#define VIRTIO_MMIO_QUEUE_DEVICE_HIGH   0x0a4u
#define VIRTIO_MMIO_CONFIG_GENERATION   0x0fcu
#define VIRTIO_MMIO_CONFIG              0x100u

#define VIRTIO_DEVICE_ID_NETWORK 1u
#define VIRTIO_DEVICE_ID_BLOCK   2u
#define VIRTIO_DEVICE_ID_ENTROPY 4u

#define VIRTIO_BLK_F_CONFIG_WCE_WORD0 (1u << 11)
#define VIRTIO_BLK_CONFIG_CAPACITY     0u
#define VIRTIO_BLK_CONFIG_WRITEBACK    32u

#define VIRTIO_NET_CONFIG_MAC             0u
#define VIRTIO_NET_CONFIG_STATUS          6u
#define VIRTIO_NET_CONFIG_MAX_QUEUE_PAIRS 8u
#define VIRTIO_NET_CONFIG_MTU              10u
#define VIRTIO_NET_CONFIG_SPEED            12u
#define VIRTIO_NET_CONFIG_DUPLEX           16u
#define VIRTIO_NET_CONFIG_RSS_KEY_SIZE     17u

#define VIRTIO_NET_CONFIG_FEATURES_WORD0 \
  ((1u << 3) | (1u << 5) | (1u << 16))
#define VIRTIO_NET_F_MQ_WORD0          (1u << 22)
#define VIRTIO_NET_F_HASH_REPORT_WORD1 (1u << (57 - 32))
#define VIRTIO_NET_F_RSS_WORD1         (1u << (60 - 32))
#define VIRTIO_NET_F_SPEED_WORD1       (1u << (63 - 32))

#define VIRTIO_STATUS_ACKNOWLEDGE 0x01u
#define VIRTIO_STATUS_DRIVER      0x02u
#define VIRTIO_STATUS_DRIVER_OK   0x04u
#define VIRTIO_STATUS_FEATURES_OK 0x08u
#define VIRTIO_STATUS_NEEDS_RESET 0x40u
#define VIRTIO_STATUS_FAILED      0x80u

#define VIRTIO_F_VERSION_1_WORD1 0x00000001u
#define VIRTQ_DESC_F_WRITE       0x0002u
#define VIRTIO_QUEUE_SIZE        8u

#if __riscv_xlen == 64
#define VIRTIO_TRAP_STORE "sd"
#else
#define VIRTIO_TRAP_STORE "sw"
#endif

typedef struct __attribute__((packed)) {
  uint64_t address;
  uint32_t length;
  uint16_t flags;
  uint16_t next;
} TestVirtqueueDescriptor;

typedef struct __attribute__((packed)) {
  uint16_t flags;
  uint16_t index;
  uint16_t ring[VIRTIO_QUEUE_SIZE];
  uint16_t used_event;
} TestVirtqueueAvailable;

typedef struct __attribute__((packed)) {
  uint32_t id;
  uint32_t length;
} TestVirtqueueUsedElement;

typedef struct __attribute__((packed)) {
  uint16_t flags;
  uint16_t index;
  TestVirtqueueUsedElement ring[VIRTIO_QUEUE_SIZE];
  uint16_t available_event;
} TestVirtqueueUsed;

_Static_assert(sizeof(TestVirtqueueDescriptor) == 16,
    "split virtqueue descriptor wire size");

static volatile TestVirtqueueDescriptor descriptors[VIRTIO_QUEUE_SIZE]
    __attribute__((aligned(16)));
static volatile TestVirtqueueAvailable available __attribute__((aligned(16)));
static volatile TestVirtqueueUsed used __attribute__((aligned(16)));
static volatile uint8_t random_bytes[32] __attribute__((aligned(16)));

static volatile uintptr_t virtio_trap_count;
static volatile uintptr_t virtio_trap_cause;
static volatile uintptr_t virtio_trap_value;

extern void virtio_mmio_trap_entry(void);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl virtio_mmio_trap_entry\n"
"virtio_mmio_trap_entry:\n"
"  csrr t0, mcause\n"
"  la t1, virtio_trap_cause\n"
"  " VIRTIO_TRAP_STORE " t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, virtio_trap_value\n"
"  " VIRTIO_TRAP_STORE " t0, 0(t1)\n"
"  la t1, virtio_trap_count\n"
"  li t0, 1\n"
"  " VIRTIO_TRAP_STORE " t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
".option pop\n"
);

static inline uint32_t device_mmio_read32(uintptr_t base, uint32_t offset) {
  return *(volatile uint32_t *)(base + offset);
}

static inline void device_mmio_write32(
    uintptr_t base, uint32_t offset, uint32_t value) {
  *(volatile uint32_t *)(base + offset) = value;
}

static inline uint32_t mmio_read32(uint32_t offset) {
  return device_mmio_read32(VIRTIO_RNG_BASE, offset);
}

static inline void mmio_write32(uint32_t offset, uint32_t value) {
  device_mmio_write32(VIRTIO_RNG_BASE, offset, value);
}

static inline void publish_guest_memory(void) {
  asm volatile("fence rw, rw" : : : "memory");
}

static bool wait_for_used_index(uint16_t expected, uint32_t attempts) {
  for (uint32_t i = 0; i < attempts; i++) {
    asm volatile("fence r, rw" : : : "memory");
    if (used.index == expected) return true;
  }
  return false;
}

static bool random_buffer_changed(void) {
  for (uint32_t i = 0; i < sizeof(random_bytes); i++) {
    if (random_bytes[i] != 0xa5u) return true;
  }
  return false;
}

static void check_or_halt(bool condition, int error_code) {
  if (!condition) halt(error_code);
}

static inline uintptr_t read_mtvec(void) {
  uintptr_t value;
  asm volatile("csrr %0, mtvec" : "=r"(value));
  return value;
}

static inline void write_mtvec(uintptr_t value) {
  asm volatile("csrw mtvec, %0" : : "r"(value) : "memory");
}

static void clear_trap_record(void) {
  virtio_trap_count = 0;
  virtio_trap_cause = 0;
  virtio_trap_value = 0;
}

static void expect_access_fault(
    uintptr_t cause, uintptr_t address, int error_code) {
  check_or_halt(virtio_trap_count == 1 &&
      virtio_trap_cause == cause && virtio_trap_value == address,
      error_code);
}

static void expect_byte_load_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lb zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(5, address, error_code);
}

static void expect_halfword_load_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lh zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(5, address, error_code);
}

static void expect_word_load_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(5, address, error_code);
}

static void expect_byte_store_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sb zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(7, address, error_code);
}

static void expect_halfword_store_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sh zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(7, address, error_code);
}

static void expect_word_store_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(7, address, error_code);
}

#if __riscv_xlen == 64
static void expect_doubleword_load_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "ld zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(5, address, error_code);
}

static void expect_doubleword_store_access_fault(
    uintptr_t address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sd zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_access_fault(7, address, error_code);
}
#endif

static bool probe_virtio_device(
    uintptr_t base, uint32_t expected_device_id, int error_code) {
  uintptr_t address = base + VIRTIO_MMIO_DEVICE_ID;
  uint32_t device_id;
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw %0, 0(%1)\n"
      ".option pop\n"
      : "=&r"(device_id) : "r"(address) : "t0", "t1", "memory");
  if (virtio_trap_count != 0) {
    expect_access_fault(5, address, error_code);
    return false;
  }
  if (device_id == 0) return false;
  check_or_halt(device_id == expected_device_id, error_code);
  return true;
}

static uint8_t checked_mmio_read8(
    uintptr_t base, uint32_t offset, int error_code) {
  uintptr_t address = base + offset;
  uintptr_t value;
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lbu %0, 0(%1)\n"
      ".option pop\n"
      : "=&r"(value) : "r"(address) : "t0", "t1", "memory");
  check_or_halt(virtio_trap_count == 0, error_code);
  return (uint8_t)value;
}

static uint16_t checked_mmio_read16(
    uintptr_t base, uint32_t offset, int error_code) {
  uintptr_t address = base + offset;
  uintptr_t value;
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lhu %0, 0(%1)\n"
      ".option pop\n"
      : "=&r"(value) : "r"(address) : "t0", "t1", "memory");
  check_or_halt(virtio_trap_count == 0, error_code);
  return (uint16_t)value;
}

static uint32_t checked_mmio_read32(
    uintptr_t base, uint32_t offset, int error_code) {
  uintptr_t address = base + offset;
  uintptr_t value;
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw %0, 0(%1)\n"
      ".option pop\n"
      : "=&r"(value) : "r"(address) : "t0", "t1", "memory");
  check_or_halt(virtio_trap_count == 0, error_code);
  return (uint32_t)value;
}

static void checked_mmio_write8(
    uintptr_t base, uint32_t offset, uint8_t value, int error_code) {
  uintptr_t address = base + offset;
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sb %1, 0(%0)\n"
      ".option pop\n"
      : : "r"(address), "r"((uintptr_t)value) : "t0", "t1", "memory");
  check_or_halt(virtio_trap_count == 0, error_code);
}

static void checked_mmio_write32(
    uintptr_t base, uint32_t offset, uint32_t value, int error_code) {
  uintptr_t address = base + offset;
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sw %1, 0(%0)\n"
      ".option pop\n"
      : : "r"(address), "r"((uintptr_t)value) : "t0", "t1", "memory");
  check_or_halt(virtio_trap_count == 0, error_code);
}

static void clear_queue_memory(void) {
  for (uint32_t i = 0; i < VIRTIO_QUEUE_SIZE; i++) {
    descriptors[i].address = 0;
    descriptors[i].length = 0;
    descriptors[i].flags = 0;
    descriptors[i].next = 0;
    available.ring[i] = 0;
    used.ring[i].id = 0;
    used.ring[i].length = 0;
  }
  available.flags = 0;
  available.index = 0;
  available.used_event = 0;
  used.flags = 0;
  used.index = 0;
  used.available_event = 0;
  for (uint32_t i = 0; i < sizeof(random_bytes); i++) {
    random_bytes[i] = 0xa5u;
  }
}

static void write_queue_address(
    uint32_t low_register, uint32_t high_register, uint64_t address) {
  mmio_write32(low_register, (uint32_t)address);
  mmio_write32(high_register, (uint32_t)(address >> 32));
}

static void negotiate_version_1(void) {
  mmio_write32(VIRTIO_MMIO_STATUS, 0);
  mmio_write32(VIRTIO_MMIO_STATUS, VIRTIO_STATUS_ACKNOWLEDGE);
  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER);
  mmio_write32(VIRTIO_MMIO_DRIVER_FEATURES_SEL, 0);
  mmio_write32(VIRTIO_MMIO_DRIVER_FEATURES, 0);
  mmio_write32(VIRTIO_MMIO_DRIVER_FEATURES_SEL, 1);
  mmio_write32(VIRTIO_MMIO_DRIVER_FEATURES, VIRTIO_F_VERSION_1_WORD1);
  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_FEATURES_OK);
  check_or_halt(
      (mmio_read32(VIRTIO_MMIO_STATUS) & VIRTIO_STATUS_FEATURES_OK) != 0, 20);
}

static void configure_queue(uint64_t descriptor_address,
    uint64_t driver_address, uint64_t device_address) {
  mmio_write32(VIRTIO_MMIO_QUEUE_SEL, 0);
  mmio_write32(VIRTIO_MMIO_QUEUE_NUM, VIRTIO_QUEUE_SIZE);
  write_queue_address(
      VIRTIO_MMIO_QUEUE_DESC_LOW, VIRTIO_MMIO_QUEUE_DESC_HIGH,
      descriptor_address);
  write_queue_address(
      VIRTIO_MMIO_QUEUE_DRIVER_LOW, VIRTIO_MMIO_QUEUE_DRIVER_HIGH,
      driver_address);
  write_queue_address(
      VIRTIO_MMIO_QUEUE_DEVICE_LOW, VIRTIO_MMIO_QUEUE_DEVICE_HIGH,
      device_address);
  mmio_write32(VIRTIO_MMIO_QUEUE_READY, 1);
}

static void prepare_one_random_buffer(uint64_t buffer_address) {
  descriptors[0].address = buffer_address;
  descriptors[0].length = sizeof(random_bytes);
  descriptors[0].flags = VIRTQ_DESC_F_WRITE;
  available.ring[0] = 0;
  available.index = 1;
  publish_guest_memory();
}

static void check_virtio_identity(
    uintptr_t base, uint32_t device_id, int error_code) {
  check_or_halt(
      checked_mmio_read32(base, VIRTIO_MMIO_MAGIC, error_code) ==
          UINT32_C(0x74726976),
      error_code);
  check_or_halt(
      checked_mmio_read32(base, VIRTIO_MMIO_VERSION, error_code) == 2,
      error_code);
  check_or_halt(
      checked_mmio_read32(base, VIRTIO_MMIO_DEVICE_ID, error_code) ==
          device_id,
      error_code);
}

static void reset_virtio_transport(uintptr_t base, int error_code) {
  checked_mmio_write32(base, VIRTIO_MMIO_STATUS, 0, error_code);
  check_or_halt(
      checked_mmio_read32(base, VIRTIO_MMIO_STATUS, error_code) == 0,
      error_code);
}

static uint32_t read_device_feature_word(
    uintptr_t base, uint32_t select, int error_code) {
  /* DeviceFeaturesSel is WO; only DeviceFeatures is read back. */
  checked_mmio_write32(
      base, VIRTIO_MMIO_DEVICE_FEATURES_SEL, select, error_code);
  return checked_mmio_read32(
      base, VIRTIO_MMIO_DEVICE_FEATURES, error_code);
}

static void negotiate_device_features(
    uintptr_t base, uint32_t feature_word0, int error_code) {
  reset_virtio_transport(base, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_DRIVER_FEATURES_SEL,
      0, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_DRIVER_FEATURES,
      feature_word0, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_DRIVER_FEATURES_SEL,
      1, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_DRIVER_FEATURES,
      VIRTIO_F_VERSION_1_WORD1, error_code);
  checked_mmio_write32(base, VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_FEATURES_OK, error_code);
  check_or_halt(
      (checked_mmio_read32(base, VIRTIO_MMIO_STATUS, error_code) &
       VIRTIO_STATUS_FEATURES_OK) != 0,
      error_code);
}

static void test_virtio_blk_device_config(void) {
  const uintptr_t config = VIRTIO_BLK_BASE + VIRTIO_MMIO_CONFIG;
  check_virtio_identity(VIRTIO_BLK_BASE, VIRTIO_DEVICE_ID_BLOCK, 40);
  reset_virtio_transport(VIRTIO_BLK_BASE, 41);
  check_or_halt((read_device_feature_word(
      VIRTIO_BLK_BASE, 0, 44) & VIRTIO_BLK_F_CONFIG_WCE_WORD0) != 0, 44);

  /* le64 capacity is two independently readable, aligned le32 words. */
  uint32_t capacity_low = checked_mmio_read32(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_CAPACITY, 42);
  uint32_t capacity_high = checked_mmio_read32(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_CAPACITY + 4u, 43);

  expect_halfword_load_access_fault(
      config + VIRTIO_BLK_CONFIG_CAPACITY, 45);
  expect_word_load_access_fault(
      config + VIRTIO_BLK_CONFIG_CAPACITY + 2u, 46);
  expect_word_store_access_fault(
      config + VIRTIO_BLK_CONFIG_CAPACITY, 47);
#if __riscv_xlen == 64
  expect_doubleword_load_access_fault(
      config + VIRTIO_BLK_CONFIG_CAPACITY, 48);
  expect_doubleword_store_access_fault(
      config + VIRTIO_BLK_CONFIG_CAPACITY, 49);
#endif

  /* Faulting accesses are precise and cannot mutate config or transport. */
  check_or_halt(checked_mmio_read32(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_CAPACITY, 50) == capacity_low,
      50);
  check_or_halt(checked_mmio_read32(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_CAPACITY + 4u, 51) ==
          capacity_high,
      51);
  check_or_halt(checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_STATUS, 52) == 0, 52);

  /* writeback is byte RW, but becomes writable only after CONFIG_WCE. */
  uint8_t original_writeback = checked_mmio_read8(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 53);
  check_or_halt(original_writeback <= 1u, 54);
  uint32_t generation_before = checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 55);
  checked_mmio_write8(VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK,
      original_writeback ^ 1u, 56);
  check_or_halt(checked_mmio_read8(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 57) ==
          original_writeback,
      57);
  check_or_halt(checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 58) ==
          generation_before,
      58);

  expect_halfword_load_access_fault(
      config + VIRTIO_BLK_CONFIG_WRITEBACK, 59);
  expect_word_store_access_fault(
      config + VIRTIO_BLK_CONFIG_WRITEBACK, 60);
  check_or_halt(checked_mmio_read8(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 61) ==
          original_writeback,
      61);

  negotiate_device_features(
      VIRTIO_BLK_BASE, VIRTIO_BLK_F_CONFIG_WCE_WORD0, 62);
  generation_before = checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 63);
  checked_mmio_write8(VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK,
      original_writeback ^ 1u, 64);
  check_or_halt(checked_mmio_read8(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 65) ==
          (uint8_t)(original_writeback ^ 1u),
      65);
  check_or_halt(checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 66) ==
          generation_before + 1u,
      66);

  /* An invalid byte value is bus-legal but rejected by field semantics. */
  generation_before = checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 67);
  checked_mmio_write8(VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 2u, 68);
  check_or_halt(checked_mmio_read8(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 69) ==
          (uint8_t)(original_writeback ^ 1u),
      69);
  check_or_halt(checked_mmio_read32(
      VIRTIO_BLK_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 70) ==
          generation_before,
      70);

  checked_mmio_write8(VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK,
      original_writeback, 71);
  check_or_halt(checked_mmio_read8(
      VIRTIO_BLK_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_BLK_CONFIG_WRITEBACK, 72) ==
          original_writeback,
      72);
  reset_virtio_transport(VIRTIO_BLK_BASE, 73);
}

static void test_virtio_net_device_config(void) {
  const uintptr_t config = VIRTIO_NET_BASE + VIRTIO_MMIO_CONFIG;
  check_virtio_identity(VIRTIO_NET_BASE, VIRTIO_DEVICE_ID_NETWORK, 80);
  reset_virtio_transport(VIRTIO_NET_BASE, 81);
  uint32_t feature_word0 = read_device_feature_word(
      VIRTIO_NET_BASE, 0, 116);
  uint32_t feature_word1 = read_device_feature_word(
      VIRTIO_NET_BASE, 1, 117);
  check_or_halt(
      (feature_word0 & VIRTIO_NET_CONFIG_FEATURES_WORD0) ==
          VIRTIO_NET_CONFIG_FEATURES_WORD0 &&
      (feature_word0 & VIRTIO_NET_F_MQ_WORD0) == 0 &&
      (feature_word1 & VIRTIO_NET_F_SPEED_WORD1) != 0 &&
      (feature_word1 &
          (VIRTIO_NET_F_HASH_REPORT_WORD1 | VIRTIO_NET_F_RSS_WORD1)) == 0,
      118);

  static const uint8_t expected_mac[6] = {
    0x52u, 0x54u, 0x00u, 0x12u, 0x34u, 0x56u,
  };
  uint8_t mac[6];
  for (uint32_t i = 0; i < sizeof(mac); i++) {
    mac[i] = checked_mmio_read8(VIRTIO_NET_BASE,
        VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_MAC + i, 82);
    check_or_halt(mac[i] == expected_mac[i], 83);
  }
  uint16_t net_status = checked_mmio_read16(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_STATUS, 84);
  uint16_t mtu = checked_mmio_read16(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_MTU, 85);
  uint32_t speed = checked_mmio_read32(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_SPEED, 86);
  uint8_t duplex = checked_mmio_read8(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_DUPLEX, 87);
  check_or_halt(net_status == 1u && mtu == 1500u &&
      speed == 1000u && duplex == 1u, 88);

  uint32_t generation_before = checked_mmio_read32(
      VIRTIO_NET_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 89);
  uint32_t status_before = checked_mmio_read32(
      VIRTIO_NET_BASE, VIRTIO_MMIO_STATUS, 90);

  /* Every field is driver-read-only and has its manual-defined width. */
  expect_halfword_load_access_fault(
      config + VIRTIO_NET_CONFIG_MAC, 91);
  expect_byte_store_access_fault(
      config + VIRTIO_NET_CONFIG_MAC, 92);
  expect_byte_load_access_fault(
      config + VIRTIO_NET_CONFIG_STATUS, 93);
  expect_halfword_load_access_fault(
      config + VIRTIO_NET_CONFIG_STATUS + 1u, 94);
  expect_halfword_store_access_fault(
      config + VIRTIO_NET_CONFIG_STATUS, 95);

  /* MQ/RSS are not advertised, so their conditional fields do not exist. */
  expect_halfword_load_access_fault(
      config + VIRTIO_NET_CONFIG_MAX_QUEUE_PAIRS, 96);
  expect_halfword_store_access_fault(
      config + VIRTIO_NET_CONFIG_MAX_QUEUE_PAIRS, 97);

  expect_byte_load_access_fault(config + VIRTIO_NET_CONFIG_MTU, 98);
  expect_word_load_access_fault(config + VIRTIO_NET_CONFIG_MTU, 99);
  expect_halfword_load_access_fault(
      config + VIRTIO_NET_CONFIG_MTU + 1u, 100);
  expect_halfword_store_access_fault(config + VIRTIO_NET_CONFIG_MTU, 101);
  expect_halfword_load_access_fault(config + VIRTIO_NET_CONFIG_SPEED, 102);
  expect_word_load_access_fault(config + VIRTIO_NET_CONFIG_SPEED + 1u, 103);
  expect_word_store_access_fault(config + VIRTIO_NET_CONFIG_SPEED, 104);
  expect_halfword_load_access_fault(config + VIRTIO_NET_CONFIG_DUPLEX, 105);
  expect_byte_store_access_fault(config + VIRTIO_NET_CONFIG_DUPLEX, 106);
  expect_byte_load_access_fault(config + VIRTIO_NET_CONFIG_RSS_KEY_SIZE, 107);
  expect_byte_store_access_fault(config + VIRTIO_NET_CONFIG_RSS_KEY_SIZE, 108);

  check_or_halt(checked_mmio_read32(
      VIRTIO_NET_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 109) ==
          generation_before,
      109);
  check_or_halt(checked_mmio_read32(
      VIRTIO_NET_BASE, VIRTIO_MMIO_STATUS, 110) == status_before, 110);
  for (uint32_t i = 0; i < sizeof(mac); i++) {
    check_or_halt(checked_mmio_read8(VIRTIO_NET_BASE,
        VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_MAC + i, 111) == mac[i],
        111);
  }
  check_or_halt(checked_mmio_read16(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_STATUS, 112) == net_status, 112);
  check_or_halt(checked_mmio_read16(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_MTU, 113) == mtu, 113);
  check_or_halt(checked_mmio_read32(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_SPEED, 114) == speed, 114);
  check_or_halt(checked_mmio_read8(VIRTIO_NET_BASE,
      VIRTIO_MMIO_CONFIG + VIRTIO_NET_CONFIG_DUPLEX, 115) == duplex, 115);
}

static void test_virtio_rng_has_no_device_config(void) {
  const uintptr_t config = VIRTIO_RNG_BASE + VIRTIO_MMIO_CONFIG;
  check_virtio_identity(VIRTIO_RNG_BASE, VIRTIO_DEVICE_ID_ENTROPY, 120);
  reset_virtio_transport(VIRTIO_RNG_BASE, 121);
  uint32_t generation_before = checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 122);
  uint32_t status_before = checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_STATUS, 123);
  uint32_t queue_ready_before = checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_QUEUE_READY, 124);
  uint32_t interrupt_before = checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_INTERRUPT_STATUS, 125);

  expect_byte_load_access_fault(config, 126);
  expect_halfword_load_access_fault(config, 127);
  expect_word_load_access_fault(config, 128);
  expect_byte_store_access_fault(config, 129);
  expect_halfword_store_access_fault(config, 130);
  expect_word_store_access_fault(config, 131);
#if __riscv_xlen == 64
  expect_doubleword_load_access_fault(config, 132);
  expect_doubleword_store_access_fault(config, 133);
#endif

  check_or_halt(checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_CONFIG_GENERATION, 134) ==
          generation_before,
      134);
  check_or_halt(checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_STATUS, 135) == status_before, 135);
  check_or_halt(checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_QUEUE_READY, 136) == queue_ready_before,
      136);
  check_or_halt(checked_mmio_read32(
      VIRTIO_RNG_BASE, VIRTIO_MMIO_INTERRUPT_STATUS, 137) ==
          interrupt_before,
      137);
}

int main(void) {
  const uintptr_t old_mtvec = read_mtvec();
  write_mtvec((uintptr_t)virtio_mmio_trap_entry);

  const bool blk_present = probe_virtio_device(
      VIRTIO_BLK_BASE, VIRTIO_DEVICE_ID_BLOCK, 140);
  const bool net_present = probe_virtio_device(
      VIRTIO_NET_BASE, VIRTIO_DEVICE_ID_NETWORK, 141);
  const bool rng_present = probe_virtio_device(
      VIRTIO_RNG_BASE, VIRTIO_DEVICE_ID_ENTROPY, 142);

  if (blk_present) {
    test_virtio_blk_device_config();
  } else {
    printf("virtio-mmio-manual: SKIP blk config (device unavailable)\n");
  }
  if (net_present) {
    test_virtio_net_device_config();
  } else {
    printf("virtio-mmio-manual: SKIP net config (device unavailable)\n");
  }
  if (rng_present) {
    test_virtio_rng_has_no_device_config();
  } else {
    printf("virtio-mmio-manual: SKIP rng config/transport "
        "(device unavailable)\n");
    goto finish;
  }

  /* Unexpected faults in the functional queue test must remain fatal. */
  write_mtvec(old_mtvec);
  /* The remainder exercises the common transport through virtio-rng. */
  check_or_halt(mmio_read32(VIRTIO_MMIO_MAGIC) == UINT32_C(0x74726976), 2);
  check_or_halt(mmio_read32(VIRTIO_MMIO_VERSION) == 2, 3);
  check_or_halt(mmio_read32(VIRTIO_MMIO_DEVICE_ID) == 4, 4);

  mmio_write32(VIRTIO_MMIO_STATUS, 0);
  check_or_halt(mmio_read32(VIRTIO_MMIO_STATUS) == 0, 5);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 0, 6);
  check_or_halt(mmio_read32(VIRTIO_MMIO_INTERRUPT_STATUS) == 0, 7);

  /* Unsupported features make the device reject FEATURES_OK. */
  mmio_write32(VIRTIO_MMIO_STATUS, VIRTIO_STATUS_ACKNOWLEDGE);
  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER);
  mmio_write32(VIRTIO_MMIO_DRIVER_FEATURES_SEL, 1);
  mmio_write32(VIRTIO_MMIO_DRIVER_FEATURES,
      VIRTIO_F_VERSION_1_WORD1 | UINT32_C(0x2));
  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_FEATURES_OK);
  check_or_halt(
      (mmio_read32(VIRTIO_MMIO_STATUS) & VIRTIO_STATUS_FEATURES_OK) == 0, 8);

  negotiate_version_1();
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_NUM_MAX) >= VIRTIO_QUEUE_SIZE, 9);

  /* QueueNum must be a non-zero power of two within QueueNumMax. */
  clear_queue_memory();
  mmio_write32(VIRTIO_MMIO_QUEUE_SEL, 0);
  mmio_write32(VIRTIO_MMIO_QUEUE_NUM, 3);
  write_queue_address(
      VIRTIO_MMIO_QUEUE_DESC_LOW, VIRTIO_MMIO_QUEUE_DESC_HIGH,
      (uint64_t)(uintptr_t)descriptors);
  write_queue_address(
      VIRTIO_MMIO_QUEUE_DRIVER_LOW, VIRTIO_MMIO_QUEUE_DRIVER_HIGH,
      (uint64_t)(uintptr_t)&available);
  write_queue_address(
      VIRTIO_MMIO_QUEUE_DEVICE_LOW, VIRTIO_MMIO_QUEUE_DEVICE_HIGH,
      (uint64_t)(uintptr_t)&used);
  mmio_write32(VIRTIO_MMIO_QUEUE_READY, 1);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 0, 10);

  configure_queue(
      (uint64_t)(uintptr_t)descriptors,
      (uint64_t)(uintptr_t)&available,
      (uint64_t)(uintptr_t)&used);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 1, 27);

  /*
   * QueueNum and queue addresses are write-only.  Once QueueReady is one the
   * driver must not touch them; this deliberate bad-driver sequence verifies
   * that the device keeps ownership of the original ring through completion.
   */
  mmio_write32(VIRTIO_MMIO_QUEUE_NUM, 4);
  mmio_write32(VIRTIO_MMIO_QUEUE_DESC_LOW,
      (uint32_t)(uintptr_t)descriptors + 16u);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 1, 12);

  prepare_one_random_buffer((uint64_t)(uintptr_t)random_bytes);

  /* A device must not consume or publish used buffers before DRIVER_OK. */
  mmio_write32(VIRTIO_MMIO_QUEUE_NOTIFY, 0);
  for (uint32_t i = 0; i < 128; i++) {
    publish_guest_memory();
    check_or_halt(used.index == 0, 14);
    check_or_halt(!random_buffer_changed(), 15);
    check_or_halt(mmio_read32(VIRTIO_MMIO_INTERRUPT_STATUS) == 0, 16);
  }

  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK);
  mmio_write32(VIRTIO_MMIO_QUEUE_NOTIFY, 0);
  check_or_halt(wait_for_used_index(1, 4096), 17);
  check_or_halt(used.ring[0].id == 0, 18);
  check_or_halt(used.ring[0].length > 0 &&
      used.ring[0].length <= sizeof(random_bytes), 19);
  check_or_halt(random_buffer_changed(), 20);
  check_or_halt(
      (mmio_read32(VIRTIO_MMIO_INTERRUPT_STATUS) & 1u) != 0, 21);
  mmio_write32(VIRTIO_MMIO_INTERRUPT_ACK, 1);
  check_or_halt(
      (mmio_read32(VIRTIO_MMIO_INTERRUPT_STATUS) & 1u) == 0, 22);

  /* QueueReady=0 is the queue-stop synchronization point in MMIO transport. */
  mmio_write32(VIRTIO_MMIO_QUEUE_READY, 0);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 0, 23);
  mmio_write32(VIRTIO_MMIO_QUEUE_NUM, 4);
  mmio_write32(VIRTIO_MMIO_QUEUE_READY, 1);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 1, 24);
  mmio_write32(VIRTIO_MMIO_QUEUE_READY, 0);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 0, 34);

  descriptors[1].address = (uint64_t)(uintptr_t)random_bytes;
  descriptors[1].length = sizeof(random_bytes);
  descriptors[1].flags = VIRTQ_DESC_F_WRITE;
  available.ring[1] = 1;
  available.index = 2;
  publish_guest_memory();
  mmio_write32(VIRTIO_MMIO_QUEUE_NOTIFY, 0);
  for (uint32_t i = 0; i < 128; i++) {
    publish_guest_memory();
    check_or_halt(used.index == 1, 25);
  }

  /* Status=0 is the only full device reset and releases all queue ownership. */
  mmio_write32(VIRTIO_MMIO_STATUS, 0);
  check_or_halt(mmio_read32(VIRTIO_MMIO_STATUS) == 0, 26);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 0, 28);
  check_or_halt(mmio_read32(VIRTIO_MMIO_INTERRUPT_STATUS) == 0, 29);

  /*
   * NEMU's PMA policy validates all three ring spans at QueueReady. A non-zero
   * high word is therefore rejected and must never alias low 32-bit PMEM.
   */
  negotiate_version_1();
  clear_queue_memory();
  configure_queue(
      UINT64_C(0x100000000) | (uint32_t)(uintptr_t)descriptors,
      UINT64_C(0x100000000) | (uint32_t)(uintptr_t)&available,
      UINT64_C(0x100000000) | (uint32_t)(uintptr_t)&used);
  check_or_halt(mmio_read32(VIRTIO_MMIO_QUEUE_READY) == 0, 30);
  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK);
  mmio_write32(VIRTIO_MMIO_QUEUE_NOTIFY, 0);
  check_or_halt(!wait_for_used_index(1, 128), 31);
  check_or_halt(!random_buffer_changed(), 32);

  /* The same no-alias rule applies to every descriptor buffer address. */
  mmio_write32(VIRTIO_MMIO_STATUS, 0);
  negotiate_version_1();
  clear_queue_memory();
  configure_queue(
      (uint64_t)(uintptr_t)descriptors,
      (uint64_t)(uintptr_t)&available,
      (uint64_t)(uintptr_t)&used);
  prepare_one_random_buffer(
      UINT64_C(0x100000000) | (uint32_t)(uintptr_t)random_bytes);
  mmio_write32(VIRTIO_MMIO_STATUS,
      VIRTIO_STATUS_ACKNOWLEDGE | VIRTIO_STATUS_DRIVER |
      VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK);
  mmio_write32(VIRTIO_MMIO_QUEUE_NOTIFY, 0);
  publish_guest_memory();
  for (uint32_t i = 0; i < sizeof(random_bytes); i++) {
    check_or_halt(random_bytes[i] == 0xa5u, 33);
  }

  mmio_write32(VIRTIO_MMIO_STATUS, 0);
finish:
  write_mtvec(old_mtvec);
  halt(0);
  return 0;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif

#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

/* NEMU's default machine map places these two complete 4 KiB regions adjacent. */
#define SERIAL_BASE       ((uintptr_t)0x10000000u)
#define VIRTIO_BLK_BASE   ((uintptr_t)0x10001000u)
#define VIRTIO_RNG_BASE   ((uintptr_t)0x10002000u)
#define GOLDFISH_RTC_BASE ((uintptr_t)0x10003000u)
#define VIRTIO_REGION_LEN ((uintptr_t)0x1000u)

#define VIRTIO_MAGIC            0x000u
#define VIRTIO_VERSION          0x004u
#define VIRTIO_RESERVED_018     0x018u
#define VIRTIO_QUEUE_NOTIFY     0x050u
#define GOLDFISH_IRQ_ENABLED    0x010u
#define GOLDFISH_ALARM_STATUS   0x018u

#define MSTATUS_MPP_MASK ((uintptr_t)3u << 11)
#define MSTATUS_MPP_S    ((uintptr_t)1u << 11)
#define MSTATUS_MPRV     ((uintptr_t)1u << 17)

#if __riscv_xlen == 64
#define MMIO_TRAP_STORE "sd"
#else
#define MMIO_TRAP_STORE "sw"
#endif

static volatile uintptr_t mmio_trap_count;
static volatile uintptr_t mmio_trap_cause;
static volatile uintptr_t mmio_trap_value;

extern void mmio_pma_trap_entry(void);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl mmio_pma_trap_entry\n"
"mmio_pma_trap_entry:\n"
"  csrr t0, mcause\n"
"  la t1, mmio_trap_cause\n"
"  " MMIO_TRAP_STORE " t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, mmio_trap_value\n"
"  " MMIO_TRAP_STORE " t0, 0(t1)\n"
"  la t1, mmio_trap_count\n"
"  " MMIO_TRAP_STORE " zero, 0(t1)\n"
"  li t0, 1\n"
"  " MMIO_TRAP_STORE " t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  li t0, 0x20000\n"
"  csrc mstatus, t0\n"
"  mret\n"
".option pop\n"
);

static inline uintptr_t read_mtvec(void) {
  uintptr_t value;
  asm volatile("csrr %0, mtvec" : "=r"(value));
  return value;
}

static inline void write_mtvec(uintptr_t value) {
  asm volatile("csrw mtvec, %0" : : "r"(value) : "memory");
}

static inline uintptr_t read_mstatus(void) {
  uintptr_t value;
  asm volatile("csrr %0, mstatus" : "=r"(value));
  return value;
}

static inline void write_mstatus(uintptr_t value) {
  asm volatile("csrw mstatus, %0" : : "r"(value) : "memory");
}

static inline uintptr_t read_satp(void) {
  uintptr_t value;
  asm volatile("csrr %0, satp" : "=r"(value));
  return value;
}

static inline void write_satp(uintptr_t value) {
  asm volatile("csrw satp, %0\nsfence.vma" : : "r"(value) : "memory");
}

static void clear_trap_record(void) {
  mmio_trap_count = 0;
  mmio_trap_cause = 0;
  mmio_trap_value = 0;
}

static void expect_trap(uintptr_t cause, uintptr_t address, int error_code) {
  if (mmio_trap_count != 1 || mmio_trap_cause != cause ||
      mmio_trap_value != address) {
    printf("mmio-pma-manual failure %d: traps=%lu cause=%lu "
        "mtval=0x%lx expected-cause=%lu expected-mtval=0x%lx\n",
        error_code, (unsigned long)mmio_trap_count,
        (unsigned long)mmio_trap_cause, (unsigned long)mmio_trap_value,
        (unsigned long)cause, (unsigned long)address);
    halt(error_code);
  }
}

static void expect_load_access_fault(
    uintptr_t address, uintptr_t fault_address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_trap(5, fault_address, error_code);
}

static void expect_store_access_fault(
    uintptr_t address, uintptr_t fault_address, int error_code) {
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  expect_trap(7, fault_address, error_code);
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
  expect_trap(5, address, error_code);
}

static void expect_page_table_memory_access_fault(int error_code) {
  const uintptr_t old_satp = read_satp();
  const uintptr_t old_mstatus = read_mstatus();
#if __riscv_xlen == 64
  const uintptr_t paged_satp = ((uintptr_t)8u << 60) |
      (VIRTIO_RNG_BASE >> 12);
#else
  const uintptr_t paged_satp = ((uintptr_t)1u << 31) |
      (VIRTIO_RNG_BASE >> 12);
#endif

  /*
   * MPRV+MPP=S applies page translation to this explicit load while the
   * instruction itself remains in M-mode.  The satp root points at a readable
   * Virtio aperture: an implementation that treats MMIO as page-table memory
   * will decode MagicValue as a PTE and incorrectly report a page fault.
   */
  write_satp(paged_satp);
  write_mstatus((old_mstatus & ~MSTATUS_MPP_MASK) |
      MSTATUS_MPP_S | MSTATUS_MPRV);
  clear_trap_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw zero, 0(zero)\n"
      ".option pop\n"
      : : : "t0", "t1", "memory");
  write_mstatus(old_mstatus);
  write_satp(old_satp);
  expect_trap(5, 0, error_code);
}

int main(void) {
  const uintptr_t old_mtvec = read_mtvec();
  write_mtvec((uintptr_t)mmio_pma_trap_entry);

  /*
   * A mapped bus transaction belongs to exactly one physical region. These
   * deliberately misaligned words start in serial and end in virtio-blk;
   * NEMU's scalar-memory EEI permits PMEM misalignment but no device PMA
   * advertises cross-page decomposition.  The complete instruction therefore
   * faults at its original virtual address before either device callback.
   */
  expect_load_access_fault(
      VIRTIO_BLK_BASE - 2, VIRTIO_BLK_BASE - 2, 2);
  expect_store_access_fault(
      VIRTIO_BLK_BASE - 2, VIRTIO_BLK_BASE - 2, 3);

  /* A span leaving the last byte of one aperture is likewise unmapped. */
  expect_load_access_fault(
      VIRTIO_BLK_BASE + VIRTIO_REGION_LEN - 2,
      VIRTIO_BLK_BASE + VIRTIO_REGION_LEN - 2, 4);
  expect_store_access_fault(
      VIRTIO_BLK_BASE + VIRTIO_REGION_LEN - 2,
      VIRTIO_BLK_BASE + VIRTIO_REGION_LEN - 2, 5);

  /* Address arithmetic must reject wraparound before any physical callback. */
  expect_load_access_fault(UINTPTR_MAX - 1, UINTPTR_MAX - 1, 6);
  expect_store_access_fault(UINTPTR_MAX - 1, UINTPTR_MAX - 1, 7);

  /* Virtio 1.x transport registers are naturally aligned 32-bit accesses. */
  expect_byte_load_access_fault(VIRTIO_RNG_BASE + VIRTIO_MAGIC, 8);
  expect_load_access_fault(
      VIRTIO_RNG_BASE + VIRTIO_MAGIC + 1,
      VIRTIO_RNG_BASE + VIRTIO_MAGIC + 1, 9);

  /* Register direction and reserved offsets are PMA, not callback no-ops. */
  expect_store_access_fault(VIRTIO_RNG_BASE + VIRTIO_MAGIC,
      VIRTIO_RNG_BASE + VIRTIO_MAGIC, 10);
  expect_store_access_fault(VIRTIO_RNG_BASE + VIRTIO_VERSION,
      VIRTIO_RNG_BASE + VIRTIO_VERSION, 11);
  expect_load_access_fault(VIRTIO_RNG_BASE + VIRTIO_QUEUE_NOTIFY,
      VIRTIO_RNG_BASE + VIRTIO_QUEUE_NOTIFY, 12);
  expect_load_access_fault(VIRTIO_RNG_BASE + VIRTIO_RESERVED_018,
      VIRTIO_RNG_BASE + VIRTIO_RESERVED_018, 13);
  expect_store_access_fault(VIRTIO_RNG_BASE + VIRTIO_RESERVED_018,
      VIRTIO_RNG_BASE + VIRTIO_RESERVED_018, 14);

  /* Goldfish exposes 32-bit action/status registers with explicit direction. */
  expect_load_access_fault(GOLDFISH_RTC_BASE + GOLDFISH_IRQ_ENABLED,
      GOLDFISH_RTC_BASE + GOLDFISH_IRQ_ENABLED, 15);
  expect_store_access_fault(GOLDFISH_RTC_BASE + GOLDFISH_ALARM_STATUS,
      GOLDFISH_RTC_BASE + GOLDFISH_ALARM_STATUS, 16);

  /* Implicit PTE reads require idempotent PMEM, never a readable device. */
  expect_page_table_memory_access_fault(17);

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

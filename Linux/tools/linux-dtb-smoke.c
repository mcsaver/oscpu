#include <stdint.h>

#define FDT_MAGIC 0xd00dfeedu
#define FDT_VERSION 17u
#define BOOT_HARTID 0ull
#ifndef DTB_SMOKE_STACK
#define DTB_SMOKE_STACK 0x87eff000
#endif

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

asm(
".section .text, \"ax\", @progbits\n"
".globl _start\n"
".option push\n"
".option norvc\n"
".align 2\n"
"_start:\n"
"  li sp, " STR(DTB_SMOKE_STACK) "\n"
"  call linux_dtb_smoke_main\n"
"  ebreak\n"
".option pop\n"
);

static uint32_t load_be32(const uint8_t *p) {
  return ((uint32_t)p[0] << 24) |
         ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) |
         (uint32_t)p[3];
}

static int bytes_equal(const uint8_t *p, const char *s) {
  while (*s != '\0') {
    if (*p != (uint8_t)*s) return 0;
    p++;
    s++;
  }
  return 1;
}

static int blob_contains(const uint8_t *blob, uint32_t size, const char *needle) {
  for (uint32_t i = 0; i < size; i++) {
    if (bytes_equal(blob + i, needle)) return 1;
  }
  return 0;
}

uintptr_t linux_dtb_smoke_main(uintptr_t hartid, const uint8_t *dtb) {
  if (hartid != BOOT_HARTID) return 1;
  if (dtb == (const uint8_t *)0) return 2;
  if (load_be32(dtb + 0) != FDT_MAGIC) return 3;

  uint32_t totalsize = load_be32(dtb + 4);
  uint32_t off_struct = load_be32(dtb + 8);
  uint32_t off_strings = load_be32(dtb + 12);
  uint32_t off_mem_rsvmap = load_be32(dtb + 16);
  uint32_t version = load_be32(dtb + 20);
  uint32_t last_comp_version = load_be32(dtb + 24);
  uint32_t boot_cpuid = load_be32(dtb + 28);
  uint32_t size_strings = load_be32(dtb + 32);
  uint32_t size_struct = load_be32(dtb + 36);

  if (totalsize < 256u || totalsize > 65536u) return 4;
  if (version < FDT_VERSION || last_comp_version > 16u) return 5;
  if (boot_cpuid != 0u) return 6;
  if (off_mem_rsvmap < 40u || off_struct <= off_mem_rsvmap) return 7;
  if (off_strings <= off_struct) return 8;
  if (size_struct == 0u || size_strings == 0u) return 9;
  if (off_struct + size_struct > totalsize) return 10;
  if (off_strings + size_strings > totalsize) return 11;

  if (!blob_contains(dtb, totalsize, "YSYX NPC RV64")) return 12;
  if (!blob_contains(dtb, totalsize, "rv64imafdc_zicsr_zifencei")) return 13;
  if (!blob_contains(dtb, totalsize, "riscv,sv39")) return 14;
  if (!blob_contains(dtb, totalsize, "riscv,clint0")) return 15;
  if (!blob_contains(dtb, totalsize, "riscv,plic0")) return 16;
  if (!blob_contains(dtb, totalsize, "ns16550a")) return 17;
  if (!blob_contains(dtb, totalsize, "stdout-path")) return 18;
  if (!blob_contains(dtb, totalsize, "timebase-frequency")) return 19;

  return 0;
}

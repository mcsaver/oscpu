#include "trap.h"

typedef unsigned int uint32_t;
#ifdef __ISA_RISCV64__
typedef unsigned long uintptr_t;
#endif

#define RVC_PUSH ".option push\n.option arch, +c\n"
#define RVC_POP  ".option pop\n"

static inline uint32_t run_rvc_arith(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 5\n"
      "c.addi a2, 3\n"
      "c.slli a2, 1\n"
      "c.srli a2, 1\n"
      "c.srai a2, 1\n"
      "c.andi a2, 7\n"
      "li a3, 2\n"
      "c.add a2, a3\n"
      "c.sub a2, a3\n"
      "c.xor a2, a3\n"
      "c.or a2, a3\n"
      "c.and a2, a3\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_load_store(uint32_t *buf) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 0x13572468\n"
      "mv a3, %1\n"
      "c.sw a2, 0(a3)\n"
      "li a2, 0\n"
      "c.lw a2, 0(a3)\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      : "r"(buf)
      : "a2", "a3", "memory");
  return out;
}

static inline uint32_t run_rvc_sp_ops(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "addi sp, sp, -16\n"
      "li a2, 0x24681357\n"
      "c.swsp a2, 0(sp)\n"
      "li a2, 0\n"
      "c.lwsp a2, 0(sp)\n"
      "addi sp, sp, 16\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "memory");
  return out;
}

static inline uint32_t run_rvc_sp_imm(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "mv a3, sp\n"
      "c.addi4spn a2, sp, 16\n"
      "sub %0, a2, a3\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_li_lui(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "c.li a2, -3\n"
      "c.addi a2, 4\n"
      "c.lui a3, 1\n"
      "add %0, a2, a3\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

#ifdef __ISA_RISCV64__
static inline uintptr_t run_rvc64_addiw(void) {
  uintptr_t out;
  asm volatile(
      RVC_PUSH
      "li a2, -1\n"
      "c.addiw a2, 1\n"
      "c.addiw a2, -1\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2");
  return out;
}

static inline uintptr_t run_rvc64_shamt6(void) {
  uintptr_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 1\n"
      "c.slli a2, 42\n"
      "c.srli a2, 41\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2");
  return out;
}

static inline uintptr_t run_rvc64_ld_sd(uintptr_t *buf) {
  uintptr_t out;
  asm volatile(
      RVC_PUSH
      "li a2, -5\n"
      "mv a3, %1\n"
      "c.sd a2, 0(a3)\n"
      "li a2, 0\n"
      "c.ld a2, 0(a3)\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      : "r"(buf)
      : "a2", "a3", "memory");
  return out;
}

static inline uintptr_t run_rvc64_ld_sd_sp(void) {
  uintptr_t out;
  asm volatile(
      RVC_PUSH
      "addi sp, sp, -16\n"
      "li a2, -7\n"
      "c.sdsp a2, 0(sp)\n"
      "li a2, 0\n"
      "c.ldsp a2, 0(sp)\n"
      "addi sp, sp, 16\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "memory");
  return out;
}

static inline uintptr_t run_rvc64_addw_subw(void) {
  uintptr_t out;
  asm volatile(
      RVC_PUSH
      "li a2, -1\n"
      "li a3, 2\n"
      "c.addw a2, a3\n"
      "li a3, 3\n"
      "c.subw a2, a3\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}
#endif

static inline uint32_t run_rvc_branches(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 0\n"
      "li a3, 0\n"
      "c.beqz a2, 1f\n"
      "li a3, 9\n"
      "1:\n"
      "c.addi a3, 1\n"
      "c.bnez a3, 2f\n"
      "li a3, 9\n"
      "2:\n"
      "c.mv %0, a3\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_jumps(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 0\n"
      "c.j 1f\n"
      "li a2, 9\n"
      "1:\n"
      "c.addi a2, 1\n"
      "la a3, 2f\n"
      "c.jr a3\n"
      "li a2, 9\n"
      "2:\n"
      "c.addi a2, 1\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

#ifndef __ISA_RISCV64__
static inline uint32_t run_rvc_link_pc2(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 0\n"
      "c.jal 1f\n"
      "c.addi a2, 1\n"
      "c.j 2f\n"
      "1:\n"
      "c.jr ra\n"
      "2:\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "ra");
  return out;
}
#endif

static inline uint32_t run_rvc_jalr_pc2(void) {
  uint32_t out;
  asm volatile(
      RVC_PUSH
      "li a2, 0\n"
      "la a3, 1f\n"
      "c.jalr a3\n"
      "c.addi a2, 1\n"
      "c.j 2f\n"
      "1:\n"
      "c.jr ra\n"
      "2:\n"
      "c.mv %0, a2\n"
      RVC_POP
      : "=r"(out)
      :
      : "a2", "a3", "ra");
  return out;
}

int main() {
  uint32_t buf[1] = {0};
#ifdef __ISA_RISCV64__
  uintptr_t buf64[1] = {0};
#endif

  check(run_rvc_arith() == 2u);
  check(run_rvc_load_store(buf) == 0x13572468u);
  check(run_rvc_sp_ops() == 0x24681357u);
  check(run_rvc_sp_imm() == 16u);
  check(run_rvc_li_lui() == 0x1001u);
#ifdef __ISA_RISCV64__
  check(run_rvc64_addiw() == (uintptr_t)-1);
  check(run_rvc64_shamt6() == 2ul);
  check(run_rvc64_ld_sd(buf64) == (uintptr_t)-5);
  check(run_rvc64_ld_sd_sp() == (uintptr_t)-7);
  check(run_rvc64_addw_subw() == (uintptr_t)-2);
#endif
  check(run_rvc_branches() == 1u);
  check(run_rvc_jumps() == 2u);
#ifndef __ISA_RISCV64__
  check(run_rvc_link_pc2() == 1u);
#endif
  check(run_rvc_jalr_pc2() == 1u);

  return 0;
}

#include "trap.h"

typedef unsigned int uint32_t;

static inline uint32_t run_rvc_arith(void) {
  uint32_t out;
  asm volatile(
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
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_load_store(uint32_t *buf) {
  uint32_t out;
  asm volatile(
      "li a2, 0x13572468\n"
      "mv a3, %1\n"
      "c.sw a2, 0(a3)\n"
      "li a2, 0\n"
      "c.lw a2, 0(a3)\n"
      "c.mv %0, a2\n"
      : "=r"(out)
      : "r"(buf)
      : "a2", "a3", "memory");
  return out;
}

static inline uint32_t run_rvc_sp_ops(void) {
  uint32_t out;
  asm volatile(
      "addi sp, sp, -16\n"
      "li a2, 0x24681357\n"
      "c.swsp a2, 0(sp)\n"
      "li a2, 0\n"
      "c.lwsp a2, 0(sp)\n"
      "addi sp, sp, 16\n"
      "c.mv %0, a2\n"
      : "=r"(out)
      :
      : "a2", "memory");
  return out;
}

static inline uint32_t run_rvc_sp_imm(void) {
  uint32_t out;
  asm volatile(
      "mv a3, sp\n"
      "c.addi4spn a2, sp, 16\n"
      "sub %0, a2, a3\n"
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_li_lui(void) {
  uint32_t out;
  asm volatile(
      "c.li a2, -3\n"
      "c.addi a2, 4\n"
      "c.lui a3, 1\n"
      "add %0, a2, a3\n"
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_branches(void) {
  uint32_t out;
  asm volatile(
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
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_jumps(void) {
  uint32_t out;
  asm volatile(
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
      : "=r"(out)
      :
      : "a2", "a3");
  return out;
}

static inline uint32_t run_rvc_link_pc2(void) {
  uint32_t out;
  asm volatile(
      "li a2, 0\n"
      "c.jal 1f\n"
      "c.addi a2, 1\n"
      "c.j 2f\n"
      "1:\n"
      "c.jr ra\n"
      "2:\n"
      "c.mv %0, a2\n"
      : "=r"(out)
      :
      : "a2", "ra");
  return out;
}

static inline uint32_t run_rvc_jalr_pc2(void) {
  uint32_t out;
  asm volatile(
      "li a2, 0\n"
      "la a3, 1f\n"
      "c.jalr a3\n"
      "c.addi a2, 1\n"
      "c.j 2f\n"
      "1:\n"
      "c.jr ra\n"
      "2:\n"
      "c.mv %0, a2\n"
      : "=r"(out)
      :
      : "a2", "a3", "ra");
  return out;
}

int main() {
  uint32_t buf[1] = {0};

  check(run_rvc_arith() == 2u);
  check(run_rvc_load_store(buf) == 0x13572468u);
  check(run_rvc_sp_ops() == 0x24681357u);
  check(run_rvc_sp_imm() == 16u);
  check(run_rvc_li_lui() == 0x1001u);
  check(run_rvc_branches() == 1u);
  check(run_rvc_jumps() == 2u);
  check(run_rvc_link_pc2() == 1u);
  check(run_rvc_jalr_pc2() == 1u);

  return 0;
}

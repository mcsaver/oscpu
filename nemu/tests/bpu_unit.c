#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include <cpu/bpu.h>

static uint32_t encode_b_type(int imm, int rs2, int rs1, int funct3, uint32_t opcode) {
  uint32_t uimm = (uint32_t)imm;
  return (((uimm >> 12) & 0x1) << 31) |
         (((uimm >> 5) & 0x3f) << 25) |
         ((rs2 & 0x1f) << 20) |
         ((rs1 & 0x1f) << 15) |
         ((funct3 & 0x7) << 12) |
         (((uimm >> 1) & 0xf) << 8) |
         (((uimm >> 11) & 0x1) << 7) |
         (opcode & 0x7f);
}

static uint32_t encode_j_type(int imm, int rd, uint32_t opcode) {
  uint32_t uimm = (uint32_t)imm;
  return (((uimm >> 20) & 0x1) << 31) |
         (((uimm >> 1) & 0x3ff) << 21) |
         (((uimm >> 11) & 0x1) << 20) |
         (((uimm >> 12) & 0xff) << 12) |
         ((rd & 0x1f) << 7) |
         (opcode & 0x7f);
}

static uint32_t encode_i_type(int imm, int rs1, int funct3, int rd, uint32_t opcode) {
  return (((uint32_t)imm & 0xfff) << 20) |
         ((rs1 & 0x1f) << 15) |
         ((funct3 & 0x7) << 12) |
         ((rd & 0x1f) << 7) |
         (opcode & 0x7f);
}

static void test_taken_branch_learns_direction_and_target(void) {
  bpu_init_for_test();

  uint32_t beq = encode_b_type(8, 0, 0, 0x0, 0x63);
  bpu_commit(0x1000, beq, 0x1004, 0x1008);
  bpu_commit(0x1000, beq, 0x1004, 0x1008);

  const BpuStats *stats = bpu_get_stats();
  assert(stats->branch_access == 2);
  assert(stats->branch_miss == 1);
  assert(stats->branch_hit == 1);
  assert(stats->target_access == 1);
  assert(stats->target_hit == 1);
}

static void test_ras_predicts_return_after_call_push(void) {
  bpu_init_for_test();

  uint32_t jal = encode_j_type(0x20, 1, 0x6f);
  uint32_t ret = encode_i_type(0, 1, 0x0, 0, 0x67);
  bpu_commit(0x2000, jal, 0x2004, 0x2020);
  bpu_commit(0x3000, ret, 0x3004, 0x2004);

  const BpuStats *stats = bpu_get_stats();
  assert(stats->ras_push == 1);
  assert(stats->ras_pop == 1);
  assert(stats->ras_access == 1);
  assert(stats->ras_hit == 1);
}

static void test_ras_overflow_discards_oldest_return(void) {
  bpu_init_for_test();

  uint32_t jal = encode_j_type(0x20, 1, 0x6f);
  bpu_commit(0x4000, jal, 0x4004, 0x4020);
  bpu_commit(0x5000, jal, 0x5004, 0x5020);
  bpu_commit(0x6000, jal, 0x6004, 0x6020);

  const BpuStats *stats = bpu_get_stats();
  assert(stats->ras_push == 3);
  assert(stats->ras_overflow == 1);
}

int main(void) {
  test_taken_branch_learns_direction_and_target();
  test_ras_predicts_return_after_call_push();
  test_ras_overflow_discards_oldest_return();
  puts("bpu_unit PASS");
  return 0;
}

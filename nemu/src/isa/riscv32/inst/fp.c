/* RV32 executes the shared F/D manual semantics after pure descriptor decode. */
#ifdef CONFIG_RISCV_EXT_F
#include <isa/riscv/floating_execute.inc>
#else
static inline bool exec_rvf_flw(int rd, word_t addr) {
  (void)rd;
  (void)addr;
  return false;
}

static inline bool exec_rvf_fld(int rd, word_t addr) {
  (void)rd;
  (void)addr;
  return false;
}

static inline bool exec_rvf_fsw(word_t addr, int rs2) {
  (void)addr;
  (void)rs2;
  return false;
}

static inline bool exec_rvf_fsd(word_t addr, int rs2) {
  (void)addr;
  (void)rs2;
  return false;
}

static inline bool exec_rvf_decoded(
    const RiscvFloatingInstruction *instruction) {
  (void)instruction;
  return false;
}
#endif

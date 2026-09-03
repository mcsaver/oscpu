/* RV32/RV64 F/D load/store、算术、转换、比较和分类的共享执行语义。 */

/* NEMU RISC-V F/D: Berkeley SoftFloat (RISC-V specialization) 金标准实现。
 * 2026-07-06 从 host-float 升级为 proper IEEE-754(与 spike 同源 softfloat)。
 * ★SoftFloat 的 roundingMode(0-4) 与 RISC-V frm 位相同; exceptionFlags 位
 *  (inexact=1/underflow=2/overflow=4/infinite=8/invalid=16) 与 RISC-V fflags
 *  (NX/UF/OF/DZ/NV) 完全相同(均按 RISC-V 设计), 故 glue 极简: 直接或入。 */
#include "softfloat.h"

static inline void fp_raise_invalid(void) {
  cpu.csr.fflags |= RISCV_FFLAGS_NV;
  fp_mark_dirty();
}

/* SoftFloat glue: 位模式 ↔ float{32,64}_t; 按 frm 设 roundingMode; 异常 flag 累积到 fflags。 */
static inline float32_t to_f32(uint32_t v) { float32_t x = { .v = v }; return x; }
static inline float64_t to_f64(uint64_t v) { float64_t x = { .v = v }; return x; }
static inline uint32_t neg_f32_bits(uint32_t v) { return v ^ 0x80000000u; }
static inline uint64_t neg_f64_bits(uint64_t v) { return v ^ 0x8000000000000000ull; }

static inline uint32_t fp_current_flen(void) {
  return riscv_flen(
      ISDEF(CONFIG_RISCV_EXT_F), ISDEF(CONFIG_RISCV_EXT_D));
}

static inline uint64_t f32_box(uint32_t value) {
  return riscv_fp_box_single(value, fp_current_flen());
}

static inline void sf_set_rm(uint32_t rm) {
  softfloat_roundingMode = (uint_fast8_t)((rm == 0x7) ? cpu.csr.frm : rm);
}

static inline void fp_flags_clear(void) { softfloat_exceptionFlags = 0; }

static inline void fp_flags_accum(void) {
  if (softfloat_exceptionFlags != 0) {
    cpu.csr.fflags |= (uint32_t)softfloat_exceptionFlags;  /* 位与 RISC-V fflags 相同 */
    fp_mark_dirty();
  }
}

#include <isa/riscv/floating_load_trace.inc>

/*
 * NEMU EEI scalar-memory policy:
 *   - a naturally misaligned FP access may be emulated within one translated
 *     4 KiB page;
 *   - a naturally misaligned translated access crossing that page boundary
 *     raises the architectural address-misaligned exception before any
 *     memory byte is committed;
 *   - translation, protection and MMIO legality remain the vaddr/PMA layer's
 *     responsibility.
 */
static inline bool riscv_fp_misaligned_page_crossing_traps(
    word_t address, uint32_t width_bytes, int memory_type,
    word_t exception_cause) {
  const bool is_naturally_misaligned =
      (address & (word_t)(width_bytes - 1)) != 0;
  if (!is_naturally_misaligned) return false;

  const bool uses_address_translation =
      isa_mmu_check(address, (int)width_bytes, memory_type) == MMU_TRANSLATE;
  const bool crosses_4k_page =
      (address & (word_t)0xfff) + width_bytes > (word_t)0x1000;
  if (!uses_address_translation || !crosses_4k_page) return false;

  vaddr_set_fault(exception_cause, address);
  return true;
}

static inline bool exec_rvf_flw(int rd, word_t address) {
  if (!fp_state_enabled()) return false;
  if (riscv_fp_misaligned_page_crossing_traps(
          address, 4, MEM_TYPE_READ, CAUSE_LOAD_MISALIGNED)) {
    return true;
  }

  uint64_t raw_value = 0;
  if (!vaddr_read_bits(address, 4, &raw_value)) return true;
  fp_load_trace_after_load("FLW", rd, address, 4, (uint32_t)raw_value);
  F(rd) = f32_box((uint32_t)raw_value);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fld(int rd, word_t address) {
#ifdef CONFIG_RISCV_EXT_D
  if (!fp_state_enabled()) return false;
  if (riscv_fp_misaligned_page_crossing_traps(
          address, 8, MEM_TYPE_READ, CAUSE_LOAD_MISALIGNED)) {
    return true;
  }

  uint64_t raw_value = 0;
  if (!vaddr_read_bits(address, 8, &raw_value)) return true;
  fp_load_trace_after_load("FLD", rd, address, 8, raw_value);
  F(rd) = raw_value;
  fp_mark_dirty();
  return true;
#else
  (void)rd;
  (void)address;
  return false;
#endif
}

static inline bool exec_rvf_fsw(word_t address, int rs2) {
  if (!fp_state_enabled()) return false;
  if (riscv_fp_misaligned_page_crossing_traps(
          address, 4, MEM_TYPE_WRITE, CAUSE_STORE_MISALIGNED)) {
    return true;
  }

  (void)vaddr_write_bits(address, 4, (uint32_t)F(rs2));
  return true;
}

static inline bool exec_rvf_fsd(word_t address, int rs2) {
#ifdef CONFIG_RISCV_EXT_D
  if (!fp_state_enabled()) return false;
  if (riscv_fp_misaligned_page_crossing_traps(
          address, 8, MEM_TYPE_WRITE, CAUSE_STORE_MISALIGNED)) {
    return true;
  }

  (void)vaddr_write_bits(address, 8, F(rs2));
  return true;
#else
  (void)address;
  (void)rs2;
  return false;
#endif
}

static inline word_t fclass32(uint32_t value) {
  uint32_t sign = value >> 31;
  uint32_t exp = BITS(value, 30, 23);
  uint32_t frac = value & 0x7fffffu;
  if (exp == 0xffu) {
    if (frac == 0) return sign ? 0x001 : 0x080;
    return (frac & 0x400000u) ? 0x200 : 0x100;
  }
  if (exp == 0) {
    if (frac == 0) return sign ? 0x008 : 0x010;
    return sign ? 0x004 : 0x020;
  }
  return sign ? 0x002 : 0x040;
}

static inline bool f32_is_nan(uint32_t value) {
  return (value & 0x7fffffffu) > 0x7f800000u;
}

static inline bool f32_is_snan(uint32_t value) {
  uint32_t frac = value & 0x7fffffu;
  return (BITS(value, 30, 23) == 0xffu) && frac != 0 && (frac & 0x400000u) == 0;
}

static inline bool f64_is_nan(uint64_t value) {
  return (value & 0x7fffffffffffffffull) > 0x7ff0000000000000ull;
}

static inline bool f64_is_snan(uint64_t value) {
  uint64_t frac = value & 0x000fffffffffffffull;
  return (((value >> 52) & 0x7ffu) == 0x7ffu) && frac != 0 &&
         (frac & 0x0008000000000000ull) == 0;
}

/* RISC-V NaN boxing: 单精 op 读 FPR, 高 32 位非全 1 → 视为 canonical qNaN。
 * (FMV.X.W 与 FSW 是 raw 位形搬运, 不做该检查。) */
static inline uint32_t f32_unbox(uint64_t value) {
  return riscv_fp_unbox_single(value, fp_current_flen());
}

/* host-float 转换 helper 已删: SoftFloat 直接在位模式(float{32,64}_t)上运算, 结果已 canonical。 */

static inline bool fp_rounding_mode_valid(uint32_t rm) {
  uint32_t resolved = rm == 0x7 ? cpu.csr.frm : rm;
  return resolved <= 0x4;
}

static inline bool exec_rvf_arith_s(
                                    RiscvFloatingOperation operation,
                                    uint32_t rm, int rd,
                                    uint32_t a, uint32_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float32_t af = to_f32(a), bf = to_f32(b), result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FADD_S: result = f32_add(af, bf); break;
    case RISCV_FLOAT_OPERATION_FSUB_S: result = f32_sub(af, bf); break;
    case RISCV_FLOAT_OPERATION_FMUL_S: result = f32_mul(af, bf); break;
    case RISCV_FLOAT_OPERATION_FDIV_S: result = f32_div(af, bf); break;
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = f32_box(result.v);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_arith_d(
                                    RiscvFloatingOperation operation,
                                    uint32_t rm, int rd,
                                    uint64_t a, uint64_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float64_t af = to_f64(a), bf = to_f64(b), result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FADD_D: result = f64_add(af, bf); break;
    case RISCV_FLOAT_OPERATION_FSUB_D: result = f64_sub(af, bf); break;
    case RISCV_FLOAT_OPERATION_FMUL_D: result = f64_mul(af, bf); break;
    case RISCV_FLOAT_OPERATION_FDIV_D: result = f64_div(af, bf); break;
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = result.v;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_sqrt_s(uint32_t rm, int rd, uint32_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  sf_set_rm(rm);
  fp_flags_clear();
  float32_t result = f32_sqrt(to_f32(value));  // 负有限数/sNaN → canonical NaN + NV(SoftFloat 内建)
  fp_flags_accum();
  F(rd) = f32_box(result.v);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_sqrt_d(uint32_t rm, int rd, uint64_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  sf_set_rm(rm);
  fp_flags_clear();
  float64_t result = f64_sqrt(to_f64(value));
  fp_flags_accum();
  F(rd) = result.v;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_s(
                                         RiscvFloatingOperation operation,
                                         uint32_t rm, int rd,
                                         uint32_t a, uint32_t b, uint32_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  uint32_t na = neg_f32_bits(a), nc = neg_f32_bits(c);
  float32_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FMADD_S:
      result = f32_mulAdd(to_f32(a), to_f32(b), to_f32(c)); break;
    case RISCV_FLOAT_OPERATION_FMSUB_S:
      result = f32_mulAdd(to_f32(a), to_f32(b), to_f32(nc)); break;
    case RISCV_FLOAT_OPERATION_FNMSUB_S:
      result = f32_mulAdd(to_f32(na), to_f32(b), to_f32(c)); break;
    case RISCV_FLOAT_OPERATION_FNMADD_S:
      result = f32_mulAdd(to_f32(na), to_f32(b), to_f32(nc)); break;
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = f32_box(result.v);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_d(
                                         RiscvFloatingOperation operation,
                                         uint32_t rm, int rd,
                                         uint64_t a, uint64_t b, uint64_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  uint64_t na = neg_f64_bits(a), nc = neg_f64_bits(c);
  float64_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FMADD_D:
      result = f64_mulAdd(to_f64(a), to_f64(b), to_f64(c)); break;
    case RISCV_FLOAT_OPERATION_FMSUB_D:
      result = f64_mulAdd(to_f64(a), to_f64(b), to_f64(nc)); break;
    case RISCV_FLOAT_OPERATION_FNMSUB_D:
      result = f64_mulAdd(to_f64(na), to_f64(b), to_f64(c)); break;
    case RISCV_FLOAT_OPERATION_FNMADD_D:
      result = f64_mulAdd(to_f64(na), to_f64(b), to_f64(nc)); break;
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = result.v;
  fp_mark_dirty();
  return true;
}

static inline uint32_t fminmax32(uint32_t a, uint32_t b, bool is_max) {
  bool an = f32_is_nan(a);
  bool bn = f32_is_nan(b);
  if (f32_is_snan(a) || f32_is_snan(b)) fp_raise_invalid();
  if (an && bn) return 0x7fc00000u;
  if (an) return b;
  if (bn) return a;
  // a,b 均非 NaN: 用 quiet 比较避免多余 flag。±0 同值异号: max→+0, min→-0。
  if (f32_eq(to_f32(a), to_f32(b)) && ((a ^ b) & 0x80000000u) != 0) {
    return is_max ? 0x00000000u : 0x80000000u;
  }
  bool a_lt_b = f32_lt_quiet(to_f32(a), to_f32(b));
  if (is_max) return a_lt_b ? b : a;
  return a_lt_b ? a : b;
}

static inline uint64_t fminmax64(uint64_t a, uint64_t b, bool is_max) {
  bool an = f64_is_nan(a);
  bool bn = f64_is_nan(b);
  if (f64_is_snan(a) || f64_is_snan(b)) fp_raise_invalid();
  if (an && bn) return 0x7ff8000000000000ull;
  if (an) return b;
  if (bn) return a;
  if (f64_eq(to_f64(a), to_f64(b)) && ((a ^ b) & 0x8000000000000000ull) != 0) {
    return is_max ? 0x0000000000000000ull : 0x8000000000000000ull;
  }
  bool a_lt_b = f64_lt_quiet(to_f64(a), to_f64(b));
  if (is_max) return a_lt_b ? b : a;
  return a_lt_b ? a : b;
}

/* fcvt_round_by_rm / host fcvt_to_int 已删: SoftFloat f{32,64}_to_{i,ui}{32,64}(x, rm, exact=true)
 * 在 RISCV specialization 下直接给 RISC-V 正确的饱和值 + NV/NX。★to-int 的舍入是函数参数(非全局)。
 * 32 位结果按 RISC-V 规则 sext 到 XLEN(含 wu: 无符号 32 位结果也 sext)。 */
static inline word_t sf_f32_to_int(
    float32_t x, RiscvFloatingOperation operation, uint_fast8_t r) {
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FCVT_W_S:
      return (word_t)(int64_t)(int32_t)f32_to_i32(x, r, true);
    case RISCV_FLOAT_OPERATION_FCVT_WU_S:
      return (word_t)(int64_t)(int32_t)(uint32_t)f32_to_ui32(x, r, true);
    case RISCV_FLOAT_OPERATION_FCVT_L_S:
      return (word_t)(int64_t)f32_to_i64(x, r, true);
    case RISCV_FLOAT_OPERATION_FCVT_LU_S:
      return (word_t)(uint64_t)f32_to_ui64(x, r, true);
    default:
      return 0;
  }
}
static inline word_t sf_f64_to_int(
    float64_t x, RiscvFloatingOperation operation, uint_fast8_t r) {
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FCVT_W_D:
      return (word_t)(int64_t)(int32_t)f64_to_i32(x, r, true);
    case RISCV_FLOAT_OPERATION_FCVT_WU_D:
      return (word_t)(int64_t)(int32_t)(uint32_t)f64_to_ui32(x, r, true);
    case RISCV_FLOAT_OPERATION_FCVT_L_D:
      return (word_t)(int64_t)f64_to_i64(x, r, true);
    case RISCV_FLOAT_OPERATION_FCVT_LU_D:
      return (word_t)(uint64_t)f64_to_ui64(x, r, true);
    default:
      return 0;
  }
}

static inline bool exec_rvf_fcvt_int_s(
                                       RiscvFloatingOperation operation,
                                       uint32_t rm, int rd,
                                       uint32_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  uint_fast8_t r = (uint_fast8_t)((rm == 0x7) ? cpu.csr.frm : rm);
  fp_flags_clear();
  R(rd) = sf_f32_to_int(to_f32(value), operation, r);
  fp_flags_accum();
  return true;
}

static inline bool exec_rvf_fcvt_int_d(
                                       RiscvFloatingOperation operation,
                                       uint32_t rm, int rd,
                                       uint64_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  uint_fast8_t r = (uint_fast8_t)((rm == 0x7) ? cpu.csr.frm : rm);
  fp_flags_clear();
  R(rd) = sf_f64_to_int(to_f64(value), operation, r);
  fp_flags_accum();
  return true;
}

static inline bool exec_rvf_fcvt_from_int_s(
                                            RiscvFloatingOperation operation,
                                            uint32_t rm, int rd, int rs1) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float32_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FCVT_S_W:
      result = i32_to_f32((int32_t)R(rs1)); break;
    case RISCV_FLOAT_OPERATION_FCVT_S_WU:
      result = ui32_to_f32((uint32_t)R(rs1)); break;
    case RISCV_FLOAT_OPERATION_FCVT_S_L:
      result = i64_to_f32((int64_t)R(rs1)); break;
    case RISCV_FLOAT_OPERATION_FCVT_S_LU:
      result = ui64_to_f32((uint64_t)R(rs1)); break;
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = f32_box(result.v);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_from_int_d(
                                            RiscvFloatingOperation operation,
                                            uint32_t rm, int rd, int rs1) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float64_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FCVT_D_W:
      result = i32_to_f64((int32_t)R(rs1)); break;
    case RISCV_FLOAT_OPERATION_FCVT_D_WU:
      result = ui32_to_f64((uint32_t)R(rs1)); break;
    case RISCV_FLOAT_OPERATION_FCVT_D_L:
      result = i64_to_f64((int64_t)R(rs1)); break;
    case RISCV_FLOAT_OPERATION_FCVT_D_LU:
      result = ui64_to_f64((uint64_t)R(rs1)); break;
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = result.v;
  fp_mark_dirty();
  return true;
}

#if defined(CONFIG_RISCV_EXT_F) && defined(CONFIG_RISCV_EXT_D)
static inline bool exec_rvf_fcvt_s_d(uint32_t rm, int rd, uint64_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  sf_set_rm(rm);                                // fcvt.s.d 加窄, 需舍入
  fp_flags_clear();
  float32_t result = f64_to_f32(to_f64(value));
  fp_flags_accum();
  F(rd) = f32_box(result.v);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_d_s(uint32_t rm, int rd, uint32_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  fp_flags_clear();                             // fcvt.d.s 加宽精确(无需舍入), sNaN → NV
  float64_t result = f32_to_f64(to_f32(value));
  fp_flags_accum();
  F(rd) = result.v;
  fp_mark_dirty();
  return true;
}
#endif

static inline bool exec_rvf_compare_s(
                                      RiscvFloatingOperation operation,
                                      int rd, uint32_t a,
                                      uint32_t b) {
  // f32_le/lt 是 signaling(任意 NaN→NV、返 0), f32_eq 是 quiet(仅 sNaN→NV) —— 正合 RISC-V。
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FLE_S:
      R(rd) = f32_le(to_f32(a), to_f32(b)); break;
    case RISCV_FLOAT_OPERATION_FLT_S:
      R(rd) = f32_lt(to_f32(a), to_f32(b)); break;
    case RISCV_FLOAT_OPERATION_FEQ_S:
      R(rd) = f32_eq(to_f32(a), to_f32(b)); break;
    default:
      return false;
  }
  fp_flags_accum();
  return true;
}

static inline bool exec_rvf_compare_d(
                                      RiscvFloatingOperation operation,
                                      int rd, uint64_t a,
                                      uint64_t b) {
  fp_flags_clear();
  switch (operation) {
    case RISCV_FLOAT_OPERATION_FLE_D:
      R(rd) = f64_le(to_f64(a), to_f64(b)); break;
    case RISCV_FLOAT_OPERATION_FLT_D:
      R(rd) = f64_lt(to_f64(a), to_f64(b)); break;
    case RISCV_FLOAT_OPERATION_FEQ_D:
      R(rd) = f64_eq(to_f64(a), to_f64(b)); break;
    default:
      return false;
  }
  fp_flags_accum();
  return true;
}

static inline word_t fclass64(uint64_t value) {
  uint64_t sign = value >> 63;
  uint64_t exp = (value >> 52) & 0x7ffu;
  uint64_t frac = value & 0x000fffffffffffffull;
  if (exp == 0x7ffu) {
    if (frac == 0) return sign ? 0x001 : 0x080;
    return (frac & 0x0008000000000000ull) ? 0x200 : 0x100;
  }
  if (exp == 0) {
    if (frac == 0) return sign ? 0x008 : 0x010;
    return sign ? 0x004 : 0x020;
  }
  return sign ? 0x002 : 0x040;
}

static inline bool exec_rvf_decoded(
    const RiscvFloatingInstruction *instruction) {
  if (!fp_state_enabled()) return false;

  const int rd = instruction->rd;
  const int rs1 = instruction->rs1;
  const int rs2 = instruction->rs2;
  const int rs3 = instruction->rs3;
  const uint32_t rm = instruction->rounding_mode;

  switch (instruction->operation) {
#ifdef CONFIG_RISCV_EXT_F
    case RISCV_FLOAT_OPERATION_FLW:
      return exec_rvf_flw(
          rd, R(rs1) + (word_t)instruction->immediate);
    case RISCV_FLOAT_OPERATION_FSW:
      return exec_rvf_fsw(
          R(rs1) + (word_t)instruction->immediate, rs2);
    case RISCV_FLOAT_OPERATION_FMADD_S:
    case RISCV_FLOAT_OPERATION_FMSUB_S:
    case RISCV_FLOAT_OPERATION_FNMSUB_S:
    case RISCV_FLOAT_OPERATION_FNMADD_S:
      return exec_rvf_fused_madd_s(
          instruction->operation, rm, rd,
          f32_unbox(F(rs1)), f32_unbox(F(rs2)), f32_unbox(F(rs3)));
    case RISCV_FLOAT_OPERATION_FADD_S:
    case RISCV_FLOAT_OPERATION_FSUB_S:
    case RISCV_FLOAT_OPERATION_FMUL_S:
    case RISCV_FLOAT_OPERATION_FDIV_S:
      return exec_rvf_arith_s(
          instruction->operation, rm, rd,
          f32_unbox(F(rs1)), f32_unbox(F(rs2)));
    case RISCV_FLOAT_OPERATION_FSQRT_S:
      return exec_rvf_sqrt_s(rm, rd, f32_unbox(F(rs1)));
    case RISCV_FLOAT_OPERATION_FSGNJ_S:
    case RISCV_FLOAT_OPERATION_FSGNJN_S:
    case RISCV_FLOAT_OPERATION_FSGNJX_S: {
      const uint32_t a = f32_unbox(F(rs1));
      const uint32_t b = f32_unbox(F(rs2));
      uint32_t sign = b & UINT32_C(0x80000000);
      if (instruction->operation == RISCV_FLOAT_OPERATION_FSGNJN_S) {
        sign ^= UINT32_C(0x80000000);
      } else if (instruction->operation == RISCV_FLOAT_OPERATION_FSGNJX_S) {
        sign = (a ^ b) & UINT32_C(0x80000000);
      }
      F(rd) = f32_box((a & UINT32_C(0x7fffffff)) | sign);
      fp_mark_dirty();
      return true;
    }
    case RISCV_FLOAT_OPERATION_FMIN_S:
    case RISCV_FLOAT_OPERATION_FMAX_S:
      F(rd) = f32_box(fminmax32(
          f32_unbox(F(rs1)), f32_unbox(F(rs2)),
          instruction->operation == RISCV_FLOAT_OPERATION_FMAX_S));
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_D)
    case RISCV_FLOAT_OPERATION_FCVT_S_D:
      return exec_rvf_fcvt_s_d(rm, rd, F(rs1));
#endif
    case RISCV_FLOAT_OPERATION_FLE_S:
    case RISCV_FLOAT_OPERATION_FLT_S:
    case RISCV_FLOAT_OPERATION_FEQ_S:
      return exec_rvf_compare_s(
          instruction->operation, rd,
          f32_unbox(F(rs1)), f32_unbox(F(rs2)));
    case RISCV_FLOAT_OPERATION_FCVT_W_S:
    case RISCV_FLOAT_OPERATION_FCVT_WU_S:
    case RISCV_FLOAT_OPERATION_FCVT_L_S:
    case RISCV_FLOAT_OPERATION_FCVT_LU_S:
      return exec_rvf_fcvt_int_s(
          instruction->operation, rm, rd, f32_unbox(F(rs1)));
    case RISCV_FLOAT_OPERATION_FCVT_S_W:
    case RISCV_FLOAT_OPERATION_FCVT_S_WU:
    case RISCV_FLOAT_OPERATION_FCVT_S_L:
    case RISCV_FLOAT_OPERATION_FCVT_S_LU:
      return exec_rvf_fcvt_from_int_s(
          instruction->operation, rm, rd, rs1);
    case RISCV_FLOAT_OPERATION_FMV_X_W:
      R(rd) = (word_t)(int32_t)(uint32_t)F(rs1);
      return true;
    case RISCV_FLOAT_OPERATION_FCLASS_S:
      R(rd) = fclass32(f32_unbox(F(rs1)));
      return true;
    case RISCV_FLOAT_OPERATION_FMV_W_X:
      F(rd) = f32_box((uint32_t)R(rs1));
      fp_mark_dirty();
      return true;
#endif

#ifdef CONFIG_RISCV_EXT_D
    case RISCV_FLOAT_OPERATION_FLD:
      return exec_rvf_fld(
          rd, R(rs1) + (word_t)instruction->immediate);
    case RISCV_FLOAT_OPERATION_FSD:
      return exec_rvf_fsd(
          R(rs1) + (word_t)instruction->immediate, rs2);
    case RISCV_FLOAT_OPERATION_FMADD_D:
    case RISCV_FLOAT_OPERATION_FMSUB_D:
    case RISCV_FLOAT_OPERATION_FNMSUB_D:
    case RISCV_FLOAT_OPERATION_FNMADD_D:
      return exec_rvf_fused_madd_d(
          instruction->operation, rm, rd, F(rs1), F(rs2), F(rs3));
    case RISCV_FLOAT_OPERATION_FADD_D:
    case RISCV_FLOAT_OPERATION_FSUB_D:
    case RISCV_FLOAT_OPERATION_FMUL_D:
    case RISCV_FLOAT_OPERATION_FDIV_D:
      return exec_rvf_arith_d(
          instruction->operation, rm, rd, F(rs1), F(rs2));
    case RISCV_FLOAT_OPERATION_FSQRT_D:
      return exec_rvf_sqrt_d(rm, rd, F(rs1));
    case RISCV_FLOAT_OPERATION_FSGNJ_D:
    case RISCV_FLOAT_OPERATION_FSGNJN_D:
    case RISCV_FLOAT_OPERATION_FSGNJX_D: {
      const uint64_t a = F(rs1);
      const uint64_t b = F(rs2);
      uint64_t sign = b & UINT64_C(0x8000000000000000);
      if (instruction->operation == RISCV_FLOAT_OPERATION_FSGNJN_D) {
        sign ^= UINT64_C(0x8000000000000000);
      } else if (instruction->operation == RISCV_FLOAT_OPERATION_FSGNJX_D) {
        sign = (a ^ b) & UINT64_C(0x8000000000000000);
      }
      F(rd) = (a & UINT64_C(0x7fffffffffffffff)) | sign;
      fp_mark_dirty();
      return true;
    }
    case RISCV_FLOAT_OPERATION_FMIN_D:
    case RISCV_FLOAT_OPERATION_FMAX_D:
      F(rd) = fminmax64(
          F(rs1), F(rs2),
          instruction->operation == RISCV_FLOAT_OPERATION_FMAX_D);
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_F)
    case RISCV_FLOAT_OPERATION_FCVT_D_S:
      return exec_rvf_fcvt_d_s(rm, rd, f32_unbox(F(rs1)));
#endif
    case RISCV_FLOAT_OPERATION_FLE_D:
    case RISCV_FLOAT_OPERATION_FLT_D:
    case RISCV_FLOAT_OPERATION_FEQ_D:
      return exec_rvf_compare_d(
          instruction->operation, rd, F(rs1), F(rs2));
    case RISCV_FLOAT_OPERATION_FCVT_W_D:
    case RISCV_FLOAT_OPERATION_FCVT_WU_D:
    case RISCV_FLOAT_OPERATION_FCVT_L_D:
    case RISCV_FLOAT_OPERATION_FCVT_LU_D:
      return exec_rvf_fcvt_int_d(
          instruction->operation, rm, rd, F(rs1));
    case RISCV_FLOAT_OPERATION_FCVT_D_W:
    case RISCV_FLOAT_OPERATION_FCVT_D_WU:
    case RISCV_FLOAT_OPERATION_FCVT_D_L:
    case RISCV_FLOAT_OPERATION_FCVT_D_LU:
      return exec_rvf_fcvt_from_int_d(
          instruction->operation, rm, rd, rs1);
    case RISCV_FLOAT_OPERATION_FMV_X_D:
      R(rd) = (word_t)F(rs1);
      return true;
    case RISCV_FLOAT_OPERATION_FCLASS_D:
      R(rd) = fclass64(F(rs1));
      return true;
    case RISCV_FLOAT_OPERATION_FMV_D_X:
      F(rd) = (uint64_t)R(rs1);
      fp_mark_dirty();
      return true;
#endif
    default:
      return false;
  }
}

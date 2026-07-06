/* RV64 F/D 浮点 load/store、算术、转换、比较和分类。 */

/* NEMU RV64 F/D: Berkeley SoftFloat (RISC-V specialization) 金标准实现。
 * 2026-07-06 从 host-float 升级为 proper IEEE-754(与 spike 同源 softfloat)。
 * ★SoftFloat 的 roundingMode(0-4) 与 RISC-V frm 位相同; exceptionFlags 位
 *  (inexact=1/underflow=2/overflow=4/infinite=8/invalid=16) 与 RISC-V fflags
 *  (NX/UF/OF/DZ/NV) 完全相同(均按 RISC-V 设计), 故 glue 极简: 直接或入。 */
#include "softfloat.h"

static inline bool fp_state_enabled(void) {
  return (cpu.csr.mstatus & MSTATUS_FS_MASK) != 0;
}

static inline void fp_mark_dirty(void) {
  cpu.csr.mstatus = (cpu.csr.mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY;
}

static inline void fp_raise_invalid(void) {
  cpu.csr.fflags |= FFLAGS_NV;
  fp_mark_dirty();
}

/* SoftFloat glue: 位模式 ↔ float{32,64}_t; 按 frm 设 roundingMode; 异常 flag 累积到 fflags。 */
static inline float32_t to_f32(uint32_t v) { float32_t x = { .v = v }; return x; }
static inline float64_t to_f64(uint64_t v) { float64_t x = { .v = v }; return x; }
static inline uint32_t neg_f32_bits(uint32_t v) { return v ^ 0x80000000u; }
static inline uint64_t neg_f64_bits(uint64_t v) { return v ^ 0x8000000000000000ull; }

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

static bool fp_load_trace_is_enabled = false;
static word_t fp_load_trace_pc_start = 0;
static word_t fp_load_trace_pc_end = 0;
static bool fp_load_trace_has_addr_range = false;
static word_t fp_load_trace_addr_start = 0;
static word_t fp_load_trace_addr_end = 0;
static uint64_t fp_load_trace_max = 4096;
static uint64_t fp_load_trace_count = 0;
static bool fp_load_trace_user_only = true;

static bool fp_load_trace_env_enabled_default_true(const char *name) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  return !(env != NULL && env[0] != '\0' && strcmp(env, "0") == 0);
#else
  (void)name;
  return true;
#endif
}

static bool fp_load_trace_env_u64(const char *name, uint64_t *value) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  if (env == NULL || env[0] == '\0') {
    return false;
  }
  errno = 0;
  char *end = NULL;
  uint64_t parsed = strtoull(env, &end, 0);
  Assert(errno == 0 && end != env && *end == '\0',
      "invalid %s=%s, expect an integer", name, env);
  *value = parsed;
  return true;
#else
  (void)name;
  (void)value;
  return false;
#endif
}

__attribute__((constructor))
static void fp_load_trace_config_init(void) {
#ifndef CONFIG_TARGET_AM
  uint64_t pc_start = 0;
  uint64_t pc_end = 0;
  bool has_pc_start = fp_load_trace_env_u64("NEMU_FP_LOAD_TRACE_PC_START", &pc_start);
  bool has_pc_end = fp_load_trace_env_u64("NEMU_FP_LOAD_TRACE_PC_END", &pc_end);
  uint64_t addr_start = 0;
  uint64_t addr_end = 0;
  bool has_addr_start = fp_load_trace_env_u64("NEMU_FP_LOAD_TRACE_ADDR_START", &addr_start);
  bool has_addr_end = fp_load_trace_env_u64("NEMU_FP_LOAD_TRACE_ADDR_END", &addr_end);
  const char *trace_env = getenv("NEMU_FP_LOAD_TRACE");
  bool requested = trace_env != NULL && trace_env[0] != '\0' &&
    strcmp(trace_env, "0") != 0;
  if (requested || has_pc_start || has_pc_end || has_addr_start || has_addr_end) {
    Assert(has_pc_start && has_pc_end,
        "NEMU_FP_LOAD_TRACE requires PC_START and PC_END");
    Assert(pc_end >= pc_start,
        "NEMU_FP_LOAD_TRACE PC range end must be >= start");
    if (has_addr_start || has_addr_end) {
      Assert(has_addr_start && has_addr_end,
          "NEMU_FP_LOAD_TRACE address range requires ADDR_START and ADDR_END");
      Assert(addr_end >= addr_start,
          "NEMU_FP_LOAD_TRACE address range end must be >= start");
      fp_load_trace_addr_start = (word_t)addr_start;
      fp_load_trace_addr_end = (word_t)addr_end;
      fp_load_trace_has_addr_range = true;
    }
    fp_load_trace_env_u64("NEMU_FP_LOAD_TRACE_MAX", &fp_load_trace_max);
    fp_load_trace_user_only =
      fp_load_trace_env_enabled_default_true("NEMU_FP_LOAD_TRACE_USER_ONLY");
    fp_load_trace_pc_start = (word_t)pc_start;
    fp_load_trace_pc_end = (word_t)pc_end;
    fp_load_trace_count = 0;
    fp_load_trace_is_enabled = true;
    Log("fp-load-trace armed pc_start=" FMT_WORD " pc_end=" FMT_WORD
        " addr_start=" FMT_WORD " addr_end=" FMT_WORD
        " addr_filter=%d max=%" PRIu64 " user_only=%d",
        fp_load_trace_pc_start, fp_load_trace_pc_end,
        fp_load_trace_addr_start, fp_load_trace_addr_end,
        fp_load_trace_has_addr_range ? 1 : 0,
        fp_load_trace_max, fp_load_trace_user_only ? 1 : 0);
  }
#endif
}

static inline void fp_load_trace_after_load(uint32_t funct3, int rd,
    word_t addr, uint32_t len, uint64_t raw) {
  if (likely(!fp_load_trace_is_enabled)) return;
  if (fp_load_trace_max != 0 && fp_load_trace_count >= fp_load_trace_max) {
    return;
  }
  if (fp_load_trace_user_only && cpu.priv != PRIV_U) {
    return;
  }
  if (cpu.pc < fp_load_trace_pc_start || cpu.pc > fp_load_trace_pc_end) {
    return;
  }
  if (fp_load_trace_has_addr_range &&
      (addr < fp_load_trace_addr_start || addr > fp_load_trace_addr_end)) {
    return;
  }
  fp_load_trace_count++;
  paddr_t paddr = 0;
  bool has_paddr = vaddr_last_read_paddr((vaddr_t)addr, (int)len, &paddr);
  // 记录本次 FP load 已经取回的 raw 数据，避免 trace 自己再次访问 guest 内存。
  Log("fp-load-trace count=%" PRIu64 " pc=" FMT_WORD
      " funct3=0x%x rd=%d addr=" FMT_WORD " len=%u"
      " paddr=0x%016" PRIx64 " has_paddr=%d"
      " raw=0x%016" PRIx64 " f64=%a priv=%u satp=" FMT_WORD,
      fp_load_trace_count, cpu.pc, funct3, rd, addr, len,
      has_paddr ? (uint64_t)paddr : UINT64_MAX, has_paddr ? 1 : 0,
      raw,
      len == 8 ? (union { uint64_t u; double d; }){ .u = raw }.d : 0.0,
      cpu.priv, cpu.csr.satp);
}

static inline bool exec_rvf_load(uint32_t funct3, int rd, word_t addr) {
  if (!fp_state_enabled()) return false;
  switch (funct3) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x2: { // flw
      word_t val = Mr(addr, 4);
      if (vaddr_has_fault()) return true;
      fp_load_trace_after_load(funct3, rd, addr, 4, (uint32_t)val);
      F(rd) = 0xffffffff00000000ull | (uint32_t)val;
      fp_mark_dirty();
      return true;
    }
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x3: { // fld
      word_t val = Mr(addr, 8);
      if (vaddr_has_fault()) return true;
      fp_load_trace_after_load(funct3, rd, addr, 8, val);
      F(rd) = val;
      fp_mark_dirty();
      return true;
    }
#endif
    default:
      return false;
  }
}
static inline bool exec_rvf_store(uint32_t funct3, word_t addr, int rs2) {
  if (!fp_state_enabled()) return false;
  switch (funct3) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x2: // fsw
      Mw(addr, 4, (uint32_t)F(rs2));
      return true;
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x3: // fsd
      Mw(addr, 8, F(rs2));
      return true;
#endif
    default:
      return false;
  }
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
  return ((value >> 32) == 0xffffffffull) ? (uint32_t)value : 0x7fc00000u;
}

/* host-float 转换 helper 已删: SoftFloat 直接在位模式(float{32,64}_t)上运算, 结果已 canonical。 */

static inline bool fp_rounding_mode_valid(uint32_t rm) {
  uint32_t resolved = rm == 0x7 ? cpu.csr.frm : rm;
  return resolved <= 0x4;
}

static inline bool exec_rvf_arith_s(uint32_t funct7, uint32_t rm, int rd,
                                    uint32_t a, uint32_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float32_t af = to_f32(a), bf = to_f32(b), result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (funct7) {
    case 0x00: result = f32_add(af, bf); break;                 // fadd.s
    case 0x04: result = f32_sub(af, bf); break;                 // fsub.s
    case 0x08: result = f32_mul(af, bf); break;                 // fmul.s
    case 0x0c: result = f32_div(af, bf); break;                 // fdiv.s
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = 0xffffffff00000000ull | result.v;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_arith_d(uint32_t funct7, uint32_t rm, int rd,
                                    uint64_t a, uint64_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float64_t af = to_f64(a), bf = to_f64(b), result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (funct7) {
    case 0x01: result = f64_add(af, bf); break;                 // fadd.d
    case 0x05: result = f64_sub(af, bf); break;                 // fsub.d
    case 0x09: result = f64_mul(af, bf); break;                 // fmul.d
    case 0x0d: result = f64_div(af, bf); break;                 // fdiv.d
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
  F(rd) = 0xffffffff00000000ull | result.v;
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

static inline bool exec_rvf_fused_madd_s(uint32_t opcode, uint32_t rm, int rd,
                                         uint32_t a, uint32_t b, uint32_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  uint32_t na = neg_f32_bits(a), nc = neg_f32_bits(c);
  float32_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (opcode) {                                             // 符号位 XOR 实现 ±(a*b)±c(与 spike 同)
    case OPC_MADD:  result = f32_mulAdd(to_f32(a),  to_f32(b), to_f32(c));  break; // fmadd.s  = a*b + c
    case OPC_MSUB:  result = f32_mulAdd(to_f32(a),  to_f32(b), to_f32(nc)); break; // fmsub.s  = a*b - c
    case OPC_NMSUB: result = f32_mulAdd(to_f32(na), to_f32(b), to_f32(c));  break; // fnmsub.s = -a*b + c
    case OPC_NMADD: result = f32_mulAdd(to_f32(na), to_f32(b), to_f32(nc)); break; // fnmadd.s = -a*b - c
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = 0xffffffff00000000ull | result.v;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_d(uint32_t opcode, uint32_t rm, int rd,
                                         uint64_t a, uint64_t b, uint64_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  uint64_t na = neg_f64_bits(a), nc = neg_f64_bits(c);
  float64_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (opcode) {
    case OPC_MADD:  result = f64_mulAdd(to_f64(a),  to_f64(b), to_f64(c));  break; // fmadd.d
    case OPC_MSUB:  result = f64_mulAdd(to_f64(a),  to_f64(b), to_f64(nc)); break; // fmsub.d
    case OPC_NMSUB: result = f64_mulAdd(to_f64(na), to_f64(b), to_f64(c));  break; // fnmsub.d
    case OPC_NMADD: result = f64_mulAdd(to_f64(na), to_f64(b), to_f64(nc)); break; // fnmadd.d
    default:
      return false;
  }
  fp_flags_accum();
  F(rd) = result.v;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd(uint32_t opcode, uint32_t inst, int rd,
                                       int rs1, int rs2) {
  if (!fp_state_enabled()) return false;
  uint32_t fmt = FUNCT2(inst);
#if defined(CONFIG_RISCV_EXT_F) || defined(CONFIG_RISCV_EXT_D)
  uint32_t rm = FUNCT3(inst);
  int rs3 = RS3(inst);
#endif
  switch (fmt) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x0:
      return exec_rvf_fused_madd_s(opcode, rm, rd, f32_unbox(F(rs1)),
                                   f32_unbox(F(rs2)), f32_unbox(F(rs3)));
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x1:
      return exec_rvf_fused_madd_d(opcode, rm, rd, F(rs1), F(rs2), F(rs3));
#endif
    default:
      return false;
  }
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
static inline word_t sf_f32_to_int(float32_t x, int rs2, uint_fast8_t r) {
  switch (rs2) {
    case 0:  return (word_t)(int64_t)(int32_t)f32_to_i32 (x, r, true);           // fcvt.w.s
    case 1:  return (word_t)(int64_t)(int32_t)(uint32_t)f32_to_ui32(x, r, true); // fcvt.wu.s
    case 2:  return (word_t)(int64_t)f32_to_i64 (x, r, true);                    // fcvt.l.s
    default: return (word_t)(uint64_t)f32_to_ui64(x, r, true);                   // fcvt.lu.s
  }
}
static inline word_t sf_f64_to_int(float64_t x, int rs2, uint_fast8_t r) {
  switch (rs2) {
    case 0:  return (word_t)(int64_t)(int32_t)f64_to_i32 (x, r, true);           // fcvt.w.d
    case 1:  return (word_t)(int64_t)(int32_t)(uint32_t)f64_to_ui32(x, r, true); // fcvt.wu.d
    case 2:  return (word_t)(int64_t)f64_to_i64 (x, r, true);                    // fcvt.l.d
    default: return (word_t)(uint64_t)f64_to_ui64(x, r, true);                   // fcvt.lu.d
  }
}

static inline bool exec_rvf_fcvt_int_s(uint32_t rm, int rd, int rs2,
                                       uint32_t value) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  uint_fast8_t r = (uint_fast8_t)((rm == 0x7) ? cpu.csr.frm : rm);
  fp_flags_clear();
  R(rd) = sf_f32_to_int(to_f32(value), rs2, r);
  fp_flags_accum();
  return true;
}

static inline bool exec_rvf_fcvt_int_d(uint32_t rm, int rd, int rs2,
                                       uint64_t value) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  uint_fast8_t r = (uint_fast8_t)((rm == 0x7) ? cpu.csr.frm : rm);
  fp_flags_clear();
  R(rd) = sf_f64_to_int(to_f64(value), rs2, r);
  fp_flags_accum();
  return true;
}

static inline bool exec_rvf_fcvt_from_int_s(uint32_t rm, int rd, int rs1,
                                            int rs2) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  float32_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (rs2) {
    case 0:  result = i32_to_f32 ((int32_t)R(rs1));  break;     // fcvt.s.w
    case 1:  result = ui32_to_f32((uint32_t)R(rs1)); break;     // fcvt.s.wu
    case 2:  result = i64_to_f32 ((int64_t)R(rs1));  break;     // fcvt.s.l
    default: result = ui64_to_f32((uint64_t)R(rs1)); break;     // fcvt.s.lu
  }
  fp_flags_accum();
  F(rd) = 0xffffffff00000000ull | result.v;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_from_int_d(uint32_t rm, int rd, int rs1,
                                            int rs2) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  float64_t result;
  sf_set_rm(rm);
  fp_flags_clear();
  switch (rs2) {
    case 0:  result = i32_to_f64 ((int32_t)R(rs1));  break;     // fcvt.d.w  (精确)
    case 1:  result = ui32_to_f64((uint32_t)R(rs1)); break;     // fcvt.d.wu (精确)
    case 2:  result = i64_to_f64 ((int64_t)R(rs1));  break;     // fcvt.d.l
    default: result = ui64_to_f64((uint64_t)R(rs1)); break;     // fcvt.d.lu
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
  F(rd) = 0xffffffff00000000ull | result.v;
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

static inline bool exec_rvf_compare_s(uint32_t funct3, int rd, uint32_t a,
                                      uint32_t b) {
  // f32_le/lt 是 signaling(任意 NaN→NV、返 0), f32_eq 是 quiet(仅 sNaN→NV) —— 正合 RISC-V。
  fp_flags_clear();
  switch (funct3) {
    case 0x0: R(rd) = f32_le(to_f32(a), to_f32(b)); break;    // fle.s
    case 0x1: R(rd) = f32_lt(to_f32(a), to_f32(b)); break;    // flt.s
    case 0x2: R(rd) = f32_eq(to_f32(a), to_f32(b)); break;    // feq.s
    default:
      return false;
  }
  fp_flags_accum();
  return true;
}

static inline bool exec_rvf_compare_d(uint32_t funct3, int rd, uint64_t a,
                                      uint64_t b) {
  fp_flags_clear();
  switch (funct3) {
    case 0x0: R(rd) = f64_le(to_f64(a), to_f64(b)); break;    // fle.d
    case 0x1: R(rd) = f64_lt(to_f64(a), to_f64(b)); break;    // flt.d
    case 0x2: R(rd) = f64_eq(to_f64(a), to_f64(b)); break;    // feq.d
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

static inline bool exec_rvf_op(uint32_t inst, int rd, int rs1, int rs2) {
  if (!fp_state_enabled()) return false;
  uint32_t funct7 = FUNCT7(inst);
#if defined(CONFIG_RISCV_EXT_F) || defined(CONFIG_RISCV_EXT_D)
  uint32_t funct3 = FUNCT3(inst);
#endif

  switch (funct7) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x00:                                                   // fadd.s
    case 0x04:                                                   // fsub.s
    case 0x08:                                                   // fmul.s
    case 0x0c:                                                   // fdiv.s
      return exec_rvf_arith_s(funct7, funct3, rd, f32_unbox(F(rs1)), f32_unbox(F(rs2)));
    case 0x2c:                                                   // fsqrt.s
      return rs2 == 0 ? exec_rvf_sqrt_s(funct3, rd, f32_unbox(F(rs1))) : false;
    case 0x10: {                                                 // fsgnj.s/fsgnjn.s/fsgnjx.s
      uint32_t a = f32_unbox(F(rs1));
      uint32_t b = f32_unbox(F(rs2));
      uint32_t sign = b & 0x80000000u;
      if (funct3 == 0x1) sign ^= 0x80000000u;
      else if (funct3 == 0x2) sign = (a ^ b) & 0x80000000u;
      else if (funct3 != 0x0) return false;
      F(rd) = 0xffffffff00000000ull | (a & 0x7fffffffu) | sign;
      fp_mark_dirty();
      return true;
    }
    case 0x14:                                                   // fmin.s/fmax.s
      if (funct3 > 0x1) return false;
      F(rd) = 0xffffffff00000000ull |
              fminmax32(f32_unbox(F(rs1)), f32_unbox(F(rs2)), funct3 == 0x1);
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_D)
    case 0x20:                                                   // fcvt.s.d
      return rs2 == 1 ? exec_rvf_fcvt_s_d(funct3, rd, F(rs1)) : false;
#endif
    case 0x50:                                                   // fle.s/flt.s/feq.s
      return exec_rvf_compare_s(funct3, rd, f32_unbox(F(rs1)), f32_unbox(F(rs2)));
    case 0x60:                                                   // fcvt.w/wu/l/lu.s
      return exec_rvf_fcvt_int_s(funct3, rd, rs2, f32_unbox(F(rs1)));
    case 0x68:                                                   // fcvt.s.w/wu/l/lu
      return exec_rvf_fcvt_from_int_s(funct3, rd, rs1, rs2);
    case 0x70:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.x.w
        R(rd) = (word_t)SEXT((uint32_t)F(rs1), 32);
        return true;
      }
      if (rs2 == 0 && funct3 == 0x1) {                         // fclass.s
        R(rd) = fclass32(f32_unbox(F(rs1)));
        return true;
      }
      return false;
    case 0x78:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.w.x
        F(rd) = 0xffffffff00000000ull | (uint32_t)R(rs1);
        fp_mark_dirty();
        return true;
      }
      return false;
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x01:                                                   // fadd.d
    case 0x05:                                                   // fsub.d
    case 0x09:                                                   // fmul.d
    case 0x0d:                                                   // fdiv.d
      return exec_rvf_arith_d(funct7, funct3, rd, F(rs1), F(rs2));
    case 0x2d:                                                   // fsqrt.d
      return rs2 == 0 ? exec_rvf_sqrt_d(funct3, rd, F(rs1)) : false;
    case 0x11: {                                                 // fsgnj.d/fsgnjn.d/fsgnjx.d
      uint64_t a = F(rs1);
      uint64_t b = F(rs2);
      uint64_t sign = b & 0x8000000000000000ull;
      if (funct3 == 0x1) sign ^= 0x8000000000000000ull;
      else if (funct3 == 0x2) sign = (a ^ b) & 0x8000000000000000ull;
      else if (funct3 != 0x0) return false;
      F(rd) = (a & 0x7fffffffffffffffull) | sign;
      fp_mark_dirty();
      return true;
    }
    case 0x15:                                                   // fmin.d/fmax.d
      if (funct3 > 0x1) return false;
      F(rd) = fminmax64(F(rs1), F(rs2), funct3 == 0x1);
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_F)
    case 0x21:                                                   // fcvt.d.s
      return rs2 == 0 ? exec_rvf_fcvt_d_s(funct3, rd, f32_unbox(F(rs1))) : false;
#endif
    case 0x51:                                                   // fle.d/flt.d/feq.d
      return exec_rvf_compare_d(funct3, rd, F(rs1), F(rs2));
    case 0x61:                                                   // fcvt.w/wu/l/lu.d
      return exec_rvf_fcvt_int_d(funct3, rd, rs2, F(rs1));
    case 0x69:                                                   // fcvt.d.w/wu/l/lu
      return exec_rvf_fcvt_from_int_d(funct3, rd, rs1, rs2);
    case 0x71:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.x.d
        R(rd) = F(rs1);
        return true;
      }
      if (rs2 == 0 && funct3 == 0x1) {                         // fclass.d
        R(rd) = fclass64(F(rs1));
        return true;
      }
      return false;
    case 0x79:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.d.x
        F(rd) = R(rs1);
        fp_mark_dirty();
        return true;
      }
      return false;
#endif
    default:
      return false;
  }
}

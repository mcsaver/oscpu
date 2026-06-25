/* RV64 F/D 浮点 load/store、算术、转换、比较和分类。 */

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

static inline float f32_to_host(uint32_t value) {
  union {
    uint32_t u;
    float f;
  } v = { .u = value };
  return v.f;
}

static inline double f64_to_host(uint64_t value) {
  union {
    uint64_t u;
    double f;
  } v = { .u = value };
  return v.f;
}

static inline uint32_t f32_from_host(float value) {
  union {
    uint32_t u;
    float f;
  } v = { .f = value };
  return v.u;
}

static inline uint64_t f64_from_host(double value) {
  union {
    uint64_t u;
    double f;
  } v = { .f = value };
  return v.u;
}

static inline bool fp_rounding_mode_valid(uint32_t rm) {
  uint32_t resolved = rm == 0x7 ? cpu.csr.frm : rm;
  return resolved <= 0x4;
}

static inline bool exec_rvf_arith_s(uint32_t funct7, uint32_t rm, int rd,
                                    uint32_t a, uint32_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float af = f32_to_host(a);
  float bf = f32_to_host(b);
  float result = 0.0f;
  switch (funct7) {
    case 0x00: result = af + bf; break;                         // fadd.s
    case 0x04: result = af - bf; break;                         // fsub.s
    case 0x08: result = af * bf; break;                         // fmul.s
    case 0x0c: result = af / bf; break;                         // fdiv.s
    default:
      return false;
  }
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_arith_d(uint32_t funct7, uint32_t rm, int rd,
                                    uint64_t a, uint64_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  double af = f64_to_host(a);
  double bf = f64_to_host(b);
  double result = 0.0;
  switch (funct7) {
    case 0x01: result = af + bf; break;                         // fadd.d
    case 0x05: result = af - bf; break;                         // fsub.d
    case 0x09: result = af * bf; break;                         // fmul.d
    case 0x0d: result = af / bf; break;                         // fdiv.d
    default:
      return false;
  }
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool f32_is_negative_nonzero(uint32_t value) {
  return (value & 0x80000000u) != 0 && (value & 0x7fffffffu) != 0 &&
         !f32_is_nan(value);
}

static inline bool f64_is_negative_nonzero(uint64_t value) {
  return (value & 0x8000000000000000ull) != 0 &&
         (value & 0x7fffffffffffffffull) != 0 && !f64_is_nan(value);
}

static inline bool exec_rvf_sqrt_s(uint32_t rm, int rd, uint32_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  // full Ubuntu/Python 会触发 FSQRT；负有限数按 RISC-V 规则置 invalid 并返回 canonical NaN。
  if (f32_is_snan(value) || f32_is_negative_nonzero(value)) {
    fp_raise_invalid();
  }
  uint32_t result = f32_is_negative_nonzero(value)
                      ? 0x7fc00000u
                      : f32_from_host(__builtin_sqrtf(f32_to_host(value)));
  F(rd) = 0xffffffff00000000ull | result;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_sqrt_d(uint32_t rm, int rd, uint64_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  // 与现有 FP 算术一致先闭合功能语义；完整 rounding/fflags 仍由后续 FP signoff 处理。
  if (f64_is_snan(value) || f64_is_negative_nonzero(value)) {
    fp_raise_invalid();
  }
  uint64_t result = f64_is_negative_nonzero(value)
                      ? 0x7ff8000000000000ull
                      : f64_from_host(__builtin_sqrt(f64_to_host(value)));
  F(rd) = result;
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_s(uint32_t opcode, uint32_t rm, int rd,
                                         uint32_t a, uint32_t b, uint32_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float af = f32_to_host(a);
  float bf = f32_to_host(b);
  float cf = f32_to_host(c);
  float result = 0.0f;
  switch (opcode) {
    case OPC_MADD:  result = __builtin_fmaf( af, bf,  cf); break; // fmadd.s
    case OPC_MSUB:  result = __builtin_fmaf( af, bf, -cf); break; // fmsub.s
    case OPC_NMSUB: result = __builtin_fmaf(-af, bf,  cf); break; // fnmsub.s
    case OPC_NMADD: result = __builtin_fmaf(-af, bf, -cf); break; // fnmadd.s
    default:
      return false;
  }
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_d(uint32_t opcode, uint32_t rm, int rd,
                                         uint64_t a, uint64_t b, uint64_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  double af = f64_to_host(a);
  double bf = f64_to_host(b);
  double cf = f64_to_host(c);
  double result = 0.0;
  switch (opcode) {
    case OPC_MADD:  result = __builtin_fma( af, bf,  cf); break;  // fmadd.d
    case OPC_MSUB:  result = __builtin_fma( af, bf, -cf); break;  // fmsub.d
    case OPC_NMSUB: result = __builtin_fma(-af, bf,  cf); break;  // fnmsub.d
    case OPC_NMADD: result = __builtin_fma(-af, bf, -cf); break;  // fnmadd.d
    default:
      return false;
  }
  F(rd) = f64_from_host(result);
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
      return exec_rvf_fused_madd_s(opcode, rm, rd, (uint32_t)F(rs1),
                                   (uint32_t)F(rs2), (uint32_t)F(rs3));
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
  float af = f32_to_host(a);
  float bf = f32_to_host(b);
  if (af == bf && ((a ^ b) & 0x80000000u) != 0) {
    return is_max ? 0x00000000u : 0x80000000u;
  }
  if (is_max) return af < bf ? b : a;
  return af < bf ? a : b;
}

static inline uint64_t fminmax64(uint64_t a, uint64_t b, bool is_max) {
  bool an = f64_is_nan(a);
  bool bn = f64_is_nan(b);
  if (f64_is_snan(a) || f64_is_snan(b)) fp_raise_invalid();
  if (an && bn) return 0x7ff8000000000000ull;
  if (an) return b;
  if (bn) return a;
  double af = f64_to_host(a);
  double bf = f64_to_host(b);
  if (af == bf && ((a ^ b) & 0x8000000000000000ull) != 0) {
    return is_max ? 0x0000000000000000ull : 0x8000000000000000ull;
  }
  if (is_max) return af < bf ? b : a;
  return af < bf ? a : b;
}

static inline word_t fcvt_to_int(double value, uint32_t rs2) {
  if (value != value) {
    fp_raise_invalid();
    return rs2 == 0 || rs2 == 2 ? (word_t)0x7fffffffffffffffull : ~(word_t)0;
  }

  switch (rs2) {
    case 0:                                                     // w
      if (value < -2147483648.0) { fp_raise_invalid(); return (word_t)(int64_t)(int32_t)0x80000000u; }
      if (value > 2147483647.0) { fp_raise_invalid(); return 0x7fffffffu; }
      return (word_t)(int64_t)(int32_t)value;
    case 1:                                                     // wu
      if (value < 0.0) { fp_raise_invalid(); return 0; }
      if (value > 4294967295.0) { fp_raise_invalid(); return 0xffffffffu; }
      return (word_t)(uint32_t)value;
    case 2:                                                     // l
      if (value < -9223372036854775808.0) {
        fp_raise_invalid();
        return (word_t)0x8000000000000000ull;
      }
      if (value >= 9223372036854775808.0) {
        fp_raise_invalid();
        return (word_t)0x7fffffffffffffffull;
      }
      return (word_t)(int64_t)value;
    case 3:                                                     // lu
      if (value < 0.0) { fp_raise_invalid(); return 0; }
      if (value >= 18446744073709551616.0) {
        fp_raise_invalid();
        return ~(word_t)0;
      }
      return (word_t)(uint64_t)value;
    default:
      return 0;
  }
}

static inline bool exec_rvf_fcvt_int_s(uint32_t rm, int rd, int rs2,
                                       uint32_t value) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  R(rd) = fcvt_to_int((double)f32_to_host(value), rs2);
  return true;
}

static inline bool exec_rvf_fcvt_int_d(uint32_t rm, int rd, int rs2,
                                       uint64_t value) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  R(rd) = fcvt_to_int(f64_to_host(value), rs2);
  return true;
}

static inline bool exec_rvf_fcvt_from_int_s(uint32_t rm, int rd, int rs1,
                                            int rs2) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  float result = 0.0f;
  switch (rs2) {
    case 0: result = (float)(int32_t)R(rs1); break;             // fcvt.s.w
    case 1: result = (float)(uint32_t)R(rs1); break;            // fcvt.s.wu
    case 2: result = (float)(int64_t)R(rs1); break;             // fcvt.s.l
    case 3: result = (float)(uint64_t)R(rs1); break;            // fcvt.s.lu
  }
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_from_int_d(uint32_t rm, int rd, int rs1,
                                            int rs2) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  double result = 0.0;
  switch (rs2) {
    case 0: result = (double)(int32_t)R(rs1); break;            // fcvt.d.w
    case 1: result = (double)(uint32_t)R(rs1); break;           // fcvt.d.wu
    case 2: result = (double)(int64_t)R(rs1); break;            // fcvt.d.l
    case 3: result = (double)(uint64_t)R(rs1); break;           // fcvt.d.lu
  }
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}

#if defined(CONFIG_RISCV_EXT_F) && defined(CONFIG_RISCV_EXT_D)
static inline bool exec_rvf_fcvt_s_d(uint32_t rm, int rd, uint64_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float result = (float)f64_to_host(value);
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_d_s(uint32_t rm, int rd, uint32_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  double result = (double)f32_to_host(value);
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}
#endif

static inline bool exec_rvf_compare_s(uint32_t funct3, int rd, uint32_t a,
                                      uint32_t b) {
  bool nan = f32_is_nan(a) || f32_is_nan(b);
  switch (funct3) {
    case 0x0:                                                 // fle.s
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f32_to_host(a) <= f32_to_host(b);
      return true;
    case 0x1:                                                 // flt.s
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f32_to_host(a) < f32_to_host(b);
      return true;
    case 0x2:                                                 // feq.s
      if (f32_is_snan(a) || f32_is_snan(b)) fp_raise_invalid();
      R(rd) = nan ? 0 : (f32_to_host(a) == f32_to_host(b));
      return true;
    default:
      return false;
  }
}

static inline bool exec_rvf_compare_d(uint32_t funct3, int rd, uint64_t a,
                                      uint64_t b) {
  bool nan = f64_is_nan(a) || f64_is_nan(b);
  switch (funct3) {
    case 0x0:                                                 // fle.d
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f64_to_host(a) <= f64_to_host(b);
      return true;
    case 0x1:                                                 // flt.d
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f64_to_host(a) < f64_to_host(b);
      return true;
    case 0x2:                                                 // feq.d
      if (f64_is_snan(a) || f64_is_snan(b)) fp_raise_invalid();
      R(rd) = nan ? 0 : (f64_to_host(a) == f64_to_host(b));
      return true;
    default:
      return false;
  }
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
      return exec_rvf_arith_s(funct7, funct3, rd, (uint32_t)F(rs1), (uint32_t)F(rs2));
    case 0x2c:                                                   // fsqrt.s
      return rs2 == 0 ? exec_rvf_sqrt_s(funct3, rd, (uint32_t)F(rs1)) : false;
    case 0x10: {                                                 // fsgnj.s/fsgnjn.s/fsgnjx.s
      uint32_t a = (uint32_t)F(rs1);
      uint32_t b = (uint32_t)F(rs2);
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
              fminmax32((uint32_t)F(rs1), (uint32_t)F(rs2), funct3 == 0x1);
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_D)
    case 0x20:                                                   // fcvt.s.d
      return rs2 == 1 ? exec_rvf_fcvt_s_d(funct3, rd, F(rs1)) : false;
#endif
    case 0x50:                                                   // fle.s/flt.s/feq.s
      return exec_rvf_compare_s(funct3, rd, (uint32_t)F(rs1), (uint32_t)F(rs2));
    case 0x60:                                                   // fcvt.w/wu/l/lu.s
      return exec_rvf_fcvt_int_s(funct3, rd, rs2, (uint32_t)F(rs1));
    case 0x68:                                                   // fcvt.s.w/wu/l/lu
      return exec_rvf_fcvt_from_int_s(funct3, rd, rs1, rs2);
    case 0x70:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.x.w
        R(rd) = (word_t)SEXT((uint32_t)F(rs1), 32);
        return true;
      }
      if (rs2 == 1 && funct3 == 0x1) {                         // fclass.s
        R(rd) = fclass32((uint32_t)F(rs1));
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
      return rs2 == 0 ? exec_rvf_fcvt_d_s(funct3, rd, (uint32_t)F(rs1)) : false;
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
      if (rs2 == 1 && funct3 == 0x1) {                         // fclass.d
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

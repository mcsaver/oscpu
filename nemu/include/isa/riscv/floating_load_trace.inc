/*
 * Optional diagnostics for completed floating-point loads.
 *
 * This file deliberately observes the value already returned by the guest
 * access.  A trace must never issue a second load or change architectural
 * fault/commit ordering.
 */

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
  bool has_pc_start = fp_load_trace_env_u64(
      "NEMU_FP_LOAD_TRACE_PC_START", &pc_start);
  bool has_pc_end = fp_load_trace_env_u64(
      "NEMU_FP_LOAD_TRACE_PC_END", &pc_end);
  uint64_t addr_start = 0;
  uint64_t addr_end = 0;
  bool has_addr_start = fp_load_trace_env_u64(
      "NEMU_FP_LOAD_TRACE_ADDR_START", &addr_start);
  bool has_addr_end = fp_load_trace_env_u64(
      "NEMU_FP_LOAD_TRACE_ADDR_END", &addr_end);
  const char *trace_env = getenv("NEMU_FP_LOAD_TRACE");
  bool requested = trace_env != NULL && trace_env[0] != '\0' &&
    strcmp(trace_env, "0") != 0;
  if (requested || has_pc_start || has_pc_end ||
      has_addr_start || has_addr_end) {
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

static inline void fp_load_trace_after_load(
    const char *mnemonic, int rd, word_t address,
    uint32_t width_bytes, uint64_t raw_value) {
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
      (address < fp_load_trace_addr_start ||
       address > fp_load_trace_addr_end)) {
    return;
  }

  fp_load_trace_count++;
  paddr_t physical_address = 0;
  bool has_physical_address = vaddr_last_read_paddr(
      (vaddr_t)address, (int)width_bytes, &physical_address);
  Log("fp-load-trace count=%" PRIu64 " pc=" FMT_WORD
      " mnemonic=%s rd=%d addr=" FMT_WORD " width_bytes=%u"
      " paddr=0x%016" PRIx64 " has_paddr=%d"
      " raw=0x%016" PRIx64 " f64=%a priv=%u satp=" FMT_WORD,
      fp_load_trace_count, cpu.pc, mnemonic, rd, address, width_bytes,
      has_physical_address ? (uint64_t)physical_address : UINT64_MAX,
      has_physical_address ? 1 : 0, raw_value,
      width_bytes == 8
          ? (union { uint64_t u; double d; }){ .u = raw_value }.d
          : 0.0,
      cpu.priv, cpu.csr.satp);
}

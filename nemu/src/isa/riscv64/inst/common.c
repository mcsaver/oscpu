/* RV64 指令公共基础：字段提取、寄存器/访存别名、日志和通用 bit helper。 */

/* 基础设施：寄存器/访存入口、字段提取和少量规范常量都放在文件开头。
 * 执行层只通过这些窄接口读写状态，后续扩指令不再到处散落位切片。 */
#define R(i) gpr(i)
#define F(i) (cpu.fpr[(i)])
#define Mr vaddr_read
#define Mw vaddr_write

#define XLEN_BITS ((uint32_t)(sizeof(word_t) * 8))
#define WORD_SIGN_BIT ((word_t)1 << (XLEN_BITS - 1))

#define OPCODE(i) BITS(i, 6, 0)
#define RD(i)     BITS(i, 11, 7)
#define FUNCT3(i) BITS(i, 14, 12)
#define RS1(i)    BITS(i, 19, 15)
#define RS2(i)    BITS(i, 24, 20)
#define FUNCT2(i) BITS(i, 26, 25)
#define RS3(i)    BITS(i, 31, 27)
#define FUNCT7(i) BITS(i, 31, 25)

#define IMM_I(i) SEXT(BITS(i, 31, 20), 12)
#define IMM_U(i) (SEXT(BITS(i, 31, 12), 20) << 12)
#define IMM_S(i) ((SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7))
#define IMM_B(i) SEXT((BITS(i, 31, 31) << 12 | BITS(i, 7, 7) << 11 | \
                       BITS(i, 30, 25) << 5  | BITS(i, 11, 8) << 1), 13)
#define IMM_J(i) SEXT((BITS(i, 31, 31) << 20 | BITS(i, 19, 12) << 12 | \
                       BITS(i, 20, 20) << 11 | BITS(i, 30, 21) << 1), 21)

#define OPC_LOAD   0x03
#define OPC_LOAD_FP 0x07
#define OPC_MISC_MEM 0x0f
#define OPC_OP_IMM 0x13
#define OPC_OP_IMM_32 0x1b
#define OPC_AUIPC  0x17
#define OPC_STORE  0x23
#define OPC_STORE_FP 0x27
#define OPC_AMO    0x2f
#define OPC_OP     0x33
#define OPC_OP_32  0x3b
#define OPC_MADD   0x43
#define OPC_MSUB   0x47
#define OPC_NMSUB  0x4b
#define OPC_NMADD  0x4f
#define OPC_OP_FP  0x53
#define OPC_LUI    0x37
#define OPC_BRANCH 0x63
#define OPC_JALR   0x67
#define OPC_JAL    0x6f
#define OPC_SYSTEM 0x73

#define FFLAGS_NV 0x10u

#define OP_KEY(funct3, funct7) ((((funct7) & 0x7f) << 3) | ((funct3) & 0x7))
#define SHAMT5(value) ((value) & 0x1f)
#define SHAMT_XLEN(value) ((value) & (XLEN_BITS - 1))
#define BAD_DECODE() return false

static inline bool rv_runtime_env_enabled_default_true(const char *name) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  return !(env != NULL && env[0] != '\0' && strcmp(env, "0") == 0);
#else
  (void)name;
  return true;
#endif
}

#ifdef CONFIG_INTERPRETER_DECODE_CACHE
bool isa_riscv64_decode_cache_is_enabled = true;
#else
bool isa_riscv64_decode_cache_is_enabled = false;
#endif

__attribute__((constructor))
static void rv_runtime_config_init(void) {
#ifdef CONFIG_INTERPRETER_DECODE_CACHE
  isa_riscv64_decode_cache_is_enabled =
    rv_runtime_env_enabled_default_true("NEMU_INTERPRETER_DECODE_CACHE");
#endif
}

#ifdef CONFIG_RISCV_EXT_A
static bool lr_reservation_valid = false;
static paddr_t lr_reservation_paddr = 0;
static int lr_reservation_len = 0;

static inline bool lr_sc_range_overlap(paddr_t lhs_start, int lhs_len,
    paddr_t rhs_start, int rhs_len) {
  paddr_t lhs_end = lhs_start + (paddr_t)lhs_len;
  paddr_t rhs_end = rhs_start + (paddr_t)rhs_len;
  return lhs_start < rhs_end && rhs_start < lhs_end;
}

void isa_riscv64_lr_sc_invalidate(paddr_t paddr, int len) {
  if (!lr_reservation_valid) return;
  if (lr_sc_range_overlap(lr_reservation_paddr, lr_reservation_len, paddr, len)) {
    lr_reservation_valid = false;
  }
}
#else
void isa_riscv64_lr_sc_invalidate(paddr_t paddr, int len) {
  (void)paddr;
  (void)len;
}
#endif

#ifdef CONFIG_INTERPRETER_DECODE_CACHE
#define RV_DECODE_CACHE_ENTRIES CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES

#if (RV_DECODE_CACHE_ENTRIES & (RV_DECODE_CACHE_ENTRIES - 1)) != 0
#error "CONFIG_INTERPRETER_DECODE_CACHE_ENTRIES must be a power of two"
#endif

typedef enum {
  RV_DC_NONE = 0,
  RV_DC_RVC,
  RV_DC_OP_IMM,
  RV_DC_OP_IMM_32,
  RV_DC_LOAD,
  RV_DC_LOAD_FP,
  RV_DC_STORE,
  RV_DC_STORE_FP,
  RV_DC_AMO,
  RV_DC_OP,
  RV_DC_OP_32,
  RV_DC_BRANCH,
  RV_DC_JALR,
  RV_DC_JAL,
  RV_DC_LUI,
  RV_DC_AUIPC,
  RV_DC_KIND_COUNT,
} RvDecodeCacheKind;

typedef struct {
  vaddr_t pc;
  uint32_t inst_key;
  word_t imm;
  uint8_t kind;
  uint8_t rd;
  uint8_t rs1;
  uint8_t rs2;
  uint8_t funct3;
  uint8_t funct7;
} RvDecodeCacheEntry;

static RvDecodeCacheEntry rv_decode_cache[RV_DECODE_CACHE_ENTRIES];

static inline uint32_t rv_decode_cache_index(vaddr_t pc) {
  return (pc >> 1) & (RV_DECODE_CACHE_ENTRIES - 1);
}

static inline uint32_t rv_decode_cache_inst_key(uint32_t inst) {
#ifdef CONFIG_RISCV_EXT_C
  return (inst & 0x3u) == 0x3u ? inst : (inst & 0xffffu);
#else
  return inst;
#endif
}

static inline void rv_decode_cache_flush(void) {
  memset(rv_decode_cache, 0, sizeof(rv_decode_cache));
}
#else
#define rv_decode_cache_flush() ((void)0)
#endif
#ifdef CONFIG_RISCV_DEBUG_LOG
static int csr_boot_log_budget = 8;
#define CSR_DEBUG_LOG(...) do { \
  if (csr_boot_log_budget > 0) { \
    csr_boot_log_budget--; \
    Log(__VA_ARGS__); \
  } \
} while (0)
#else
#define CSR_DEBUG_LOG(...) do {} while (0)
#endif

#ifdef CONFIG_RISCV_IRQ_DEBUG_LOG
static int csr_intr_log_budget = 128;
#define CSR_INTR_DEBUG_LOG(...) do { \
  if (csr_intr_log_budget > 0) { \
    csr_intr_log_budget--; \
    Log(__VA_ARGS__); \
  } \
} while (0)
#else
#define CSR_INTR_DEBUG_LOG(...) do {} while (0)
#endif

#ifdef CONFIG_RISCV_SYSCALL_DEBUG_LOG
static int syscall_debug_budget = CONFIG_RISCV_SYSCALL_DEBUG_BUDGET;
static bool syscall_return_pending = false;
static word_t syscall_return_nr = 0;
static vaddr_t syscall_return_epc = 0;
static int post_exec_pc_log_budget = 64;
static uint64_t post_exec_uinst_seen = 0;

static inline void syscall_debug_log_enter(vaddr_t pc) {
  if (cpu.priv != PRIV_U || syscall_debug_budget <= 0) return;
  syscall_debug_budget--;
  syscall_return_pending = true;
  syscall_return_nr = R(17);
  syscall_return_epc = pc;
  Log("[Strace] enter pc=" FMT_WORD " nr=%" PRIu64
      " a0=" FMT_WORD " a1=" FMT_WORD " a2=" FMT_WORD
      " a3=" FMT_WORD " a4=" FMT_WORD " a5=" FMT_WORD
      " sp=" FMT_WORD,
      pc, (uint64_t)R(17), R(10), R(11), R(12), R(13), R(14), R(15), R(2));
}

static inline void syscall_debug_log_return(vaddr_t target) {
  if (!syscall_return_pending || cpu.priv != PRIV_U) return;
  word_t nr = syscall_return_nr;
  vaddr_t epc = syscall_return_epc;
  syscall_return_pending = false;
  Log("[Strace] return pc=" FMT_WORD " nr=%" PRIu64
      " ret=" FMT_WORD " target=" FMT_WORD,
      epc, (uint64_t)nr, R(10), target);
  if (nr == 221 && target != epc + 4) {
    post_exec_uinst_seen = 0;
    Log("[Strace] execve switched image target=" FMT_WORD " sp=" FMT_WORD,
        target, R(2));
  }
}

static inline void syscall_debug_log_user_pc(vaddr_t pc, uint32_t inst) {
  if (post_exec_pc_log_budget <= 0 || cpu.priv != PRIV_U) return;
  post_exec_uinst_seen++;
  if (post_exec_uinst_seen <= 16 || post_exec_uinst_seen % 1000000 == 0) {
    post_exec_pc_log_budget--;
    Log("[Utrace] after-exec seen=%" PRIu64 " pc=" FMT_WORD
        " inst=0x%08x ra=" FMT_WORD " sp=" FMT_WORD,
        post_exec_uinst_seen, pc, inst, R(1), R(2));
  }
}
#else
#define syscall_debug_log_enter(pc) ((void)0)
#define syscall_debug_log_return(target) ((void)0)
#define syscall_debug_log_user_pc(pc, inst) ((void)0)
#endif

static inline word_t sext32(uint32_t value) {
  return (word_t)SEXT(value, 32);
}

static inline word_t rol_xlen(word_t value, word_t shamt) {
  shamt = SHAMT_XLEN(shamt);
  return shamt == 0 ? value : (word_t)((value << shamt) | (value >> (XLEN_BITS - shamt)));
}

static inline word_t ror_xlen(word_t value, word_t shamt) {
  shamt = SHAMT_XLEN(shamt);
  return shamt == 0 ? value : (word_t)((value >> shamt) | (value << (XLEN_BITS - shamt)));
}

static inline word_t clz_xlen(word_t value) {
  if (value == 0) return XLEN_BITS;
#ifdef CONFIG_ISA64
  return (word_t)__builtin_clzll(value);
#else
  return (word_t)__builtin_clz((uint32_t)value);
#endif
}

static inline word_t ctz_xlen(word_t value) {
  if (value == 0) return XLEN_BITS;
#ifdef CONFIG_ISA64
  return (word_t)__builtin_ctzll(value);
#else
  return (word_t)__builtin_ctz((uint32_t)value);
#endif
}

static inline word_t cpop_xlen(word_t value) {
#ifdef CONFIG_ISA64
  return (word_t)__builtin_popcountll(value);
#else
  return (word_t)__builtin_popcount((uint32_t)value);
#endif
}

static inline word_t sext_b_xlen(word_t value) {
  return SEXT(BITS(value, 7, 0), 8);
}

static inline word_t sext_h_xlen(word_t value) {
  return SEXT(BITS(value, 15, 0), 16);
}

static inline word_t orc_b_xlen(word_t value) {
  word_t r = 0;
  for (int i = 0; i < (int)(XLEN_BITS / 8); i++) {
    word_t b = (value >> (i * 8)) & 0xffu;
    if (b != 0) r |= (word_t)0xff << (i * 8);
  }
  return r;
}

static inline word_t rev8_xlen(word_t value) {
  word_t r = 0;
  for (int i = 0; i < (int)(XLEN_BITS / 8); i++) {
    r |= ((value >> (i * 8)) & 0xffu) << ((XLEN_BITS / 8 - 1 - i) * 8);
  }
  return r;
}

static inline word_t clmul_xlen(word_t src1, word_t src2) {
  word_t r = 0;
  for (int i = 0; i < (int)XLEN_BITS; i++) {
    if ((src2 >> i) & 1u) r ^= src1 << i;
  }
  return r;
}

static inline word_t clmulh_xlen(word_t src1, word_t src2) {
  word_t r = 0;
  for (int i = 1; i < (int)XLEN_BITS; i++) {
    if ((src2 >> i) & 1u) r ^= src1 >> (XLEN_BITS - i);
  }
  return r;
}

static inline word_t clmulr_xlen(word_t src1, word_t src2) {
  word_t r = 0;
  for (int i = 0; i < (int)XLEN_BITS; i++) {
    if ((src2 >> i) & 1u) r ^= src1 >> (XLEN_BITS - 1 - i);
  }
  return r;
}

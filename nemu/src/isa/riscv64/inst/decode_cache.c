/* 解释器预译码 cache：缓存可直接执行的常见指令形态。 */

#include <utils/profile.h>

static inline void raise_illegal_inst(Decode *s, uint32_t inst) {
  s->dnpc = isa_raise_intr_with_tval(CAUSE_ILLEGAL_INST, s->pc, inst);
  R(0) = 0;
}

#ifdef CONFIG_INTERPRETER_DECODE_CACHE
static inline RvDecodeCacheKind rv_decode_cache_kind(uint32_t inst) {
#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3u) != 0x3u) return RV_DC_RVC;
#endif

  switch (OPCODE(inst)) {
    case OPC_OP_IMM: return RV_DC_OP_IMM;
    case OPC_OP_IMM_32: return RV_DC_OP_IMM_32;
    case OPC_LOAD: return RV_DC_LOAD;
    case OPC_LOAD_FP: return RV_DC_LOAD_FP;
    case OPC_STORE: return RV_DC_STORE;
    case OPC_STORE_FP: return RV_DC_STORE_FP;
    case OPC_AMO: return RV_DC_AMO;
    case OPC_OP: return RV_DC_OP;
    case OPC_OP_32: return RV_DC_OP_32;
    case OPC_BRANCH: return RV_DC_BRANCH;
    case OPC_JALR: return RV_DC_JALR;
    case OPC_JAL: return RV_DC_JAL;
    case OPC_LUI: return RV_DC_LUI;
    case OPC_AUIPC: return RV_DC_AUIPC;
    default: return RV_DC_NONE;
  }
}

#if defined(CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH)
#if !defined(__GNUC__)
#error "CONFIG_INTERPRETER_DECODE_DIRECT_DISPATCH requires GNU C labels-as-values support"
#endif
#define RV_DECODE_CACHE_USE_DIRECT_DISPATCH 1
#else
#define RV_DECODE_CACHE_USE_DIRECT_DISPATCH 0
#endif

static inline void rv_decode_cache_fill(const Decode *s) {
  if (unlikely(!isa_riscv64_decode_cache_runtime_enabled())) return;

  uint32_t inst = s->isa.inst;
  RvDecodeCacheKind kind = rv_decode_cache_kind(inst);
  if (kind == RV_DC_NONE) return;
  if (nemu_profile_decode_cache_enabled()) {
    nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_FILLS, 1);
    if (kind == RV_DC_RVC) {
      nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_FILL_RVC, 1);
    }
  }

  RvDecodeCacheEntry next = {
    .pc = s->pc,
    .inst_key = rv_decode_cache_inst_key(inst),
    .imm = 0,
    .kind = kind,
    .rd = RD(inst),
    .rs1 = RS1(inst),
    .rs2 = RS2(inst),
    .funct3 = FUNCT3(inst),
    .funct7 = FUNCT7(inst),
  };

  switch (kind) {
    case RV_DC_LOAD:
    case RV_DC_LOAD_FP:
    case RV_DC_JALR:
      next.imm = IMM_I(inst);
      break;
    case RV_DC_STORE:
    case RV_DC_STORE_FP:
      next.imm = IMM_S(inst);
      break;
    case RV_DC_BRANCH:
      next.imm = IMM_B(inst);
      break;
    case RV_DC_JAL:
      next.imm = IMM_J(inst);
      break;
    case RV_DC_LUI:
    case RV_DC_AUIPC:
      next.imm = IMM_U(inst);
      break;
    default:
      break;
  }

  rv_decode_cache[rv_decode_cache_index(s->pc)] = next;
}

static inline bool rv_decode_cache_exec(Decode *s) {
  if (unlikely(!isa_riscv64_decode_cache_runtime_enabled())) return false;

  bool profile_decode_cache = nemu_profile_decode_cache_enabled();
  if (profile_decode_cache) {
    nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_LOOKUPS, 1);
  }
  uint32_t inst_key = rv_decode_cache_inst_key(s->isa.inst);
  RvDecodeCacheEntry *entry = &rv_decode_cache[rv_decode_cache_index(s->pc)];
  if (entry->kind == RV_DC_NONE || entry->pc != s->pc || entry->inst_key != inst_key) {
    if (profile_decode_cache) {
      nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_MISSES, 1);
    }
    return false;
  }
  if (profile_decode_cache) {
    nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_HITS, 1);
    if (entry->kind == RV_DC_RVC) {
      nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_HIT_RVC, 1);
    }
  }

  uint32_t inst = s->isa.inst;
  s->dnpc = s->snpc;

  // decode-cache 命中后只剩 kind 分发，这里用 direct dispatch 减少大 switch 热路径开销。
#if RV_DECODE_CACHE_USE_DIRECT_DISPATCH
  static void *const rv_decode_cache_dispatch[RV_DC_KIND_COUNT] = {
    [RV_DC_NONE] = &&dc_miss,
    [RV_DC_RVC] = &&dc_rvc,
    [RV_DC_OP_IMM] = &&dc_op_imm,
    [RV_DC_OP_IMM_32] = &&dc_op_imm_32,
    [RV_DC_LOAD] = &&dc_load,
    [RV_DC_LOAD_FP] = &&dc_load_fp,
    [RV_DC_STORE] = &&dc_store,
    [RV_DC_STORE_FP] = &&dc_store_fp,
    [RV_DC_AMO] = &&dc_amo,
    [RV_DC_OP] = &&dc_op,
    [RV_DC_OP_32] = &&dc_op_32,
    [RV_DC_BRANCH] = &&dc_branch,
    [RV_DC_JALR] = &&dc_jalr,
    [RV_DC_JAL] = &&dc_jal,
    [RV_DC_LUI] = &&dc_lui,
    [RV_DC_AUIPC] = &&dc_auipc,
  };
  if (entry->kind >= RV_DC_KIND_COUNT) return false;
  goto *rv_decode_cache_dispatch[entry->kind];
#else
  switch ((RvDecodeCacheKind)entry->kind) {
    case RV_DC_NONE: goto dc_miss;
    case RV_DC_RVC: goto dc_rvc;
    case RV_DC_OP_IMM: goto dc_op_imm;
    case RV_DC_OP_IMM_32: goto dc_op_imm_32;
    case RV_DC_LOAD: goto dc_load;
    case RV_DC_LOAD_FP: goto dc_load_fp;
    case RV_DC_STORE: goto dc_store;
    case RV_DC_STORE_FP: goto dc_store_fp;
    case RV_DC_AMO: goto dc_amo;
    case RV_DC_OP: goto dc_op;
    case RV_DC_OP_32: goto dc_op_32;
    case RV_DC_BRANCH: goto dc_branch;
    case RV_DC_JALR: goto dc_jalr;
    case RV_DC_JAL: goto dc_jal;
    case RV_DC_LUI: goto dc_lui;
    case RV_DC_AUIPC: goto dc_auipc;
    default: return false;
  }
#endif

dc_rvc:
#ifdef CONFIG_RISCV_EXT_C
  if (!exec_rv64c(s, inst & 0xffffu)) goto invalid;
  goto decoded;
#else
  goto invalid;
#endif
dc_op_imm: {
  word_t src1 = R(entry->rs1);
  if (!exec_rv64i_op_imm(inst, entry->rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
    if (!exec_zb_op_imm(inst, entry->rd, src1)) goto invalid;
#else
    goto invalid;
#endif
  }
  goto decoded;
}
dc_op_imm_32:
  if (!exec_rv64i_op_imm_32(inst, entry->rd, R(entry->rs1))) goto invalid;
  goto decoded;
dc_load:
  if (!exec_rv64i_load(entry->funct3, entry->rd, R(entry->rs1) + entry->imm)) goto invalid;
  goto decoded;
dc_load_fp:
  if (!exec_rvf_load(entry->funct3, entry->rd, R(entry->rs1) + entry->imm)) goto invalid;
  goto decoded;
dc_store:
  if (!exec_rv64i_store(entry->funct3, R(entry->rs1) + entry->imm, R(entry->rs2))) goto invalid;
  goto decoded;
dc_store_fp:
  if (!exec_rvf_store(entry->funct3, R(entry->rs1) + entry->imm, entry->rs2)) goto invalid;
  goto decoded;
dc_amo:
#ifdef CONFIG_RISCV_EXT_A
  if (!exec_rva_amo(inst, entry->rd, entry->rs1, entry->rs2)) goto invalid;
  goto decoded;
#else
  goto invalid;
#endif
dc_op: {
  word_t src1 = R(entry->rs1);
  word_t src2 = R(entry->rs2);
  if (exec_rv64i_op(entry->funct3, entry->funct7, entry->rd, src1, src2)) goto decoded;
#ifdef CONFIG_RISCV_EXT_M
  if (exec_rvm_op(entry->funct3, entry->funct7, entry->rd, src1, src2)) goto decoded;
#endif
#ifdef CONFIG_RISCV_EXT_B
  if (exec_zb_op(entry->funct3, entry->funct7, entry->rd, entry->rs2, src1, src2)) goto decoded;
#endif
  goto invalid;
}
dc_op_32: {
  word_t src1 = R(entry->rs1);
  word_t src2 = R(entry->rs2);
#ifdef CONFIG_RISCV_EXT_B
  if (exec_zb_op_32(entry->funct3, entry->funct7, entry->rd, entry->rs2, src1, src2)) goto decoded;
#endif
  if (exec_rv64i_op_32(entry->funct3, entry->funct7, entry->rd, src1, src2)) goto decoded;
#ifdef CONFIG_RISCV_EXT_M
  if (exec_rvm_op_32(entry->funct3, entry->funct7, entry->rd, src1, src2)) goto decoded;
#endif
  goto invalid;
}
dc_branch:
  if (!exec_rv64i_branch(s, entry->funct3, R(entry->rs1), R(entry->rs2), entry->imm)) goto invalid;
  goto decoded;
dc_jalr: {
  if (entry->funct3 != 0x0) goto invalid;
  word_t target = (R(entry->rs1) + entry->imm) & ~(word_t)1;
  R(entry->rd) = s->pc + 4;
  s->dnpc = target;
  IFDEF(CONFIG_FTRACE, {
    if (entry->rd == 0 && entry->rs1 == 1) ftrace_log(-1, s->pc, target);
    else if (entry->rd == 1 || entry->rd == 5) ftrace_log(1, s->pc, target);
  })
  goto decoded;
}
dc_jal:
  R(entry->rd) = s->pc + 4;
  s->dnpc = s->pc + entry->imm;
  IFDEF(CONFIG_FTRACE, if (entry->rd == 1 || entry->rd == 5) ftrace_log(1, s->pc, s->dnpc));
  goto decoded;
dc_lui:
  R(entry->rd) = entry->imm;
  goto decoded;
dc_auipc:
  R(entry->rd) = s->pc + entry->imm;
  goto decoded;
dc_miss:
  return false;

decoded:
  R(0) = 0;
  return true;

invalid:
  raise_illegal_inst(s, inst);
  return true;
}
#else
#define rv_decode_cache_fill(s) ((void)0)
#define rv_decode_cache_exec(s) false
#endif

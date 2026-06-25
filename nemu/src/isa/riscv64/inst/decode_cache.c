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

#ifdef CONFIG_RISCV_EXT_C
static inline bool rv_decode_cache_rvc_op_is_direct(uint8_t op) {
  return op > RV_DC_RVC_FALLBACK && op < RV_DC_RVC_OP_COUNT;
}
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
    .rvc_op = RV_DC_RVC_FALLBACK,
    .int_op = RV_DC_INT_FALLBACK,
    .rd = RD(inst),
    .rs1 = RS1(inst),
    .rs2 = RS2(inst),
    .funct3 = FUNCT3(inst),
    .funct7 = FUNCT7(inst),
  };

  switch (kind) {
    case RV_DC_RVC: {
#ifdef CONFIG_RISCV_EXT_C
      if (!isa_riscv64_decode_cache_rvc_fast_runtime_enabled()) break;
      uint16_t cinst = inst & 0xffffu;
      uint32_t op = cinst & 0x3u;
      uint32_t funct3 = C_FUNCT3(cinst);
      uint32_t rd = BITS(cinst, 11, 7);
      uint32_t rs2 = BITS(cinst, 6, 2);

      // RVC hit path 只预解码语义直观且热度高的形态，其余继续复用 exec_rv64c。
      if (op == 0x0) {
        switch (funct3) {
          case 0x0: { // c.addi4spn
            word_t imm = c_imm_addi4spn(cinst);
            if (imm != 0) {
              next.rvc_op = RV_DC_RVC_ADDI4SPN;
              next.rd = C_RD(cinst);
              next.imm = imm;
            }
            break;
          }
          case 0x2: // c.lw
            next.rvc_op = RV_DC_RVC_LW;
            next.rd = C_RD(cinst);
            next.rs1 = C_RS1(cinst);
            next.imm = c_imm_lw_sw(cinst);
            break;
          case 0x3: // c.ld
            next.rvc_op = RV_DC_RVC_LD;
            next.rd = C_RD(cinst);
            next.rs1 = C_RS1(cinst);
            next.imm = c_imm_ld_sd(cinst);
            break;
          case 0x6: // c.sw
            next.rvc_op = RV_DC_RVC_SW;
            next.rs1 = C_RS1(cinst);
            next.rs2 = C_RS2(cinst);
            next.imm = c_imm_lw_sw(cinst);
            break;
          case 0x7: // c.sd
            next.rvc_op = RV_DC_RVC_SD;
            next.rs1 = C_RS1(cinst);
            next.rs2 = C_RS2(cinst);
            next.imm = c_imm_ld_sd(cinst);
            break;
          default:
            break;
        }
      } else if (op == 0x1) {
        switch (funct3) {
          case 0x0: // c.addi / c.nop
            next.rvc_op = RV_DC_RVC_ADDI;
            next.rd = rd;
            next.imm = c_imm_6(cinst);
            break;
          case 0x1: // c.addiw
            if (rd != 0) {
              next.rvc_op = RV_DC_RVC_ADDIW;
              next.rd = rd;
              next.imm = c_imm_6(cinst);
            }
            break;
          case 0x2: // c.li
            next.rvc_op = RV_DC_RVC_LI;
            next.rd = rd;
            next.imm = c_imm_6(cinst);
            break;
          case 0x3: {
            word_t imm = (rd == 2) ? c_imm_addi16sp(cinst) : c_imm_6(cinst);
            if (rd == 2 && imm != 0) {
              next.rvc_op = RV_DC_RVC_ADDI16SP;
              next.imm = imm;
            } else if (rd != 0 && imm != 0) {
              next.rvc_op = RV_DC_RVC_LUI;
              next.rd = rd;
              next.imm = imm << 12;
            }
            break;
          }
          case 0x4: {
            uint32_t rs1p = C_RS1(cinst);
            uint32_t rs2p = C_RS2(cinst);
            switch (BITS(cinst, 11, 10)) {
              case 0x0:
                next.rvc_op = RV_DC_RVC_SRLI;
                next.rs1 = rs1p;
                next.imm = c_shamt(cinst);
                break;
              case 0x1:
                next.rvc_op = RV_DC_RVC_SRAI;
                next.rs1 = rs1p;
                next.imm = c_shamt(cinst);
                break;
              case 0x2:
                next.rvc_op = RV_DC_RVC_ANDI;
                next.rs1 = rs1p;
                next.imm = c_imm_6(cinst);
                break;
              case 0x3:
                next.rs1 = rs1p;
                next.rs2 = rs2p;
                switch ((BITS(cinst, 12, 12) << 2) | BITS(cinst, 6, 5)) {
                  case 0x0: next.rvc_op = RV_DC_RVC_SUB; break;
                  case 0x1: next.rvc_op = RV_DC_RVC_XOR; break;
                  case 0x2: next.rvc_op = RV_DC_RVC_OR; break;
                  case 0x3: next.rvc_op = RV_DC_RVC_AND; break;
                  case 0x4: next.rvc_op = RV_DC_RVC_SUBW; break;
                  case 0x5: next.rvc_op = RV_DC_RVC_ADDW; break;
                  default: break;
                }
                break;
              default:
                break;
            }
            break;
          }
          case 0x5: // c.j
            next.rvc_op = RV_DC_RVC_J;
            next.imm = c_imm_j(cinst);
            break;
          case 0x6: // c.beqz
            next.rvc_op = RV_DC_RVC_BEQZ;
            next.rs1 = C_RS1(cinst);
            next.imm = c_imm_b(cinst);
            break;
          case 0x7: // c.bnez
            next.rvc_op = RV_DC_RVC_BNEZ;
            next.rs1 = C_RS1(cinst);
            next.imm = c_imm_b(cinst);
            break;
          default:
            break;
        }
      } else if (op == 0x2) {
        switch (funct3) {
          case 0x0: // c.slli
            next.rvc_op = RV_DC_RVC_SLLI;
            next.rd = rd;
            next.imm = c_shamt(cinst);
            break;
          case 0x2: // c.lwsp
            if (rd != 0) {
              next.rvc_op = RV_DC_RVC_LWSP;
              next.rd = rd;
              next.imm = c_imm_lwsp(cinst);
            }
            break;
          case 0x3: // c.ldsp
            if (rd != 0) {
              next.rvc_op = RV_DC_RVC_LDSP;
              next.rd = rd;
              next.imm = c_imm_ldsp(cinst);
            }
            break;
          case 0x4:
            if (BITS(cinst, 12, 12) == 0) {
              if (rd != 0 && rs2 == 0) {
                next.rvc_op = RV_DC_RVC_JR;
                next.rd = rd;
              } else if (rd != 0 && rs2 != 0) {
                next.rvc_op = RV_DC_RVC_MV;
                next.rd = rd;
                next.rs2 = rs2;
              }
            } else if (rd != 0 && rs2 != 0) {
              next.rvc_op = RV_DC_RVC_ADD;
              next.rd = rd;
              next.rs2 = rs2;
            }
            break;
          case 0x6: // c.swsp
            next.rvc_op = RV_DC_RVC_SWSP;
            next.rs2 = rs2;
            next.imm = c_imm_swsp(cinst);
            break;
          case 0x7: // c.sdsp
            next.rvc_op = RV_DC_RVC_SDSP;
            next.rs2 = rs2;
            next.imm = c_imm_sdsp(cinst);
            break;
          default:
            break;
        }
      }
#endif
      break;
    }
    case RV_DC_OP_IMM: {
      next.imm = IMM_I(inst);
      if (!isa_riscv64_decode_cache_int_fast_runtime_enabled()) break;
      uint32_t funct3 = FUNCT3(inst);
      uint32_t funct7 = FUNCT7(inst);
      uint32_t funct6 = BITS(inst, 31, 26);
      switch (funct3) {
        case 0x0: next.int_op = RV_DC_INT_ADDI; break;
        case 0x2: next.int_op = RV_DC_INT_SLTI; break;
        case 0x3: next.int_op = RV_DC_INT_SLTIU; break;
        case 0x4: next.int_op = RV_DC_INT_XORI; break;
        case 0x6: next.int_op = RV_DC_INT_ORI; break;
        case 0x7: next.int_op = RV_DC_INT_ANDI; break;
        case 0x1:
          if (funct6 == 0x00) {
            next.int_op = RV_DC_INT_SLLI;
            next.imm = BITS(inst, 25, 20);
          }
          break;
        case 0x5:
          if (funct6 == 0x00) {
            next.int_op = RV_DC_INT_SRLI;
            next.imm = BITS(inst, 25, 20);
          } else if (funct6 == 0x10) {
            next.int_op = RV_DC_INT_SRAI;
            next.imm = BITS(inst, 25, 20);
          }
          break;
        default:
          (void)funct7;
          break;
      }
      break;
    }
    case RV_DC_OP_IMM_32: {
      next.imm = IMM_I(inst);
      if (!isa_riscv64_decode_cache_int_fast_runtime_enabled()) break;
      uint32_t funct3 = FUNCT3(inst);
      uint32_t funct7 = FUNCT7(inst);
      switch (funct3) {
        case 0x0:
          next.int_op = RV_DC_INT_ADDIW;
          break;
        case 0x1:
          if (funct7 == 0x00) {
            next.int_op = RV_DC_INT_SLLIW;
            next.imm = BITS(inst, 24, 20);
          }
          break;
        case 0x5:
          if (funct7 == 0x00) {
            next.int_op = RV_DC_INT_SRLIW;
            next.imm = BITS(inst, 24, 20);
          } else if (funct7 == 0x20) {
            next.int_op = RV_DC_INT_SRAIW;
            next.imm = BITS(inst, 24, 20);
          }
          break;
        default:
          break;
      }
      break;
    }
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
    case RV_DC_OP: {
      if (!isa_riscv64_decode_cache_int_fast_runtime_enabled()) break;
      switch (OP_KEY(next.funct3, next.funct7)) {
        case OP_KEY(0x0, 0x00): next.int_op = RV_DC_INT_ADD; break;
        case OP_KEY(0x0, 0x20): next.int_op = RV_DC_INT_SUB; break;
        case OP_KEY(0x1, 0x00): next.int_op = RV_DC_INT_SLL; break;
        case OP_KEY(0x2, 0x00): next.int_op = RV_DC_INT_SLT; break;
        case OP_KEY(0x3, 0x00): next.int_op = RV_DC_INT_SLTU; break;
        case OP_KEY(0x4, 0x00): next.int_op = RV_DC_INT_XOR; break;
        case OP_KEY(0x5, 0x00): next.int_op = RV_DC_INT_SRL; break;
        case OP_KEY(0x5, 0x20): next.int_op = RV_DC_INT_SRA; break;
        case OP_KEY(0x6, 0x00): next.int_op = RV_DC_INT_OR; break;
        case OP_KEY(0x7, 0x00): next.int_op = RV_DC_INT_AND; break;
        default: break;
      }
      break;
    }
    case RV_DC_OP_32: {
      if (!isa_riscv64_decode_cache_int_fast_runtime_enabled()) break;
      switch (OP_KEY(next.funct3, next.funct7)) {
        case OP_KEY(0x0, 0x00): next.int_op = RV_DC_INT_ADDW; break;
        case OP_KEY(0x0, 0x20): next.int_op = RV_DC_INT_SUBW; break;
        case OP_KEY(0x1, 0x00): next.int_op = RV_DC_INT_SLLW; break;
        case OP_KEY(0x5, 0x00): next.int_op = RV_DC_INT_SRLW; break;
        case OP_KEY(0x5, 0x20): next.int_op = RV_DC_INT_SRAW; break;
        default: break;
      }
      break;
    }
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
  if (unlikely(nemu_profile_rvc_detail_enabled()) &&
      rv_decode_cache_rvc_op_is_direct(entry->rvc_op)) {
    profile_rvc_detail_inst(inst & 0xffffu);
  }
  switch ((RvDecodeCacheRvcOp)entry->rvc_op) {
    case RV_DC_RVC_ADDI4SPN:
      R(entry->rd) = R(2) + entry->imm;
      goto decoded;
    case RV_DC_RVC_ADDI:
      R(entry->rd) = R(entry->rd) + entry->imm;
      goto decoded;
    case RV_DC_RVC_ADDIW:
      R(entry->rd) = sext32((uint32_t)(R(entry->rd) + entry->imm));
      goto decoded;
    case RV_DC_RVC_ADDI16SP:
      R(2) = R(2) + entry->imm;
      goto decoded;
    case RV_DC_RVC_LI:
      if (entry->rd != 0) R(entry->rd) = entry->imm;
      goto decoded;
    case RV_DC_RVC_LUI:
      R(entry->rd) = entry->imm;
      goto decoded;
    case RV_DC_RVC_SRLI:
      R(entry->rs1) = R(entry->rs1) >> entry->imm;
      goto decoded;
    case RV_DC_RVC_SRAI:
      R(entry->rs1) = (sword_t)R(entry->rs1) >> entry->imm;
      goto decoded;
    case RV_DC_RVC_ANDI:
      R(entry->rs1) = R(entry->rs1) & entry->imm;
      goto decoded;
    case RV_DC_RVC_SUB:
      R(entry->rs1) = R(entry->rs1) - R(entry->rs2);
      goto decoded;
    case RV_DC_RVC_XOR:
      R(entry->rs1) = R(entry->rs1) ^ R(entry->rs2);
      goto decoded;
    case RV_DC_RVC_OR:
      R(entry->rs1) = R(entry->rs1) | R(entry->rs2);
      goto decoded;
    case RV_DC_RVC_AND:
      R(entry->rs1) = R(entry->rs1) & R(entry->rs2);
      goto decoded;
    case RV_DC_RVC_SUBW:
      R(entry->rs1) = sext32((uint32_t)R(entry->rs1) - (uint32_t)R(entry->rs2));
      goto decoded;
    case RV_DC_RVC_ADDW:
      R(entry->rs1) = sext32((uint32_t)R(entry->rs1) + (uint32_t)R(entry->rs2));
      goto decoded;
    case RV_DC_RVC_J:
      s->dnpc = s->pc + entry->imm;
      goto decoded;
    case RV_DC_RVC_JR:
      s->dnpc = R(entry->rd) & ~(word_t)1;
      IFDEF(CONFIG_FTRACE, if (entry->rd == 1) ftrace_log(-1, s->pc, s->dnpc));
      goto decoded;
    case RV_DC_RVC_SLLI:
      R(entry->rd) = R(entry->rd) << entry->imm;
      goto decoded;
    case RV_DC_RVC_MV:
      R(entry->rd) = R(entry->rs2);
      goto decoded;
    case RV_DC_RVC_ADD:
      R(entry->rd) = R(entry->rd) + R(entry->rs2);
      goto decoded;
    case RV_DC_RVC_BEQZ:
      if (R(entry->rs1) == 0) s->dnpc = s->pc + entry->imm;
      goto decoded;
    case RV_DC_RVC_BNEZ:
      if (R(entry->rs1) != 0) s->dnpc = s->pc + entry->imm;
      goto decoded;
    case RV_DC_RVC_LW:
      if (!exec_rv64i_load(0x2, entry->rd, R(entry->rs1) + entry->imm)) goto invalid;
      goto decoded;
    case RV_DC_RVC_LD:
      if (!exec_rv64i_load(0x3, entry->rd, R(entry->rs1) + entry->imm)) goto invalid;
      goto decoded;
    case RV_DC_RVC_LWSP:
      if (!exec_rv64i_load(0x2, entry->rd, R(2) + entry->imm)) goto invalid;
      goto decoded;
    case RV_DC_RVC_LDSP:
      if (!exec_rv64i_load(0x3, entry->rd, R(2) + entry->imm)) goto invalid;
      goto decoded;
    case RV_DC_RVC_SW:
      Mw(R(entry->rs1) + entry->imm, 4, R(entry->rs2));
      goto decoded;
    case RV_DC_RVC_SD:
      Mw(R(entry->rs1) + entry->imm, 8, R(entry->rs2));
      goto decoded;
    case RV_DC_RVC_SWSP:
      Mw(R(2) + entry->imm, 4, R(entry->rs2));
      goto decoded;
    case RV_DC_RVC_SDSP:
      Mw(R(2) + entry->imm, 8, R(entry->rs2));
      goto decoded;
    case RV_DC_RVC_FALLBACK:
    default:
      if (!exec_rv64c(s, inst & 0xffffu)) goto invalid;
      goto decoded;
  }
#else
  goto invalid;
#endif
dc_op_imm: {
  word_t src1 = R(entry->rs1);
  switch ((RvDecodeCacheIntOp)entry->int_op) {
    case RV_DC_INT_ADDI:  R(entry->rd) = src1 + entry->imm; goto decoded;
    case RV_DC_INT_SLTI:  R(entry->rd) = (sword_t)src1 < (sword_t)entry->imm ? 1 : 0; goto decoded;
    case RV_DC_INT_SLTIU: R(entry->rd) = src1 < (word_t)entry->imm ? 1 : 0; goto decoded;
    case RV_DC_INT_XORI:  R(entry->rd) = src1 ^ entry->imm; goto decoded;
    case RV_DC_INT_ORI:   R(entry->rd) = src1 | entry->imm; goto decoded;
    case RV_DC_INT_ANDI:  R(entry->rd) = src1 & entry->imm; goto decoded;
    case RV_DC_INT_SLLI:  R(entry->rd) = src1 << entry->imm; goto decoded;
    case RV_DC_INT_SRLI:  R(entry->rd) = src1 >> entry->imm; goto decoded;
    case RV_DC_INT_SRAI:  R(entry->rd) = (sword_t)src1 >> entry->imm; goto decoded;
    default:
      break;
  }
  if (!exec_rv64i_op_imm(inst, entry->rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
    if (!exec_zb_op_imm(inst, entry->rd, src1)) goto invalid;
#else
    goto invalid;
#endif
  }
  goto decoded;
}
dc_op_imm_32: {
  word_t src1 = R(entry->rs1);
  uint32_t src32 = src1;
  switch ((RvDecodeCacheIntOp)entry->int_op) {
    case RV_DC_INT_ADDIW: R(entry->rd) = sext32(src32 + (uint32_t)entry->imm); goto decoded;
    case RV_DC_INT_SLLIW: R(entry->rd) = sext32(src32 << entry->imm); goto decoded;
    case RV_DC_INT_SRLIW: R(entry->rd) = sext32(src32 >> entry->imm); goto decoded;
    case RV_DC_INT_SRAIW: R(entry->rd) = sext32((uint32_t)((int32_t)src32 >> entry->imm)); goto decoded;
    default:
      break;
  }
  if (!exec_rv64i_op_imm_32(inst, entry->rd, R(entry->rs1))) goto invalid;
  goto decoded;
}
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
  switch ((RvDecodeCacheIntOp)entry->int_op) {
    case RV_DC_INT_ADD:  R(entry->rd) = src1 + src2; goto decoded;
    case RV_DC_INT_SUB:  R(entry->rd) = src1 - src2; goto decoded;
    case RV_DC_INT_SLL:  R(entry->rd) = src1 << SHAMT_XLEN(src2); goto decoded;
    case RV_DC_INT_SLT:  R(entry->rd) = (sword_t)src1 < (sword_t)src2 ? 1 : 0; goto decoded;
    case RV_DC_INT_SLTU: R(entry->rd) = src1 < src2 ? 1 : 0; goto decoded;
    case RV_DC_INT_XOR:  R(entry->rd) = src1 ^ src2; goto decoded;
    case RV_DC_INT_SRL:  R(entry->rd) = src1 >> SHAMT_XLEN(src2); goto decoded;
    case RV_DC_INT_SRA:  R(entry->rd) = (sword_t)src1 >> SHAMT_XLEN(src2); goto decoded;
    case RV_DC_INT_OR:   R(entry->rd) = src1 | src2; goto decoded;
    case RV_DC_INT_AND:  R(entry->rd) = src1 & src2; goto decoded;
    default:
      break;
  }
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
  uint32_t a = src1;
  uint32_t b = src2;
  uint32_t shamt = b & 0x1f;
  switch ((RvDecodeCacheIntOp)entry->int_op) {
    case RV_DC_INT_ADDW: R(entry->rd) = sext32(a + b); goto decoded;
    case RV_DC_INT_SUBW: R(entry->rd) = sext32(a - b); goto decoded;
    case RV_DC_INT_SLLW: R(entry->rd) = sext32(a << shamt); goto decoded;
    case RV_DC_INT_SRLW: R(entry->rd) = sext32(a >> shamt); goto decoded;
    case RV_DC_INT_SRAW: R(entry->rd) = sext32((uint32_t)((int32_t)a >> shamt)); goto decoded;
    default:
      break;
  }
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

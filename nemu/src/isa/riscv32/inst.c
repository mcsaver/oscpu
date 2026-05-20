/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "local-include/reg.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>
#include <memory/cache.h>
#include <ftrace.h>
#include <etrace.h>

/* 基础设施：寄存器/访存入口、字段提取和少量规范常量都放在文件开头。
 * 执行层只通过这些窄接口读写状态，后续扩指令不再到处散落位切片。 */
#define R(i) MUXDEF(CONFIG_RVE, gpr(i), cpu.gpr[(i)])
#define Mr vaddr_read
#define Mw vaddr_write

#define RV32_INT_MIN (-2147483647 - 1)

#define OPCODE(i) BITS(i, 6, 0)
#define RD(i)     BITS(i, 11, 7)
#define FUNCT3(i) BITS(i, 14, 12)
#define RS1(i)    BITS(i, 19, 15)
#define RS2(i)    BITS(i, 24, 20)
#define FUNCT7(i) BITS(i, 31, 25)

#define IMM_I(i) SEXT(BITS(i, 31, 20), 12)
#define IMM_U(i) (SEXT(BITS(i, 31, 12), 20) << 12)
#define IMM_S(i) ((SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7))
#define IMM_B(i) SEXT((BITS(i, 31, 31) << 12 | BITS(i, 7, 7) << 11 | \
                       BITS(i, 30, 25) << 5  | BITS(i, 11, 8) << 1), 13)
#define IMM_J(i) SEXT((BITS(i, 31, 31) << 20 | BITS(i, 19, 12) << 12 | \
                       BITS(i, 20, 20) << 11 | BITS(i, 30, 21) << 1), 21)

#define OPC_LOAD   0x03
#define OPC_MISC_MEM 0x0f
#define OPC_OP_IMM 0x13
#define OPC_AUIPC  0x17
#define OPC_STORE  0x23
#define OPC_OP     0x33
#define OPC_LUI    0x37
#define OPC_BRANCH 0x63
#define OPC_JALR   0x67
#define OPC_JAL    0x6f
#define OPC_SYSTEM 0x73

#define CSR_MSTATUS  0x300
#define CSR_MISA     0x301
#define CSR_MIE      0x304
#define CSR_MTVEC    0x305
#define CSR_MSCRATCH 0x340
#define CSR_MEPC     0x341
#define CSR_MCAUSE   0x342
#define CSR_MTVAL    0x343
#define CSR_MIP      0x344
#define CSR_MHARTID  0xf14

#define CAUSE_ILLEGAL_INST 2
#define CAUSE_ECALL_M      11

#define MSTATUS_MIE      (1u << 3)
#define MSTATUS_MPIE     (1u << 7)
#define MSTATUS_MPP_MASK (3u << 11)

#define OP_KEY(funct3, funct7) ((((funct7) & 0x7f) << 3) | ((funct3) & 0x7))
#define SHAMT5(value) ((value) & 0x1f)
#define BAD_DECODE() return false

static inline word_t rol32(word_t value, word_t shamt) {
  shamt &= 0x1f;
  uint32_t v = value;
  return shamt == 0 ? v : (word_t)((v << shamt) | (v >> (32 - shamt)));
}

static inline word_t ror32(word_t value, word_t shamt) {
  shamt &= 0x1f;
  uint32_t v = value;
  return shamt == 0 ? v : (word_t)((v >> shamt) | (v << (32 - shamt)));
}

static inline word_t clz32(word_t value) {
  uint32_t v = value;
  return v == 0 ? 32 : (word_t)__builtin_clz(v);
}

static inline word_t ctz32(word_t value) {
  uint32_t v = value;
  return v == 0 ? 32 : (word_t)__builtin_ctz(v);
}

static inline word_t cpop32(word_t value) {
  return (word_t)__builtin_popcount((uint32_t)value);
}

static inline word_t sext_b32(word_t value) {
  return SEXT(BITS(value, 7, 0), 8);
}

static inline word_t sext_h32(word_t value) {
  return SEXT(BITS(value, 15, 0), 16);
}

static inline word_t orc_b32(word_t value) {
  uint32_t v = value;
  uint32_t r = 0;
  for (int i = 0; i < 4; i++) {
    uint32_t b = (v >> (i * 8)) & 0xffu;
    if (b != 0) r |= 0xffu << (i * 8);
  }
  return r;
}

static inline word_t rev8_32(word_t value) {
  uint32_t v = value;
  return ((v & 0x000000ffu) << 24) |
         ((v & 0x0000ff00u) << 8) |
         ((v & 0x00ff0000u) >> 8) |
         ((v & 0xff000000u) >> 24);
}

static inline word_t clmul32(word_t src1, word_t src2) {
  uint32_t a = src1, b = src2, r = 0;
  for (int i = 0; i < 32; i++) {
    if ((b >> i) & 1u) r ^= a << i;
  }
  return r;
}

static inline word_t clmulh32(word_t src1, word_t src2) {
  uint32_t a = src1, b = src2, r = 0;
  for (int i = 1; i < 32; i++) {
    if ((b >> i) & 1u) r ^= a >> (32 - i);
  }
  return r;
}

static inline word_t clmulr32(word_t src1, word_t src2) {
  uint32_t a = src1, b = src2, r = 0;
  for (int i = 0; i < 32; i++) {
    if ((b >> i) & 1u) r ^= a >> (31 - i);
  }
  return r;
}

/* CSR 执行基础设施集中在这里。SYSTEM 分发只决定“是哪类系统指令”，
 * CSR 的读改写语义、misa 配置回显和 mepc 对齐规则都不散到主 switch 里。 */
static inline word_t csr_misa_value() {
  word_t misa = (1u << 30);
#ifdef CONFIG_RVE
  misa |= 1u << ('E' - 'A');
#else
  misa |= 1u << ('I' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_M
  misa |= 1u << ('M' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_B
  misa |= 1u << ('B' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_C
  misa |= 1u << ('C' - 'A');
#endif
  return misa;
}

static inline bool csr_read(uint32_t csr, word_t *value) {
  switch (csr) {
    case CSR_MSTATUS:  *value = cpu.csr.mstatus; return true;
    case CSR_MIE:      *value = cpu.csr.mie; return true;
    case CSR_MTVEC:    *value = cpu.csr.mtvec; return true;
    case CSR_MSCRATCH: *value = cpu.csr.mscratch; return true;
    case CSR_MEPC:     *value = cpu.csr.mepc; return true;
    case CSR_MCAUSE:   *value = cpu.csr.mcause; return true;
    case CSR_MTVAL:    *value = cpu.csr.mtval; return true;
    case CSR_MIP:      *value = cpu.csr.mip; return true;
    case CSR_MISA:     *value = csr_misa_value(); return true;
    case CSR_MHARTID:  *value = 0; return true;
    default: return false;
  }
}

static inline bool csr_write(uint32_t csr, word_t value) {
  word_t mepc_mask = MUXDEF(CONFIG_RISCV_EXT_C, ~0x1u, ~0x3u);
  switch (csr) {
    case CSR_MSTATUS:  cpu.csr.mstatus = value; return true;
    case CSR_MIE:      cpu.csr.mie = value; return true;
    case CSR_MTVEC:    cpu.csr.mtvec = value; return true;
    case CSR_MSCRATCH: cpu.csr.mscratch = value; return true;
    case CSR_MEPC:     cpu.csr.mepc = value & mepc_mask; return true;
    case CSR_MCAUSE:   cpu.csr.mcause = value; return true;
    case CSR_MTVAL:    cpu.csr.mtval = value; return true;
    case CSR_MIP:      cpu.csr.mip = value; return true;
    default: return false;
  }
}

static inline void csr_mret(Decode *s) {
  word_t mstatus = cpu.csr.mstatus;
  if (mstatus & MSTATUS_MPIE) cpu.csr.mstatus |= MSTATUS_MIE;
  else cpu.csr.mstatus &= ~MSTATUS_MIE;
  cpu.csr.mstatus |= MSTATUS_MPIE;
  cpu.csr.mstatus &= ~MSTATUS_MPP_MASK;
  s->dnpc = cpu.csr.mepc;
  etrace_log_mret(s->pc, s->dnpc, cpu.csr.mstatus);
}

static inline bool exec_csr(uint32_t inst, uint32_t funct3, int rd, int rs1) {
  uint32_t csr = BITS(inst, 31, 20);
  word_t old_val = 0;
  word_t new_val = 0;
  bool need_write = false;

  if (!csr_read(csr, &old_val)) return false;

  switch (funct3) {
    case 0x1: new_val = R(rs1); need_write = true; break;                 // csrrw
    case 0x2: new_val = old_val | R(rs1); need_write = (rs1 != 0); break;  // csrrs
    case 0x3: new_val = old_val & ~R(rs1); need_write = (rs1 != 0); break; // csrrc
    case 0x5: new_val = rs1; need_write = true; break;                    // csrrwi
    case 0x6: new_val = old_val | (word_t)rs1; need_write = (rs1 != 0); break;
    case 0x7: new_val = old_val & ~((word_t)rs1); need_write = (rs1 != 0); break;
    default: return false;
  }

  if (need_write && !csr_write(csr, new_val)) return false;
  R(rd) = old_val;
  return true;
}

/* RV32I 基础执行块：主干 ISA 按指令格式归类，直接 switch 到最终语义。
 * 这层是热路径，不使用表生成宏，读起来就是规范编码到行为的最短映射。 */
static inline bool exec_rv32i_op_imm(uint32_t inst, int rd, word_t src1) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  word_t imm = IMM_I(inst);

  switch (funct3) {
    case 0x0: R(rd) = src1 + imm; return true;                                // addi
    case 0x2: R(rd) = (sword_t)src1 < (sword_t)imm ? 1 : 0; return true;       // slti
    case 0x3: R(rd) = src1 < (word_t)imm ? 1 : 0; return true;                 // sltiu
    case 0x4: R(rd) = src1 ^ imm; return true;                                 // xori
    case 0x6: R(rd) = src1 | imm; return true;                                  // ori
    case 0x7: R(rd) = src1 & imm; return true;                                  // andi
    case 0x1:
      if (funct7 == 0x00) { R(rd) = src1 << SHAMT5(imm); return true; }         // slli
      break;
    case 0x5:
      if (funct7 == 0x00) { R(rd) = src1 >> SHAMT5(imm); return true; }         // srli
      if (funct7 == 0x20) { R(rd) = (sword_t)src1 >> SHAMT5(imm); return true; }// srai
      break;
  }

  return false;
}

static inline bool exec_rv32i_load(uint32_t funct3, int rd, word_t addr) {
  switch (funct3) {
    case 0x0: R(rd) = SEXT(Mr(addr, 1), 8); return true;  // lb
    case 0x1: R(rd) = SEXT(Mr(addr, 2), 16); return true; // lh
    case 0x2: R(rd) = Mr(addr, 4); return true;           // lw
    case 0x4: R(rd) = Mr(addr, 1); return true;           // lbu
    case 0x5: R(rd) = Mr(addr, 2); return true;           // lhu
    default: return false;
  }
}

static inline bool exec_rv32i_store(uint32_t funct3, word_t addr, word_t data) {
  switch (funct3) {
    case 0x0: Mw(addr, 1, data); return true; // sb
    case 0x1: Mw(addr, 2, data); return true; // sh
    case 0x2: Mw(addr, 4, data); return true; // sw
    default: return false;
  }
}

static inline bool exec_rv32i_branch(Decode *s, uint32_t funct3, word_t src1, word_t src2, word_t imm) {
  switch (funct3) {
    case 0x0: if (src1 == src2) s->dnpc = s->pc + imm; return true;                 // beq
    case 0x1: if (src1 != src2) s->dnpc = s->pc + imm; return true;                 // bne
    case 0x4: if ((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm; return true; // blt
    case 0x5: if ((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm; return true;// bge
    case 0x6: if (src1 < src2) s->dnpc = s->pc + imm; return true;                  // bltu
    case 0x7: if (src1 >= src2) s->dnpc = s->pc + imm; return true;                 // bgeu
    default: return false;
  }
}

static inline bool exec_rv32i_op(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x00): R(rd) = src1 + src2; return true;                             // add
    case OP_KEY(0x0, 0x20): R(rd) = src1 - src2; return true;                             // sub
    case OP_KEY(0x1, 0x00): R(rd) = src1 << SHAMT5(src2); return true;                    // sll
    case OP_KEY(0x2, 0x00): R(rd) = (sword_t)src1 < (sword_t)src2 ? 1 : 0; return true;   // slt
    case OP_KEY(0x3, 0x00): R(rd) = src1 < src2 ? 1 : 0; return true;                     // sltu
    case OP_KEY(0x4, 0x00): R(rd) = src1 ^ src2; return true;                             // xor
    case OP_KEY(0x5, 0x00): R(rd) = src1 >> SHAMT5(src2); return true;                    // srl
    case OP_KEY(0x5, 0x20): R(rd) = (sword_t)src1 >> SHAMT5(src2); return true;           // sra
    case OP_KEY(0x6, 0x00): R(rd) = src1 | src2; return true;                             // or
    case OP_KEY(0x7, 0x00): R(rd) = src1 & src2; return true;                             // and
    default: return false;
  }
}

static inline bool exec_system(Decode *s, uint32_t inst, uint32_t funct3, int rd, int rs1) {
  if (funct3 != 0) return exec_csr(inst, funct3, rd, rs1);

  switch (inst) {
    case 0x00000073: // ecall
      s->dnpc = isa_raise_intr(CAUSE_ECALL_M, s->pc);
      return true;
    case 0x00100073: // ebreak
      NEMUTRAP(s->pc, R(10));
      return true;
    case 0x30200073: // mret
      csr_mret(s);
      return true;
    case 0x10500073: // wfi
      return true;
    default:
      return false;
  }
}

static inline bool exec_misc_mem(uint32_t funct3) {
  switch (funct3) {
    case 0x0: // fence
      return true;
    case 0x1: // fence.i
      // NEMU 的 cache 是透明模拟层；fence.i 时写回 DCache 并失效 ICache，保证自修改代码后能重新取指。
      IFDEF(CONFIG_CACHE, cache_flush_all());
      return true;
    default:
      return false;
  }
}

#ifdef CONFIG_RISCV_EXT_M
/* RV32M 扩展：乘除相关编码集中在一个入口。关闭 Kconfig 后整组编码自然非法。 */
static inline bool exec_rv32m_op(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (funct7 != 0x01) return false;

  switch (funct3) {
    case 0x0: { // mul
      int64_t prod = (int64_t)(sword_t)src1 * (int64_t)(sword_t)src2;
      R(rd) = (word_t)prod;
      return true;
    }
    case 0x1: { // mulh
      int64_t prod = (int64_t)(sword_t)src1 * (int64_t)(sword_t)src2;
      R(rd) = (word_t)(prod >> 32);
      return true;
    }
    case 0x2: { // mulhsu
      int64_t prod = (int64_t)(sword_t)src1 * (int64_t)(uint32_t)src2;
      R(rd) = (word_t)(prod >> 32);
      return true;
    }
    case 0x3: { // mulhu
      uint64_t prod = (uint64_t)(uint32_t)src1 * (uint64_t)(uint32_t)src2;
      R(rd) = (word_t)(prod >> 32);
      return true;
    }
    case 0x4: // div
      if (src2 == 0) R(rd) = (word_t)-1;
      else if ((sword_t)src1 == RV32_INT_MIN && (sword_t)src2 == -1) R(rd) = (word_t)RV32_INT_MIN;
      else R(rd) = (sword_t)src1 / (sword_t)src2;
      return true;
    case 0x5: // divu
      R(rd) = (src2 == 0) ? (word_t)0xffffffffu : src1 / src2;
      return true;
    case 0x6: // rem
      if (src2 == 0) R(rd) = src1;
      else if ((sword_t)src1 == RV32_INT_MIN && (sword_t)src2 == -1) R(rd) = 0;
      else R(rd) = (sword_t)src1 % (sword_t)src2;
      return true;
    case 0x7: // remu
      R(rd) = (src2 == 0) ? src1 : src1 % src2;
      return true;
    default:
      return false;
  }
}
#endif

#ifdef CONFIG_RISCV_EXT_B
/* Zba/Zbb/Zbc/Zbs 扩展：所有 bitmanip 逻辑集中在这里。
 * 主译码只在 RV32I 没命中时进入本块，常见基础指令不为扩展表付额外层次。 */
static inline bool exec_zb_op_imm(uint32_t inst, int rd, word_t src1) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t imm5 = BITS(inst, 24, 20);

  if (funct3 == 0x1) {
    switch (funct7) {
      case 0x14: R(rd) = src1 | (1u << imm5); return true;       // bseti
      case 0x24: R(rd) = src1 & ~(1u << imm5); return true;      // bclri
      case 0x34: R(rd) = src1 ^ (1u << imm5); return true;       // binvi
      case 0x30:
        switch (imm5) {
          case 0x00: R(rd) = clz32(src1); return true;           // clz
          case 0x01: R(rd) = ctz32(src1); return true;           // ctz
          case 0x02: R(rd) = cpop32(src1); return true;          // cpop
          case 0x04: R(rd) = sext_b32(src1); return true;        // sext.b
          case 0x05: R(rd) = sext_h32(src1); return true;        // sext.h
          default: return false;
        }
      default:
        return false;
    }
  }

  if (funct3 == 0x5) {
    switch (funct7) {
      case 0x30: R(rd) = ror32(src1, imm5); return true;         // rori
      case 0x24: R(rd) = (src1 >> imm5) & 1u; return true;       // bexti
      case 0x14:
        if (imm5 != 0x07) return false;
        R(rd) = orc_b32(src1);                                  // orc.b
        return true;
      case 0x34:
        if (imm5 != 0x18) return false;
        R(rd) = rev8_32(src1);                                  // rev8
        return true;
      default:
        return false;
    }
  }

  return false;
}

static inline bool exec_zb_op(uint32_t funct3, uint32_t funct7, int rd, int rs2, word_t src1, word_t src2) {
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x2, 0x10): R(rd) = (src1 << 1) + src2; return true; // sh1add
    case OP_KEY(0x4, 0x10): R(rd) = (src1 << 2) + src2; return true; // sh2add
    case OP_KEY(0x6, 0x10): R(rd) = (src1 << 3) + src2; return true; // sh3add
    case OP_KEY(0x7, 0x20): R(rd) = src1 & ~src2; return true;       // andn
    case OP_KEY(0x6, 0x20): R(rd) = src1 | ~src2; return true;       // orn
    case OP_KEY(0x4, 0x20): R(rd) = ~(src1 ^ src2); return true;     // xnor
    case OP_KEY(0x1, 0x30): R(rd) = rol32(src1, src2); return true;  // rol
    case OP_KEY(0x5, 0x30): R(rd) = ror32(src1, src2); return true;  // ror
    case OP_KEY(0x4, 0x05): R(rd) = ((sword_t)src1 < (sword_t)src2) ? src1 : src2; return true; // min
    case OP_KEY(0x5, 0x05): R(rd) = (src1 < src2) ? src1 : src2; return true;                   // minu
    case OP_KEY(0x6, 0x05): R(rd) = ((sword_t)src1 > (sword_t)src2) ? src1 : src2; return true; // max
    case OP_KEY(0x7, 0x05): R(rd) = (src1 > src2) ? src1 : src2; return true;                   // maxu
    case OP_KEY(0x1, 0x05): R(rd) = clmul32(src1, src2); return true;  // clmul
    case OP_KEY(0x2, 0x05): R(rd) = clmulr32(src1, src2); return true; // clmulr
    case OP_KEY(0x3, 0x05): R(rd) = clmulh32(src1, src2); return true; // clmulh
    case OP_KEY(0x1, 0x14): R(rd) = src1 | (1u << SHAMT5(src2)); return true;      // bset
    case OP_KEY(0x1, 0x24): R(rd) = src1 & ~(1u << SHAMT5(src2)); return true;     // bclr
    case OP_KEY(0x5, 0x24): R(rd) = (src1 >> SHAMT5(src2)) & 1u; return true;      // bext
    case OP_KEY(0x1, 0x34): R(rd) = src1 ^ (1u << SHAMT5(src2)); return true;      // binv
    case OP_KEY(0x4, 0x04):
      if (rs2 != 0) return false;
      R(rd) = src1 & 0xffffu;                                      // zext.h
      return true;
    default:
      return false;
  }
}
#endif

#ifdef CONFIG_RISCV_EXT_C
/* RV32C 扩展：可变长取指只负责拿到 16/32 位原始指令，压缩语义全部收口在本块。 */
#define C_FUNCT3(i) BITS(i, 15, 13)
#define C_RD(i)     (8 + BITS(i, 4, 2))
#define C_RS1(i)    (8 + BITS(i, 9, 7))
#define C_RS2(i)    (8 + BITS(i, 4, 2))

static inline word_t c_imm_addi4spn(uint16_t inst) {
  return (BITS(inst, 10, 7) << 6) |
         (BITS(inst, 12, 11) << 4) |
         (BITS(inst, 5, 5) << 3) |
         (BITS(inst, 6, 6) << 2);
}

static inline word_t c_imm_lw_sw(uint16_t inst) {
  return (BITS(inst, 5, 5) << 6) |
         (BITS(inst, 12, 10) << 3) |
         (BITS(inst, 6, 6) << 2);
}

static inline word_t c_imm_6(uint16_t inst) {
  return SEXT((BITS(inst, 12, 12) << 5) | BITS(inst, 6, 2), 6);
}

static inline word_t c_imm_j(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 11) |
                 (BITS(inst, 11, 11) << 4) |
                 (BITS(inst, 10, 9) << 8) |
                 (BITS(inst, 8, 8) << 10) |
                 (BITS(inst, 7, 7) << 6) |
                 (BITS(inst, 6, 6) << 7) |
                 (BITS(inst, 5, 3) << 1) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 12);
}

static inline word_t c_imm_addi16sp(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 9) |
                 (BITS(inst, 6, 6) << 4) |
                 (BITS(inst, 5, 5) << 6) |
                 (BITS(inst, 4, 3) << 7) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 10);
}

static inline word_t c_imm_b(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 8) |
                 (BITS(inst, 11, 10) << 3) |
                 (BITS(inst, 6, 5) << 6) |
                 (BITS(inst, 4, 3) << 1) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 9);
}

static inline word_t c_imm_lwsp(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) |
         (BITS(inst, 6, 4) << 2) |
         (BITS(inst, 3, 2) << 6);
}

static inline word_t c_imm_swsp(uint16_t inst) {
  return (BITS(inst, 8, 7) << 6) |
         (BITS(inst, 12, 9) << 2);
}

static inline word_t c_shamt(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) | BITS(inst, 6, 2);
}

static inline bool exec_rv32c(Decode *s, uint16_t inst) {
  uint32_t funct3 = C_FUNCT3(inst);
  uint32_t rd = BITS(inst, 11, 7);
  uint32_t rs2 = BITS(inst, 6, 2);

  switch (BITS(inst, 1, 0)) {
    case 0x0:
      switch (funct3) {
        case 0x0: { // c.addi4spn
          word_t imm = c_imm_addi4spn(inst);
          if (imm == 0) BAD_DECODE();
          R(C_RD(inst)) = R(2) + imm;
          return true;
        }
        case 0x2: // c.lw
          R(C_RD(inst)) = Mr(R(C_RS1(inst)) + c_imm_lw_sw(inst), 4);
          return true;
        case 0x6: // c.sw
          Mw(R(C_RS1(inst)) + c_imm_lw_sw(inst), 4, R(C_RS2(inst)));
          return true;
        default:
          BAD_DECODE();
      }
    case 0x1:
      switch (funct3) {
        case 0x0: // c.addi / c.nop
          R(rd) = R(rd) + c_imm_6(inst);
          return true;
        case 0x1: // c.jal
          R(1) = s->pc + 2;
          s->dnpc = s->pc + c_imm_j(inst);
          IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, s->dnpc));
          return true;
        case 0x2: // c.li
          if (rd != 0) R(rd) = c_imm_6(inst);
          return true;
        case 0x3:
          if (rd == 2) { // c.addi16sp
            word_t imm = c_imm_addi16sp(inst);
            if (imm == 0) BAD_DECODE();
            R(2) = R(2) + imm;
          } else { // c.lui
            word_t imm = c_imm_6(inst);
            if (rd == 0 || imm == 0) BAD_DECODE();
            R(rd) = imm << 12;
          }
          return true;
        case 0x4: {
          uint32_t rs1p = C_RS1(inst);
          uint32_t rs2p = C_RS2(inst);
          switch (BITS(inst, 11, 10)) {
            case 0x0: // c.srli
              if (BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = R(rs1p) >> c_shamt(inst);
              return true;
            case 0x1: // c.srai
              if (BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = (sword_t)R(rs1p) >> c_shamt(inst);
              return true;
            case 0x2: // c.andi
              R(rs1p) = R(rs1p) & c_imm_6(inst);
              return true;
            case 0x3:
              if (BITS(inst, 12, 12)) BAD_DECODE();
              switch (BITS(inst, 6, 5)) {
                case 0x0: R(rs1p) = R(rs1p) - R(rs2p); return true; // c.sub
                case 0x1: R(rs1p) = R(rs1p) ^ R(rs2p); return true; // c.xor
                case 0x2: R(rs1p) = R(rs1p) | R(rs2p); return true; // c.or
                case 0x3: R(rs1p) = R(rs1p) & R(rs2p); return true; // c.and
                default: BAD_DECODE();
              }
            default:
              BAD_DECODE();
          }
        }
        case 0x5: // c.j
          s->dnpc = s->pc + c_imm_j(inst);
          return true;
        case 0x6: // c.beqz
          if (R(C_RS1(inst)) == 0) s->dnpc = s->pc + c_imm_b(inst);
          return true;
        case 0x7: // c.bnez
          if (R(C_RS1(inst)) != 0) s->dnpc = s->pc + c_imm_b(inst);
          return true;
        default:
          BAD_DECODE();
      }
    case 0x2:
      switch (funct3) {
        case 0x0: // c.slli
          if (BITS(inst, 12, 12)) BAD_DECODE();
          R(rd) = R(rd) << c_shamt(inst);
          return true;
        case 0x2: // c.lwsp
          if (rd == 0) BAD_DECODE();
          R(rd) = Mr(R(2) + c_imm_lwsp(inst), 4);
          return true;
        case 0x4:
          if (BITS(inst, 12, 12) == 0) {
            if (rs2 == 0) { // c.jr
              if (rd == 0) BAD_DECODE();
              s->dnpc = R(rd) & ~1u;
              IFDEF(CONFIG_FTRACE, if (rd == 1) ftrace_log(-1, s->pc, s->dnpc));
            } else if (rd != 0) { // c.mv
              R(rd) = R(rs2);
            }
          } else {
            if (rs2 == 0) {
              if (rd == 0) {
                NEMUTRAP(s->pc, R(10)); // c.ebreak
              } else { // c.jalr
                word_t target = R(rd) & ~1u;
                R(1) = s->pc + 2;
                s->dnpc = target;
                IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, target));
              }
            } else if (rd != 0) { // c.add
              R(rd) = R(rd) + R(rs2);
            }
          }
          return true;
        case 0x6: // c.swsp
          Mw(R(2) + c_imm_swsp(inst), 4, R(rs2));
          return true;
        default:
          BAD_DECODE();
      }
    default:
      BAD_DECODE();
  }
}
#endif

static int decode_exec(Decode *s) {
  s->dnpc = s->snpc;
  uint32_t inst = s->isa.inst;

#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3) != 0x3) {
    if (!exec_rv32c(s, inst & 0xffffu)) goto invalid;
    R(0) = 0;
    return 0;
  }
#endif

  uint32_t opcode = OPCODE(inst);
  uint32_t funct3 = FUNCT3(inst);
  int rd = RD(inst);
  int rs1 = RS1(inst);
  int rs2 = RS2(inst);

  switch (opcode) {
    case OPC_OP_IMM: {
      word_t src1 = R(rs1);
      if (!exec_rv32i_op_imm(inst, rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
        if (!exec_zb_op_imm(inst, rd, src1)) goto invalid;
#else
        goto invalid;
#endif
      }
      break;
    }
    case OPC_LOAD: {
      word_t addr = R(rs1) + IMM_I(inst);
      if (!exec_rv32i_load(funct3, rd, addr)) goto invalid;
      break;
    }
    case OPC_MISC_MEM:
      if (!exec_misc_mem(funct3)) goto invalid;
      break;
    case OPC_STORE: {
      word_t addr = R(rs1) + IMM_S(inst);
      if (!exec_rv32i_store(funct3, addr, R(rs2))) goto invalid;
      break;
    }
    case OPC_OP: {
      uint32_t funct7 = FUNCT7(inst);
      word_t src1 = R(rs1);
      word_t src2 = R(rs2);
      if (exec_rv32i_op(funct3, funct7, rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rv32m_op(funct3, funct7, rd, src1, src2)) break;
#endif
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op(funct3, funct7, rd, rs2, src1, src2)) break;
#endif
      goto invalid;
    }
    case OPC_BRANCH:
      if (!exec_rv32i_branch(s, funct3, R(rs1), R(rs2), IMM_B(inst))) goto invalid;
      break;
    case OPC_JALR: {
      if (funct3 != 0x0) goto invalid;
      word_t target = (R(rs1) + IMM_I(inst)) & ~1u;
      R(rd) = s->pc + 4;
      s->dnpc = target;
      IFDEF(CONFIG_FTRACE, {
        if (rd == 0 && rs1 == 1) ftrace_log(-1, s->pc, target);
        else if (rd == 1 || rd == 5) ftrace_log(1, s->pc, target);
      })
      break;
    }
    case OPC_JAL:
      R(rd) = s->pc + 4;
      s->dnpc = s->pc + IMM_J(inst);
      IFDEF(CONFIG_FTRACE, if (rd == 1 || rd == 5) ftrace_log(1, s->pc, s->dnpc));
      break;
    case OPC_LUI:
      R(rd) = IMM_U(inst);
      break;
    case OPC_AUIPC:
      R(rd) = s->pc + IMM_U(inst);
      break;
    case OPC_SYSTEM:
      if (!exec_system(s, inst, funct3, rd, rs1)) goto invalid;
      break;
    default:
      goto invalid;
  }

  R(0) = 0;
  return 0;

invalid:
  s->dnpc = isa_raise_intr_with_tval(CAUSE_ILLEGAL_INST, s->pc, inst);
  R(0) = 0;
  return 0;
}

int isa_exec_once(Decode *s) {
#ifdef CONFIG_RISCV_EXT_C
  uint32_t inst = inst_fetch(&s->snpc, 2);
  if ((inst & 0x3) == 0x3) {
    inst |= inst_fetch(&s->snpc, 2) << 16;
  }
  s->isa.inst = inst;
#else
  s->isa.inst = inst_fetch(&s->snpc, 4);
#endif
  return decode_exec(s);
}

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
#include <ftrace.h>

#define R(i) MUXDEF(CONFIG_RVE, gpr(i), cpu.gpr[(i)])
#define Mr vaddr_read
#define Mw vaddr_write

#define MIN_INT  -2147483648//RV32

// 把常用字段先提成宏，后面按 opcode/funct 分层分发时可以少做重复位切片。
// 这样既减少热路径里的样板代码，也让常见指令能够更快落到对应分支。
#define OPCODE(i) BITS(i, 6, 0)
#define RD(i)  BITS(i, 11, 7)
#define RS1(i) BITS(i, 19, 15)
#define RS2(i) BITS(i, 24, 20)
#define FUNCT3(i) BITS(i, 14, 12)
#define FUNCT7(i) BITS(i, 31, 25)

#define IMM_I(i) SEXT(BITS(i, 31, 20), 12)
#define IMM_U(i) (SEXT(BITS(i, 31, 12), 20) << 12)
#define IMM_S(i) ((SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7))
#define IMM_J(i) SEXT((BITS(i, 31, 31) << 20 | BITS(i, 19, 12) << 12 | BITS(i, 20, 20) << 11 | BITS(i, 30, 21) << 1), 21)
#define IMM_B(i) SEXT((BITS(i, 31, 31) << 12 | BITS(i, 7, 7) << 11 | BITS(i, 30, 25) << 5 | BITS(i, 11, 8) << 1), 13)

#define OPC_LOAD   0x03
#define OPC_OP_IMM 0x13
#define OPC_AUIPC  0x17
#define OPC_STORE  0x23
#define OPC_OP     0x33
#define OPC_LUI    0x37
#define OPC_BRANCH 0x63
#define OPC_JALR   0x67
#define OPC_JAL    0x6f
#define OPC_SYSTEM 0x73

#define INVALID_INST() goto invalid

#define OPCODE_CASE(code, prepare, body) \
  case code: { \
    prepare; \
    body; \
    break; \
  }

#define FUNCT3_CASE(code, body) \
  case code: { \
    body; \
    break; \
  }

#define FUNCT3_CASE_F7(code, body) \
  case code: { \
    switch (funct7) { \
      body \
      default: INVALID_INST(); \
    } \
    break; \
  }

#define FUNCT7_CASE(code, body) \
  case code: { \
    body; \
    break; \
  }

#define OP_CASE_KEY(funct3, funct7) ((((funct7) & 0x7f) << 3) | ((funct3) & 0x7))
#define OP_CASE(code3, code7, body) \
  case OP_CASE_KEY(code3, code7): { \
    body; \
    break; \
  }

#define GEN_FUNCT3_CASE(code, body) FUNCT3_CASE(code, body)
#define GEN_OP_CASE(code3, code7, body) OP_CASE(code3, code7, body)

// 把每一类指令写成 X-macro 表项，查看时可以直接把“编码 -> 行为”对齐着读。
// 这样既去掉了大片 if-else 嵌套，也保留了按 opcode/funct 分层命中的热路径结构。
#define OPIMM_DIRECT_CASES(_) \
  _(0x0, R(rd) = src1 + imm) /* addi */ \
  _(0x7, R(rd) = src1 & imm) /* andi */ \
  _(0x6, R(rd) = src1 | imm) /* ori */ \
  _(0x4, R(rd) = src1 ^ imm) /* xori */ \
  _(0x2, R(rd) = (sword_t)src1 < (sword_t)imm ? 1 : 0) /* slti */ \
  _(0x3, R(rd) = src1 < (word_t)imm ? 1 : 0) /* sltiu */

#define LOAD_CASES(_) \
  _(0x2, R(rd) = Mr(src1 + imm, 4)) /* lw */ \
  _(0x0, R(rd) = SEXT(Mr(src1 + imm, 1), 8)) /* lb */ \
  _(0x1, R(rd) = SEXT(Mr(src1 + imm, 2), 16)) /* lh */ \
  _(0x4, R(rd) = Mr(src1 + imm, 1)) /* lbu */ \
  _(0x5, R(rd) = Mr(src1 + imm, 2)) /* lhu */

#define STORE_CASES(_) \
  _(0x2, Mw(src1 + imm, 4, src2)) /* sw */ \
  _(0x0, Mw(src1 + imm, 1, src2)) /* sb */ \
  _(0x1, Mw(src1 + imm, 2, src2)) /* sh */

#define BRANCH_CASES(_) \
  _(0x0, if (src1 == src2) s->dnpc = s->pc + imm) /* beq */ \
  _(0x1, if (src1 != src2) s->dnpc = s->pc + imm) /* bne */ \
  _(0x4, if ((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm) /* blt */ \
  _(0x5, if ((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm) /* bge */ \
  _(0x6, if (src1 < src2) s->dnpc = s->pc + imm) /* bltu */ \
  _(0x7, if (src1 >= src2) s->dnpc = s->pc + imm) /* bgeu */

#define OP_CASES(_) \
  _(0x0, 0x00, R(rd) = src1 + src2) /* add */ \
  _(0x0, 0x20, R(rd) = src1 - src2) /* sub */ \
  _(0x0, 0x01, R(rd) = (sword_t)src1 * (sword_t)src2) /* mul */ \
  _(0x7, 0x00, R(rd) = src1 & src2) /* and */ \
  _(0x7, 0x01, R(rd) = (src2 == 0) ? src1 : src1 % src2) /* remu */ \
  _(0x6, 0x00, R(rd) = src1 | src2) /* or */ \
  _(0x6, 0x01, if (src2 == 0) R(rd) = src1; else if ((sword_t)src1 == MIN_INT && (sword_t)src2 == -1) R(rd) = 0; else R(rd) = (sword_t)src1 % (sword_t)src2) /* rem */ \
  _(0x4, 0x00, R(rd) = src1 ^ src2) /* xor */ \
  _(0x4, 0x01, if (src2 == 0) R(rd) = -1; else if ((sword_t)src1 == MIN_INT && (sword_t)src2 == -1) R(rd) = (word_t)MIN_INT; else R(rd) = (sword_t)src1 / (sword_t)src2) /* div */ \
  _(0x1, 0x00, R(rd) = src1 << (src2 & 0x1f)) /* sll */ \
  _(0x1, 0x01, R(rd) = (word_t)(((int64_t)(sword_t)src1 * (int64_t)(sword_t)src2) >> 32)) /* mulh */ \
  _(0x5, 0x00, R(rd) = src1 >> (src2 & 0x1f)) /* srl */ \
  _(0x5, 0x20, R(rd) = (sword_t)src1 >> (src2 & 0x1f)) /* sra */ \
  _(0x5, 0x01, R(rd) = (src2 == 0) ? 0xffffffff : src1 / src2) /* divu */ \
  _(0x2, 0x00, R(rd) = (sword_t)src1 < (sword_t)src2 ? 1 : 0) /* slt */ \
  _(0x3, 0x00, R(rd) = src1 < src2 ? 1 : 0) /* sltu */ \
  _(0x3, 0x01, R(rd) = (word_t)(((uint64_t)src1 * (uint64_t)src2) >> 32)) /* mulhu */



static int decode_exec(Decode *s) {
  //snpc：本条指令的下一条指令，即顺序执行的下一个PC，通常是PC+4，
  //dnpc：本次执行后实际要跳转到的PC，即真正执行CPU的下一个PC
  //对于跳转、分支、异常等指令，dnpc会被设置为跳转目标地址或异常入口
  s->dnpc = s->snpc;

  // 这里从“线性穷举所有 INSTPAT”改成“先按 opcode，再按 funct3/funct7”分层分发。
  // 目的就是把最常见的整型、访存、分支类指令提前命中，缩短平均译码路径。
  uint32_t inst = s->isa.inst;
  uint32_t opcode = OPCODE(inst);
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  int rd = RD(inst);
  int rs1 = RS1(inst);
  int rs2 = RS2(inst);
  word_t src1 = 0, src2 = 0, imm = 0;

  // 这里继续保留“先按 opcode，再按 funct3/funct7”分层命中。
  // 只是把分支主体改成宏表项，方便把一整类指令横向对照着看。
  switch (opcode) {
    // 常见整型立即数指令被写成表项后，新增或检查单条指令时不需要翻嵌套 if-else。
    // 同时只有 slli/srli/srai 这些真正依赖 funct7 的指令才会再进下一层 switch。
    OPCODE_CASE(OPC_OP_IMM,
      src1 = R(rs1);
      imm = IMM_I(inst),
      switch (funct3) {
        OPIMM_DIRECT_CASES(GEN_FUNCT3_CASE)
        FUNCT3_CASE_F7(0x1,
          FUNCT7_CASE(0x00, R(rd) = src1 << (imm & 0x1f))
        )
        FUNCT3_CASE_F7(0x5,
          FUNCT7_CASE(0x00, R(rd) = src1 >> (imm & 0x1f))
          FUNCT7_CASE(0x20, R(rd) = (sword_t)src1 >> (imm & 0x1f))
        )
        default: INVALID_INST();
      }
    )
    OPCODE_CASE(OPC_LOAD,
      src1 = R(rs1);
      imm = IMM_I(inst),
      switch (funct3) {
        LOAD_CASES(GEN_FUNCT3_CASE)
        default: INVALID_INST();
      }
    )
    OPCODE_CASE(OPC_STORE,
      src1 = R(rs1);
      src2 = R(rs2);
      imm = IMM_S(inst),
      switch (funct3) {
        STORE_CASES(GEN_FUNCT3_CASE)
        default: INVALID_INST();
      }
    )
    // OP 类最容易因为 funct3/funct7 组合变多而失去可读性。
    // 这里把二者压成一个组合 key 后，每条 R-type/M 扩展指令都能稳定占一行表项。
    OPCODE_CASE(OPC_OP,
      src1 = R(rs1);
      src2 = R(rs2),
      switch (OP_CASE_KEY(funct3, funct7)) {
        OP_CASES(GEN_OP_CASE)
        default: INVALID_INST();
      }
    )
    OPCODE_CASE(OPC_BRANCH,
      src1 = R(rs1);
      src2 = R(rs2);
      imm = IMM_B(inst),
      switch (funct3) {
        BRANCH_CASES(GEN_FUNCT3_CASE)
        default: INVALID_INST();
      }
    )
    OPCODE_CASE(OPC_JALR,
      ((void)0),
      if (funct3 != 0x0) INVALID_INST();
      src1 = R(rs1);
      imm = IMM_I(inst);
      R(rd) = s->pc + 4;
      uint32_t target = (src1 + imm) & ~1;
      s->dnpc = target;
      IFDEF(CONFIG_FTRACE, {
        if (rd == 0 && rs1 == 1) ftrace_log(-1, s->pc, target); // ret
        else if (rd == 1 || rd == 5) ftrace_log(1, s->pc, target); // call
      })
    )
    OPCODE_CASE(OPC_JAL,
      ((void)0),
      imm = IMM_J(inst);
      R(rd) = s->pc + 4;
      s->dnpc = s->pc + imm;
      IFDEF(CONFIG_FTRACE, if (rd == 1 || rd == 5) { ftrace_log(1, s->pc, s->dnpc); })
    )
    OPCODE_CASE(OPC_LUI,
      ((void)0),
      R(rd) = IMM_U(inst)
    )
    OPCODE_CASE(OPC_AUIPC,
      ((void)0),
      R(rd) = s->pc + IMM_U(inst)
    )
    OPCODE_CASE(OPC_SYSTEM,
      ((void)0),
      if (inst == 0x00100073) NEMUTRAP(s->pc, R(10)); // ebreak, R(10) is $a0
      else INVALID_INST();
    )
    default: INVALID_INST();
  }

  R(0) = 0; // reset $zero to 0

  return 0;

invalid:
  // 保留统一的非法指令出口，保证分层分发后出错语义仍和原先一致。
  INV(s->pc);
  R(0) = 0;
  return 0;
}

/* typedef struct Decode {
  vaddr_t pc;
  vaddr_t snpc; // static next pc
  vaddr_t dnpc; // dynamic next pc
  ISADecodeInfo isa;
  IFDEF(CONFIG_ITRACE, char logbuf[128]);
} Decode;
 */

/* // decode
typedef struct {
  uint32_t inst;
} MUXDEF(CONFIG_RV64, riscv64_ISADecodeInfo, riscv32_ISADecodeInfo); */

int isa_exec_once(Decode *s) {
  s->isa.inst = inst_fetch(&s->snpc, 4);
  return decode_exec(s);
}

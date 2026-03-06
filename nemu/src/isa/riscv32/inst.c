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

#define R(i) gpr(i)
#define Mr vaddr_read
#define Mw vaddr_write

#define MIN_INT  -2147483648//RV32

enum {
  TYPE_I, TYPE_U, TYPE_S, TYPE_J, TYPE_B, TYPE_R,
  TYPE_N, // none
};

//immI()：取I型立即数字段i[31:20]，符号拓展到32位
//immU(): 取U型立即数字段i[31:12]，符号拓展后左移12
//immS()：取S型立即数字段i[31:25]和i[11:7]拼接，并符号拓展
#define src1R() do { *src1 = R(rs1); } while (0)
#define src2R() do { *src2 = R(rs2); } while (0)
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)
#define immJ() do { *imm = SEXT((BITS(i, 31, 31) << 20 | BITS(i, 19, 12) << 12 | BITS(i, 20, 20) << 11 | BITS(i, 30, 21) << 1), 21); } while(0)
#define immB() do { *imm = SEXT((BITS(i, 31, 31) << 12 | BITS(i, 7, 7) << 11 | BITS(i, 30, 25) << 5 | BITS(i, 11, 8) << 1), 13); } while(0)


static void decode_operand(Decode *s, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = s->isa.inst;
  int rs1 = BITS(i, 19, 15);
  int rs2 = BITS(i, 24, 20);
  *rd     = BITS(i, 11, 7);
  switch (type) {
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_J: src1R();          immJ(); break;
    case TYPE_B: src1R(); src2R(); immB(); break;
    case TYPE_R: src1R(); src2R();         break;
    //inv
    case TYPE_N: break;
    default: panic("unsupported type = %d", type);
  }
}

static int decode_exec(Decode *s) {
  //snpc：本条指令的下一条指令，即顺序执行的下一个PC，通常是PC+4，
  //dnpc：本次执行后实际要跳转到的PC，即真正执行CPU的下一个PC
  //对于跳转、分支、异常等指令，dnpc会被设置为跳转目标地址或异常入口
  s->dnpc = s->snpc;

//s->isa.inst已经在inst_fetch中被赋值当前正在译码/执行那条指令的32位机器码
#define INSTPAT_INST(s) ((s)->isa.inst)
#define INSTPAT_MATCH(s, name, type, ... /* execute body */ ) { \
  int rd = 0; \
  word_t src1 = 0, src2 = 0, imm = 0; \
  decode_operand(s, &rd, &src1, &src2, &imm, concat(TYPE_, type)); \
  __VA_ARGS__ ; \
}
  //INSTPAT_START：打开一个块，定义局部变量__instpat_end，保存标签地址&&__instpat_end_<name>，它不会自己关掉
  INSTPAT_START();
  //INSTPAT(模式字符串， 指令名词， 指令类型，指令执行操作)
  //指令名词再代码中仅当注释使用，不参与宏展开
  //指令类型用于后续译码过程
  //指令执行操作通过C代码来模拟指令执行的真正行为
  //为什么此处要用src1而不是R(rs1)：
  //1.解耦译码和执行：将译码和执行分开，在执行阶段就不需要关系src1从哪里读出来的
  //2.安全性与副作用管理：当目的寄存器和源寄存器一样的时候，使用快照保留原值避免出错
  //3.支持由不同来源构成的操作数
  //4.性能优化
  INSTPAT("??????? ????? ????? 000 ????? 00100 11", addi  , I, R(rd) = src1 + imm);
  INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc  , U, R(rd) = s->pc + imm);
  INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, R(rd) = Mr(src1 + imm, 1));
  INSTPAT("??????? ????? ????? 010 ????? 00000 11", lw    , I, R(rd) = Mr(src1 + imm, 4));
  INSTPAT("??????? ????? ????? 000 ????? 01000 11", sb     , S, Mw(src1 + imm, 1, src2));
  INSTPAT("??????? ????? ????? ??? ????? 11011 11", jal    , J,
    R(rd) = (s->pc + 4);
    s->dnpc = (s->pc) + imm; 
    // ftrace:rd == 1(ra) 或者rd(t0)视为call
    IFDEF(CONFIG_FTRACE, if(rd == 1 || rd == 5) {ftrace_log(1, s->pc, s->dnpc);})
  );
  INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , N, NEMUTRAP(s->pc, R(10))); // R(10) is $a0
  INSTPAT("??????? ????? ????? 010 ????? 01000 11", sw    , S, Mw(src1 + imm, 4, src2));
  INSTPAT("??????? ????? ????? 000 ????? 11001 11", jalr    , I, 
    R(rd) = s->pc + 4;
    uint32_t _target = (src1 + imm) & ~1;
    s->dnpc = _target;
    //ftrace： rd == 0 且rs1=ra -> ret：否则rd == 1 或者 rd == 5 -> call
    IFDEF(CONFIG_FTRACE, {
      uint32_t _inst = s->isa.inst;
      int _rs1 = BITS(_inst, 19, 15);
      if (rd == 0 && _rs1 == 1)
        ftrace_log(-1, s->pc, _target); //ret
      else if (rd == 1 || rd == 5)
        ftrace_log(1, s->pc, _target); //call
    })
  );
  INSTPAT("??????? ????? ????? 001 ????? 11000 11", bne    , B, if(src1 != src2) {s->dnpc = (s->pc) + imm;});
  INSTPAT("??????? ????? ????? 000 ????? 11000 11", beq    , B, if(src1 == src2) {s->dnpc = (s->pc) + imm;});
  INSTPAT("0100000 ????? ????? 000 ????? 01100 11", sub    , R , R(rd) = src1 - src2);
  INSTPAT("??????? ????? ????? 011 ????? 00100 11", sltiu    , I, if(src1 < imm) {R(rd) = 1;} else {R(rd) = 0;});
  INSTPAT("??????? ????? ????? 101 ????? 00100 11", srli    , I, R(rd) = src1 >> imm);
  INSTPAT("??????? ????? ????? 111 ????? 00100 11", inv    , I, R(rd) = src1 & imm);
  INSTPAT("??????? ????? ????? 000 ????? 01100 11", add    , R, R(rd) = src1 + src2);
  INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem    , R, if(src2 == 0) {R(rd) = src1;} else if((src1 == MIN_INT) & (src2 == -1)) {R(rd) = 0;}
                                                                  else {R(rd) = src1 % src2;});
  INSTPAT("0000001 ????? ????? 100 ????? 01100 11", div    , R, if(src2 == 0) {R(rd) = -1;} else if ((src1 == MIN_INT) & (src2 == -1)) {R(rd) = MIN_INT;}
                                                                  else {R(rd) = src1 / src2;});
  INSTPAT("??????? ????? ????? ??? ????? 01101 11", lui    , U, R(rd) = imm);
  INSTPAT("??????? ????? ????? 101 ????? 11000 11", bge    , B, if(src1 >= src2) {s->dnpc = (s->pc) + imm;});
  INSTPAT("0000000 ????? ????? 001 ????? 00100 11", slli    , I, R(rd) = src1 << imm);
  INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, R(rd) = src1 & src2);
  INSTPAT("0000000 ????? ????? 100 ????? 01100 11", xor    , R, R(rd) = src1 ^ src2);
  INSTPAT("??????? ????? ????? 100 ????? 00100 11", xori    , I, R(rd) = src1 ^ imm);
  INSTPAT("??????? ????? ????? 111 ????? 11000 11", bgeu    , B, if(src1 >= src2) {(s->dnpc) = (s->pc) + imm;});

  //INSTPAT("??????? ????? ????? ??? ????? ????? ??",     , , );                                                        
  //错误指令
  INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, INV(s->pc));

  //与INSTPAT_START相呼应，定义标签__instpat_end_<name>:并且结束块
  INSTPAT_END();

  R(0) = 0; // reset $zero to 0

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

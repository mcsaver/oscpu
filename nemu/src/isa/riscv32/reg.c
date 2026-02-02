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

#include <isa.h>
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};


void isa_reg_display() {
  //printf("hello word\n");
  for (int i = 0; i < 32; i++)
  {
    //%-2d，宽度为2，-表示左对齐
    //%4s，默认右对齐，不够用空格不上
    //%08x，无符号十六进制，宽度8，左侧用0填充，强制转换成unsigned避免符号拓展
    printf("x%-2d (%4s) = 0x%08x\n", i, reg_name(i), (unsigned)gpr(i));
  }
  
  //print program counter
  printf("pc  = 0x%08x\n", (unsigned int)cpu.pc);

}

word_t isa_reg_str2val(const char *s, bool *success) {
  int index = -1;

  for (int i = 0; i <= 31; i++)
  {
    if (strcmp(reg_name(i), s) == 0)
    {
      index = i;
      break;
    }
  }
  if (index == -1)
  {
    *success = false;
    return 0;
  }
  
  if (success)
  {
    *success = true;
  }
  
  return (word_t)gpr(index);
}

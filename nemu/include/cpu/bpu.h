/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#ifndef __CPU_BPU_H__
#define __CPU_BPU_H__

#include <common.h>

typedef struct {
  uint64_t control_access;
  uint64_t branch_access;
  uint64_t branch_hit;
  uint64_t branch_miss;
  uint64_t target_access;
  uint64_t target_hit;
  uint64_t target_miss;
  uint64_t btb_access;
  uint64_t btb_hit;
  uint64_t btb_miss;
  uint64_t ras_access;
  uint64_t ras_hit;
  uint64_t ras_miss;
  uint64_t ras_push;
  uint64_t ras_pop;
  uint64_t ras_overflow;
  uint64_t ras_underflow;
} BpuStats;

void init_bpu(void);
void bpu_commit(vaddr_t pc, uint32_t inst, vaddr_t snpc, vaddr_t dnpc);
void bpu_statistic(void);
const BpuStats *bpu_get_stats(void);
void bpu_init_for_test(void);

#endif

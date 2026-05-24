/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
***************************************************************************************/

#ifndef __MEMORY_SOC_H__
#define __MEMORY_SOC_H__

#include <common.h>

// ysyxSoC 平台模型挂在 paddr 层，保证 NPC difftest reference so 不依赖完整设备初始化。
bool soc_sim_in_range(paddr_t addr);
bool soc_sim_should_skip_ref(paddr_t addr);
word_t soc_sim_read(paddr_t addr, int len);
void soc_sim_write(paddr_t addr, int len, word_t data);
void soc_sim_reset(void);
bool soc_sim_memcpy(paddr_t addr, void *buf, size_t n, bool direction);

#endif

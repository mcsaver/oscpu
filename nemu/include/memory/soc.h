/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
***************************************************************************************/

#ifndef __MEMORY_SOC_H__
#define __MEMORY_SOC_H__

#include <common.h>

typedef enum {
  SOC_SIM_REGION_MEMORY,
  SOC_SIM_REGION_MMIO,
  SOC_SIM_REGION_XIP_FLASH,
} SocSimRegionKind;

typedef enum {
  SOC_SIM_TRANSACTION_IFETCH,
  SOC_SIM_TRANSACTION_READ,
  SOC_SIM_TRANSACTION_WRITE,
} SocSimTransactionDirection;

/*
 * ysyxSoC 手册中的一个物理地址区域。
 *
 * readonly 描述 CPU store 是否能改变该区域的架构状态；skip_ref 描述访问
 * 是否应跳过一次 DiffTest reference execution。该表只描述 guest 可见拓扑，
 * 不暴露模型内部的 host backing pointer。
 */
typedef struct {
  const char *name;
  paddr_t base;
  size_t size;
  SocSimRegionKind kind;
  bool readonly;
  bool skip_ref;
} SocSimRegionInfo;

// ysyxSoC 平台模型挂在 paddr 层，保证 NPC difftest reference so 不依赖完整设备初始化。
size_t soc_sim_region_count(void);
const SocSimRegionInfo *soc_sim_region_at(size_t index);
const SocSimRegionInfo *soc_sim_region_containing(paddr_t base, size_t size);
const SocSimRegionInfo *soc_sim_region_overlapping(paddr_t base, size_t size);
/* 返回由 NEMU 主 PMEM allocation 承载的 ysyxSoC region。 */
const SocSimRegionInfo *soc_sim_pmem_backed_region(void);
bool soc_sim_transaction_valid(
    paddr_t addr, int len, SocSimTransactionDirection direction);
bool soc_sim_in_range(paddr_t addr);
bool soc_sim_span_in_range(paddr_t addr, int len);
bool soc_sim_should_skip_ref(paddr_t addr);
word_t soc_sim_read(paddr_t addr, int len);
void soc_sim_write(paddr_t addr, int len, word_t data);
void soc_sim_reset(void);
/* loader/init 专用：可初始化 MROM 等 byte-backed platform memory。 */
bool soc_sim_copy_to_guest(paddr_t addr, const void *buf, size_t n);
bool soc_sim_memcpy(paddr_t addr, void *buf, size_t n, bool direction);

#endif

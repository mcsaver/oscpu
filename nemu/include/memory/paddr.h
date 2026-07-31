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
//声明物理地址层接口与PMEM边界宏，管理guest物理内存与MMIO的入口函数

#ifndef __MEMORY_PADDR_H__
#define __MEMORY_PADDR_H__

#include <common.h>

//由CONFIT_*配置宏决定物理内存区域
#define PMEM_LEFT  ((paddr_t)CONFIG_MBASE)
#define PMEM_RIGHT ((paddr_t)CONFIG_MBASE + CONFIG_MSIZE - 1)
#define RESET_VECTOR (PMEM_LEFT + CONFIG_PC_RESET_OFFSET)

//把guest物理地址映射到NEMU的host虚拟地址
/* convert the guest physical address in the guest program to host virtual address in NEMU */
uint8_t* guest_to_host(paddr_t paddr);
//反向映射
/* convert the host virtual address in NEMU to guest physical address in the guest program */
paddr_t host_to_guest(uint8_t *haddr);

//内联，判断地址是否落在物理内存范围
static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

//物理层的读写入口（负责分发到pmem或mmio）
word_t paddr_read(paddr_t addr, int len);
void paddr_write(paddr_t addr, int len, word_t data);
// 物理地址区间是否落在合法访问窗口内 (pmem/CLINT/PLIC/SoC/MMIO); 用于访存越界优雅抬 access-fault。
bool paddr_is_accessible(paddr_t addr, int len);
// 当前平台只把主存声明为完整 Zaamo/Zalrsc 区域；设备窗口采用 AMONone/RsrvNone。
bool paddr_supports_atomic(paddr_t addr, int len);
bool paddr_dma_write(paddr_t addr, const void *buf, uint32_t len);
bool paddr_dma_write_value(paddr_t addr, int len, word_t data);
// DMA 一致读: 经 dcache peek 视图读 guest 内存(dirty 未回写也拿到最新值)。
// 设备(virtio ring/描述符/数据段)读 guest 内存一律走这两个入口, 禁止 paddr_read/裸 memcpy。
word_t paddr_dma_read_value(paddr_t addr, int len);
bool paddr_dma_read(paddr_t addr, void *buf, uint32_t len);
extern bool paddr_write_trace_is_enabled;
void paddr_write_trace_arm_range(paddr_t start, paddr_t end,
    uint64_t max_count, const char *reason);
void paddr_write_trace_disarm(const char *reason);
void paddr_write_trace_dump_machine_info(FILE *out);
void paddr_write_value_trace_arm(word_t value, word_t mask,
    uint64_t max_count, const char *reason);
void paddr_write_value_trace_disarm(const char *reason);
void paddr_tohost_set_addr(paddr_t addr);
void paddr_tohost_check_write(paddr_t addr, uint32_t len);
extern bool paddr_device_write_seen;
bool paddr_take_device_write(void);

// 热路径先用 inline guard 判空，只有真的写过设备/MMIO 时才进入清标志函数。
static inline bool paddr_has_device_write(void) {
  return unlikely(paddr_device_write_seen);
}

static inline bool paddr_write_trace_runtime_enabled(void) {
  return unlikely(paddr_write_trace_is_enabled);
}

#endif

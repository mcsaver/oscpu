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

//定义虚拟地址层（vaddr）对外接口，供cpu/取值与数据访问调用

#ifndef __MEMORY_VADDR_H__
#define __MEMORY_VADDR_H__

#include <common.h>
//指令抓取
word_t vaddr_ifetch(vaddr_t addr, int len);
// performance 模式下的 RVC 宽取指快路径；不能命中时返回 0 让 ISA 层走旧精确路径。
typedef uint64_t VaddrIfetchWideResult;
#define VADDR_IFETCH_WIDE_MISS 0ull
#define VADDR_IFETCH_WIDE_FAULT 1ull
#define VADDR_IFETCH_WIDE_LEN2 2ull
#define VADDR_IFETCH_WIDE_LEN4 4ull
#define VADDR_IFETCH_WIDE_LEN_MASK 6ull

static inline VaddrIfetchWideResult vaddr_ifetch_wide_pack(uint32_t inst) {
  return ((uint64_t)inst << 3) |
    (((inst & 0x3u) == 0x3u) ? VADDR_IFETCH_WIDE_LEN4 : VADDR_IFETCH_WIDE_LEN2);
}

static inline uint32_t vaddr_ifetch_wide_inst(VaddrIfetchWideResult result) {
  return (uint32_t)(result >> 3);
}

static inline int vaddr_ifetch_wide_len(VaddrIfetchWideResult result) {
  return (int)(result & VADDR_IFETCH_WIDE_LEN_MASK);
}

VaddrIfetchWideResult vaddr_ifetch_wide(vaddr_t addr);
// Ubuntu 诊断用 runtime 开关；默认保持性能快路径，显式设 env=0 才关闭。
extern bool vaddr_ifetch_wide_is_enabled;
extern bool vaddr_host_fast_is_enabled;
extern bool vaddr_write_trace_is_enabled;
extern bool vaddr_fault_pending;

static inline bool vaddr_ifetch_wide_runtime_enabled(void) {
  return likely(vaddr_ifetch_wide_is_enabled);
}

static inline bool vaddr_host_fast_runtime_enabled(void) {
  return likely(vaddr_host_fast_is_enabled);
}

static inline bool vaddr_write_trace_runtime_enabled(void) {
  return unlikely(vaddr_write_trace_is_enabled);
}

void vaddr_write_trace_arm_range(vaddr_t start, vaddr_t end,
    uint64_t max_count, bool user_only, const char *reason);
void vaddr_write_trace_disarm(const char *reason);
void vaddr_write_value_trace_arm(word_t value, word_t mask,
    uint64_t max_count, const char *reason);
void vaddr_write_value_trace_set_user_only(bool user_only);
void vaddr_write_value_trace_disarm(const char *reason);
void vaddr_write_trace_dump_machine_info(FILE *out);
// 最近一次 vaddr_read 的译址元数据只供诊断 trace 读取，不会再次访问 guest 内存。
bool vaddr_last_read_paddr(vaddr_t addr, int len, paddr_t *paddr);
// 取指 host-page cache 的统一失效入口，供 sfence.vma/fence.i/TLB flush 调用。
void vaddr_ifetch_cache_flush(void);
// 物理内存被设备 DMA 写入时，只失效受影响的取指 host-page cache。
void vaddr_ifetch_cache_invalidate_paddr(paddr_t addr, uint32_t len);
//从虚拟地址读数据
word_t vaddr_read(vaddr_t addr, int len);
//写数据
void vaddr_write(vaddr_t addr, int len, word_t data);

/*
 * 原子访存必须在一次完整的 MMU/PMP/PMA 检查后使用同一翻译结果完成。
 * 调用方负责先检查自然对齐；返回 false 表示 fault 已进入 vaddr pending 通道。
 */
typedef word_t (*vaddr_atomic_compute_t)(word_t old_value, const void *opaque);
bool vaddr_atomic_load_reserved(vaddr_t addr, int len,
    word_t *value, paddr_t *paddr);
bool vaddr_atomic_store_conditional(vaddr_t addr, int len, word_t data,
    bool reservation_valid, paddr_t reservation_paddr, bool *stored);
bool vaddr_atomic_rmw(vaddr_t addr, int len, vaddr_atomic_compute_t compute,
    const void *opaque, word_t *old_value);

void vaddr_set_fault(word_t cause, vaddr_t tval);
bool vaddr_take_fault(word_t *cause, vaddr_t *tval);

static inline bool vaddr_has_fault(void) {
  return unlikely(vaddr_fault_pending);
}

//定义分页常量，方便后续实现页表/分页时使用
#define PAGE_SHIFT        12
#define PAGE_SIZE         (1ul << PAGE_SHIFT)
#define PAGE_MASK         (PAGE_SIZE - 1)

#endif

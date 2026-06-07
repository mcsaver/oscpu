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
//提供三个接口，vaddr_ifetch（指令抓取）、vaddr_read（数据读取）、vaddr_write（数据写入）
//当前实现直接把虚拟地址当成物理地址，调用paddr_read/paddr_write（即不做地址转换/页表/TLB)
//作为上层（CPU/指令译码）和下层物理内存访问的桥梁，未来可以在这里插入虚拟地址到物理地址的转换逻辑

#include <isa.h>
#include <memory/host.h>
#include <memory/vaddr.h>
#include <memory/cache.h>
#include <memory/paddr.h>

//添加MTRACE标志，以免每次取值都写入log
bool g_in_ifetch = false;
static bool vaddr_fault_pending = false;
static word_t vaddr_fault_cause = 0;
static vaddr_t vaddr_fault_tval = 0;

//vaddr是虚拟地址，是cpu执行的时候看到的地址
//paddr是物理地址，是MMU转换过后的结果，直接对应内存芯片

typedef struct {
  paddr_t paddr;
  uint8_t *host_addr;
} VaddrTranslateResult;

bool vaddr_take_fault(word_t *cause, vaddr_t *tval) {
  if (!vaddr_fault_pending) return false;
  *cause = vaddr_fault_cause;
  *tval = vaddr_fault_tval;
  vaddr_fault_pending = false;
  return true;
}

bool vaddr_has_fault(void) {
  return vaddr_fault_pending;
}

static word_t vaddr_fault_cause_for_type(int type) {
  switch (type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_PAGE_FAULT;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_PAGE_FAULT;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_PAGE_FAULT;
  }
}

static inline uint8_t *vaddr_paddr_host_fast(paddr_t paddr) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  if (likely(in_pmem(paddr))) {
    return guest_to_host(paddr);
  }
#endif
  return NULL;
}

static VaddrTranslateResult vaddr_translate_checked(vaddr_t addr, int len, int type) {
  VaddrTranslateResult result = { .paddr = 0, .host_addr = NULL };
  int mmu = isa_mmu_check(addr, len, type);
  if (mmu == MMU_DIRECT) {
    result.paddr = (paddr_t)addr;
    result.host_addr = vaddr_paddr_host_fast(result.paddr);
    return result;
  }

  if (mmu != MMU_TRANSLATE) {
    vaddr_fault_pending = true;
    vaddr_fault_cause = vaddr_fault_cause_for_type(type);
    vaddr_fault_tval = addr;
    return result;
  }

#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE) && \
    defined(CONFIG_ISA_riscv) && defined(CONFIG_ISA64)
  if (!isa_mmu_translate_host(addr, len, type, &result.paddr, &result.host_addr)) {
    vaddr_fault_pending = true;
    vaddr_fault_cause = vaddr_fault_cause_for_type(type);
    vaddr_fault_tval = addr;
    return result;
  }
#else
  result.paddr = isa_mmu_translate(addr, len, type);
  if (result.paddr == (paddr_t)-1) {
    vaddr_fault_pending = true;
    vaddr_fault_cause = vaddr_fault_cause_for_type(type);
    vaddr_fault_tval = addr;
    return result;
  }
  result.host_addr = vaddr_paddr_host_fast(result.paddr);
#endif
  return result;
}

static inline word_t vaddr_paddr_read_fast(VaddrTranslateResult trans, int len) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  /*
   * Ubuntu performance 配置关闭 cache/MTRACE 后，TLB/direct 翻译会尽量给出
   * PMEM host_addr；命中时直接落到 host buffer，非 PMEM 仍回落 paddr 层。
   */
  if (likely(trans.host_addr != NULL)) {
    return host_read(trans.host_addr, len);
  }
#endif
  return paddr_read(trans.paddr, len);
}

static inline void vaddr_paddr_write_fast(VaddrTranslateResult trans, int len, word_t data) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  if (likely(trans.host_addr != NULL)) {
    host_write(trans.host_addr, len, data);
    return;
  }
#endif
  paddr_write(trans.paddr, len, data);
}

static word_t vaddr_read_translated(vaddr_t addr, int len, int type) {
  if (((addr & PAGE_MASK) + len) > PAGE_SIZE) {
    word_t ret = 0;
    for (int i = 0; i < len; i++) {
      ret |= vaddr_read_translated(addr + i, 1, type) << (i * 8);
    }
    return ret;
  }
  VaddrTranslateResult trans = vaddr_translate_checked(addr, len, type);
  if (vaddr_fault_pending) return 0;
  return MUXDEF(CONFIG_CACHE,
      (type == MEM_TYPE_IFETCH ? icache_read(trans.paddr, len) : dcache_read(trans.paddr, len)),
      vaddr_paddr_read_fast(trans, len));
}

word_t vaddr_ifetch(vaddr_t addr, int len) {
  g_in_ifetch = true;
  // 取指和数据访存从这里分流，便于分别统计 ICache/DCache，同时保留 paddr 层的 MMIO 处理。
  word_t ret = vaddr_read_translated(addr, len, MEM_TYPE_IFETCH);
  g_in_ifetch = false;
  return ret;
}

bool vaddr_ifetch_wide(vaddr_t addr, uint32_t *inst, int *len) {
#if defined(CONFIG_INTERPRETER_WIDE_IFETCH) && defined(CONFIG_RISCV_EXT_C) && \
    !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  if (((addr & PAGE_MASK) + 4) > PAGE_SIZE) {
    return false;
  }

  g_in_ifetch = true;
  VaddrTranslateResult trans = vaddr_translate_checked(addr, 4, MEM_TYPE_IFETCH);
  g_in_ifetch = false;
  if (vaddr_fault_pending) {
    return true;
  }
  if (trans.host_addr == NULL) {
    return false;
  }

  /*
   * RVC 取指通常先取 16 bit 再决定是否补取后半字。Ubuntu 热路径中
   * PMEM 同页命中时直接读 4 字节，只缓存“原始取指包”，不缓存译码结果；
   * MMIO/跨页/fault 仍走旧路径，避免额外设备读或改变精确异常地址。
   */
  uint32_t raw = 0;
  memcpy(&raw, trans.host_addr, sizeof(raw));
  *inst = raw;
  *len = (raw & 0x3u) == 0x3u ? 4 : 2;
  return true;
#else
  return false;
#endif
}

word_t vaddr_read(vaddr_t addr, int len) {
  return vaddr_read_translated(addr, len, MEM_TYPE_READ);
}

void vaddr_write(vaddr_t addr, int len, word_t data) {
  if (((addr & PAGE_MASK) + len) > PAGE_SIZE) {
    VaddrTranslateResult translations[8];
    assert(len <= (int)ARRLEN(translations));
    /* 跨页 store 必须先完成全部翻译，再真正写内存；否则后半截 page fault
     * 会留下前半截写入，破坏 Linux demand paging 依赖的精确异常语义。 */
    for (int i = 0; i < len; i++) {
      translations[i] = vaddr_translate_checked(addr + i, 1, MEM_TYPE_WRITE);
      if (vaddr_fault_pending) return;
    }
    for (int i = 0; i < len; i++) {
      IFDEF(CONFIG_CACHE, dcache_write(translations[i].paddr, 1, data >> (i * 8)); continue);
      vaddr_paddr_write_fast(translations[i], 1, data >> (i * 8));
    }
    return;
  }
  VaddrTranslateResult trans = vaddr_translate_checked(addr, len, MEM_TYPE_WRITE);
  if (vaddr_fault_pending) return;
  IFDEF(CONFIG_CACHE, dcache_write(trans.paddr, len, data); return);
  vaddr_paddr_write_fast(trans, len, data);
}

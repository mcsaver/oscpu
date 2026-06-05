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

static paddr_t vaddr_translate_checked(vaddr_t addr, int len, int type) {
  int mmu = isa_mmu_check(addr, len, type);
  if (mmu == MMU_DIRECT) return (paddr_t)addr;

  if (mmu != MMU_TRANSLATE) {
    vaddr_fault_pending = true;
    vaddr_fault_cause = vaddr_fault_cause_for_type(type);
    vaddr_fault_tval = addr;
    return 0;
  }

  paddr_t paddr = isa_mmu_translate(addr, len, type);
  if (paddr == (paddr_t)-1) {
    vaddr_fault_pending = true;
    vaddr_fault_cause = vaddr_fault_cause_for_type(type);
    vaddr_fault_tval = addr;
    return 0;
  }
  return paddr;
}

static word_t vaddr_read_translated(vaddr_t addr, int len, int type) {
  if (((addr & PAGE_MASK) + len) > PAGE_SIZE) {
    word_t ret = 0;
    for (int i = 0; i < len; i++) {
      ret |= vaddr_read_translated(addr + i, 1, type) << (i * 8);
    }
    return ret;
  }
  paddr_t paddr = vaddr_translate_checked(addr, len, type);
  if (vaddr_fault_pending) return 0;
  return MUXDEF(CONFIG_CACHE,
      (type == MEM_TYPE_IFETCH ? icache_read(paddr, len) : dcache_read(paddr, len)),
      paddr_read(paddr, len));
}

word_t vaddr_ifetch(vaddr_t addr, int len) {
  g_in_ifetch = true;
  // 取指和数据访存从这里分流，便于分别统计 ICache/DCache，同时保留 paddr 层的 MMIO 处理。
  word_t ret = vaddr_read_translated(addr, len, MEM_TYPE_IFETCH);
  g_in_ifetch = false;
  return ret;
}

word_t vaddr_read(vaddr_t addr, int len) {
  return vaddr_read_translated(addr, len, MEM_TYPE_READ);
}

void vaddr_write(vaddr_t addr, int len, word_t data) {
  if (((addr & PAGE_MASK) + len) > PAGE_SIZE) {
    paddr_t paddrs[8];
    assert(len <= (int)ARRLEN(paddrs));
    /* 跨页 store 必须先完成全部翻译，再真正写内存；否则后半截 page fault
     * 会留下前半截写入，破坏 Linux demand paging 依赖的精确异常语义。 */
    for (int i = 0; i < len; i++) {
      paddrs[i] = vaddr_translate_checked(addr + i, 1, MEM_TYPE_WRITE);
      if (vaddr_fault_pending) return;
    }
    for (int i = 0; i < len; i++) {
      IFDEF(CONFIG_CACHE, dcache_write(paddrs[i], 1, data >> (i * 8)); continue);
      paddr_write(paddrs[i], 1, data >> (i * 8));
    }
    return;
  }
  paddr_t paddr = vaddr_translate_checked(addr, len, MEM_TYPE_WRITE);
  if (vaddr_fault_pending) return;
  IFDEF(CONFIG_CACHE, dcache_write(paddr, len, data); return);
  paddr_write(paddr, len, data);
}

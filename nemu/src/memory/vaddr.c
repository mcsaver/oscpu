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
#include <memory/cache.h>
#include <memory/paddr.h>

//添加MTRACE标志，以免每次取值都写入log
bool g_in_ifetch = false;

//vaddr是虚拟地址，是cpu执行的时候看到的地址
//paddr是物理地址，是MMU转换过后的结果，直接对应内存芯片

word_t vaddr_ifetch(vaddr_t addr, int len) {
  g_in_ifetch = true;
  // 取指和数据访存从这里分流，便于分别统计 ICache/DCache，同时保留 paddr 层的 MMIO 处理。
  word_t ret = MUXDEF(CONFIG_CACHE, icache_read(addr, len), paddr_read(addr, len));
  g_in_ifetch = false;
  return ret;
}

word_t vaddr_read(vaddr_t addr, int len) {
  return MUXDEF(CONFIG_CACHE, dcache_read(addr, len), paddr_read(addr, len));
}

void vaddr_write(vaddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_CACHE, dcache_write(addr, len, data); return);
  paddr_write(addr, len, data);
}

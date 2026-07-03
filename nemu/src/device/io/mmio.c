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

//MMIO设备注册表+MMIO访问分发器
//它本身不模拟任何具体设备，不管串口、时钟还是VGA的行为细节；他只负责两件事情
//1.把某个设备注册到一段MMIO地址区间上
//2.当CPU方位这个地址区间时，把请求转发给对应设备

#include <device/map.h>
#include <device/mmio.h>
#include <memory/paddr.h>
#include <isa.h>
#include <utils.h>
//#include <device/map.h>

//最多允许16个MMIO设备
#define NR_MAP 16

//maps：保存了所有MMIO设备的映射信息
static IOMap maps[NR_MAP] = {};
//nr_map：当前已经注册了多少个设备
static int nr_map = 0;

//IOMap结构体：
//1.设备名
//2.地址上界
//3.地址下界
//4.后端存储空间
//5.访问回调

//fetch_mmio_map的作用，给一个物理地址addr，查这个地址命中了哪一个MMIO设备
//如果找到了，就返回对应的IOMap*
//如果没找到，就返回NULL
//用于MMIO的“译码”
static IOMap* fetch_mmio_map(paddr_t addr) {
  int mapid = find_mapid_by_addr(maps, nr_map, addr);
  return (mapid == -1 ? NULL : &maps[mapid]);
}

// 纯查询: [addr, addr+len-1] 是否完全落在某个已注册 MMIO 设备窗口内。
// 用 map_inside 而非 find_mapid_by_addr, 避免后者命中即 difftest_skip_ref 的副作用——
// 本函数只做"物理地址可访问性预检", 不能扰动 difftest 步进。
bool mmio_is_mapped(paddr_t addr, int len) {
  if (len <= 0) return false;
  paddr_t last = addr + (paddr_t)len - 1;
  if (last < addr) return false;
  bool lo = false, hi = false;
  for (int i = 0; i < nr_map; i++) {
    if (map_inside(&maps[i], addr)) lo = true;
    if (map_inside(&maps[i], last)) hi = true;
  }
  return lo && hi;
}

//只在注册设备的时候使用，作用是：
//报错提示在某段新注册的MMIO地址区间已经和已有区域冲突了
//它会在两种情况下触发：
//1.新设备映射和pmem重叠
//2.新设备映射和已注册的其他MMIO设备重叠
static void report_mmio_overlap(const char *name1, paddr_t l1, paddr_t r1,
    const char *name2, paddr_t l2, paddr_t r2) {
  panic("MMIO region %s@[" FMT_PADDR ", " FMT_PADDR "] is overlapped "
               "with %s@[" FMT_PADDR ", " FMT_PADDR "]", name1, l1, r1, name2, l2, r2);
}

/* device interface */
//核心注册函数：参数：name：设备名字；addr：设备映射起始物理地址；space：设备后端寄存器缓存区；len：设备映射长度；callback：访问设备时要触发的回调
void add_mmio_map(const char *name, paddr_t addr, void *space, uint32_t len, io_callback_t callback) {
  assert(nr_map < NR_MAP);
  paddr_t left = addr, right = addr + len - 1;
  if (in_pmem(left) || in_pmem(right)) {
    report_mmio_overlap(name, left, right, "pmem", PMEM_LEFT, PMEM_RIGHT);
  }
  for (int i = 0; i < nr_map; i++) {
    if (left <= maps[i].high && right >= maps[i].low) {
      report_mmio_overlap(name, left, right, maps[i].name, maps[i].low, maps[i].high);
    }
  }

  maps[nr_map] = (IOMap){ .name = name, .low = addr, .high = addr + len - 1,
    .space = space, .callback = callback };
  Log("Add mmio map '%s' at [" FMT_PADDR ", " FMT_PADDR "]",
      maps[nr_map].name, maps[nr_map].low, maps[nr_map].high);

  nr_map ++;
}

#ifndef CONFIG_TARGET_AM
void dump_mmio_maps(FILE *out) {
  fprintf(out, "mmio.count=%d\n", nr_map);
  for (int i = 0; i < nr_map; i++) {
    fprintf(out, "mmio.%s=" FMT_PADDR ".." FMT_PADDR "\n",
        maps[i].name, maps[i].low, maps[i].high);
  }
}
#endif

/* bus interface */
//MMIO读总线入口，先用fetch_mmio_map找到命中的设备映射
//再调用map_read，本身不处理设备逻辑
//只负责，把一次MMIO读请求转交给通用map机制
word_t mmio_read(paddr_t addr, int len) {
  //return map_read(addr, len, fetch_mmio_map(addr));
  IOMap *map_fetch_reg = fetch_mmio_map(addr);
  word_t map_result = map_read(addr, len, map_fetch_reg);

#ifdef CONFIG_DTRACE
  if (DTRACE_COND) {
    log_write("[Dtrace] MMIO R %-8s addr=" FMT_PADDR
            " off=" FMT_PADDR " len=%d val=" FMT_WORD
            " pc=" FMT_WORD "\n",
            map_fetch_reg->name,
            addr,
            addr - map_fetch_reg->low,
            len,
            map_result,
            cpu.pc);
  }
#endif

  return map_result;
}

//和read一样
void mmio_write(paddr_t addr, int len, word_t data) {
  //map_write(addr, len, data, fetch_mmio_map(addr));
  IOMap *map_fetch_reg = fetch_mmio_map(addr);
  map_write(addr, len, data, map_fetch_reg);

#ifdef CONFIG_DTRACE
  if (DTRACE_COND) {
    log_write("[Dtrace] MMIO W %-8s addr=" FMT_PADDR
            " off=" FMT_PADDR " len=%d val=" FMT_WORD
            " pc=" FMT_WORD "\n",
            map_fetch_reg->name,
            addr,
            addr - map_fetch_reg->low,
            len,
            data,
            cpu.pc);
  }
#endif
  //return map_result;
}

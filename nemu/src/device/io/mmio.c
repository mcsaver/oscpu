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
#include <memory/soc.h>
#include <platform/platform-map.h>
#include <isa/riscv/clint.h>
#include <isa/riscv/plic.h>
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
static IOMap* fetch_mmio_map(paddr_t addr, int len, bool is_write) {
  for (int i = 0; i < nr_map; i++) {
    if (map_decode_transaction(
            &maps[i], addr, len, is_write, NULL) == IO_TRANSACTION_ACCEPTED) {
      difftest_skip_ref();
      return &maps[i];
    }
  }
  return NULL;
}

// 纯查询: [addr, addr+len-1] 是否完全落在某个已注册 MMIO 设备窗口内。
// 用 map_inside 而非 find_mapid_by_addr, 避免后者命中即 difftest_skip_ref 的副作用——
// 本函数只做"物理地址可访问性预检", 不能扰动 difftest 步进。
bool mmio_is_mapped(paddr_t addr, int len) {
  if (len <= 0) return false;
  for (int i = 0; i < nr_map; i++) {
    if (map_span_inside(&maps[i], addr, (uint64_t)len)) return true;
  }
  return false;
}

IoTransactionStatus mmio_decode_transaction(
    paddr_t addr, int len, bool is_write) {
  IoTransactionStatus span_status = IO_TRANSACTION_OUTSIDE_REGION;
  for (int i = 0; i < nr_map; i++) {
    IoTransactionStatus status = map_decode_transaction(
        &maps[i], addr, len, is_write, NULL);
    if (status == IO_TRANSACTION_ACCEPTED) return status;
    if (map_inside(&maps[i], addr)) span_status = status;
  }
  return span_status;
}

//只在注册设备的时候使用，作用是：
//报错提示在某段新注册的MMIO地址区间已经和已有区域冲突了
//它会在三种情况下触发：
//1.新设备映射和pmem重叠
//2.新设备映射和SOC平台固定区域重叠
//3.新设备映射和所选平台的CLINT/PLIC固定区域重叠
//4.新设备映射和已注册的其他MMIO设备重叠
static void report_mmio_overlap(const char *name1, paddr_t l1, paddr_t r1,
    const char *name2, paddr_t l2, paddr_t r2) {
  panic("MMIO region %s@[" FMT_PADDR ", " FMT_PADDR "] is overlapped "
               "with %s@[" FMT_PADDR ", " FMT_PADDR "]", name1, l1, r1, name2, l2, r2);
}

static void validate_mmio_policy(const char *map_name, uint32_t map_len,
    const IoAccessPolicy *policy) {
  for (; policy != NULL; policy = policy->parent) {
    Assert(policy->register_count == 0 || policy->registers != NULL,
        "MMIO policy %s has no register descriptors", map_name);
    for (uint32_t i = 0; i < policy->register_count; i++) {
      const IoRegisterDescriptor *reg = &policy->registers[i];
      Assert(reg->first_offset <= reg->last_offset &&
             reg->last_offset < map_len && reg->stride != 0 &&
             reg->width_mask != 0 && reg->direction_mask != 0,
          "invalid MMIO register policy %s.%s",
          map_name, reg->name != NULL ? reg->name : "<unnamed>");
    }
  }
}

/* device interface */
//核心注册函数：参数：name：设备名字；addr：设备映射起始物理地址；space：设备后端寄存器缓存区；len：设备映射长度；callback：访问设备时要触发的回调
void add_mmio_map_with_policy(const char *name, paddr_t addr, void *space,
    uint32_t len, io_callback_t callback, const IoAccessPolicy *policy) {
  assert(nr_map < NR_MAP);
  Assert(len != 0 && (uint64_t)len - 1 <= (uint64_t)(paddr_t)-1 - (uint64_t)addr,
      "invalid MMIO region %s addr=" FMT_PADDR " len=%u", name, addr, len);
  validate_mmio_policy(name, len, policy);
  paddr_t left = addr, right = addr + len - 1;
  if (left <= PMEM_RIGHT && right >= PMEM_LEFT) {
    report_mmio_overlap(name, left, right, "pmem", PMEM_LEFT, PMEM_RIGHT);
  }

  /*
   * SOC_SIM regions live directly on the physical bus rather than in the
   * generic IOMap registry.  They still own their complete address ranges:
   * registering an IOMap on top of one would create a hidden device whose
   * apparent initialization disagrees with the address decoder.  Query the
   * platform manifest here so partial overlaps (for example GPIO against a
   * larger virtio-mmio aperture) fail just like IOMap-to-IOMap overlaps.
   */
  const SocSimRegionInfo *soc_region =
      soc_sim_region_overlapping(left, (size_t)len);
  if (soc_region != NULL) {
    Assert(soc_region->size != 0,
        "ysyxSoC region %s has an empty address range", soc_region->name);
    paddr_t soc_right = soc_region->base + (paddr_t)soc_region->size - 1;
    char soc_name[64];
    snprintf(soc_name, sizeof(soc_name), "ysyxsoc.%s", soc_region->name);
    report_mmio_overlap(name, left, right, soc_name,
        soc_region->base, soc_right);
  }

  /*
   * CLINT/PLIC bypass the IOMap registry, but in the generic RISC-V profile
   * they still own their complete apertures.  Validate those owners here so a
   * newly initialized IOMap can never become invisible behind a fixed decoder.
   * The ysyxSoC profile compiles both checks out because that machine contains
   * neither controller.
   */
#if NEMU_PLATFORM_HAS_RISCV_CLINT
  const paddr_t clint_left = (paddr_t)RISCV_CLINT_BASE;
  const paddr_t clint_right = clint_left + (paddr_t)RISCV_CLINT_SIZE - 1;
  if (left <= clint_right && right >= clint_left) {
    report_mmio_overlap(name, left, right, "riscv-clint",
        clint_left, clint_right);
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  const paddr_t plic_left = (paddr_t)RISCV_PLIC_BASE;
  const paddr_t plic_right = plic_left + (paddr_t)RISCV_PLIC_SIZE - 1;
  if (left <= plic_right && right >= plic_left) {
    report_mmio_overlap(name, left, right, "riscv-plic",
        plic_left, plic_right);
  }
#endif

  for (int i = 0; i < nr_map; i++) {
    if (left <= maps[i].high && right >= maps[i].low) {
      report_mmio_overlap(name, left, right, maps[i].name, maps[i].low, maps[i].high);
    }
  }

  maps[nr_map] = (IOMap){ .name = name, .low = addr, .high = addr + len - 1,
    .space = space, .callback = callback, .policy = policy };
  Log("Add mmio map '%s' at [" FMT_PADDR ", " FMT_PADDR "]",
      maps[nr_map].name, maps[nr_map].low, maps[nr_map].high);

  nr_map ++;
}

void add_mmio_map(const char *name, paddr_t addr, void *space,
    uint32_t len, io_callback_t callback) {
  add_mmio_map_with_policy(name, addr, space, len, callback, NULL);
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
  IOMap *map_fetch_reg = fetch_mmio_map(addr, len, false);
  word_t map_result = map_read(addr, len, map_fetch_reg);

#ifdef CONFIG_DTRACE
  if (map_fetch_reg != NULL && NEMU_DTRACE_COND) {
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
  IOMap *map_fetch_reg = fetch_mmio_map(addr, len, true);
  map_write(addr, len, data, map_fetch_reg);

#ifdef CONFIG_DTRACE
  if (map_fetch_reg != NULL && NEMU_DTRACE_COND) {
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

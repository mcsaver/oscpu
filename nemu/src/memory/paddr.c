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

//管理物理内存（pmem）与外设映射（MMIO）

#include <memory/host.h>
#include <memory/paddr.h>
#include <memory/vaddr.h>
#include <memory/cache.h>
#include <memory/soc.h>
#include <device/mmio.h>
#include <cpu/difftest.h>
#include <utils/profile.h>
#include <isa.h>

#ifdef CONFIG_MTRACE
  #define CONFIG_MTRACE_START 0x80000000
  #define CONFIG_MTRACE_END 0x90000000
#endif

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

bool paddr_device_write_seen = false;

static inline void paddr_note_device_write(void) {
  paddr_device_write_seen = true;
}

bool paddr_take_device_write(void) {
  bool seen = paddr_device_write_seen;
  paddr_device_write_seen = false;
  return seen;
}

//guest物理地址与模拟器主机内存地址的映射转换
uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

//在主内存（pmem）上读写，使用host_read/host_write做按字节宽度的安全访问
//
static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static bool pmem_range_ok(paddr_t addr, uint32_t len) {
  if (len == 0) return true;
  paddr_t end = addr + (paddr_t)len - 1;
  return end >= addr && in_pmem(addr) && in_pmem(end);
}

static void paddr_dma_notify_cpu(paddr_t addr, uint32_t len) {
  if (len == 0) return;
  IFDEF(CONFIG_ISA_riscv, isa_riscv_lr_sc_invalidate(addr, (int)len));
  /*
   * Device DMA is an external PMEM write. Keep the interpreter's private
   * instruction-side host-page cache coherent without flushing unrelated pages.
   */
  vaddr_ifetch_cache_invalidate_paddr(addr, len);
}

bool paddr_dma_write(paddr_t addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!pmem_range_ok(addr, len)) return false;
  memcpy(guest_to_host(addr), buf, len);
  paddr_dma_notify_cpu(addr, len);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITES, 1);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITE_BYTES, len);
  return true;
}

bool paddr_dma_write_value(paddr_t addr, int len, word_t data) {
  assert(len >= 1 && len <= 8);
  if (!pmem_range_ok(addr, (uint32_t)len)) return false;
  pmem_write(addr, len, data);
  paddr_dma_notify_cpu(addr, (uint32_t)len);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITES, 1);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITE_BYTES, (uint64_t)len);
  return true;
}


//当访问越界且没有MMIO时触发panic，并打印访问地址和cpu.pc以便调试
static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

//分配/初始化pmem（支持CONFIG_PMEM_MALLOC或静态数组），可按照CONFIG_MEM_RANDOM填充随机值并打印物理内存区间日志
void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
  // SoC 仿真窗口是 paddr 层直连模型，初始化时清空其平台状态，避免 reference so 多轮复用串味。
  IFDEF(CONFIG_SOC_SIM, soc_sim_reset());
  // cache 以 paddr 层作为后端，初始化只建立 tag/data 状态，不改变 PMEM/MMIO 的权威语义。
  IFDEF(CONFIG_CACHE, init_cache());
}

//对外的物理地址读写入口，若地址在pmem范围则走pmem_read/pmem_write，否则在启用CONFIG_DEVICE时调用mmio_read/mmio_write
//否则触发out_of_bound(panic)
word_t paddr_read(paddr_t addr, int len) {
  if (likely(in_pmem(addr))) {
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_READS, 1);
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_READ_BYTES, (uint64_t)len);
    word_t ret = pmem_read(addr, len);
#ifdef CONFIG_MTRACE
    extern bool g_in_ifetch;
    if (!g_in_ifetch && cpu.pc >= CONFIG_MTRACE_START && cpu.pc <= CONFIG_MTRACE_END)
      log_write("[Mtrace] R addr=" FMT_PADDR " len=%d val " FMT_WORD " pc = " FMT_WORD "\n",
      addr, len, ret, cpu.pc);
#endif
  return ret;
  }
  if (MUXDEF(CONFIG_ISA_riscv, isa_riscv_clint_in_range(addr), false)) {
    // CLINT 是 RISC-V 平台固定 MMIO；在 paddr 层直连后，reference so 不需要走完整 device init。
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_CLINT_READS, 1);
    return isa_riscv_clint_read(addr, len);
  }
  if (MUXDEF(CONFIG_ISA_riscv, isa_riscv_plic_in_range(addr), false)) {
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PLIC_READS, 1);
    return isa_riscv_plic_read(addr, len);
  }
  if (MUXDEF(CONFIG_SOC_SIM, soc_sim_in_range(addr), false)) {
    // ysyxSoC 平台窗口不依赖 CONFIG_DEVICE；MROM/SRAM/SDRAM 是可比较内存，
    // 只有 UART/占位设备这类 MMIO 副作用需要跳过 reference 步进。
    if (soc_sim_should_skip_ref(addr)) difftest_skip_ref();
    return soc_sim_read(addr, len);
  }
  IFDEF(CONFIG_DEVICE, nemu_profile_count_if(NEMU_PROFILE_PADDR_MMIO_READS, 1); return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (likely(in_pmem(addr))){
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_WRITES, 1);
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_WRITE_BYTES, (uint64_t)len);
    pmem_write(addr, len, data);
#ifdef CONFIG_MTRACE
    extern bool g_in_ifetch;
    if(!g_in_ifetch && cpu.pc >= CONFIG_MTRACE_START && cpu.pc <= CONFIG_MTRACE_END)
      log_write("[Mtrace] W addr=" FMT_PADDR " len=%d val " FMT_WORD " pc = " FMT_WORD "\n",
      addr, len, data, cpu.pc);
#endif
    return;
  }
  if (MUXDEF(CONFIG_ISA_riscv, isa_riscv_clint_in_range(addr), false)) {
    // CLINT 写会改变软件/定时器中断源；这里和读路径一起对齐 NPC 的 0x0200_0000 地址窗口。
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_CLINT_WRITES, 1);
    paddr_note_device_write();
    isa_riscv_clint_write(addr, len, data);
    return;
  }
  if (MUXDEF(CONFIG_ISA_riscv, isa_riscv_plic_in_range(addr), false)) {
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PLIC_WRITES, 1);
    paddr_note_device_write();
    isa_riscv_plic_write(addr, len, data);
    return;
  }
  if (MUXDEF(CONFIG_SOC_SIM, soc_sim_in_range(addr), false)) {
    // SoC 模型在 paddr 层完成副作用；片上存储保持指令级比较，MMIO 才跳过。
    if (soc_sim_should_skip_ref(addr)) {
      difftest_skip_ref();
      paddr_note_device_write();
    }
    soc_sim_write(addr, len, data);
    return;
  }
  IFDEF(CONFIG_DEVICE, nemu_profile_count_if(NEMU_PROFILE_PADDR_MMIO_WRITES, 1); paddr_note_device_write(); mmio_write(addr, len, data); return);
  out_of_bound(addr);
}

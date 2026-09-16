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

#include <isa.h>
#include <cpu/bpu.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>
#include <memory/cache.h>
#include <memory/soc.h>
#include <utils.h>
#include <device/mmio.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (n == 0) return;
  assert(buf != NULL);
  // SoC 模式允许 testbench/loader 把镜像或数据同步到片上 SRAM/MROM/SDRAM 等非主 PMEM 窗口。
  if (MUXDEF(CONFIG_SOC_SIM, soc_sim_memcpy(addr, buf, n, direction), false)) {
    return;
  }
  Assert((uint64_t)n == n && paddr_span_in_pmem(addr, (uint64_t)n),
      "difftest memcpy out of pmem: addr=" FMT_PADDR ", size=%zu", addr, n);

  if (direction == DIFFTEST_TO_REF) {
    memcpy(guest_to_host(addr), buf, n);
#ifdef CONFIG_ISA_riscv
    /* 外部写入按物理重叠范围使本 hart 的 reservation set 失效。 */
    isa_riscv_lr_sc_invalidate(addr, (uint64_t)n);
#endif
  } else {
    memcpy(buf, guest_to_host(addr), n);
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  assert(dut != NULL);
  if (direction == DIFFTEST_TO_REF) {
    memcpy(&cpu, dut, DIFFTEST_REG_SIZE);
    cpu.gpr[0] = 0;
#ifdef CONFIG_ISA_riscv
    /* difftest ABI 不传隐藏 reservation；同步新寄存器状态时保守清除。 */
    isa_riscv_lr_sc_clear();
#endif
  } else {
    memcpy(dut, &cpu, DIFFTEST_REG_SIZE);
  }
}

#if defined(CONFIG_ISA_riscv) && defined(CONFIG_RV64)
/*
 * RV64 NPC 的全状态 difftest 扩展：旁路导出 CSR/priv 和 FPR。
 * 该 ABI 的字段约定属于 RV64 NPC，不是通用 RISC-V regcpy 接口；
 * RV32 reference 因此不导出这两个可选符号，也不伪造空 snapshot。
 */
/* Read the coherent reference view, including dirty cache bytes. This is an
 * observation API: unlike memcpy-to-DUT it must not bypass modeled caches. */
/* Optional platform initialization for the native system harness. ISA-only
 * references retain their original lightweight initialization. */
__EXPORT void difftest_init_devices(void) {
#ifdef CONFIG_DEVICE
  static bool initialized = false;
  if (!initialized) {
    void init_map(void);
    init_map();
    // UART, RTC and reset syscon are always present. The block endpoint is
    // initialized explicitly with its own backing image; RNG/NET are absent.
#ifdef CONFIG_HAS_SERIAL
    void init_serial(void); init_serial();
#endif
#ifdef CONFIG_HAS_VGA
    void init_vga(void); init_vga();
#endif
#ifdef CONFIG_HAS_TIMER
    void init_timer(void); init_timer();
#endif
#ifdef CONFIG_HAS_GOLDFISH_RTC
    void init_goldfish_rtc(void); init_goldfish_rtc();
#endif
#ifdef CONFIG_HAS_SYSCON_RESET
    void init_syscon_reset(void); init_syscon_reset();
#endif
    initialized = true;
  }
#endif
}
#ifdef CONFIG_TARGET_SHARE
#ifdef CONFIG_HAS_DISK
__EXPORT void difftest_init_block(const char *path) {
  void disk_set_image(const char *);
  void init_disk(void);
  /* Device completion order follows the accepted MMIO transaction, not host
   * thread scheduling. The independent reference uses its own disk and RAM. */
  assert(setenv("NEMU_VIRTIO_BLK_SYNC", "1", 1) == 0);
  disk_set_image(path);
  init_disk();
}
__EXPORT bool difftest_device_mmio(paddr_t addr, int len,
    uint64_t *value, bool write) {
  if (mmio_decode_transaction(addr, len, write) != IO_TRANSACTION_ACCEPTED)
    return false;
  if (write) mmio_write(addr, len, *value);
  else *value = mmio_read(addr, len);
  return true;
}
#endif
#ifdef CONFIG_HAS_SERIAL
__EXPORT void difftest_set_serial_sink(void (*sink)(uint8_t)) {
  extern void (*difftest_serial_sink)(uint8_t);
  difftest_serial_sink = sink;
}
#endif
__EXPORT void difftest_configure_mmu(uint16_t satp_modes, uint64_t extra_reserved_pte) {
  extern uint16_t difftest_satp_mode_mask;
  extern uint64_t difftest_pte_reserved_extra;
  const uint16_t supported = (1u << 0) | (1u << 8) | (1u << 9) | (1u << 10);
  assert((satp_modes & 1) && !(satp_modes & ~supported));
  assert((extra_reserved_pte & ~(UINT64_C(3) << 59)) == 0);
  difftest_satp_mode_mask = satp_modes;
  difftest_pte_reserved_extra = extra_reserved_pte;
}
bool difftest_external_interrupt_control = false;
__EXPORT void difftest_set_external_interrupts(bool enabled) {
  difftest_external_interrupt_control = enabled;
}
#endif

__EXPORT uint64_t difftest_pmem_read(paddr_t addr, int len) {
  assert(len > 0 && len <= 8 && paddr_span_in_pmem(addr, (uint64_t)len));
  return dcache_peek_read(addr, len);
}

/* Environment-timed CSR/MMIO observations may synchronize one destination.
 * Do not clear hidden LR/SC reservation as a full register restore would. */
__EXPORT void difftest_set_gpr(unsigned index, uint64_t value) {
  assert(index < 32);
  if (index != 0) cpu.gpr[index] = value;
}

/* Explicit EEI policy trap, after the caller independently verifies the
 * faulting instruction/address. Preserve tval and normal delegation/xPIE. */
__EXPORT void difftest_raise_exception(word_t cause, word_t tval) {
  assert((cause >> 63) == 0);
  cpu.pc = isa_raise_intr_with_tval(cause, cpu.pc, tval);
}

/* The independent custom-instruction oracle supplies decoded length and DMA
 * effects. It does not restore GPR/FPR/CSR or silently execute unknown opcodes. */
__EXPORT void difftest_extension_advance(word_t expected_pc, unsigned length) {
  assert(cpu.pc == expected_pc && (length == 4 || length == 8));
  cpu.pc += length;
}
__EXPORT void difftest_dma_write(paddr_t addr, int len, uint64_t value) {
  assert(len > 0 && len <= 8 && paddr_span_in_pmem(addr, (uint64_t)len));
  dcache_coherent_write(addr, len, value);
  isa_riscv_lr_sc_invalidate(addr, (uint64_t)len);
}

__EXPORT void difftest_csr_snapshot(void *buf) {
  isa_difftest_csr_snapshot((uint64_t *)buf);
}
__EXPORT void difftest_fpr_snapshot(void *buf) {
  isa_difftest_fpr_snapshot((uint64_t *)buf);
}
#endif

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  cpu.pc = isa_raise_intr(NO, cpu.pc);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  (void)port;
  init_mem();
  IFDEF(CONFIG_BPU, init_bpu());
  /* Perform ISA dependent initialization. */
  init_isa();
  nemu_state.state = NEMU_STOP;
}

/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <isa.h>
#include <isa/riscv/plic.h>
#include <platform/platform-map.h>

static RiscvPlicState plic;

void isa_riscv32_plic_reset(void) {
  riscv_plic_reset(&plic);
}

void isa_riscv32_plic_set_irq(uint32_t irq, bool level) {
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  riscv_plic_gateway_update_level(&plic, irq, level);
#else
  (void)irq;
  (void)level;
#endif
}

bool isa_riscv32_plic_maybe_pending(void) {
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  return riscv_plic_any_context_notifies(&plic);
#else
  return false;
#endif
}

word_t isa_riscv32_plic_pending_bits(void) {
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  word_t pending = 0;
  if (riscv_plic_select_notification(&plic, RISCV_PLIC_MACHINE_CONTEXT) != 0) {
    pending |= MIP_MEIP;
  }
  if (riscv_plic_select_notification(&plic, RISCV_PLIC_SUPERVISOR_CONTEXT) != 0) {
    pending |= MIP_SEIP;
  }
  return pending;
#else
  return 0;
#endif
}

bool isa_riscv32_plic_in_range(paddr_t addr) {
  return NEMU_PLATFORM_HAS_RISCV_PLIC &&
      riscv_plic_address_in_aperture(addr);
}

bool isa_riscv32_plic_access_valid(paddr_t addr, int len) {
  return NEMU_PLATFORM_HAS_RISCV_PLIC &&
      riscv_plic_mmio_access_valid(addr, len);
}

word_t isa_riscv32_plic_read(paddr_t addr, int len) {
  /* vaddr 预检负责给 guest 抬 access-fault；这里仍防御直接 paddr 调用。 */
  if (!isa_riscv32_plic_access_valid(addr, len)) return 0;
  uint32_t offset = (uint32_t)(addr - RISCV_PLIC_BASE);
  return riscv_plic_read_register(&plic, offset, NULL);
}

void isa_riscv32_plic_write(paddr_t addr, int len, word_t data) {
  if (!isa_riscv32_plic_access_valid(addr, len)) return;
  uint32_t offset = (uint32_t)(addr - RISCV_PLIC_BASE);
  riscv_plic_write_register(&plic, offset, data, NULL);
}

void isa_riscv32_plic_statistic(void) {
}

/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <cpu/cpu.h>
#include <device/map.h>
#include <isa.h>
#include <utils.h>

#define SYSCON_RESET_SIZE 0x1000u

static uint32_t syscon_reset_reg;

static void syscon_reset_io_handler(uint32_t offset, int len, bool is_write) {
  if (!is_write) return;
  if (len <= 0) return;
  uint32_t end = offset + (uint32_t)len;
  if (end <= offset || offset >= sizeof(syscon_reset_reg)) return;

  uint32_t value = syscon_reset_reg;
  if (value == CONFIG_SYSCON_POWEROFF_VALUE) {
    Log("syscon-reset: poweroff requested value=0x%08x pc=" FMT_WORD,
        value, cpu.pc);
    set_nemu_state(NEMU_END, cpu.pc, 0);
  } else if (value == CONFIG_SYSCON_REBOOT_VALUE) {
    Log("syscon-reset: reboot requested value=0x%08x pc=" FMT_WORD,
        value, cpu.pc);
    set_nemu_state(NEMU_END, cpu.pc, 0);
  } else if ((value & 0xffffu) == 0x3333u) {
    // SiFive Test Finisher FAIL 编码: 低 16 位=0x3333, 高 16 位=退出码。
    // AM guest 的 halt(code!=0) 经此统一退出 → BAD TRAP(halt_ret=code); halt(0) 走 poweroff(0x5555)。
    int code = (int)(value >> 16);
    Log("syscon-reset: test-finisher exit code=%d value=0x%08x pc=" FMT_WORD,
        code, value, cpu.pc);
    set_nemu_state(NEMU_END, cpu.pc, code);
  }
}

void init_syscon_reset() {
  // Linux/OpenSBI 都能识别 syscon-poweroff/syscon-reboot binding；
  // 这里提供对应 MMIO 终点，让 systemd poweroff 走官方关机链路自然退出 NEMU。
  syscon_reset_reg = 0;
  add_mmio_map("syscon-reset", DEV_SYSCON_RESET_MMIO,
      &syscon_reset_reg, SYSCON_RESET_SIZE, syscon_reset_io_handler);
}

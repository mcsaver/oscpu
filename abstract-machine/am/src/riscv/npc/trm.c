#include <am.h>
#include <klib-macros.h>

#include "npc.h"

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
  // 直接沿用 NEMU 的串口地址约定，AM 上层程序换到 NPC 时不需要重新学习一套 UART 地址图。
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  // 用 ebreak + a0 退出，和当前 NPC 顶层导出的 exit_code/exit_is_ebreak 观测口保持一致。
  npc_trap(code);

  while (1);
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}

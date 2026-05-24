#include <am.h>
#include <klib-macros.h>

#include "ysyxsoc.h"

extern char _heap_start;
extern char _heap_end;
int main(const char *args);

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER);

void putch(char ch) {
  // ysyxSoC 的可用串口是 0x1000_0000 的 16550 THR；AM 基础输出直接落到这一路设备。
  outb(YSYXSOC_UART_THR, ch);
}

void halt(int code) {
  // 继续沿用 AM/NPC 的 ebreak + a0 退出协议，便于 npc/soc 后端和 difftest 识别 GOOD/BAD TRAP。
  ysyxsoc_trap(code);

  while (1);
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}

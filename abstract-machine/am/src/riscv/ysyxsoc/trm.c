#include <am.h>
#include <klib-macros.h>

#include "ysyxsoc.h"

extern char _heap_start;
extern char _heap_end;
int main(const char *args);

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER);

void putch(char ch) {
  // 真实 16550 发送 FIFO 有容量限制；等待 THR ready 后再写，避免长字符串覆盖 FIFO。
  ysyxsoc_uart_putc(ch);
}

void halt(int code) {
  // 继续沿用 AM/NPC 的 ebreak + a0 退出协议，便于 npc/soc 后端和 difftest 识别 GOOD/BAD TRAP。
  ysyxsoc_trap(code);

  while (1);
}

void _trm_init() {
  ysyxsoc_uart_init();
  int ret = main(mainargs);
  halt(ret);
}

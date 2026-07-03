#include <am.h>
#include <nemu.h>

extern char _heap_start;
int main(const char *args);

//该结构用于指示堆区的起始和末尾
Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

//用于输出一个字符
void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

//用于结束程序的运行
void halt(int code) {
#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
  // 统一到设备树 reset_syscon (SiFive Test Finisher), 与 Linux poweroff 走同一退出终点:
  //   code==0 → 0x5555 (poweroff/pass) → HIT GOOD TRAP
  //   code!=0 → (code<<16)|0x3333 (fail) → HIT BAD TRAP(halt_ret=code)
  // 不再用 ebreak: NEMU system 模式把 ebreak 当官方 breakpoint 异常(ACT4 依赖), 不能兼作退出协议。
  outl(SYSCON_ADDR, code == 0 ? 0x5555u : (((uint32_t)code << 16) | 0x3333u));
#else
  nemu_trap(code);
#endif

  // should not reach here
  while (1);
}

//用于进行TRM相关的初始化工作
void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}

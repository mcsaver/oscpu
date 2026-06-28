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
  // 为进入 S/U 模式的 cpu-test(sv39/sbi/plic/linux 等)在 M-mode 下放行 PMP。
  // 为什么这么改：NPC 核已按 RISC-V 规范实现 PMP——当没有任何 PMP 条目匹配时，
  // S/U 模式访问一律被拒绝(access fault)；只有 M 模式默认放行。AM 启动默认不配
  // 任何 PMP 条目，于是这些测试一旦 mret 进入 S-mode，第一条取指/访存就 access
  // fault，进而陷入 M<->S 反复 trap 死循环或直接 BAD TRAP。真实固件(如 OpenSBI)
  // 在交给 S-mode 前同样会先配 PMP，这里用一条 NAPOT 覆盖全地址空间 + RWX 的
  // 条目对齐该约定；改完后所有 S-mode cpu-test 能像旧的宽松默认一样获得访问授权，
  // 而 M-mode 行为与核的 PMP 规范实现都不受影响。
  asm volatile(
    "li t0, -1\n"          // pmpaddr0 全 1 -> NAPOT 覆盖整个物理地址空间
    "csrw pmpaddr0, t0\n"
    "li t0, 0x1f\n"        // pmp0cfg = A=NAPOT(0x18) | X(0x4) | W(0x2) | R(0x1)
    "csrw pmpcfg0, t0\n"
    ::: "t0");
  int ret = main(mainargs);
  halt(ret);
}

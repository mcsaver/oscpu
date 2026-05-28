#ifndef __AM_RISCV_YSYXSOC_H__
#define __AM_RISCV_YSYXSOC_H__

#include <riscv/riscv.h>

#define YSYXSOC_CLINT_BASE      0x02000000ul
#define YSYXSOC_CLINT_MTIME     (YSYXSOC_CLINT_BASE + 0x0000bff8ul)
#define YSYXSOC_UART_BASE       0x10000000ul
#define YSYXSOC_UART_THR        (YSYXSOC_UART_BASE + 0)
#define YSYXSOC_UART_RBR        (YSYXSOC_UART_BASE + 0)
#define YSYXSOC_UART_DLL        (YSYXSOC_UART_BASE + 0)
#define YSYXSOC_UART_DLM        (YSYXSOC_UART_BASE + 1)
#define YSYXSOC_UART_FCR        (YSYXSOC_UART_BASE + 2)
#define YSYXSOC_UART_LCR        (YSYXSOC_UART_BASE + 3)
#define YSYXSOC_UART_LSR        (YSYXSOC_UART_BASE + 5)
#define YSYXSOC_SPI_BASE        0x10001000ul
#define YSYXSOC_GPIO_BASE       0x10002000ul
#define YSYXSOC_PS2_BASE        0x10011000ul
#define YSYXSOC_MROM_BASE       0x20000000ul
#define YSYXSOC_VGA_BASE        0x21000000ul
#define YSYXSOC_FLASH_BASE      0x30000000ul
#define YSYXSOC_PSRAM_BASE      0x80000000ul
#define YSYXSOC_PSRAM_SIZE      (4ul * 1024ul * 1024ul)
#define YSYXSOC_SRAM_BASE       0x0f000000ul
#define YSYXSOC_SRAM_SIZE       (8ul * 1024ul)
#define YSYXSOC_SDRAM_BASE      0xa0000000ul
#define YSYXSOC_SDRAM_SIZE      (32ul * 1024ul * 1024ul)

#define PMEM_END (YSYXSOC_SRAM_BASE + YSYXSOC_SRAM_SIZE)

#ifndef YSYXSOC_HAS_INPUT
#define YSYXSOC_HAS_INPUT 0
#endif

#ifndef YSYXSOC_HAS_GPU
#define YSYXSOC_HAS_GPU 0
#endif

#ifndef YSYXSOC_GPU_WIDTH
#define YSYXSOC_GPU_WIDTH 400
#endif

#ifndef YSYXSOC_GPU_HEIGHT
#define YSYXSOC_GPU_HEIGHT 300
#endif

#ifndef YSYXSOC_MTIME_TICKS_PER_US
#define YSYXSOC_MTIME_TICKS_PER_US 1
#endif

#define ysyxsoc_trap(code) asm volatile("mv a0, %0; ebreak" : : "r"(code))

static inline void ysyxsoc_uart_init(void) {
  // ysyxSoCFull 里的真实 16550 发送器依赖除数锁存器产生 bit enable；TRM 入口先配置好 8N1 + divisor=1。
  outb(YSYXSOC_UART_LCR, 0x83);
  outb(YSYXSOC_UART_DLL, 0x01);
  outb(YSYXSOC_UART_DLM, 0x00);
  outb(YSYXSOC_UART_FCR, 0x07);
  outb(YSYXSOC_UART_LCR, 0x03);
}

static inline void ysyxsoc_uart_wait_tx_ready(void) {
  while ((inb(YSYXSOC_UART_LSR) & 0x20) == 0) {
  }
}

static inline void ysyxsoc_uart_putc(char ch) {
  ysyxsoc_uart_wait_tx_ready();
  outb(YSYXSOC_UART_THR, ch);
}

#endif

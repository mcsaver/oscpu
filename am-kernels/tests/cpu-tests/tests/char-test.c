#include "trap.h"

static void emit_by_putch(const char *s) {
  while (*s) putch(*s++);
}

#if defined(__PLATFORM_YSYXSOC)
static void emit_by_uart_tx(const char *s) {
  while (*s) io_write(AM_UART_TX, *s++);
}
#endif

int main() {
  emit_by_putch("char-test: putch path -> 0123456789 ABC xyz\n");

#if defined(__PLATFORM_YSYXSOC)
  // UART handlers are statically registered; this test only needs the serial path.
  AM_UART_CONFIG_T cfg = io_read(AM_UART_CONFIG);
  check(cfg.present);

  emit_by_uart_tx("char-test: AM_UART_TX path -> ysyxSoC UART OK\n");

  AM_UART_RX_T rx = io_read(AM_UART_RX);
  check(rx.data == (char)-1);
#endif

  return 0;
}

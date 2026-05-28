#include <am.h>

#include "ysyxsoc.h"

void __am_uart_tx(AM_UART_TX_T *uart) {
  ysyxsoc_uart_putc(uart->data);
}

void __am_uart_rx(AM_UART_RX_T *uart) {
  uint8_t lsr = inb(YSYXSOC_UART_LSR);
  uart->data = (lsr & 0x01) ? (char)inb(YSYXSOC_UART_RBR) : (char)-1;
}

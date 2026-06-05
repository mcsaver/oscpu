/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <utils.h>
#include <device/map.h>
#include <isa.h>
#ifndef CONFIG_TARGET_AM
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

/* http://en.wikibooks.org/wiki/Serial_Programming/8250_UART_Programming */
// NOTE: this is compatible to 16550

#define UART_RBR 0
#define UART_THR 0
#define UART_DLL 0
#define UART_IER 1
#define UART_DLM 1
#define UART_IIR 2
#define UART_FCR 2
#define UART_LCR 3
#define UART_MCR 4
#define UART_LSR 5
#define UART_MSR 6
#define UART_SCR 7

#define UART_LCR_DLAB 0x80
#define UART_LSR_DR   0x01
#define UART_LSR_THRE 0x20
#define UART_LSR_TEMT 0x40
#define UART_IER_RDI  0x01
#define UART_IER_THRI 0x02
#define UART_IIR_NO_INT 0x01
#define UART_IIR_THRI   0x02
#define UART_IIR_RDI    0x04
#define UART_PLIC_IRQ   1u
#define UART_RX_FIFO_SIZE 4096u
#define UART_RX_FIFO_MASK (UART_RX_FIFO_SIZE - 1u)
#define UART_RX_POLL_CHUNK 256u

static uint8_t *serial_base = NULL;
static uint8_t rx_fifo[UART_RX_FIFO_SIZE];
static uint32_t rx_head = 0;
static uint32_t rx_tail = 0;

#ifdef CONFIG_SERIAL_INPUT_FIFO
static int serial_fifo_fd = -1;
static const char *serial_fifo_path = "/tmp/nemu.serial";
#endif

static bool serial_rx_empty(void) {
  return rx_head == rx_tail;
}

static bool serial_rx_full(void) {
  return ((rx_tail + 1u) & UART_RX_FIFO_MASK) == rx_head;
}

static void serial_refresh_lsr(void) {
  serial_base[UART_LSR] = UART_LSR_THRE | UART_LSR_TEMT;
  if (!serial_rx_empty()) {
    serial_base[UART_LSR] |= UART_LSR_DR;
  }
}

static void serial_rx_push(uint8_t ch) {
  if (serial_rx_full()) {
    // Linux console 输入不能阻塞 NEMU；FIFO 满时丢最旧字节，保留最新交互输入。
    rx_head = (rx_head + 1u) & UART_RX_FIFO_MASK;
  }
  rx_fifo[rx_tail] = ch;
  rx_tail = (rx_tail + 1u) & UART_RX_FIFO_MASK;
  serial_refresh_lsr();
}

static bool serial_rx_pop(uint8_t *ch) {
  if (serial_rx_empty()) {
    return false;
  }
  *ch = rx_fifo[rx_head];
  rx_head = (rx_head + 1u) & UART_RX_FIFO_MASK;
  serial_refresh_lsr();
  return true;
}

static void serial_rx_clear(void) {
  rx_head = rx_tail = 0;
  serial_refresh_lsr();
}

static bool serial_tx_irq_pending(void) {
  return (serial_base[UART_IER] & UART_IER_THRI) &&
         (serial_base[UART_LSR] & UART_LSR_THRE);
}

static bool serial_rx_irq_pending(void) {
  return (serial_base[UART_IER] & UART_IER_RDI) &&
         (serial_base[UART_LSR] & UART_LSR_DR);
}

static void serial_update_irq(void) {
  IFDEF(CONFIG_ISA_riscv, isa_riscv32_plic_set_irq(UART_PLIC_IRQ,
        serial_tx_irq_pending() || serial_rx_irq_pending()));
}

static void serial_putc(char ch) {
  MUXDEF(CONFIG_TARGET_AM, putch(ch), putc(ch, stderr));
}

#if defined(CONFIG_SERIAL_INPUT_STDIN) || defined(CONFIG_SERIAL_INPUT_FIFO)
static bool serial_fd_ready(int fd) {
  fd_set readfds;
  struct timeval timeout = {0, 0};
  FD_ZERO(&readfds);
  FD_SET(fd, &readfds);
  return select(fd + 1, &readfds, NULL, NULL, &timeout) > 0;
}

static void serial_poll_fd(int fd, bool *eof_seen) {
  if (fd < 0 || (eof_seen != NULL && *eof_seen) || !serial_fd_ready(fd)) {
    return;
  }

  uint8_t buf[UART_RX_POLL_CHUNK];
  ssize_t nread = read(fd, buf, sizeof(buf));
  if (nread > 0) {
    for (ssize_t i = 0; i < nread; i++) {
      serial_rx_push(buf[i]);
    }
  } else if (nread == 0 && eof_seen != NULL) {
    *eof_seen = true;
  } else if (nread < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
    if (eof_seen != NULL) {
      *eof_seen = true;
    }
  }
}
#endif

void serial_poll_input(void) {
#ifdef CONFIG_SERIAL_INPUT_STDIN
  static bool stdin_eof = false;
  serial_poll_fd(STDIN_FILENO, &stdin_eof);
#endif
#ifdef CONFIG_SERIAL_INPUT_FIFO
  serial_poll_fd(serial_fifo_fd, NULL);
#endif
  if (serial_base != NULL) {
    serial_refresh_lsr();
    serial_update_irq();
  }
}

static void serial_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1);
  bool dlab = (serial_base[UART_LCR] & UART_LCR_DLAB) != 0;

  if (is_write) {
    switch (offset) {
      case UART_THR:
        if (dlab) {
          serial_base[UART_DLL] = serial_base[offset];
        } else {
          // NEMU 发送是立即完成的，写 THR 后重新保持 THRE/TEMT，
          // 后续中断是否投递由 IER.THRI 和 PLIC in-service 共同决定。
          serial_putc(serial_base[UART_THR]);
        }
        break;
      case UART_IER:
        if (dlab) {
          serial_base[UART_DLM] = serial_base[offset];
        } else {
          serial_base[UART_IER] &= 0x0f;
        }
        break;
      case UART_FCR:
        if (serial_base[UART_FCR] & 0x02) {
          // 16550 FCR bit1 清 RX FIFO；Linux 初始化串口时会依赖这个动作复位输入状态。
          serial_rx_clear();
        }
        break;
      case UART_LCR:
      case UART_MCR:
      case UART_SCR:
        break;
      default:
        break;
    }
    serial_refresh_lsr();
    serial_update_irq();
    return;
  }

  serial_poll_input();
  switch (offset) {
    case UART_RBR:
      if (!dlab) {
        uint8_t ch = 0;
        serial_rx_pop(&ch);
        serial_base[UART_RBR] = ch;
      }
      break;
    case UART_IER:
      break;
    case UART_IIR:
      if (serial_rx_irq_pending()) {
        serial_base[UART_IIR] = UART_IIR_RDI;
      } else {
        serial_base[UART_IIR] = serial_tx_irq_pending() ? UART_IIR_THRI : UART_IIR_NO_INT;
      }
      break;
    case UART_LCR:
    case UART_MCR:
    case UART_SCR:
      break;
    case UART_LSR:
      serial_refresh_lsr();
      break;
    case UART_MSR:
      serial_base[UART_MSR] = 0;
      break;
    default:
      serial_base[offset] = 0;
      break;
  }
  serial_update_irq();
}

void init_serial() {
  serial_base = new_space(8);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map ("serial", CONFIG_SERIAL_PORT, serial_base, 8, serial_io_handler);
#else
  add_mmio_map("serial", CONFIG_SERIAL_MMIO, serial_base, 8, serial_io_handler);
#endif
  serial_refresh_lsr();
#ifdef CONFIG_SERIAL_INPUT_FIFO
  const char *fifo_env = getenv("NEMU_SERIAL_FIFO");
  if (fifo_env != NULL && fifo_env[0] != '\0') {
    // 自动化 Linux/systemd gate 会并行或连续启动 NEMU；允许每次运行指定独立 FIFO，避免复用 /tmp/nemu.serial 污染输入。
    serial_fifo_path = fifo_env;
  }
  if (mkfifo(serial_fifo_path, 0600) != 0 && errno != EEXIST) {
    Log("serial: cannot create input FIFO %s: %s", serial_fifo_path, strerror(errno));
  }
  serial_fifo_fd = open(serial_fifo_path, O_RDWR | O_NONBLOCK);
  if (serial_fifo_fd < 0) {
    Log("serial: cannot open input FIFO %s: %s", serial_fifo_path, strerror(errno));
  }
#endif
  serial_update_irq();

}

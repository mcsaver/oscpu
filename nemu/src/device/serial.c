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
#include <device/uart16550.h>
#include <isa.h>

#ifndef CONFIG_TARGET_AM
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

/*
 * NEMU serial front-end.
 *
 * The 16550A device model lives in uart16550.c.  This file owns only the
 * platform shell around it: NEMU IOMap registration, host input endpoints,
 * TX output, and the RISC-V PLIC IRQ wire.
 */

#define SERIAL_UART0_IRQ 1u
#define SERIAL_HOST_RX_POLL_CHUNK 512u
#define SERIAL_HOST_RX_POLL_BUDGET 16u
#define SERIAL_HOST_RX_STAGING_CAP 1048576u

#if !defined(CONFIG_TARGET_AM) && \
    (defined(CONFIG_SERIAL_INPUT_STDIN) || defined(CONFIG_SERIAL_INPUT_FIFO))
#define SERIAL_HAS_HOST_RX 1
#endif

#ifdef SERIAL_HAS_HOST_RX
typedef struct {
  uint8_t *data;
  uint32_t capacity;
  uint32_t head;
  uint32_t tail;
  uint32_t count;
} SerialByteFifo;
#endif

typedef struct {
  const char *name;
  uint32_t irq;
  Uart16550 *uart;
  Uart16550BusProfile bus_profile;
  uint32_t bus_map_size;
  uint8_t *bus_space;

#ifdef SERIAL_HAS_HOST_RX
  SerialByteFifo host_rx;
  uint8_t *host_rx_storage;
  uint64_t host_rx_dropped;
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_STDIN)
  bool stdin_eof;
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_FIFO)
  int fifo_fd;
  const char *fifo_path;
#endif
} SerialPort;

static SerialPort serial0 = {
  .name = "serial",
  .irq = SERIAL_UART0_IRQ,
  .bus_profile = UART16550_BUS_PROFILE_8BIT,
#if !defined(CONFIG_TARGET_AM) && defined(CONFIG_SERIAL_INPUT_FIFO)
  .fifo_fd = -1,
  .fifo_path = "/tmp/nemu.serial",
#endif
};

static void serial_port_tx(void *opaque, uint8_t ch) {
  SerialPort *port = (SerialPort *)opaque;
  (void)port;
  MUXDEF(CONFIG_TARGET_AM, putch(ch), putc(ch, stderr));
}

static void serial_port_irq(void *opaque, bool level) {
  SerialPort *port = (SerialPort *)opaque;
#ifdef CONFIG_ISA_riscv
  isa_riscv32_plic_set_irq(port->irq, level);
#else
  (void)port;
  (void)level;
#endif
}

#ifdef SERIAL_HAS_HOST_RX
static void serial_fifo_bind(SerialByteFifo *fifo, uint8_t *data,
    uint32_t capacity) {
  fifo->data = data;
  fifo->capacity = capacity;
  fifo->head = fifo->tail = fifo->count = 0;
}

static bool serial_fifo_empty(const SerialByteFifo *fifo) {
  return fifo->count == 0;
}

static bool serial_fifo_full(const SerialByteFifo *fifo) {
  return fifo->count == fifo->capacity;
}

static bool serial_fifo_push(SerialByteFifo *fifo, uint8_t value) {
  if (serial_fifo_full(fifo)) {
    return false;
  }
  fifo->data[fifo->tail] = value;
  fifo->tail = (fifo->tail + 1u) % fifo->capacity;
  fifo->count++;
  return true;
}

static bool serial_fifo_pop(SerialByteFifo *fifo, uint8_t *value) {
  if (serial_fifo_empty(fifo)) {
    return false;
  }
  *value = fifo->data[fifo->head];
  fifo->head = (fifo->head + 1u) % fifo->capacity;
  fifo->count--;
  return true;
}

static void serial_host_rx_init(SerialPort *port) {
  /*
   * 宿主可能一次性写入整段 guest-check 脚本；这是仿真前端能力，
   * 不是 16550A 硬件 FIFO，所以大缓冲放在 SerialPort 层维护。
   */
  port->host_rx_storage =
      (uint8_t *)calloc(SERIAL_HOST_RX_STAGING_CAP, sizeof(uint8_t));
  Assert(port->host_rx_storage != NULL,
      "can not allocate serial host RX staging queue");
  serial_fifo_bind(&port->host_rx, port->host_rx_storage,
      SERIAL_HOST_RX_STAGING_CAP);
}

static void serial_host_rx_enqueue(SerialPort *port, const uint8_t *data,
    size_t len) {
  for (size_t i = 0; i < len; i++) {
    if (!serial_fifo_push(&port->host_rx, data[i])) {
      uint8_t dropped = 0;
      (void)serial_fifo_pop(&port->host_rx, &dropped);
      (void)serial_fifo_push(&port->host_rx, data[i]);
      port->host_rx_dropped++;
    }
  }
}

static void serial_host_rx_drain_to_uart(SerialPort *port) {
  if (port->uart == NULL) {
    return;
  }

  uint8_t chunk[SERIAL_HOST_RX_POLL_CHUNK];
  while (!serial_fifo_empty(&port->host_rx)) {
    uint32_t room = uart16550_rx_room(port->uart);
    if (room == 0) {
      break;
    }

    size_t n = 0;
    while (n < sizeof(chunk) && n < room &&
        serial_fifo_pop(&port->host_rx, &chunk[n])) {
      n++;
    }
    if (n == 0) {
      break;
    }
    size_t consumed = uart16550_receive(port->uart, chunk, n);
    Assert(consumed == n, "serial host RX drain lost bytes: consumed=%zu n=%zu",
        consumed, n);
  }
}

static bool serial_fd_ready(int fd) {
  fd_set readfds;
  struct timeval timeout = {0, 0};
  FD_ZERO(&readfds);
  FD_SET(fd, &readfds);
  return select(fd + 1, &readfds, NULL, NULL, &timeout) > 0;
}

static void serial_host_poll_fd(SerialPort *port, int fd, bool *eof_seen) {
  if (fd < 0 || (eof_seen != NULL && *eof_seen)) {
    return;
  }

  for (uint32_t chunk = 0; chunk < SERIAL_HOST_RX_POLL_BUDGET; chunk++) {
    if (!serial_fd_ready(fd)) {
      break;
    }

    uint8_t buf[SERIAL_HOST_RX_POLL_CHUNK];
    ssize_t nread = read(fd, buf, sizeof(buf));
    if (nread > 0) {
      serial_host_rx_enqueue(port, buf, (size_t)nread);
    } else if (nread == 0 && eof_seen != NULL) {
      *eof_seen = true;
      break;
    } else if (nread < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
        break;
      }
      if (eof_seen != NULL) {
        *eof_seen = true;
      }
      break;
    }
  }
  serial_host_rx_drain_to_uart(port);
}
#endif

static uint64_t serial_bus_load(const SerialPort *port, uint32_t offset,
    int len) {
  uint64_t value = 0;
  if (port->bus_space == NULL) {
    return value;
  }

  for (int i = 0; i < len; i++) {
    uint32_t pos = offset + (uint32_t)i;
    if (pos < port->bus_map_size) {
      value |= (uint64_t)port->bus_space[pos] << (i * 8);
    }
  }
  return value;
}

static void serial_bus_store(SerialPort *port, uint32_t offset, int len,
    uint64_t value) {
  if (port->bus_space == NULL) {
    return;
  }

  for (int i = 0; i < len; i++) {
    uint32_t pos = offset + (uint32_t)i;
    if (pos < port->bus_map_size) {
      port->bus_space[pos] = (uint8_t)(value >> (i * 8));
    }
  }
}

static void serial_port_poll_host(SerialPort *port) {
  if (port->uart == NULL) {
    return;
  }
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_STDIN)
  serial_host_poll_fd(port, STDIN_FILENO, &port->stdin_eof);
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_FIFO)
  serial_host_poll_fd(port, port->fifo_fd, NULL);
#endif
#ifdef SERIAL_HAS_HOST_RX
  serial_host_rx_drain_to_uart(port);
#endif
  if (port->bus_space != NULL) {
    uart16550_service(port->uart);
  }
}

void serial_poll_input(void) {
  serial_port_poll_host(&serial0);
}

static void serial_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len >= 1 && len <= 8);
  SerialPort *port = &serial0;
  if (port->uart == NULL) {
    return;
  }

  if (is_write) {
    uint64_t value = serial_bus_load(port, offset, len);
    uart16550_bus_write(port->uart, &port->bus_profile, offset, len, value);
#ifdef SERIAL_HAS_HOST_RX
    serial_host_rx_drain_to_uart(port);
#endif
    uart16550_service(port->uart);
    return;
  }

  serial_port_poll_host(port);
  uint64_t value = uart16550_bus_read(port->uart, &port->bus_profile,
      offset, len);
  serial_bus_store(port, offset, len, value);
#ifdef SERIAL_HAS_HOST_RX
  serial_host_rx_drain_to_uart(port);
#endif
  uart16550_service(port->uart);
}

static void serial_register_bus(SerialPort *port) {
  /*
   * 当前 Linux DTS 是 ns16550a + reg-shift=0；这里仍通过 profile 计算 PIO
   * span，避免前端重新隐含“offset 就是寄存器号”的旧 mini UART 假设。
   */
  port->bus_map_size = MUXDEF(CONFIG_HAS_PORT_IO,
      uart16550_bus_profile_span(&port->bus_profile),
      UART16550_MMIO_MAP_SIZE);
  port->bus_space = new_space(port->bus_map_size);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map(port->name, CONFIG_SERIAL_PORT, port->bus_space,
      port->bus_map_size, serial_io_handler);
#else
  add_mmio_map(port->name, CONFIG_SERIAL_MMIO, port->bus_space,
      port->bus_map_size, serial_io_handler);
#endif
}

static void serial_open_host_inputs(SerialPort *port) {
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_FIFO)
  const char *fifo_env = getenv("NEMU_SERIAL_FIFO");
  if (fifo_env != NULL && fifo_env[0] != '\0') {
    port->fifo_path = fifo_env;
  }
  if (mkfifo(port->fifo_path, 0600) != 0 && errno != EEXIST) {
    Log("serial: cannot create input FIFO %s: %s", port->fifo_path,
        strerror(errno));
  }
  port->fifo_fd = open(port->fifo_path, O_RDWR | O_NONBLOCK);
  if (port->fifo_fd < 0) {
    Log("serial: cannot open input FIFO %s: %s", port->fifo_path,
        strerror(errno));
  }
#else
  (void)port;
#endif
}

void init_serial() {
  SerialPort *port = &serial0;
  Uart16550Ops ops = {
    .tx = serial_port_tx,
    .irq = serial_port_irq,
  };
  Uart16550Config config = {
    .ops = &ops,
    .opaque = port,
  };
  port->uart = uart16550_create(&config);
  Assert(port->uart != NULL, "can not create serial 16550A device");
#ifdef SERIAL_HAS_HOST_RX
  serial_host_rx_init(port);
#endif
  serial_register_bus(port);
  serial_open_host_inputs(port);
  uart16550_service(port->uart);
}

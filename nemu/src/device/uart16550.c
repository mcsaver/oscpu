/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <device/uart16550.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>

/*
 * Linux 的 8250/ns16550a 驱动会依赖寄存器别名、IIR 读取确认、FIFO trigger
 * 和 level IRQ 语义。这里刻意把 UART core 做成纯硬件状态机：只保留真实
 * 16550 寄存器/FIFO/IRQ，不保存宿主脚本输入的大缓冲；宿主 staging 属于
 * SerialPort 前端，避免把自动化输入能力伪装成 UART 硬件容量。
 */

typedef struct {
  uint8_t *data;
  uint32_t capacity;
  uint32_t head;
  uint32_t tail;
  uint32_t count;
} Uart16550ByteFifo;

struct Uart16550 {
  uint8_t dll;
  uint8_t dlm;
  uint8_t ier;
  uint8_t fcr;
  uint8_t lcr;
  uint8_t mcr;
  uint8_t msr;
  uint8_t scr;
  uint8_t lsr_error_bits;
  uint8_t rx_trigger;
  bool fifo_enabled;
  bool thr_irq_pending;
  bool irq_level;

  Uart16550ByteFifo rx_fifo;
  uint8_t *rx_storage;

  Uart16550Ops ops;
  void *opaque;
};

static void fifo_bind(Uart16550ByteFifo *fifo, uint8_t *data, uint32_t capacity) {
  fifo->data = data;
  fifo->capacity = capacity;
  fifo->head = fifo->tail = fifo->count = 0;
}

static bool fifo_empty(const Uart16550ByteFifo *fifo) {
  return fifo->count == 0;
}

static bool fifo_full(const Uart16550ByteFifo *fifo) {
  return fifo->count == fifo->capacity;
}

static void fifo_clear(Uart16550ByteFifo *fifo) {
  fifo->head = fifo->tail = fifo->count = 0;
}

static bool fifo_push(Uart16550ByteFifo *fifo, uint8_t value) {
  if (fifo_full(fifo)) {
    return false;
  }
  fifo->data[fifo->tail] = value;
  fifo->tail = (fifo->tail + 1u) % fifo->capacity;
  fifo->count++;
  return true;
}

static bool fifo_pop(Uart16550ByteFifo *fifo, uint8_t *value) {
  if (fifo_empty(fifo)) {
    return false;
  }
  *value = fifo->data[fifo->head];
  fifo->head = (fifo->head + 1u) % fifo->capacity;
  fifo->count--;
  return true;
}

static uint32_t uart_rx_visible_capacity(const Uart16550 *uart) {
  return uart->fifo_enabled ? uart->rx_fifo.capacity : 1u;
}

static bool uart_rx_full(const Uart16550 *uart) {
  return uart->rx_fifo.count >= uart_rx_visible_capacity(uart);
}

static bool uart_rx_push(Uart16550 *uart, uint8_t value) {
  if (uart_rx_full(uart)) {
    uart->lsr_error_bits |= UART16550_LSR_OE;
    return false;
  }
  return fifo_push(&uart->rx_fifo, value);
}

static uint8_t uart_lsr_value(const Uart16550 *uart) {
  uint8_t lsr = UART16550_LSR_THRE | UART16550_LSR_TEMT;
  if (!fifo_empty(&uart->rx_fifo)) {
    lsr |= UART16550_LSR_DR;
  }
  lsr |= uart->lsr_error_bits;
  if (uart->lsr_error_bits != 0 && uart->fifo_enabled) {
    lsr |= UART16550_LSR_FIFO;
  }
  return lsr;
}

static uint8_t uart_fifo_iir_bits(const Uart16550 *uart) {
  return uart->fifo_enabled ? UART16550_IIR_FIFO_BITS : 0;
}

static uint8_t uart_rx_interrupt_id(const Uart16550 *uart) {
  if (fifo_empty(&uart->rx_fifo)) {
    return UART16550_IIR_NO_INT;
  }
  if (!uart->fifo_enabled || uart->rx_fifo.count >= uart->rx_trigger) {
    return UART16550_IIR_RDI;
  }

  /*
   * 未建模真实 baud 时间，但低水位字符也必须能唤醒 Linux tty。
   * CTI 在这里表达“已有字符等待”，避免 trigger > 1 时单字节输入沉睡。
   */
  return UART16550_IIR_CTI;
}

static uint8_t uart_interrupt_id(const Uart16550 *uart) {
  if ((uart->ier & UART16550_IER_RLSI) && uart->lsr_error_bits != 0) {
    return UART16550_IIR_RLSI;
  }
  if (uart->ier & UART16550_IER_RDI) {
    uint8_t rx_id = uart_rx_interrupt_id(uart);
    if (rx_id != UART16550_IIR_NO_INT) {
      return rx_id;
    }
  }
  if ((uart->ier & UART16550_IER_THRI) && uart->thr_irq_pending) {
    return UART16550_IIR_THRI;
  }
  if ((uart->ier & UART16550_IER_MSI) &&
      (uart->msr & UART16550_MSR_DELTA_MASK) != 0) {
    return UART16550_IIR_MSI;
  }
  return UART16550_IIR_NO_INT;
}

static void uart_refresh_irq(Uart16550 *uart) {
  bool level = uart_interrupt_id(uart) != UART16550_IIR_NO_INT;
  if (level == uart->irq_level) {
    return;
  }
  uart->irq_level = level;
  if (uart->ops.irq != NULL) {
    uart->ops.irq(uart->opaque, level);
  }
}

static uint32_t uart_bus_stride(const Uart16550BusProfile *profile) {
  assert(profile != NULL);
  assert(profile->reg_shift < 8);
  uint32_t stride = 1u << profile->reg_shift;
  assert(profile->reg_io_width == 1 || profile->reg_io_width == 2 ||
      profile->reg_io_width == 4 || profile->reg_io_width == 8);
  assert(profile->reg_io_width <= stride);
  return stride;
}

static bool uart_bus_decode(const Uart16550BusProfile *profile,
    uint32_t offset, uint32_t *reg) {
  uint32_t stride = uart_bus_stride(profile);
  uint32_t lane = offset & (stride - 1u);
  if (lane != 0) {
    return false;
  }

  uint32_t decoded = offset >> profile->reg_shift;
  if (decoded >= UART16550_REG_COUNT) {
    return false;
  }
  *reg = decoded;
  return true;
}

static void uart_emit_tx(Uart16550 *uart, uint8_t ch) {
  if (uart->ops.tx != NULL) {
    uart->ops.tx(uart->opaque, ch);
  }
}

static void uart_raise_thr_irq_if_empty(Uart16550 *uart) {
  if (uart->ier & UART16550_IER_THRI) {
    uart->thr_irq_pending = true;
  }
}

static uint8_t modem_status_from_mcr(const Uart16550 *uart) {
  if ((uart->mcr & UART16550_MCR_LOOP) == 0) {
    return UART16550_MSR_CTS | UART16550_MSR_DSR | UART16550_MSR_DCD;
  }

  uint8_t status = 0;
  if (uart->mcr & UART16550_MCR_RTS)  status |= UART16550_MSR_CTS;
  if (uart->mcr & UART16550_MCR_DTR)  status |= UART16550_MSR_DSR;
  if (uart->mcr & UART16550_MCR_OUT1) status |= UART16550_MSR_RI;
  if (uart->mcr & UART16550_MCR_OUT2) status |= UART16550_MSR_DCD;
  return status;
}

static void uart_refresh_msr(Uart16550 *uart) {
  uint8_t old_status = uart->msr & UART16550_MSR_STATUS_MASK;
  uint8_t old_delta = uart->msr & UART16550_MSR_DELTA_MASK;
  uint8_t new_status = modem_status_from_mcr(uart);
  uint8_t delta = 0;

  if ((old_status ^ new_status) & UART16550_MSR_CTS) delta |= UART16550_MSR_DCTS;
  if ((old_status ^ new_status) & UART16550_MSR_DSR) delta |= UART16550_MSR_DDSR;
  if ((old_status ^ new_status) & UART16550_MSR_RI)  delta |= UART16550_MSR_TERI;
  if ((old_status ^ new_status) & UART16550_MSR_DCD) delta |= UART16550_MSR_DDCD;
  uart->msr = new_status | old_delta | delta;
}

static void uart_receive_wire_byte(Uart16550 *uart, uint8_t value) {
  (void)uart_rx_push(uart, value);
}

static void uart_write_thr(Uart16550 *uart, uint8_t value) {
  uart->thr_irq_pending = false;
  if (uart->mcr & UART16550_MCR_LOOP) {
    uart_receive_wire_byte(uart, value);
  } else {
    uart_emit_tx(uart, value);
  }
  uart_raise_thr_irq_if_empty(uart);
}

static void uart_write_ier(Uart16550 *uart, uint8_t value) {
  uint8_t old_ier = uart->ier;
  uart->ier = value & UART16550_IER_MASK;
  if ((uart->ier & UART16550_IER_THRI) == 0) {
    uart->thr_irq_pending = false;
  } else if ((old_ier & UART16550_IER_THRI) == 0) {
    uart_raise_thr_irq_if_empty(uart);
  }
}

static uint8_t fcr_trigger_level(uint8_t fcr) {
  switch (fcr & UART16550_FCR_TRIGGER) {
    case UART16550_FCR_TRIGGER_4: return 4;
    case UART16550_FCR_TRIGGER_8: return 8;
    case UART16550_FCR_TRIGGER_14: return 14;
    default: return 1;
  }
}

static void uart_write_fcr(Uart16550 *uart, uint8_t value) {
  bool enable_fifo = (value & UART16550_FCR_ENABLE) != 0;
  bool disabling_fifo = uart->fifo_enabled && !enable_fifo;
  uart->fifo_enabled = enable_fifo;
  uart->rx_trigger = fcr_trigger_level(value);
  uart->fcr = value & (UART16550_FCR_ENABLE | UART16550_FCR_DMA |
      UART16550_FCR_TRIGGER);

  if ((value & UART16550_FCR_CLEAR_RX) || disabling_fifo) {
    fifo_clear(&uart->rx_fifo);
    uart->lsr_error_bits = 0;
  }
  if (value & UART16550_FCR_CLEAR_TX) {
    uart_raise_thr_irq_if_empty(uart);
  }
}

static uint8_t uart_read_rbr(Uart16550 *uart) {
  uint8_t value = 0;
  (void)fifo_pop(&uart->rx_fifo, &value);
  return value;
}

static uint8_t uart_read_iir(Uart16550 *uart) {
  uint8_t id = uart_interrupt_id(uart);
  if (id == UART16550_IIR_THRI) {
    uart->thr_irq_pending = false;
  }
  return id | uart_fifo_iir_bits(uart);
}

static uint8_t uart_read_lsr(Uart16550 *uart) {
  uint8_t value = uart_lsr_value(uart);
  uart->lsr_error_bits = 0;
  return value;
}

static uint8_t uart_read_msr(Uart16550 *uart) {
  uint8_t value = uart->msr;
  uart->msr &= UART16550_MSR_STATUS_MASK;
  return value;
}

static uint32_t uart_config_capacity(uint32_t value, uint32_t fallback) {
  return value == 0 ? fallback : value;
}

Uart16550 *uart16550_create(const Uart16550Config *config) {
  uint32_t rx_capacity = UART16550_RX_FIFO_CAP;

  if (config != NULL) {
    rx_capacity = uart_config_capacity(config->rx_fifo_capacity,
        UART16550_RX_FIFO_CAP);
  }
  if (rx_capacity == 0) {
    return NULL;
  }

  Uart16550 *uart = (Uart16550 *)calloc(1, sizeof(*uart));
  if (uart == NULL) {
    return NULL;
  }

  uart->rx_storage = (uint8_t *)calloc(rx_capacity, sizeof(uint8_t));
  if (uart->rx_storage == NULL) {
    uart16550_destroy(uart);
    return NULL;
  }

  fifo_bind(&uart->rx_fifo, uart->rx_storage, rx_capacity);
  if (config != NULL && config->ops != NULL) {
    uart->ops = *config->ops;
    uart->opaque = config->opaque;
  }
  uart->irq_level = true;
  uart16550_reset(uart);
  return uart;
}

void uart16550_destroy(Uart16550 *uart) {
  if (uart == NULL) {
    return;
  }
  free(uart->rx_storage);
  free(uart);
}

void uart16550_reset(Uart16550 *uart) {
  assert(uart != NULL);
  fifo_clear(&uart->rx_fifo);

  uart->dll = 1;
  uart->dlm = 0;
  uart->ier = 0;
  uart->fcr = 0;
  uart->lcr = 0;
  uart->mcr = 0;
  uart->msr = UART16550_MSR_CTS | UART16550_MSR_DSR | UART16550_MSR_DCD;
  uart->scr = 0;
  uart->lsr_error_bits = 0;
  uart->rx_trigger = 1;
  uart->fifo_enabled = false;
  uart->thr_irq_pending = false;
  uart_refresh_irq(uart);
}

uint8_t uart16550_read(Uart16550 *uart, uint32_t offset) {
  assert(uart != NULL);
  if (offset >= UART16550_REG_COUNT) {
    return 0;
  }

  bool dlab = (uart->lcr & UART16550_LCR_DLAB) != 0;
  uint8_t value = 0;
  switch (offset) {
    case UART16550_REG_RBR: value = dlab ? uart->dll : uart_read_rbr(uart); break;
    case UART16550_REG_IER: value = dlab ? uart->dlm : uart->ier; break;
    case UART16550_REG_IIR: value = uart_read_iir(uart); break;
    case UART16550_REG_LCR: value = uart->lcr; break;
    case UART16550_REG_MCR: value = uart->mcr; break;
    case UART16550_REG_LSR: value = uart_read_lsr(uart); break;
    case UART16550_REG_MSR: value = uart_read_msr(uart); break;
    case UART16550_REG_SCR: value = uart->scr; break;
    default: value = 0; break;
  }
  uart_refresh_irq(uart);
  return value;
}

void uart16550_write(Uart16550 *uart, uint32_t offset, uint8_t value) {
  assert(uart != NULL);
  if (offset >= UART16550_REG_COUNT) {
    return;
  }

  bool dlab = (uart->lcr & UART16550_LCR_DLAB) != 0;
  switch (offset) {
    case UART16550_REG_THR:
      if (dlab) {
        uart->dll = value;
      } else {
        uart_write_thr(uart, value);
      }
      break;
    case UART16550_REG_IER:
      if (dlab) {
        uart->dlm = value;
      } else {
        uart_write_ier(uart, value);
      }
      break;
    case UART16550_REG_FCR:
      uart_write_fcr(uart, value);
      break;
    case UART16550_REG_LCR:
      uart->lcr = value;
      break;
    case UART16550_REG_MCR:
      uart->mcr = value & UART16550_MCR_MASK;
      uart_refresh_msr(uart);
      break;
    case UART16550_REG_SCR:
      uart->scr = value;
      break;
    default:
      break;
  }
  uart_refresh_irq(uart);
}

uint32_t uart16550_bus_profile_span(const Uart16550BusProfile *profile) {
  uint32_t stride = uart_bus_stride(profile);
  return ((UART16550_REG_COUNT - 1u) * stride) + profile->reg_io_width;
}

uint64_t uart16550_bus_read(Uart16550 *uart,
    const Uart16550BusProfile *profile, uint32_t offset, int len) {
  assert(uart != NULL);
  assert(len >= 1 && len <= 8);

  uint64_t value = 0;
  for (int i = 0; i < len; i++) {
    uint32_t reg = 0;
    if (uart_bus_decode(profile, offset + (uint32_t)i, &reg)) {
      value |= (uint64_t)uart16550_read(uart, reg) << (i * 8);
    }
  }
  return value;
}

void uart16550_bus_write(Uart16550 *uart,
    const Uart16550BusProfile *profile, uint32_t offset, int len,
    uint64_t value) {
  assert(uart != NULL);
  assert(len >= 1 && len <= 8);

  for (int i = 0; i < len; i++) {
    uint32_t reg = 0;
    if (uart_bus_decode(profile, offset + (uint32_t)i, &reg)) {
      uart16550_write(uart, reg, (uint8_t)(value >> (i * 8)));
    }
  }
}

uint32_t uart16550_rx_room(const Uart16550 *uart) {
  assert(uart != NULL);
  uint32_t visible = uart_rx_visible_capacity(uart);
  return visible > uart->rx_fifo.count ? visible - uart->rx_fifo.count : 0;
}

size_t uart16550_receive(Uart16550 *uart, const uint8_t *data, size_t len) {
  assert(uart != NULL);
  if (data == NULL || len == 0) {
    return 0;
  }
  size_t consumed = 0;
  for (size_t i = 0; i < len; i++) {
    if (!uart_rx_push(uart, data[i])) {
      break;
    }
    consumed++;
  }
  uart_refresh_irq(uart);
  return consumed;
}

void uart16550_service(Uart16550 *uart) {
  assert(uart != NULL);
  uart_refresh_irq(uart);
}

bool uart16550_irq_level(const Uart16550 *uart) {
  assert(uart != NULL);
  return uart->irq_level;
}

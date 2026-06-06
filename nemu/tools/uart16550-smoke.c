#include "../include/device/uart16550.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  uint8_t tx[128];
  size_t tx_len;
  bool irq_level;
  uint32_t irq_edges;
} SmokeSink;

static int failures = 0;

static void check_bool(const char *what, bool got, bool expected) {
  if (got != expected) {
    fprintf(stderr, "[uart16550-smoke] FAIL %s got=%d expected=%d\n",
        what, got, expected);
    failures++;
  }
}

static void check_u8(const char *what, uint8_t got, uint8_t expected) {
  if (got != expected) {
    fprintf(stderr, "[uart16550-smoke] FAIL %s got=0x%02x expected=0x%02x\n",
        what, got, expected);
    failures++;
  }
}

static void check_u64(const char *what, uint64_t got, uint64_t expected) {
  if (got != expected) {
    fprintf(stderr,
        "[uart16550-smoke] FAIL %s got=0x%016llx expected=0x%016llx\n",
        what, (unsigned long long)got, (unsigned long long)expected);
    failures++;
  }
}

static void smoke_tx(void *opaque, uint8_t ch) {
  SmokeSink *sink = (SmokeSink *)opaque;
  if (sink->tx_len < sizeof(sink->tx)) {
    sink->tx[sink->tx_len++] = ch;
  }
}

static void smoke_irq(void *opaque, bool level) {
  SmokeSink *sink = (SmokeSink *)opaque;
  if (sink->irq_level != level) {
    sink->irq_level = level;
    sink->irq_edges++;
  }
}

static void test_reset_and_divisor(Uart16550 *uart) {
  const Uart16550BusProfile byte_profile = UART16550_BUS_PROFILE_8BIT;
  check_u8("reset lsr", uart16550_read(uart, UART16550_REG_LSR),
      UART16550_LSR_THRE | UART16550_LSR_TEMT);
  check_bool("reset irq", uart16550_irq_level(uart), false);

  uart16550_write(uart, UART16550_REG_LCR, UART16550_LCR_DLAB);
  uart16550_bus_write(uart, &byte_profile, UART16550_REG_RBR, 2, 0x3412u);
  check_u64("dlab divisor window",
      uart16550_bus_read(uart, &byte_profile, UART16550_REG_RBR, 4),
      0x80013412ull);
  uart16550_write(uart, UART16550_REG_LCR, 0x03);
}

static void test_tx_irq(Uart16550 *uart, SmokeSink *sink) {
  uart16550_write(uart, UART16550_REG_THR, 'A');
  check_u8("tx byte", sink->tx[0], 'A');
  check_u64("tx len", sink->tx_len, 1);

  uart16550_write(uart, UART16550_REG_IER, UART16550_IER_THRI);
  check_bool("thri irq level", uart16550_irq_level(uart), true);
  check_u8("iir thri", uart16550_read(uart, UART16550_REG_IIR),
      UART16550_IIR_THRI);
  check_bool("iir thri ack", uart16550_irq_level(uart), false);
}

static void test_rx_fifo_burst(Uart16550 *uart) {
  uint8_t data[32];
  for (size_t i = 0; i < sizeof(data); i++) {
    data[i] = (uint8_t)('a' + i);
  }

  uart16550_write(uart, UART16550_REG_FCR, UART16550_FCR_ENABLE);
  uart16550_write(uart, UART16550_REG_IER, UART16550_IER_RDI);
  check_u64("rx room empty fifo", uart16550_rx_room(uart), 16);
  check_u64("rx first fifo fill", uart16550_receive(uart, data, 16), 16);
  check_u64("rx room full fifo", uart16550_rx_room(uart), 0);
  check_u64("rx overflow rejected", uart16550_receive(uart, data + 16, 1), 0);
  check_u8("rx overflow lsr",
      uart16550_read(uart, UART16550_REG_LSR) & UART16550_LSR_OE,
      UART16550_LSR_OE);
  check_bool("rdi irq level", uart16550_irq_level(uart), true);
  check_u8("iir rdi fifo", uart16550_read(uart, UART16550_REG_IIR),
      UART16550_IIR_FIFO_BITS | UART16550_IIR_RDI);

  for (size_t i = 0; i < 16; i++) {
    check_u8("rx burst byte", uart16550_read(uart, UART16550_REG_RBR),
        data[i]);
  }
  check_u64("rx second fifo fill",
      uart16550_receive(uart, data + 16, sizeof(data) - 16), 16);
  for (size_t i = 16; i < sizeof(data); i++) {
    check_u8("rx staged byte", uart16550_read(uart, UART16550_REG_RBR),
        data[i]);
  }
  check_u8("rx drained lsr", uart16550_read(uart, UART16550_REG_LSR),
      UART16550_LSR_THRE | UART16550_LSR_TEMT);

  uart16550_write(uart, UART16550_REG_FCR,
      UART16550_FCR_ENABLE | UART16550_FCR_TRIGGER_14);
  uart16550_receive(uart, (const uint8_t *)"z", 1);
  check_u8("iir cti below trigger",
      uart16550_read(uart, UART16550_REG_IIR),
      UART16550_IIR_FIFO_BITS | UART16550_IIR_CTI);
  check_u8("cti byte", uart16550_read(uart, UART16550_REG_RBR), 'z');
}

static void test_loopback(Uart16550 *uart, SmokeSink *sink) {
  size_t tx_before = sink->tx_len;
  uart16550_write(uart, UART16550_REG_MCR, UART16550_MCR_LOOP);
  uart16550_write(uart, UART16550_REG_THR, 'L');
  check_u64("loopback no host tx", sink->tx_len, tx_before);
  check_u8("loopback dr",
      uart16550_read(uart, UART16550_REG_LSR) & UART16550_LSR_DR,
      UART16550_LSR_DR);
  check_u8("loopback byte", uart16550_read(uart, UART16550_REG_RBR), 'L');
}

static void test_bus_profiles(Uart16550 *uart, SmokeSink *sink) {
  const Uart16550BusProfile byte_profile = UART16550_BUS_PROFILE_8BIT;
  const Uart16550BusProfile reg32_profile = UART16550_BUS_PROFILE_32BIT;

  uart16550_reset(uart);
  check_u64("8bit profile span",
      uart16550_bus_profile_span(&byte_profile), UART16550_REG_COUNT);
  check_u64("32bit profile span",
      uart16550_bus_profile_span(&reg32_profile), 32);

  uart16550_write(uart, UART16550_REG_LCR, UART16550_LCR_DLAB);
  uart16550_bus_write(uart, &reg32_profile, UART16550_REG_DLL << 2, 4,
      0x00000078u);
  uart16550_bus_write(uart, &reg32_profile, UART16550_REG_DLM << 2, 4,
      0x00000056u);
  check_u64("32bit dll low lane",
      uart16550_bus_read(uart, &reg32_profile, UART16550_REG_DLL << 2, 4),
      0x78);
  check_u64("32bit dlm low lane",
      uart16550_bus_read(uart, &reg32_profile, UART16550_REG_DLM << 2, 4),
      0x56);
  check_u64("32bit hole lane",
      uart16550_bus_read(uart, &reg32_profile,
        (UART16550_REG_DLM << 2) + 1u, 1), 0);

  uart16550_write(uart, UART16550_REG_LCR, 0x03);
  size_t tx_before = sink->tx_len;
  uart16550_bus_write(uart, &reg32_profile,
      (UART16550_REG_THR << 2) + 1u, 1, 'x');
  check_u64("32bit hole write ignored", sink->tx_len, tx_before);
  uart16550_bus_write(uart, &reg32_profile, UART16550_REG_THR << 2, 4, 'Q');
  check_u64("32bit tx len", sink->tx_len, tx_before + 1);
  check_u8("32bit tx byte", sink->tx[tx_before], 'Q');
}

int main(void) {
  SmokeSink sink;
  memset(&sink, 0, sizeof(sink));

  Uart16550Ops ops = {
    .tx = smoke_tx,
    .irq = smoke_irq,
  };
  Uart16550Config config = {
    .ops = &ops,
    .opaque = &sink,
  };
  Uart16550 *uart = uart16550_create(&config);
  if (uart == NULL) {
    fputs("[uart16550-smoke] FAIL create uart\n", stderr);
    return 1;
  }

  test_reset_and_divisor(uart);
  test_tx_irq(uart, &sink);
  test_rx_fifo_burst(uart);
  test_loopback(uart, &sink);
  test_bus_profiles(uart, &sink);
  uart16550_destroy(uart);

  if (failures != 0) {
    return 1;
  }
  puts("[uart16550-smoke] PASS");
  return 0;
}

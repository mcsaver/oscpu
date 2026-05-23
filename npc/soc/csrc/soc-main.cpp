// ysyxSoCFull 的最小 Verilator 入口，只用于确认 SoC 顶层和 NPC CPU 包装能完成链接/复位。
#include <cassert>
#include <cstdint>

#include <verilated.h>
#include "VysyxSoCFull.h"

extern "C" void flash_read(int32_t addr, int32_t *data) {
  (void)addr;
  (void)data;
  assert(0);
}

extern "C" void mrom_read(int32_t raddr, int32_t *rdata) {
  (void)raddr;
  (void)rdata;
  assert(0);
}

static void init_inputs(VysyxSoCFull &top) {
  top.externalPins_gpio_in = 0;
  top.externalPins_ps2_clk = 0;
  top.externalPins_ps2_data = 0;
  top.externalPins_uart_rx = 1;
}

static void tick(VysyxSoCFull &top) {
  top.clock = 0;
  top.eval();
  top.clock = 1;
  top.eval();
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  VysyxSoCFull top;
  init_inputs(top);
  top.reset = 1;
  for (int i = 0; i < 10; ++i) tick(top);

  top.reset = 0;
  for (int i = 0; i < 1000 && !Verilated::gotFinish(); ++i) tick(top);

  top.final();
  return 0;
}

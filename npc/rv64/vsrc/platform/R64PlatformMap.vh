`ifndef R64_PLATFORM_MAP_VH
`define R64_PLATFORM_MAP_VH
`include "define.v"
// Preserve the existing port order; the unused GPIO slot now hosts the real
// Goldfish RTC required by the platform regression. A zero mask is not a
// matching catch-all: the native fabric produces DECERR internally on misses.
`define R64_RTC_BASE 64'h0000000010003000
`define R64_RTC_MASK 64'hfffffffffffff000
`define R64_PLATFORM_SLAVES 16
// Endpoint indices are shared by BASE/MASK and every packed AXI channel.
// BASE/MASK below are written from the highest endpoint down to endpoint 0.
`define R64_PORT_CLINT 4'd0
`define R64_PORT_PLIC 4'd1
`define R64_PORT_RESET_SYSCON 4'd2
`define R64_PORT_UART 4'd3
`define R64_PORT_VIRTIO_BLK 4'd4
`define R64_PORT_RTC 4'd5
`define R64_PORT_PS2 4'd6
`define R64_PORT_MROM 4'd7
`define R64_PORT_VGA 4'd8
`define R64_PORT_FLASH 4'd9
`define R64_PORT_CHIPLINK_MMIO 4'd10
`define R64_PORT_PSRAM 4'd11
`define R64_PORT_LEGACY_MMIO 4'd12
`define R64_PORT_SDRAM 4'd13
`define R64_PORT_CHIPLINK_MEM 4'd14
`define R64_PORT_DEFAULT 4'd15
// The live memory read service contains PSRAM and SDRAM only. Other memory
// address windows can still terminate at an unimplemented/error endpoint.
`define R64_PLATFORM_READ_MEMORY ((16'h0001 << `R64_PORT_PSRAM) | \
                                  (16'h0001 << `R64_PORT_SDRAM))
`define R64_PLATFORM_ERROR_PORTS ((16'h0001 << `R64_PORT_PS2) | \
                                  (16'h0001 << `R64_PORT_MROM) | \
                                  (16'h0001 << `R64_PORT_VGA) | \
                                  (16'h0001 << `R64_PORT_FLASH) | \
                                  (16'h0001 << `R64_PORT_CHIPLINK_MMIO) | \
                                  (16'h0001 << `R64_PORT_CHIPLINK_MEM) | \
                                  (16'h0001 << `R64_PORT_DEFAULT))
`define R64_PLATFORM_BASE { \
  `NPC_AXI_DEFAULT_BASE, `NPC_AXI_CHIPLINK_MEM_BASE, \
  `NPC_AXI_SDRAM_BASE, `NPC_AXI_LEGACY_MMIO_BASE, \
  `NPC_AXI_PSRAM_BASE, `NPC_AXI_CHIPLINK_MMIO_BASE, \
  `NPC_AXI_FLASH_BASE, `NPC_AXI_VGA_BASE, \
  `NPC_AXI_MROM_BASE, `NPC_AXI_PS2_BASE, \
  `R64_RTC_BASE, `NPC_AXI_VIRTIO_BLK_BASE, \
  `NPC_AXI_UART_BASE, `NPC_AXI_RESET_SYSCON_BASE, \
  `NPC_AXI_PLIC_BASE, `NPC_AXI_CLINT_BASE }
`define R64_PLATFORM_MASK { \
  `NPC_AXI_DEFAULT_MASK, `NPC_AXI_CHIPLINK_MEM_MASK, \
  `NPC_AXI_SDRAM_MASK, `NPC_AXI_LEGACY_MMIO_MASK, \
  `NPC_AXI_PSRAM_MASK, `NPC_AXI_CHIPLINK_MMIO_MASK, \
  `NPC_AXI_FLASH_MASK, `NPC_AXI_VGA_MASK, \
  `NPC_AXI_MROM_MASK, `NPC_AXI_PS2_MASK, \
  `R64_RTC_MASK, `NPC_AXI_VIRTIO_BLK_MASK, \
  `NPC_AXI_UART_MASK, `NPC_AXI_RESET_SYSCON_MASK, \
  `NPC_AXI_PLIC_MASK, `NPC_AXI_CLINT_MASK }
`define R64_PLATFORM_MEMORY 16'h6a80
`define R64_PLATFORM_EXECUTABLE 16'h6a80
`endif

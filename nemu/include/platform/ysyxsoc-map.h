#ifndef __NEMU_PLATFORM_YSYXSOC_MAP_H__
#define __NEMU_PLATFORM_YSYXSOC_MAP_H__

/*
 * NEMU-side mirror of the external ysyxSoC physical address contract.
 *
 * ysyxSoC is owned outside NEMU.  NEMU adapts to that contract here; it does
 * not redefine or modify the external implementation.  Keep the device names
 * distinct from the generic NEMU devices even where their numeric addresses
 * happen to be equal: SPI is not virtio-blk and GPIO is not virtio-rng.
 */
#define YSYXSOC_PLATFORM_NAME  "ysyxsoc"

/*
 * Interrupt topology of the external ysyxSoC contract mirrored by NEMU.
 *
 * There is no CLINT or PLIC address window in the SoC crossbar.  The UART's
 * internal interrupt output is not exported by its APB wrapper, and the only
 * CPU external-interrupt input is tied low by the full-SoC top level.  Keeping
 * these facts beside the address map prevents an ISA helper from silently
 * adding devices that the selected machine does not contain.
 *
 * NEMU still advances an internal instruction-time counter for the architectural
 * time/timeh CSR.  That counter is not a guest-visible CLINT device and cannot
 * generate MSIP/MTIP in this profile.
 */
#define YSYXSOC_HAS_RISCV_CLINT              0
#define YSYXSOC_HAS_RISCV_PLIC               0
#define YSYXSOC_CPU_EXTERNAL_IRQ_CONNECTED   0
#define YSYXSOC_HAS_RISCV_TIME_COUNTER       1

#define YSYXSOC_SRAM_BASE      0x0f000000u
#define YSYXSOC_SRAM_SIZE      0x00002000u

#define YSYXSOC_UART_BASE      0x10000000u
#define YSYXSOC_UART_SIZE      0x00001000u

#define YSYXSOC_SPI_BASE       0x10001000u
#define YSYXSOC_SPI_SIZE       0x00001000u

#define YSYXSOC_GPIO_BASE      0x10002000u
#define YSYXSOC_GPIO_SIZE      0x00000010u

#define YSYXSOC_PS2_BASE       0x10011000u
#define YSYXSOC_PS2_SIZE       0x00000008u

#define YSYXSOC_MROM_BASE      0x20000000u
#define YSYXSOC_MROM_SIZE      0x00001000u
#define YSYXSOC_RESET_VECTOR   YSYXSOC_MROM_BASE

#define YSYXSOC_VGA_BASE       0x21000000u
#define YSYXSOC_VGA_SIZE       0x00200000u

#define YSYXSOC_FLASH_BASE     0x30000000u
#define YSYXSOC_FLASH_SIZE     0x10000000u

#define YSYXSOC_PSRAM_BASE     0x80000000u
#define YSYXSOC_PSRAM_SIZE     0x00400000u

#define YSYXSOC_SDRAM_BASE     0xa0000000u
#define YSYXSOC_SDRAM_SIZE     0x02000000u

#endif

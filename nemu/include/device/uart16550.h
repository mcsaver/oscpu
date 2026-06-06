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

#ifndef __DEVICE_UART16550_H__
#define __DEVICE_UART16550_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define UART16550_REG_COUNT 8u
#define UART16550_MMIO_MAP_SIZE 0x1000u
#define UART16550_RX_FIFO_CAP 16u

#define UART16550_REG_RBR 0u
#define UART16550_REG_THR 0u
#define UART16550_REG_DLL 0u
#define UART16550_REG_IER 1u
#define UART16550_REG_DLM 1u
#define UART16550_REG_IIR 2u
#define UART16550_REG_FCR 2u
#define UART16550_REG_LCR 3u
#define UART16550_REG_MCR 4u
#define UART16550_REG_LSR 5u
#define UART16550_REG_MSR 6u
#define UART16550_REG_SCR 7u

#define UART16550_IER_RDI   0x01u
#define UART16550_IER_THRI  0x02u
#define UART16550_IER_RLSI  0x04u
#define UART16550_IER_MSI   0x08u
#define UART16550_IER_MASK  0x0fu

#define UART16550_IIR_MSI       0x00u
#define UART16550_IIR_NO_INT    0x01u
#define UART16550_IIR_THRI      0x02u
#define UART16550_IIR_RDI       0x04u
#define UART16550_IIR_RLSI      0x06u
#define UART16550_IIR_CTI       0x0cu
#define UART16550_IIR_FIFO_BITS 0xc0u

#define UART16550_FCR_ENABLE    0x01u
#define UART16550_FCR_CLEAR_RX  0x02u
#define UART16550_FCR_CLEAR_TX  0x04u
#define UART16550_FCR_DMA       0x08u
#define UART16550_FCR_TRIGGER   0xc0u
#define UART16550_FCR_TRIGGER_4  0x40u
#define UART16550_FCR_TRIGGER_8  0x80u
#define UART16550_FCR_TRIGGER_14 0xc0u

#define UART16550_LCR_DLAB 0x80u

#define UART16550_MCR_DTR  0x01u
#define UART16550_MCR_RTS  0x02u
#define UART16550_MCR_OUT1 0x04u
#define UART16550_MCR_OUT2 0x08u
#define UART16550_MCR_LOOP 0x10u
#define UART16550_MCR_MASK 0x1fu

#define UART16550_LSR_DR    0x01u
#define UART16550_LSR_OE    0x02u
#define UART16550_LSR_PE    0x04u
#define UART16550_LSR_FE    0x08u
#define UART16550_LSR_BI    0x10u
#define UART16550_LSR_THRE  0x20u
#define UART16550_LSR_TEMT  0x40u
#define UART16550_LSR_FIFO  0x80u
#define UART16550_LSR_ERROR_MASK \
  (UART16550_LSR_OE | UART16550_LSR_PE | UART16550_LSR_FE | UART16550_LSR_BI)

#define UART16550_MSR_DCTS 0x01u
#define UART16550_MSR_DDSR 0x02u
#define UART16550_MSR_TERI 0x04u
#define UART16550_MSR_DDCD 0x08u
#define UART16550_MSR_CTS  0x10u
#define UART16550_MSR_DSR  0x20u
#define UART16550_MSR_RI   0x40u
#define UART16550_MSR_DCD  0x80u
#define UART16550_MSR_DELTA_MASK  0x0fu
#define UART16550_MSR_STATUS_MASK 0xf0u

typedef void (*Uart16550TxFn)(void *opaque, uint8_t ch);
typedef void (*Uart16550IrqFn)(void *opaque, bool level);

typedef struct {
  Uart16550TxFn tx;
  Uart16550IrqFn irq;
} Uart16550Ops;

typedef struct {
  // 总线 profile 只描述寄存器如何映射到字节地址；寄存器语义仍由 UART core 独占。
  uint8_t reg_shift;
  uint8_t reg_io_width;
} Uart16550BusProfile;

#define UART16550_BUS_PROFILE_8BIT  { 0u, 1u }
#define UART16550_BUS_PROFILE_32BIT { 2u, 4u }

typedef struct Uart16550 Uart16550;

typedef struct {
  const Uart16550Ops *ops;
  void *opaque;
  uint32_t rx_fifo_capacity;
} Uart16550Config;

Uart16550 *uart16550_create(const Uart16550Config *config);
void uart16550_destroy(Uart16550 *uart);
void uart16550_reset(Uart16550 *uart);

uint8_t uart16550_read(Uart16550 *uart, uint32_t offset);
void uart16550_write(Uart16550 *uart, uint32_t offset, uint8_t value);
uint32_t uart16550_bus_profile_span(const Uart16550BusProfile *profile);
uint64_t uart16550_bus_read(Uart16550 *uart,
    const Uart16550BusProfile *profile, uint32_t offset, int len);
void uart16550_bus_write(Uart16550 *uart,
    const Uart16550BusProfile *profile, uint32_t offset, int len,
    uint64_t value);

uint32_t uart16550_rx_room(const Uart16550 *uart);
size_t uart16550_receive(Uart16550 *uart, const uint8_t *data, size_t len);
void uart16550_service(Uart16550 *uart);
bool uart16550_irq_level(const Uart16550 *uart);

#endif

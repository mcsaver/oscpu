#ifndef RISCV_H__
#define RISCV_H__

#include <stdint.h>

//inb：从地址addr读取一个字节，以此类推
static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }
//outb：往地址addr写一个字节
static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

#define PTE_V 0x01//Valid，页表项有效
#define PTE_R 0x02//Readable，可读
#define PTE_W 0x04//Writabel，可写
#define PTE_X 0x08//Executable，可执行
#define PTE_U 0x10//User，用户态可访问
#define PTE_A 0x40//Accessed，页被访问过
#define PTE_D 0x80//Dirty，页被写脏过

enum { MODE_U, MODE_S, MODE_M = 3 };
#define MSTATUS_MXR  (1 << 19)
#define MSTATUS_SUM  (1 << 18)

#if __riscv_xlen == 64
#define MSTATUS_SXL  (2ull << 34)
#define MSTATUS_UXL  (2ull << 32)
#else
#define MSTATUS_SXL  0
#define MSTATUS_UXL  0
#endif

#endif

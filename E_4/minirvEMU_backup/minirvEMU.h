#ifndef MINIRVEMU_H
#define MINIRVEMU_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* 对外可见的全局状态（仅供需要时引用） */
extern uint32_t regs[];   /* GPR 寄存器文件（RV32E: 默认 16 个） */
extern uint32_t PC;       /* 程序计数器（字节地址） */

/* 常用执行接口（可选暴露） */
int step(uint32_t *imem, size_t imem_len);

#ifdef __cplusplus
}
#endif

#endif /* MINIRVEMU_H */

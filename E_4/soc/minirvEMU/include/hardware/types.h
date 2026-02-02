#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/*
 * 硬件公共常量与基础类型，供所有子模块共享。
 * 初学者可以将这里视为“硬件描述层”的字典，里面记录了处理器位宽、
 * 寄存器数量、显存布局等固定参数，以及指令解码时需要使用的宏。
 */

#define HW_XLEN                 32   /* 处理器位宽（XLEN），决定基础寄存器和算术宽度 */
#define HW_GPR_COUNT            32   /* 通用寄存器数量，RISC-V 固定 32 个 */
#define HW_DMEM_BYTES           (16u * 1024u * 1024u) /* 数据内存容量：16 MiB */
#define HW_VIDEO_WIDTH          256  /* 帧缓冲宽度（像素） */
#define HW_VIDEO_HEIGHT         256  /* 帧缓冲高度（像素） */
#define HW_VIDEO_BPP            4    /* 每像素占用字节数（这里是 RGBA8888） */
#define HW_VIDEO_BYTES          ((size_t)HW_VIDEO_WIDTH * HW_VIDEO_HEIGHT * HW_VIDEO_BPP) /* 帧缓冲总字节数 */
#define HW_VIDEO_BASE           0x20000000u /* 帧缓冲在物理地址空间中的起始地址 */
#define HW_VIDEO_LIMIT          (HW_VIDEO_BASE + (uint32_t)HW_VIDEO_BYTES) /* 帧缓冲结束地址（开区间上界） */

#define HW_INST_ECALL           0x00000073u /* RISC-V ECALL 指令编码，用于程序主动结束 */
#define HW_INST_EBREAK          0x00100073u /* RISC-V EBREAK 指令编码，常用于调试断点 */

#define HW_FIELD_OPCODE(i)      ((uint32_t)(i) & 0x7fu)             /* 取指令低 7 位作为 opcode */
#define HW_FIELD_RD(i)          (((uint32_t)(i) >> 7)  & 0x1fu)     /* 取 Rd 寄存器编号 */
#define HW_FIELD_FUNCT3(i)      (((uint32_t)(i) >> 12) & 0x7u)      /* 取 funct3 字段（决定算术种类） */
#define HW_FIELD_RS1(i)         (((uint32_t)(i) >> 15) & 0x1fu)     /* 取 Rs1 寄存器编号 */
#define HW_FIELD_RS2(i)         (((uint32_t)(i) >> 20) & 0x1fu)     /* 取 Rs2 寄存器编号 */
#define HW_FIELD_FUNCT7(i)      (((uint32_t)(i) >> 25) & 0x7fu)     /* 取 funct7 字段（区分特殊算术） */

/*
 * hw_sign_extend:
 *   参数 value 表示原始立即数，bits 为原始位宽（例如 12bits）。
 *   返回值是扩展到 32 位后的有符号整数，用于指令译码生成偏移或常量。
 */
static inline int32_t hw_sign_extend(uint32_t value, int bits) {
    uint32_t mask = 1u << (bits - 1);
    return (int32_t)((value ^ mask) - mask);
}

/*
 * CoreStepState:
 *   CORE_STEP_OK    表示指令执行成功，可继续下一条；
 *   CORE_STEP_TRAP  表示遇到 ECALL/EBREAK，此时需要根据 trap_code 做收尾；
 *   CORE_STEP_FAULT 表示出现非法指令或访问，需要立即终止运行。
 */
typedef enum {
    CORE_STEP_OK = 0,
    CORE_STEP_TRAP,
    CORE_STEP_FAULT
} CoreStepState;

/*
 * CoreStepResult:
 *   state     保存执行结果类型；
 *   trap_code 在 CORE_STEP_TRAP 时传递寄存器 a0 中的返回码，
 *             其他状态下该字段可忽略。
 */
typedef struct {
    CoreStepState state;
    int trap_code;
} CoreStepResult;

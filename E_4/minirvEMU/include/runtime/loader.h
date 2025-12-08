#pragma once

#include "hardware/memory.h"

#include <stddef.h>
#include <stdint.h>

/*
 * ProgramImage 描述“已经解码好的程序镜像”，供 SoC 加载执行：
 *   words       指向 32 位指令数组；
 *   word_count  指令数量；
 *   byte_count  原始镜像的字节长度；
 *   halt_pc     如果镜像中找到 ECALL/EBREAK，会记录其地址供循环保护使用；
 *   owns_buffer 标记 words 是否需要手动释放（1 释放 / 0 静态数组）。
 */
typedef struct {
    uint32_t *words;
    size_t word_count;
    size_t byte_count;
    uint32_t halt_pc;
    int owns_buffer;
} ProgramImage;

/* loader_from_bin:
 *   从二进制文件读取指令，填充 ProgramImage，并将数据写入 SystemMemory。
 *   成功返回 0，失败返回 -1。
 */
int loader_from_bin(const char *path, ProgramImage *image, SystemMemory *mem);

/* loader_make_builtin:
 *   构造一个内置的示例程序（简单算术 + ECALL），适合快速验证仿真器。
 */
void loader_make_builtin(ProgramImage *image, SystemMemory *mem);

/* loader_release:
 *   根据 owns_buffer 释放动态分配的指令数组，并清空 ProgramImage 字段。
 */
void loader_release(ProgramImage *image);

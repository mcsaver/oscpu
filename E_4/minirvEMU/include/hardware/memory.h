#pragma once

#include "hardware/types.h"

#include <stddef.h>
#include <stdint.h>

/*
 * SystemMemory 封装数据内存与显存，提供统一的字节/半字/字访问接口。
 * 这是仿真器“硬件层”的内存抽象：dmem 对应主存、video 对应帧缓冲，
 * video_dirty 标识是否有新的像素写入等待刷新。
 */

typedef struct {
    uint8_t dmem[HW_DMEM_BYTES];   /* 模拟主存（Data Memory） */
    uint8_t video[HW_VIDEO_BYTES]; /* 模拟显存（Frame Buffer） */
    int video_dirty;               /* 标记显存是否需要刷新至屏幕 */
} SystemMemory;

/* 将主存与显存全部清零，并重置显存脏标记。 */
void memory_reset(SystemMemory *mem);

/*
 * 以下读取函数分别返回 8/16/32 位数据：
 *   - 会根据地址自动判断读取主存还是显存；
 *   - 超出范围时直接输出错误并结束程序，模拟硬件的致命异常。
 */
uint8_t memory_read8(const SystemMemory *mem, uint32_t addr);
uint16_t memory_read16(const SystemMemory *mem, uint32_t addr);
uint32_t memory_read32(const SystemMemory *mem, uint32_t addr);

/*
 * 写入函数与读取对应：写入显存时会自动设置 video_dirty，
 * 以便视频模块获知需要刷新画面。
 */
void memory_write8(SystemMemory *mem, uint32_t addr, uint8_t value);
void memory_write16(SystemMemory *mem, uint32_t addr, uint16_t value);
void memory_write32(SystemMemory *mem, uint32_t addr, uint32_t value);

/* 批量写数据（常用来加载程序镜像），返回成功写入的字节数。 */
size_t memory_write_block(SystemMemory *mem, size_t dst, const void *src, size_t len);

/*
 * 显存辅助接口：获取帧缓冲指针、大小、分辨率，以及查询/清除脏标记。
 * 这些函数仅涉及显存元信息，不会修改主存。
 */
const uint8_t *memory_video_data(const SystemMemory *mem);
size_t memory_video_size(void);
int memory_video_width(void);
int memory_video_height(void);
int memory_video_dirty(const SystemMemory *mem);
void memory_video_clear(SystemMemory *mem);

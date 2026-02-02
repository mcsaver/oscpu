#include "hardware/memory.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>

/*
 * 模块定位：硬件内存访问层。
 * 提供主存与显存的统一访问接口，确保越界访问被及时捕获。
 */

static void check_bounds(uint32_t addr, size_t width) {
    /*
     * 通过提前计算访问范围来拦截越界，避免数据在静态数组外泄露。
     */
    uint64_t end = (uint64_t)addr + (uint64_t)width;
    if (end > HW_DMEM_BYTES) {
        fprintf(stderr, "memory access out of range: addr=0x%08x size=%zu\n", addr, width);
        fflush(stderr);
        _exit(1);
    }
}

/* translate_video_offset:
 *   将物理地址转换为 video 缓冲区的索引（假设已经确认地址位于显存范围内）。
 */
static uint32_t translate_video_offset(uint32_t addr) {
    return (uint32_t)(addr - HW_VIDEO_BASE);
}

/* memory_reset:
 *   将主存、显存清零，并重置显存脏标记。
 */
void memory_reset(SystemMemory *mem) {
    if (!mem) {
        return;
    }
    memset(mem->dmem, 0, sizeof(mem->dmem));
    memset(mem->video, 0, sizeof(mem->video));
    mem->video_dirty = 0;
}

/* memory_read8:
 *   按字节读取，优先判断显存区间，确保正确模拟图形缓冲访问。
 */
uint8_t memory_read8(const SystemMemory *mem, uint32_t addr) {
    if (!mem) {
        return 0;
    }
    if (addr >= HW_VIDEO_BASE && addr < HW_VIDEO_LIMIT) {
        return mem->video[translate_video_offset(addr)];
    }
    check_bounds(addr, 1);
    return mem->dmem[addr];
}

/* memory_read16:
 *   按半字读取，并处理跨字节拼接。显存读取遵循同样规则。
 */
uint16_t memory_read16(const SystemMemory *mem, uint32_t addr) {
    if (addr >= HW_VIDEO_BASE && (uint64_t)addr + 2ull <= HW_VIDEO_LIMIT) {
        uint32_t off = translate_video_offset(addr);
        return (uint16_t)(mem->video[off] | ((uint16_t)mem->video[off + 1] << 8));
    }
    check_bounds(addr, 2);
    return (uint16_t)(mem->dmem[addr] | ((uint16_t)mem->dmem[addr + 1] << 8));
}

/* memory_read32:
 *   按字读取，支持显存访问（例如 DMA 读取像素块）。
 */
uint32_t memory_read32(const SystemMemory *mem, uint32_t addr) {
    if (addr >= HW_VIDEO_BASE && (uint64_t)addr + 4ull <= HW_VIDEO_LIMIT) {
        uint32_t off = translate_video_offset(addr);
        return (uint32_t)mem->video[off]
             | ((uint32_t)mem->video[off + 1] << 8)
             | ((uint32_t)mem->video[off + 2] << 16)
             | ((uint32_t)mem->video[off + 3] << 24);
    }
    check_bounds(addr, 4);
    return (uint32_t)mem->dmem[addr]
         | ((uint32_t)mem->dmem[addr + 1] << 8)
         | ((uint32_t)mem->dmem[addr + 2] << 16)
         | ((uint32_t)mem->dmem[addr + 3] << 24);
}

/* memory_write8:
 *   按字节写入，并在写显存时打脏标识。
 */
void memory_write8(SystemMemory *mem, uint32_t addr, uint8_t value) {
    if (!mem) {
        return;
    }
    if (addr >= HW_VIDEO_BASE && addr < HW_VIDEO_LIMIT) {
        mem->video[translate_video_offset(addr)] = value;
        mem->video_dirty = 1;
        return;
    }
    check_bounds(addr, 1);
    mem->dmem[addr] = value;
}

/* memory_write16:
 *   对半字写入进行拆分，显存写入同样会设置脏标识。
 */
void memory_write16(SystemMemory *mem, uint32_t addr, uint16_t value) {
    if (addr >= HW_VIDEO_BASE && (uint64_t)addr + 2ull <= HW_VIDEO_LIMIT) {
        uint32_t off = translate_video_offset(addr);
        mem->video[off] = (uint8_t)(value & 0xffu);
        mem->video[off + 1] = (uint8_t)((value >> 8) & 0xffu);
        mem->video_dirty = 1;
        return;
    }
    check_bounds(addr, 2);
    mem->dmem[addr] = (uint8_t)(value & 0xffu);
    mem->dmem[addr + 1] = (uint8_t)((value >> 8) & 0xffu);
}

/* memory_write32:
 *   以 4 字节为单位写入，覆盖寄存器/显存写操作。
 */
void memory_write32(SystemMemory *mem, uint32_t addr, uint32_t value) {
    if (addr >= HW_VIDEO_BASE && (uint64_t)addr + 4ull <= HW_VIDEO_LIMIT) {
        uint32_t off = translate_video_offset(addr);
        mem->video[off]     = (uint8_t)(value & 0xffu);
        mem->video[off + 1] = (uint8_t)((value >> 8) & 0xffu);
        mem->video[off + 2] = (uint8_t)((value >> 16) & 0xffu);
        mem->video[off + 3] = (uint8_t)((value >> 24) & 0xffu);
        mem->video_dirty = 1;
        return;
    }
    check_bounds(addr, 4);
    mem->dmem[addr] = (uint8_t)(value & 0xffu);
    mem->dmem[addr + 1] = (uint8_t)((value >> 8) & 0xffu);
    mem->dmem[addr + 2] = (uint8_t)((value >> 16) & 0xffu);
    mem->dmem[addr + 3] = (uint8_t)((value >> 24) & 0xffu);
}

/* memory_write_block:
 *   从指定地址开始批量写入数据，用于加载程序或复制大块内存。
 */
size_t memory_write_block(SystemMemory *mem, size_t dst, const void *src, size_t len) {
    if (!mem || !src || len == 0) {
        return 0;
    }
    if (dst >= HW_DMEM_BYTES) {
        return 0;
    }
    size_t room = HW_DMEM_BYTES - dst;
    if (len > room) {
        len = room;
    }
    memcpy(mem->dmem + dst, src, len);
    return len;
}

/* 以下函数为显存元信息访问接口。 */
const uint8_t *memory_video_data(const SystemMemory *mem) {
    return mem ? mem->video : NULL;
}

size_t memory_video_size(void) {
    return HW_VIDEO_BYTES;
}

int memory_video_width(void) {
    return HW_VIDEO_WIDTH;
}

int memory_video_height(void) {
    return HW_VIDEO_HEIGHT;
}

int memory_video_dirty(const SystemMemory *mem) {
    return mem ? mem->video_dirty : 0;
}

void memory_video_clear(SystemMemory *mem) {
    if (mem) {
        mem->video_dirty = 0;
    }
}

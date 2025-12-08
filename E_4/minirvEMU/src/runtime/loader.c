#include "runtime/loader.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * 模块定位：程序加载层。
 * 负责把磁盘上的二进制镜像转换为仿真器可直接读取的指令数组，
 * 并提供一个内置示例 ROM，以便初学者立即运行测试。
 */

/* locate_halt:
 *   从指令序列结尾向前扫描，找到最后一个 ECALL/EBREAK，返回其地址（字节为单位）。
 *   若不存在则返回 0xffffffffu，表示无法确定自然结束点。
 */
static uint32_t locate_halt(const uint32_t *words, size_t count) {
    if (!words) {
        return 0xffffffffu;
    }
    for (size_t i = count; i > 0; --i) {
        uint32_t inst = words[i - 1];
        if (inst == HW_INST_ECALL || inst == HW_INST_EBREAK) {
            return (uint32_t)((i - 1) * 4u);
        }
    }
    return 0xffffffffu;
}

/* loader_from_bin:
 *   step1. 打开二进制文件并检查大小，确保对齐与容量合法；
 *   step2. 读取到 raw 缓冲区，再转换为 32 位小端指令；
 *   step3. 写入 SystemMemory，并填充 ProgramImage 结构；
 *   step4. 返回 0 代表成功，遇到任何异常都会输出错误并返回 -1。
 */
int loader_from_bin(const char *path, ProgramImage *image, SystemMemory *mem) {
    if (!path || !image || !mem) {
        return -1;
    }
    memset(image, 0, sizeof(*image));

    FILE *fp = fopen(path, "rb");
    if (!fp) {
        perror("open binary");
        return -1;
    }
    if (fseek(fp, 0, SEEK_END) != 0) {
        perror("seek binary");
        fclose(fp);
        return -1;
    }
    long sz = ftell(fp);
    if (sz < 0) {
        perror("size binary");
        fclose(fp);
        return -1;
    }
    if ((sz % 4) != 0) {
        fprintf(stderr, "binary size must align to 4 bytes\n");
        fclose(fp);
        return -1;
    }
    if (fseek(fp, 0, SEEK_SET) != 0) {
        perror("rewind binary");
        fclose(fp);
        return -1;
    }

    size_t byte_count = (size_t)sz;
    size_t word_count = byte_count / 4u;
    if (byte_count > HW_DMEM_BYTES) {
        fprintf(stderr, "binary too large (%zu bytes > %u)\n", byte_count, HW_DMEM_BYTES);
        fclose(fp);
        return -1;
    }
    uint8_t *raw = (uint8_t *)malloc(byte_count);
    if (!raw) {
        perror("malloc raw");
        fclose(fp);
        return -1;
    }
    size_t read_bytes = fread(raw, 1, byte_count, fp);
    fclose(fp);
    if (read_bytes != byte_count) {
        fprintf(stderr, "short read: expect %zu got %zu\n", byte_count, read_bytes);
        free(raw);
        return -1;
    }

    uint32_t *words = (uint32_t *)malloc(word_count * sizeof(uint32_t));
    if (!words) {
        perror("malloc words");
        free(raw);
        return -1;
    }
    for (size_t i = 0; i < word_count; ++i) {
        words[i] = (uint32_t)raw[i * 4 + 0]
                 | ((uint32_t)raw[i * 4 + 1] << 8)
                 | ((uint32_t)raw[i * 4 + 2] << 16)
                 | ((uint32_t)raw[i * 4 + 3] << 24);
    }

    memory_reset(mem);
    memory_write_block(mem, 0, raw, byte_count);

    image->words = words;
    image->word_count = word_count;
    image->byte_count = byte_count;
    image->halt_pc = locate_halt(words, word_count);
    image->owns_buffer = 1;

    free(raw);
    return 0;
}

/* loader_make_builtin:
 *   将一段静态数组作为“内置程序”，写入 SystemMemory，并设置 ProgramImage。
 *   适用于用户未指定外部镜像的情况。
 */
void loader_make_builtin(ProgramImage *image, SystemMemory *mem) {
    static uint32_t builtin_rom[] = {
        0x00500093u,
        0x00100113u,
        0x002081b3u,
        0x00000073u
    };
    if (!image || !mem) {
        return;
    }
    memory_reset(mem);
    for (size_t i = 0; i < sizeof(builtin_rom) / sizeof(builtin_rom[0]); ++i) {
        memory_write32(mem, (uint32_t)(i * 4u), builtin_rom[i]);
    }
    image->words = builtin_rom;
    image->word_count = sizeof(builtin_rom) / sizeof(builtin_rom[0]);
    image->byte_count = sizeof(builtin_rom);
    image->halt_pc = locate_halt(builtin_rom, image->word_count);
    image->owns_buffer = 0;
}

/* loader_release:
 *   如果 ProgramImage 持有动态分配的指令数组，则释放它并重置字段。
 */
void loader_release(ProgramImage *image) {
    if (!image) {
        return;
    }
    if (image->owns_buffer && image->words) {
        free(image->words);
    }
    image->words = NULL;
    image->word_count = 0;
    image->byte_count = 0;
    image->halt_pc = 0xffffffffu;
    image->owns_buffer = 0;
}

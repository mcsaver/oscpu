/*
 * minirv_main.c — 应用层入口：参数解析、程序加载、HALT 扫描、主循环驱动。
 * 详细说明请看 README.md；CPU 接口见 cpu.h。
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "cpu.h"
#include <am.h>

/* 前向声明：在主循环内会调用实时刷新函数 */
void video_on_halt(void);
static void video_flush(bool wait_after);

/*
 * 从小端 .bin 加载到内存：
 * - path: 二进制路径（每 4 字节为一条小端指令）
 * - out_imem/out_len: 输出的指令数组与长度（malloc 分配，由调用者负责 free）
 * - 同时把原始字节复制到 CPU dmem 的低地址处（dst=0），返回复制字节数
 * 返回 0 成功，非 0 失败（并打印错误）。
 */
static int app_load_bin(const char *path, uint32_t **out_imem, size_t *out_len, size_t *copied_bytes){
    if (!path || !out_imem || !out_len) return 1;
    *out_imem = NULL; *out_len = 0; if (copied_bytes) *copied_bytes = 0;
    FILE *f = fopen(path, "rb"); if(!f){ perror("fopen 失败"); return 1; }
    if (fseek(f, 0, SEEK_END) != 0){ perror("fseek 失败"); fclose(f); return 1; }
    long sz = ftell(f); if (sz < 0){ perror("ftell 失败"); fclose(f); return 1; }
    if (fseek(f, 0, SEEK_SET) != 0){ perror("fseek 失败"); fclose(f); return 1; }
    if ((sz % 4) != 0){ fprintf(stderr, "二进制大小必须是 4 的倍数（字节）\n"); fclose(f); return 1; }
    size_t imem_len = (size_t)sz / 4;
    uint8_t *buf = (uint8_t*)malloc((size_t)sz); if(!buf){ perror("malloc 失败"); fclose(f); return 1; }
    size_t r = fread(buf, 1, (size_t)sz, f); fclose(f); if (r != (size_t)sz){ fprintf(stderr, "读取字节数不足(short read)\n"); free(buf); return 1; }
    uint32_t *imem = (uint32_t*)malloc(imem_len * sizeof(uint32_t)); if(!imem){ perror("malloc 失败"); free(buf); return 1; }
    for (size_t i=0;i<imem_len;i++){
        imem[i] = (uint32_t)buf[i*4]
                | ((uint32_t)buf[i*4+1] << 8)
                | ((uint32_t)buf[i*4+2] << 16)
                | ((uint32_t)buf[i*4+3] << 24);
    }
    size_t wrote = cpu_dmem_write_bytes(0, buf, (size_t)sz);
    if (copied_bytes) *copied_bytes = wrote;
    free(buf);
    *out_imem = imem; *out_len = imem_len;
    return 0;
}

/*
 * 扫描 IMEM，记录程序内的 HALT（ECALL/EBREAK）地址，便于死循环触发时跳转
 */
static uint32_t app_scan_halt_pc(const uint32_t *imem, size_t imem_len){
    if (!imem || !imem_len) return 0xffffffffu;
    for (long i=(long)imem_len-1; i>=0; --i){
        uint32_t w = imem[i];
        if (w == INST_ECALL || w == INST_EBREAK) return (uint32_t)(i*4);
    }
    return 0xffffffffu;
}

/* AM(native) 的入口是 int main(const char *args) —— 由环境变量 mainargs 传入 */
int main(const char *args) {
    uint32_t *imem = NULL;
    size_t imem_len = 0;

    int auto_hold = 0; /* 是否根据文件名自动开启保持 */
    if (args && args[0]) {
        if (strcmp(args, "-h") == 0 || strcmp(args, "--help") == 0) {
            printf("用法: mainargs=<program.bin> make runhex\n");
            printf("提示: 详细使用方法与原理说明，请查看 README.md\n");
            return 0;
        }
        const char *path = args;
        size_t copied = 0;
        if (app_load_bin(path, &imem, &imem_len, &copied) != 0) return 1;
        printf("已从 %s 加载 %zu 条指令\n", path, imem_len);
        uint32_t halt_pc = app_scan_halt_pc(imem, imem_len);
        if (halt_pc != 0xffffffffu) {
            cpu_set_halt_pc(halt_pc);
            printf("在 PC=0x%08x 处发现程序的 halt（ECALL/EBREAK）\n", halt_pc);
        }
        /* 仅记录自动保持意图，稍后在加载运行时配置之后再设置，以避免被覆盖 */
        const char *bn = strrchr(path, '/'); bn = bn ? bn+1 : path;
        if (strstr(bn, "vga") == bn || strstr(bn, "vga") != NULL) {
            auto_hold = 1;
        }
    }

    // 内置冒烟测试：未提供外部程序时使用；其执行解读见 README。
    uint32_t builtin_imem[] = {
        0x01400093, // addi x1, x0, 20
        0x00000113, // addi x2, x0, 0
        0x00000193, // addi x3, x0, 0
        0x00008267, // jalr x4, x1, 0
        0x00000000, // padding
        0x03700293, // addi x5, x0, 55
    };
    size_t builtin_len = sizeof(builtin_imem)/4;
    if (!imem) { imem = builtin_imem; imem_len = builtin_len; }

    // 运行时配置 & CPU 复位
    cpu_load_runtime_config();
    if (auto_hold) {
        cpu_set_hold_after_halt(1);
        printf("检测到文件名包含 'vga'，启用 HALT 后图像保持模式。\n");
    }
    cpu_reset();

    unsigned long long step_cnt = 0;
    const unsigned long long STEP_LIMIT = 2000000000ULL;
    /* 如果希望实时看到图像，可在循环内周期刷新 framebuffer。
     * 下面做一个可选的“软刷新”：当检测到显存被写脏时，立即把已写内容显示到窗口。*/
    while (IMEM_IDX(PC) < imem_len) {
        unsigned long long prog = cpu_get_progress_every();
        if (prog && (step_cnt % prog) == 0) {
            fprintf(stderr, "进度: 步数=%llu PC=0x%08x\n", step_cnt, PC);
        }
        cpu_handle_loop_protection(imem, imem_len, step_cnt);
        int term = cpu_step(imem, imem_len);
        (void)term; // cpu_halt 内部会 exit，正常返回时 term 恒为 0
        if (cpu_video_dirty()) {
            video_flush(false); /* 立即刷新到窗口，但不退出且不等待 */
        }
        step_cnt++;
        if (step_cnt > STEP_LIMIT) { fprintf(stderr, "步数过多，正在中止\n"); break; }
    }

    if (cpu_get_show_regs_after()) {
        printf("执行结束后的寄存器（前 %d 个）：\n", GPR_COUNT);
        for (int i = 0; i < GPR_COUNT; i++) {
            printf("x%-2d = 0x%08x (%d)\n", i, regs[i], (int32_t)regs[i]);
        }
    }

    if (args && args[0]) free(imem);
    return 0;
}

/* 统一的刷屏函数：wait_after=true 用于最终 HALT 时等待片刻，false 则不等待 */
static void video_flush(bool wait_after){
    if (!cpu_video_dirty()) return;
    const uint8_t *fb = cpu_video_fb_data();
    int W = cpu_video_width();
    int H = cpu_video_height();
    for (int y=0; y<H; ++y){
        AM_GPU_FBDRAW_T ctl = { .x = 0, .y = y, .pixels = (void*)(fb + (size_t)y * W * 4), .w = W, .h = 1, .sync = false };
        ioe_write(AM_GPU_FBDRAW, &ctl);
    }
    AM_GPU_FBDRAW_T sync = { .x = 0, .y = 0, .pixels = NULL, .w = 0, .h = 0, .sync = true };
    ioe_write(AM_GPU_FBDRAW, &sync);
    cpu_video_clear_dirty();

    if (wait_after) {
        AM_TIMER_UPTIME_T t0, t1;
        ioe_read(AM_TIMER_UPTIME, &t0);
        do {
            ioe_read(AM_TIMER_UPTIME, &t1);
        } while ((t1.us - t0.us) < 2000000ull);
    }
}

/* 在 HALT 时被 cpu_halt 调用（若 framebuffer 有写入） */
void video_on_halt(void){
    video_flush(true);
}

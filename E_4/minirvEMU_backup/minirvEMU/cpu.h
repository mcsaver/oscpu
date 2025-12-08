#ifndef CPU_H
#define CPU_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * - 宏：指令位域提取、索引计算等；
 * - 常量：操作码、SYSTEM 指令编码；
 * - 配置：GPR 数量、DMEM 大小；
 * - 状态：寄存器文件与 PC；
 * - 接口：初始化、单步执行、死循环保护、运行时配置、内存写入等。
 */
/* 指令内存索引：PC 为字节地址，每条指令 4 字节，因此索引=PC>>2 */
#define IMEM_IDX(pc) ((uint32_t)(pc) >> 2)

/* 指令位域提取（RISC-V 基础位段） */
#define GET_OPCODE(i)   ((uint32_t)(i) & 0x7fu)
#define GET_RD(i)       (((uint32_t)(i) >> 7)  & 0x1fu)
#define GET_FUNCT3(i)   (((uint32_t)(i) >> 12) & 0x7u)
#define GET_RS1(i)      (((uint32_t)(i) >> 15) & 0x1fu)
#define GET_RS2(i)      (((uint32_t)(i) >> 20) & 0x1fu)
#define GET_FUNCT7(i)   (((uint32_t)(i) >> 25) & 0x7fu)

/* 立即数辅助掩码 */
#define IMM20_MASK 0xfffff000u /* [31:12] */

/* 操作码常量（RV32I 基础） */
enum {
    OPC_LUI    = 0x37,
    OPC_AUIPC  = 0x17,
    OPC_OPIMM  = 0x13,
    OPC_JALR   = 0x67,
    OPC_OP     = 0x33,
    OPC_LOAD   = 0x03,
    OPC_STORE  = 0x23,
    OPC_BRANCH = 0x63,
    OPC_JAL    = 0x6f,
    OPC_SYSTEM = 0x73,
};

/* SYSTEM 指令编码（终止相关） */
#define INST_ECALL  0x00000073u
#define INST_EBREAK 0x00100073u

/* 可配置寄存器数量（默认 RV32E=16；改为 32 以支持 RV32I） */
#ifndef GPR_COUNT
#define GPR_COUNT 16
#endif

/* 数据内存大小（字节） */
#ifndef DMEM_SIZE
#define DMEM_SIZE (16*1024*1024)
#endif

/* ===================== 简易“显存”配置 =====================
 * 为了在 minirvEMU 中支持图形显示，我们约定：
 * - 将 [VIDEO_BASE, VIDEO_BASE + VIDEO_SIZE) 作为“显存”地址区间；
 * - 每个像素 4 字节 0x00RRGGBB（与 AM 的 FBDRAW 一致，便于直接拷贝显示）；
 * - 分辨率固定为 256x256。
 * 注意：这是模拟器侧的约定，CPU 对该地址区间的写操作不会落到 dmem，
 *       而是重定向到内部的视频缓冲中。
 */
#define VIDEO_W     256
#define VIDEO_H     256
#define VIDEO_BPP   4                   /* bytes per pixel: 0x00RRGGBB */
#define VIDEO_SIZE  ((size_t)(VIDEO_W * VIDEO_H * VIDEO_BPP))
#define VIDEO_BASE  0x20000000u
#define VIDEO_LIMIT (VIDEO_BASE + (uint32_t)VIDEO_SIZE)

/* 对外可见 CPU 状态（阅读/调试所需）： */
extern uint32_t regs[]; /* x0..x(GPR_COUNT-1)，x0 恒为 0 */
extern uint32_t PC;     /* 程序计数器（字节地址） */

/* 初始化与配置 */
void cpu_reset(void);                 /* 清零寄存器，PC=0 */
void cpu_load_runtime_config(void);   /* 读取环境变量（TRACE/LOOP 等） */

/* 执行与控制 */
int  cpu_step(uint32_t *imem, size_t imem_len); /* 执行一条指令，返回 1 表示程序请求终止 */
void cpu_handle_loop_protection(uint32_t *imem, size_t imem_len, unsigned long long step_cnt);
void cpu_halt(int code);              /* 处理 ECALL/EBREAK 退出（打印摘要并 exit(code)） */

/* 工具与内存 */
int32_t cpu_sign_extend(uint32_t val, int bits); /* 符号扩展 */
size_t  cpu_dmem_write_bytes(size_t dst_addr, const void *src, size_t n); /* 写入 dmem[dst..dst+n) */

/* 辅助：应用层需要设置/查询的状态（用于进度打印与 halt 跳转） */
void                cpu_set_halt_pc(uint32_t pc);
unsigned long long  cpu_get_progress_every(void);
int                 cpu_get_show_regs_after(void);

/* ===================== 视频缓冲访问接口 ===================== */
/* 返回显存缓冲的常量指针与大小；像素格式为 0x00RRGGBB。*/
const uint8_t *cpu_video_fb_data(void);
size_t         cpu_video_fb_size(void);
int            cpu_video_width(void);
int            cpu_video_height(void);
int            cpu_video_dirty(void);        /* 是否有写入发生 */
void           cpu_video_clear_dirty(void);  /* 清除脏标记 */

/* 控制 HALT 后是否保持图像显示（运行期设置） */
void cpu_set_hold_after_halt(int hold);

#ifdef __cplusplus
}
#endif

#endif /* CPU_H */

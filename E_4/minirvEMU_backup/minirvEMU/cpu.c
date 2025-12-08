#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <unistd.h>
#include <sys/select.h>
#include <am.h>
#include "cpu.h"

/* 内部状态与实现（只在 CPU 内部使用） */
static unsigned long long g_steps = 0;            /* 已执行步数（用于 trace 限制） */
static int g_trace_ins = 0;                       /* 是否打印逐指令跟踪 */
static unsigned long long g_trace_limit = 200ULL; /* 跟踪上限 */
static unsigned long long g_instr_executed = 0ULL;/* 指令计数 */
static int g_show_regs_after = 0;                 /* 结束后是否打印寄存器（供 APP 使用） */
static unsigned long long g_progress_every = 0ULL;/* 进度打印步数 */

/* dmem 与寄存器/PC（对外暴露 regs 与 PC） */
uint32_t regs[GPR_COUNT];
static uint8_t dmem[DMEM_SIZE];
uint32_t PC = 0;

/* 简易视频缓冲（映射到地址区间 [VIDEO_BASE, VIDEO_LIMIT)）*/
static uint8_t s_video_fb[VIDEO_SIZE];
static int     s_video_dirty = 0; /* 期间是否发生过写入 */

/* 死循环检测状态 */
static uint32_t g_last_pc = 0xffffffffu;
static unsigned long long g_repeat_pc_count = 0ULL;
static unsigned long long g_loop_thresh = 1000000ULL; /* 连续同一 PC 计数阈值 */
static unsigned long long g_loop_max_steps = 5000000ULL; /* 最大步数兜底 */
static uint32_t g_halt_pc = 0xffffffffu; /* 由 APP 扫描并设置 */
static int g_hold_after_halt = 0; /* 默认关闭；由环境变量或运行期 API 打开 */
static int g_auto_clean_after_halt = 1; /* 默认在 HALT 前自动清理中间产物，可用环境变量关闭 */

/* 内部寄存器访问 */
static inline uint32_t rr(uint32_t idx){
    if (idx >= GPR_COUNT) {
        fprintf(stderr, "Illegal GPR x%u at PC=0x%08x\n", idx, PC);
        exit(2);
    }
    return regs[idx];
}

static inline void wr(uint32_t idx, uint32_t v){
    if (idx == 0) return; /* x0 忽略写入 */
    if (idx >= GPR_COUNT) {
        fprintf(stderr, "Illegal GPR x%u at PC=0x%08x\n", idx, PC);
        exit(2);
    }
    regs[idx] = v;
}

/* dmem helpers */
static inline uint8_t dmem_read8(uint32_t a){
    /* 视频区：允许读取（从内部显存返回），避免越界退出 */
    if (a >= VIDEO_BASE && a < VIDEO_LIMIT) {
        size_t off = (size_t)(a - VIDEO_BASE);
        return s_video_fb[off];
    }
    if (a + 1 > DMEM_SIZE) {
        printf("DMEM read8 越界:0x%08x\n", a);
        exit(1);
    }
    return dmem[a];
}

static inline uint32_t dmem_read32(uint32_t a){
    if (a >= VIDEO_BASE && (uint64_t)a + 4ull <= (uint64_t)VIDEO_LIMIT) {
        size_t off = (size_t)(a - VIDEO_BASE);
        return (uint32_t)s_video_fb[off]
             | ((uint32_t)s_video_fb[off + 1] << 8)
             | ((uint32_t)s_video_fb[off + 2] << 16)
             | ((uint32_t)s_video_fb[off + 3] << 24);
    }
    if (a + 4 > DMEM_SIZE) {
        printf("DMEM read32 越界:0x%08x\n", a);
        exit(1);
    }
    return (uint32_t)dmem[a]
         | ((uint32_t)dmem[a + 1] << 8)
         | ((uint32_t)dmem[a + 2] << 16)
         | ((uint32_t)dmem[a + 3] << 24);
}

static inline void dmem_write8(uint32_t a, uint8_t v){
    if (a >= VIDEO_BASE && a < VIDEO_LIMIT) {
        size_t off = (size_t)(a - VIDEO_BASE);
        s_video_fb[off] = v;
        s_video_dirty = 1;
        return;
    }
    if (a + 1 > DMEM_SIZE) {
        printf("DMEM write8 越界:0x%08x\n", a);
        exit(1);
    }
    dmem[a] = v;
}

static inline void dmem_write32(uint32_t a, uint32_t v){
    if (a >= VIDEO_BASE && (uint64_t)a + 4ull <= (uint64_t)VIDEO_LIMIT) {
        size_t off = (size_t)(a - VIDEO_BASE);
        s_video_fb[off]     = (uint8_t)(v & 0xff);
        s_video_fb[off + 1] = (uint8_t)((v >> 8)  & 0xff);
        s_video_fb[off + 2] = (uint8_t)((v >> 16) & 0xff);
        s_video_fb[off + 3] = (uint8_t)((v >> 24) & 0xff);
        s_video_dirty = 1;
        return;
    }
    if (a + 4 > DMEM_SIZE) {
        printf("DMEM write32 越界:0x%08x\n", a);
        exit(1);
    }
    dmem[a]     = (uint8_t)(v & 0xff);
    dmem[a + 1] = (uint8_t)((v >> 8)  & 0xff);
    dmem[a + 2] = (uint8_t)((v >> 16) & 0xff);
    dmem[a + 3] = (uint8_t)((v >> 24) & 0xff);
}

/* 工具函数 */
int32_t cpu_sign_extend(uint32_t val, int bits){ uint32_t m = 1u << (bits-1); return (int32_t)((val ^ m) - m); }

/* 运行时配置（来自环境变量） */
void cpu_load_runtime_config(void){
    const char *s;
    s = getenv("TRACE_INS");
    if (s && atoi(s)) {
        g_trace_ins = 1;
        s = getenv("TRACE_LIMIT");
        if (s) { unsigned long long v = strtoull(s,NULL,10); if (v>0) g_trace_limit=v; }
    }
    s = getenv("SHOW_REGS_AFTER"); if (s) g_show_regs_after = (atoi(s)!=0);
    s = getenv("PROGRESS_EVERY"); if (s) g_progress_every = (unsigned long long)strtoull(s,NULL,10);
    s = getenv("LOOP_THRESH"); if (s) { unsigned long long v = strtoull(s,NULL,10); if (v>0) g_loop_thresh=v; }
    s = getenv("LOOP_MAX_STEPS"); if (s) { unsigned long long v = strtoull(s,NULL,10); if (v>0) g_loop_max_steps=v; }
    s = getenv("HOLD_IMAGE_AFTER_HALT"); if (s) { g_hold_after_halt = (atoi(s)!=0); }
    s = getenv("AUTO_CLEAN_AFTER_HALT"); if (s) { g_auto_clean_after_halt = (atoi(s)!=0); }
}

/* CPU 复位：清零寄存器并设置 PC=0 */
void cpu_reset(void){
    memset(regs, 0, sizeof(regs));
    PC = 0;
    g_last_pc = 0xffffffffu;
    g_repeat_pc_count = 0ULL;
    memset(s_video_fb, 0, sizeof(s_video_fb));
    s_video_dirty = 0;
}

/* 提供给 APP 的 dmem 写接口（拷贝原始字节到低地址） */
size_t cpu_dmem_write_bytes(size_t dst_addr, const void *src, size_t n){
    if (dst_addr >= DMEM_SIZE) return 0;
    size_t room = DMEM_SIZE - dst_addr;
    if (n > room) n = room;
    memcpy(dmem + dst_addr, src, n);
    return n;
}

/* 死循环保护（由 APP 在循环中调用） */
void cpu_handle_loop_protection(uint32_t *imem, size_t imem_len, unsigned long long step_cnt){
    int triggered = 0;

    if (PC == g_last_pc) {
        g_repeat_pc_count++;
    } else {
        g_last_pc = PC;
        g_repeat_pc_count = 0ULL;
    }

    if (g_repeat_pc_count >= g_loop_thresh) {
        fprintf(stderr,
                "检测到可能的死循环, PC=0x%08x(重复次数=%llu)\n",
                PC, g_repeat_pc_count);
        fflush(stderr);
        triggered = 1;
    } else if (g_loop_max_steps > 0 && step_cnt >= g_loop_max_steps) {
        fprintf(stderr,
                "超过最大步数阈值 LOOP_MAX_STEPS=%llu(当前步数=%llu)\n",
                g_loop_max_steps, step_cnt);
        fflush(stderr);
        triggered = 1;
    }

    if (!triggered) return;

    if (g_halt_pc != 0xffffffffu) {
        fprintf(stderr, "-> 跳转到程序 halt 位置 PC=0x%08x\n", g_halt_pc);
        fflush(stderr);
        PC = g_halt_pc;
    } else {
        size_t idx = IMEM_IDX(PC);
        if (idx >= imem_len) {
            fprintf(stderr,
                    "-> 警告：无法注入 ECALL, PC 对应下标=%zu 已越界(imem_len=%zu)\n",
                    idx, imem_len);
            fflush(stderr);
        } else {
            fprintf(stderr,
                    "-> 未找到程序 halt, 向当前 PC 注入 ECALL 强制退出(imem 下标=%zu)\n",
                    idx);
            imem[idx] = INST_ECALL; /* ECALL */
        }
    }
    g_repeat_pc_count = 0ULL;
}

/* 工具：去除字符串首尾空白 */
static void str_trim(char *s){
    if (!s) return;
    char *p = s; while (*p==' '||*p=='\t'||*p=='\r'||*p=='\n') ++p;
    if (p != s) memmove(s, p, strlen(p)+1);
    size_t n = strlen(s);
    while (n>0 && (s[n-1]==' '||s[n-1]=='\t'||s[n-1]=='\r'||s[n-1]=='\n')) { s[--n]='\0'; }
}

/* 在保持模式下，尽力从 /dev/tty 或 stdin 读取用户输入，否则就阻塞等待直到 Ctrl+C */
static void hold_wait_for_exit(void){
    FILE *in = fopen("/dev/tty", "r");
    if (!in) in = stdin; /* 回退到标准输入 */

    printf("[保持] 图像已锁定显示。按 ESC 或 Q，或在终端输入 exit/quit/q 退出。\n");
    fflush(stdout);

    char line[256];
    int warned = 0;
    int fd = (in ? fileno(in) : -1);

    while (1) {
        /* 1) 先非阻塞地检查终端是否有可读数据（50ms 超时） */
        int got_line = 0;
        if (fd >= 0) {
            fd_set rfds; FD_ZERO(&rfds); FD_SET(fd, &rfds);
            struct timeval tv; tv.tv_sec = 0; tv.tv_usec = 50000; /* 50ms */
            int r = select(fd + 1, &rfds, NULL, NULL, &tv);
            if (r > 0 && FD_ISSET(fd, &rfds)) {
                if (fgets(line, sizeof(line), in)) {
                    str_trim(line);
                    if (strcmp(line, "exit")==0 || strcmp(line, "quit")==0 || strcmp(line, "q")==0) {
                        break;
                    }
                    printf("(保持) 输入 exit/quit/q 退出\n"); fflush(stdout);
                    got_line = 1;
                } else {
                    if (!warned) {
                        fprintf(stderr, "[保持] 终端读取失败(errno=%d)，将继续保持显示；可按 ESC/Q 或 Ctrl+C 退出。\n", errno);
                        warned = 1;
                    }
                }
            }
        } else {
            /* 无法获取终端 fd，设置一个小延时避免忙等 */
            usleep(50000);
        }

        if (got_line) continue;

        /* 2) 轮询 AM 键盘事件 */
        AM_INPUT_KEYBRD_T kb; ioe_read(AM_INPUT_KEYBRD, &kb);
        if (kb.keydown) {
            if (kb.keycode == AM_KEY_ESCAPE || kb.keycode == AM_KEY_Q) {
                break;
            }
        }
        /* 循环继续，下一次 select 或键盘轮询 */
    }

    if (in && in != stdin) fclose(in);
}

/* 宿主侧 HALT：打印寄存器 + 摘要并退出 */
static void cpu_cleanup_artifacts(void){
    if (!g_auto_clean_after_halt) return;
    const char *disable = getenv("AUTO_CLEAN_DISABLE");
    if (disable && atoi(disable)) return; /* 强制禁用 */
    FILE *mf = fopen("Makefile","r");
    if (!mf) return; /* 非预期工作目录则不清理 */
    fclose(mf);
    fprintf(stderr, "[AUTO-CLEAN] 正在删除构建中间产物(保持当前正在使用的 ELF 不影响运行)...\n");
    /* 注意：运行中的 ELF 已被加载，可安全删除其文件路径；但这里保留 ELF 仅删中间文件与生成的 .bin */
    int r = system("rm -rf build/*.o build/*.d build/native/*.o build/native/*.d 2>/dev/null"); (void)r;
    /* 删除转换生成的 .bin（保持原始 .hex） */
    r = system("rm -f *.bin 2>/dev/null"); (void)r;
    /* 如果希望彻底清理 build 目录，可再执行: rm -rf build */
    fprintf(stderr, "[AUTO-CLEAN] 完成。\n");
}
void cpu_halt(int code){
    printf("收到 HALT 请求：退出码=%d\n", code);
    printf("HALT 时寄存器：\n");
    for (int i=0;i<GPR_COUNT;++i) printf("x%02d = 0x%08x\n", i, regs[i]);
    fflush(stdout);
    extern void video_on_halt(void);
    if (s_video_dirty) {
        video_on_halt();
    }
    fprintf(stderr, "[DEBUG] g_hold_after_halt=%d\n", g_hold_after_halt);

    /* 若需要保持图像显示，即使无法读取输入也不会直接退出 */
    if (g_hold_after_halt) hold_wait_for_exit();

    fprintf(stderr, "\n=== 模拟器摘要(HALT)===\n");
    fprintf(stderr, "已执行指令数: %llu\n", g_instr_executed);
    fprintf(stderr, "指令跟踪: %s\n", g_trace_ins ? "开启" : "关闭");
    if (g_trace_ins) fprintf(stderr, "跟踪上限: %llu\n", g_trace_limit);
    fprintf(stderr, "=============================\n\n");
    /* 在真正退出前清理中间产物 */
    cpu_cleanup_artifacts();
    exit(code);
}

/* 单步执行 */
int cpu_step(uint32_t *imem, size_t imem_len){
    if (IMEM_IDX(PC) >= imem_len) { printf("PC 越界: 0x%08x\n", PC); exit(1); }
    uint32_t inst = imem[IMEM_IDX(PC)];
    uint32_t opcode = GET_OPCODE(inst);

    if (g_trace_ins && g_steps < g_trace_limit) {
        printf("跟踪 PC=0x%08x 指令=0x%08x 操作码=0x%02x\n", PC, inst, opcode);
        for (int ri = 0; ri < GPR_COUNT; ++ri) {
            printf("x%d=0x%08x \n", ri, regs[ri]);
        }
    }

    switch (opcode) {
        case OPC_LUI: {
            uint32_t rd = GET_RD(inst);
            uint32_t imm20 = inst & IMM20_MASK;
            wr(rd, imm20);
            PC += 4;
            break;
        }
        case OPC_AUIPC: {
            uint32_t rd = GET_RD(inst);
            uint32_t imm20 = inst & IMM20_MASK;
            wr(rd, PC + imm20);
            PC += 4;
            break;
        }
        case OPC_OPIMM: {
            uint32_t rd    = GET_RD(inst);
            uint32_t funct3= GET_FUNCT3(inst);
            uint32_t rs1   = GET_RS1(inst);
            uint32_t imm12 = (inst >> 20) & 0xfff;
            int32_t imm    = cpu_sign_extend(imm12, 12);
            if (funct3 == 0x0) {
                wr(rd, (uint32_t)((int32_t)rr(rs1) + imm));
                PC += 4;
            } else {
                PC += 4;
            }
            break;
        }
        case OPC_JALR: {
            uint32_t rd     = GET_RD(inst);
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1    = GET_RS1(inst);
            uint32_t imm12  = (inst >> 20) & 0xfff;
            int32_t  imm    = cpu_sign_extend(imm12, 12);
            if (funct3 != 0x0) { PC += 4; break; }
            uint32_t next_pc = PC + 4;
            uint32_t target  = (uint32_t)(((int32_t)rr(rs1)) + imm) & ~1u;
            wr(rd, next_pc);
            PC = target;
            break;
        }
        case OPC_OP: {
            uint32_t rd    = GET_RD(inst);
            uint32_t funct3= GET_FUNCT3(inst);
            uint32_t rs1   = GET_RS1(inst);
            uint32_t rs2   = GET_RS2(inst);
            uint32_t funct7= GET_FUNCT7(inst);
            if (funct3 == 0x0 && funct7 == 0x00) {
                wr(rd, (uint32_t)((int32_t)rr(rs1) + (int32_t)rr(rs2)));
                PC += 4;
            } else {
                PC += 4;
            }
            break;
        }
        case OPC_LOAD: {
            uint32_t rd     = GET_RD(inst);
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1    = GET_RS1(inst);
            uint32_t imm12  = (inst >> 20) & 0xfff;
            int32_t  imm    = cpu_sign_extend(imm12, 12);
            uint32_t addr   = (uint32_t)((int32_t)rr(rs1) + imm);
            switch (funct3) {
                case 0x2: { /* LW */
                    uint32_t v = dmem_read32(addr);
                    wr(rd, v);
                    break;
                }
                case 0x4: { /* LBU */
                    uint8_t v = dmem_read8(addr);
                    wr(rd, (uint32_t)v);
                    break;
                }
                default:
                    break;
            }
            PC += 4;
            break;
        }
        case OPC_STORE: {
            uint32_t funct3  = GET_FUNCT3(inst);
            uint32_t rs1     = GET_RS1(inst);
            uint32_t rs2     = GET_RS2(inst);
            uint32_t imm11_5 = (inst >> 25) & 0x7f;
            uint32_t imm4_0  = (inst >> 7)  & 0x1f;
            uint32_t imm     = (imm11_5 << 5) | imm4_0;
            int32_t  simm    = cpu_sign_extend(imm, 12);
            uint32_t addr    = (uint32_t)((int32_t)rr(rs1) + simm);
            switch (funct3) {
                case 0x0: /* SB */
                    dmem_write8(addr, (uint8_t)(rr(rs2) & 0xff));
                    break;
                case 0x2: /* SW */
                    dmem_write32(addr, rr(rs2));
                    break;
                default:
                    break;
            }
            PC += 4;
            break;
        }
        case OPC_BRANCH: {
            uint32_t funct3  = GET_FUNCT3(inst);
            uint32_t rs1     = GET_RS1(inst);
            uint32_t rs2     = GET_RS2(inst);
            uint32_t imm12   = ((inst >> 31) & 0x1);
            uint32_t imm10_5 = ((inst >> 25) & 0x3f);
            uint32_t imm4_1  = ((inst >> 8)  & 0xf);
            uint32_t imm11   = ((inst >> 7)  & 0x1);
            uint32_t imm     = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1);
            int32_t  simm    = cpu_sign_extend(imm, 13);
            uint32_t target  = (uint32_t)((int32_t)PC + simm);
            int take = 0;
            switch (funct3) {
                case 0x0: take = ((int32_t)rr(rs1) == (int32_t)rr(rs2)); break; /* BEQ */
                case 0x1: take = ((int32_t)rr(rs1) != (int32_t)rr(rs2)); break; /* BNE */
                case 0x4: take = ((int32_t)rr(rs1) <  (int32_t)rr(rs2)); break; /* BLT */
                case 0x5: take = ((int32_t)rr(rs1) >= (int32_t)rr(rs2)); break; /* BGE */
                case 0x6: take = ((uint32_t)rr(rs1) <  (uint32_t)rr(rs2)); break; /* BLTU */
                case 0x7: take = ((uint32_t)rr(rs1) >= (uint32_t)rr(rs2)); break; /* BGEU */
                default:  take = 0; break;
            }
            if (take) {
                PC = target;
            } else {
                PC += 4;
            }
            break;
        }
        case OPC_JAL: {
            uint32_t rd      = GET_RD(inst);
            uint32_t imm20   = (inst >> 31) & 0x1;
            uint32_t imm10_1 = (inst >> 21) & 0x3ff;
            uint32_t imm11   = (inst >> 20) & 0x1;
            uint32_t imm19_12= (inst >> 12) & 0xff;
            uint32_t imm     = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1);
            int32_t  simm    = cpu_sign_extend(imm, 21);
            uint32_t next_pc = PC + 4;
            uint32_t target  = (uint32_t)((int32_t)PC + simm);
            wr(rd, next_pc);
            PC = target;
            break;
        }
        case OPC_SYSTEM: {
            if (inst == INST_EBREAK || inst == INST_ECALL) {
                int exit_code = (int)(rr(10) & 0xffffffffu);
                cpu_halt(exit_code);
            }
            PC += 4;
            break;
        }
        default: { PC += 4; break; }
    }
    g_steps++;
    g_instr_executed++;
    return 0;
}

/* APP 使用：扫描到 HALT 位置后调用该函数，以便循环保护跳转 */
void cpu_set_halt_pc(uint32_t pc) { g_halt_pc = pc; }

/* 便于 APP 读取一些可见状态*/
unsigned long long cpu_get_progress_every(void){ return g_progress_every; }
int cpu_get_show_regs_after(void){ return g_show_regs_after; }

/* ===================== 显存访问接口实现 ===================== */
const uint8_t *cpu_video_fb_data(void){ return s_video_fb; }
size_t         cpu_video_fb_size(void){ return (size_t)VIDEO_SIZE; }
int            cpu_video_width(void){ return VIDEO_W; }
int            cpu_video_height(void){ return VIDEO_H; }
int            cpu_video_dirty(void){ return s_video_dirty; }
void           cpu_video_clear_dirty(void){ s_video_dirty = 0; }
void           cpu_set_hold_after_halt(int hold){ g_hold_after_halt = (hold!=0); }

/* 若应用未提供 video_on_halt，给一个弱符号空实现防止链接错误 */
__attribute__((weak)) void video_on_halt(void) { /* no-op */ }

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "minirvEMU.h"

// =============================
// 配置常量 / 宏（模块化命名）
// - 指令内存索引：IMEM_IDX(pc) 等价 pc/4
// - 指令字段提取：GET_* 宏
// - 操作码常量：OPC_*
// - 简易 MMIO 常量：MMIO_PUT / MMIO_EXIT
// =============================

// 指令内存索引（PC 字节地址 → 指令索引）
#define IMEM_IDX(pc) ((uint32_t)(pc) >> 2)          // 4字节，因此PC除四，即右移两位

// 指令字段提取（RISC‑V 基本位域）
#define GET_OPCODE(i)   ((uint32_t)(i) & 0x7fu)
#define GET_RD(i)       (((uint32_t)(i) >> 7)  & 0x1fu)
#define GET_FUNCT3(i)   (((uint32_t)(i) >> 12) & 0x7u)
#define GET_RS1(i)      (((uint32_t)(i) >> 15) & 0x1fu)
#define GET_RS2(i)      (((uint32_t)(i) >> 20) & 0x1fu)
#define GET_FUNCT7(i)   (((uint32_t)(i) >> 25) & 0x7fu)

// 常用立即数字段掩码
#define IMM20_MASK 0xfffff000u  // [31:12]

// 操作码常量（RV32I 基础）
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

// 简易 MMIO 约定
#define MMIO_PUT  0x10000000u  // 写入→打印
#define MMIO_EXIT 0x10000004u  // 写入→退出

// SYSTEM 指令常量
#define INST_ECALL  0x00000073u
#define INST_EBREAK 0x00100073u

// 通用寄存器数量（RV32E: 16）。如需兼容 RV32I 可将值改为 32。
#ifndef GPR_COUNT
#define GPR_COUNT 16
#endif

// 全局寄存器文件（x0..x15）
uint32_t regs[16];

// 访问寄存器的辅助：
static inline uint32_t rr(uint32_t idx) {       // inline 代表建议编译器内联展开，以减少开销，read register 读取通用寄存器的值，简写rr
    if (idx >= GPR_COUNT) {
        fprintf(stderr, "Illegal GPR x%u (GPR_COUNT=%d) at PC=0x%08x\n", idx, GPR_COUNT, PC);
        exit(2);
    }
    return regs[idx];
}
static inline void wr(uint32_t idx, uint32_t val) {         // wr write register写寄存器
    if (idx == 0) return; // x0 恒为 0
    if (idx >= GPR_COUNT) {
        fprintf(stderr, "Illegal GPR x%u (GPR_COUNT=%d) at PC=0x%08x\n", idx, GPR_COUNT, PC);
        exit(2);
    }
    regs[idx] = val;
}

// 程序计数器（字节地址）
uint32_t PC = 0;

// 全局执行步计数（供 step() 打印使用）
static unsigned long long g_steps = 0;
// 当g_trace_ins等于1的时候，程序会开启每条指令的跟踪输出
// 当跟踪开启的时候，g_trace_limit来限制最多打印多少条跟踪信息
static int g_trace_ins = 0;
/* g_trace_limit 改为 unsigned long long，以支持足够大的跟踪上限（覆盖 32-bit 范围） */
static unsigned long long g_trace_limit = 200ULL;
/* 全局指令计数器：统计已执行的指令（每条指令计数一次） */
static unsigned long long g_instr_executed = 0ULL;
// 可选：是否在结束时打印寄存器（默认关闭，设置 SHOW_REGS_AFTER=1 开启）
static int g_show_regs_after = 0;
// 进度打印间隔（步），0 表示关闭；由环境变量 PROGRESS_EVERY 配置，默认 0
static unsigned long long g_progress_every = 0ULL;

// 简单的数据内存（16 MiB）。这是按字节寻址的线性内存，供 LOAD/STORE 使用。
// 对越界访问会进行检查并终止模拟器，以便尽早发现问题。
#define DMEM_SIZE (16*1024*1024)
static uint8_t dmem[DMEM_SIZE];

// =============================
// 数据内存访问辅助函数（带边界检查）
// =============================
static inline uint8_t dmem_read8(uint32_t addr) {       // 按字节读取内存
    if (addr + 1 > DMEM_SIZE) { printf("DMEM read8 越界: 0x%08x\n", addr); exit(1); }
    return dmem[addr];
}
static inline uint32_t dmem_read32(uint32_t addr) {     //按照字节读取并且小端排序左移拼接
    if (addr + 4 > DMEM_SIZE) { printf("DMEM read32 越界: 0x%08x\n", addr); exit(1); }
    return (uint32_t)dmem[addr]
         | ((uint32_t)dmem[addr+1] << 8)
         | ((uint32_t)dmem[addr+2] << 16)
         | ((uint32_t)dmem[addr+3] << 24);
}
static inline void dmem_write8(uint32_t addr, uint8_t val) {        // 按字节写入内存
    if (addr + 1 > DMEM_SIZE) { printf("DMEM write8 越界: 0x%08x\n", addr); exit(1); }
    dmem[addr] = val;
}
static inline void dmem_write32(uint32_t addr, uint32_t val) {         // 把32位数据按小端顺序拆为4个字节写入
    if (addr + 4 > DMEM_SIZE) { printf("DMEM write32 越界: 0x%08x\n", addr); exit(1); }
    dmem[addr]   = (uint8_t)(val & 0xff);               // 掩码保证只写入一个字节
    dmem[addr+1] = (uint8_t)((val >> 8) & 0xff);
    dmem[addr+2] = (uint8_t)((val >> 16) & 0xff);
    dmem[addr+3] = (uint8_t)((val >> 24) & 0xff);
}

// 死循环检测：记录上一次 PC 以及连续重复的次数
static uint32_t g_last_pc = 0xffffffffu;
static unsigned long long g_repeat_pc_count = 0ULL;
// 默认阈值，可通过环境变量 LOOP_THRESH 调整（单位：连续重复次数）
static unsigned long long g_loop_thresh = 1000000ULL;

// 最大执行步数阈值（防止长时间运行/无法检测到短周期循环时的退路）。
// 可通过环境变量 LOOP_MAX_STEPS 调整（默认 5e6 步）。
static unsigned long long g_loop_max_steps = 5000000ULL;
// 如果程序自身包含一个 halt（ecall/ebreak）指令，我们记录其 PC，
// 在检测到死循环时跳转到该 PC 以让程序自己执行退出逻辑。
static uint32_t g_halt_pc = 0xffffffffu;

// 统一的循环保护处理：
// - 当“单个 PC 重复”达到阈值，或“最大步数退路”触发时，执行统一策略：
//   1) 若找到程序中的 halt（ECALL/EBREAK）地址，则跳转过去让程序自行退出；
//   2) 否则在当前 PC 注入 ECALL 强制退出；
//   3) 打印诊断信息并刷新 stderr；重置计数避免重复注入。
static void handle_loop_protection(uint32_t *imem, size_t imem_len, unsigned long long step_cnt)
{
    int triggered = 0;
    // 情况一：单点重复达到阈值，同一个PC被连续执行多次
    if (g_repeat_pc_count >= g_loop_thresh) {
        fprintf(stderr, "检测到可能的死循环，PC=0x%08x（重复次数=%llu）\n", PC, g_repeat_pc_count);
        fflush(stderr);
        triggered = 1;
    }
    // 情况二：最大步数退路，总执行步数超过上限的运行
    else if (g_loop_max_steps > 0 && step_cnt >= g_loop_max_steps) {
        fprintf(stderr, "超过最大步数阈值 LOOP_MAX_STEPS=%llu（当前步数=%llu）\n", g_loop_max_steps, step_cnt);
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
            // 防御性检查：理论上主循环条件已确保不越界；此处仅为稳妥并使用 imem_len
            fprintf(stderr, "-> 警告：无法注入 ECALL，PC 对应下标=%zu 已越界（imem_len=%zu）\n", idx, imem_len);
            fflush(stderr);
        } else {
            fprintf(stderr, "-> 未找到程序 halt，向当前 PC 注入 ECALL 强制退出（imem 下标=%zu）\n", idx);
            imem[idx] = 0x00000073u; // ECALL
        }
    }
    // 重置计数，避免重复注入/跳转
    g_repeat_pc_count = 0ULL;
}

// 宿主侧 halt 处理函数：当程序发出退出请求（ecall/ebreak）时调用。
// 使用 regs[10] (a0) 作为退出码。此函数会打印寄存器快照并调用 exit().
static void halt(int code) {
    printf("收到 HALT 请求：退出码=%d\n", code);
    printf("HALT 时寄存器：\n");
    for (int i = 0; i < GPR_COUNT; ++i) {
        printf("x%02d = 0x%08x\n", i, regs[i]);
    }
    fflush(stdout);
    /* 在退出前打印运行摘要到 stderr，避免与 stdout 混杂 */
    fprintf(stderr, "\n=== 模拟器摘要（HALT）===\n");
    fprintf(stderr, "已执行指令数: %llu\n", g_instr_executed);
    fprintf(stderr, "指令跟踪: %s\n", g_trace_ins ? "开启" : "关闭");
    if (g_trace_ins) fprintf(stderr, "跟踪上限: %llu\n", g_trace_limit);
    fprintf(stderr, "=============================\n\n");
    exit(code);
}

// 读取一次性的运行时配置（来自环境变量），展开写法以便新手阅读，语义与原来一致
static void load_runtime_config(void) {
    const char *s; /* 用来临时保存 getenv 返回的环境变量值 */

    /* TRACE_INS: 开启每条指令的跟踪（TRACE_LIMIT 可限制输出条数） */
    s = getenv("TRACE_INS");
    if (s) {
        if (atoi(s)) {
            g_trace_ins = 1;
            /* 仅当 TRACE_INS 被设置为非零时才尝试读取 TRACE_LIMIT */
            s = getenv("TRACE_LIMIT");
                    if (s) {
                        unsigned long long v = strtoull(s, NULL, 10);
                        if (v > 0) g_trace_limit = v;
                    }
        }
    }

    /* SHOW_REGS_AFTER: 结束时打印寄存器快照（非零开启） */
    s = getenv("SHOW_REGS_AFTER");
    if (s) {
        g_show_regs_after = (atoi(s) != 0);
    }

    /* PROGRESS_EVERY: 每 N 步打印进度（使用 strtoull 解析大整数） */
    s = getenv("PROGRESS_EVERY");
    if (s) {
        g_progress_every = (unsigned long long)strtoull(s, NULL, 10);
    }

    /* LOOP_THRESH: 单 PC 重复判定阈值（连续重复次数） */
    s = getenv("LOOP_THRESH");
    if (s) {
        unsigned long long v = strtoull(s, NULL, 10);
        if (v > 0) g_loop_thresh = v;
    }

    /* LOOP_MAX_STEPS: 最大执行步数阈值 */
    s = getenv("LOOP_MAX_STEPS");
    if (s) {
        unsigned long long v = strtoull(s, NULL, 10);
        if (v > 0) g_loop_max_steps = v;
    }
}

// regs[i] 对应寄存器 xi，regs[0] (= x0) 恒为 0。
// 辅助函数：将宽度为 `bits` 的无符号值 `val` 符号扩展为 32 位有符号整数。
// 例如：sign_extend(0b1111, 4) -> -1 (0xffffffff)
// =============================
// 工具函数：符号扩展（指令译码辅助）
// =============================
static int32_t sign_extend(uint32_t val, int bits) {
    uint32_t m = 1u << (bits - 1);                  //获得符号位的掩码
// PC 保存当前指令的字节地址；从 imem 取指时使用 imem[PC >> 2]
    return (int32_t)((val ^ m) - m);                //按位异或
}

// 执行在当前 PC 处从 `imem` 取到的一条指令。
// 如果返回 1 则表示程序应当终止（例如遇到 ecall/ebreak 或 MMIO 退出），
// dmem: 数据内存（字节数组），由 LOAD/STORE 操作访问。
// 返回 0 则继续执行下一条指令。
// =============================
// 执行引擎（数据通路 + 控制）
// - 流程：取指 → 译码 → 执行 → 写回/更新 PC
// =============================
int step(uint32_t *imem, size_t imem_len) {
    // Basic bounds check: 用 IMEM_IDX(PC) 进行取指边界检查
    if (IMEM_IDX(PC) >= imem_len) {
        printf("PC 越界: 0x%08x\n", PC);
        exit(1);
    }

    // 从 imem 中取出 32 位小端指令字
    // 使用右移 2 位代替除以 4：更明确且避免整除开销
    uint32_t inst = imem[IMEM_IDX(PC)];     // instruction 的缩写

    // 主操作码字段（位 6:0）
    uint32_t opcode = GET_OPCODE(inst);

    // Optional per-instruction trace (prints before executing instruction)   打印PC和指令以及opcode和各个寄存器的值
    if (g_trace_ins && g_steps < g_trace_limit) {
        printf("跟踪 PC=0x%08x 指令=0x%08x 操作码=0x%02x\n", PC, inst, opcode);
        // 打印寄存器快照（RV32E 的 x0..x15）
        for (int ri = 0; ri < GPR_COUNT; ++ri) {
            printf("x%d=0x%08x \n", ri, regs[ri]);
            //if ((ri & 7) == 7) printf("\n"); // newline every 8 regs for readability
        }
    }
    switch (opcode) {
        case OPC_LUI: { // LUI: load upper immediate；opcode = 00110111
            uint32_t rd = GET_RD(inst);
            uint32_t imm20 = inst & IMM20_MASK; // 高 20 位放在 [31:12]
            wr(rd, imm20); // 写入 x0 被忽略
            PC += 4; // PC 前进到下一条指令
            break;
        }
        case OPC_AUIPC: {
            // AUIPC: add upper immediate to PC
            uint32_t rd = GET_RD(inst);
            uint32_t imm20 = inst & IMM20_MASK; // already shifted <<12
            wr(rd, PC + imm20);
            PC += 4;
            break;
        }
        case OPC_OPIMM: { // OP-IMM (addi and other immediate ALU ops)；opcode = 00010011
            uint32_t rd = GET_RD(inst);
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1 = GET_RS1(inst);
            uint32_t imm12 = (inst >> 20) & 0xfff;
            int32_t imm = sign_extend(imm12, 12);
            if (funct3 == 0x0) { // addi
                wr(rd, (uint32_t)((int32_t)rr(rs1) + imm));
                PC += 4;
            } else {
                // 非 addi 的 OP-IMM：静默跳过
                PC += 4;
            }
            break;
        }
        case OPC_JALR: { // JALR: jump and link register (supported)
            uint32_t rd = GET_RD(inst);
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1 = GET_RS1(inst);
            uint32_t imm12 = (inst >> 20) & 0xfff;
            int32_t imm = sign_extend(imm12, 12);
            if (funct3 != 0x0) {
                // 不支持的 funct3，静默跳过此指令
                PC += 4; break;
            }
            uint32_t next_pc = PC + 4; // 返回地址
            // 目标地址 = regs[rs1] + imm，且按规范清除最低位
            uint32_t target = (uint32_t)(((int32_t)rr(rs1)) + imm) & ~1u;
            wr(rd, next_pc);
            PC = target;
            break;
        }
        case OPC_OP: { // R-type ALU (仅支持 add)
            uint32_t rd = GET_RD(inst);
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1 = GET_RS1(inst);
            uint32_t rs2 = GET_RS2(inst);
            uint32_t funct7 = GET_FUNCT7(inst);
            if (funct3 == 0x0 && funct7 == 0x00) { // add
                wr(rd, (uint32_t)((int32_t)rr(rs1) + (int32_t)rr(rs2)));
            } else {
                // 非 add 的 R-type：静默跳过
                PC += 4; break;
            }
            PC += 4;
            break;
        }
        case OPC_LOAD: { // LOAD (仅支持 LW, LBU)
            uint32_t rd = GET_RD(inst);
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1 = GET_RS1(inst);
            uint32_t imm12 = (inst >> 20) & 0xfff;
            int32_t imm = sign_extend(imm12, 12);
            uint32_t addr = (uint32_t)((int32_t)rr(rs1) + imm);
            switch (funct3) {
                case 0x2: { // LW (word)
                    uint32_t val = dmem_read32(addr);
                    wr(rd, val);
                    break;
                }
                case 0x4: { // LBU (unsigned byte)
                    uint8_t v = dmem_read8(addr);
                    wr(rd, (uint32_t)v);
                    break;
                }
                default:
                    // 非 LW/LBU：静默跳过（不写寄存器）
                    break;
            }
            PC += 4;
            break;
        }
        case OPC_STORE: { // STORE (仅支持 SW, SB)
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1 = GET_RS1(inst);
            uint32_t rs2 = GET_RS2(inst);
            // imm is split between bits [31:25] and [11:7] for S-type
            uint32_t imm11_5 = (inst >> 25) & 0x7f;
            uint32_t imm4_0 = (inst >> 7) & 0x1f;
            uint32_t imm = (imm11_5 << 5) | imm4_0;
            int32_t simm = sign_extend(imm, 12);
            uint32_t addr = (uint32_t)((int32_t)rr(rs1) + simm);

            // Normal memory store operations
            switch (funct3) {
                case 0x0: { // sb
                    dmem_write8(addr, (uint8_t)(rr(rs2) & 0xff)); break;
                }
                case 0x2: { // sw
                    dmem_write32(addr, rr(rs2)); break;
                }
                default:
                    // 非 SB/SW：静默跳过
                    break;
            }
            PC += 4;
            break;
        }
        case OPC_BRANCH: {
            // Conditional branches: BEQ/BNE/BLT/BGE/BLTU/BGEU
            uint32_t funct3 = GET_FUNCT3(inst);
            uint32_t rs1 = GET_RS1(inst);
            uint32_t rs2 = GET_RS2(inst);
            // B-type immediate: imm[12|10:5|4:1|11] << 1
            uint32_t imm12 = ((inst >> 31) & 0x1);
            uint32_t imm10_5 = ((inst >> 25) & 0x3f);
            uint32_t imm4_1 = ((inst >> 8) & 0xf);
            uint32_t imm11 = ((inst >> 7) & 0x1);
            uint32_t imm = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1);
            int32_t simm = sign_extend(imm, 13);
            uint32_t target = (uint32_t)((int32_t)PC + simm);
            int take = 0;
            switch (funct3) {
                case 0x0: take = ((int32_t)rr(rs1) == (int32_t)rr(rs2)); break; // BEQ
                case 0x1: take = ((int32_t)rr(rs1) != (int32_t)rr(rs2)); break; // BNE
                case 0x4: take = ((int32_t)rr(rs1) <  (int32_t)rr(rs2)); break;  // BLT
                case 0x5: take = ((int32_t)rr(rs1) >= (int32_t)rr(rs2)); break; // BGE
                case 0x6: take = ((uint32_t)rr(rs1) <  (uint32_t)rr(rs2)); break; // BLTU
                case 0x7: take = ((uint32_t)rr(rs1) >= (uint32_t)rr(rs2)); break;// BGEU
                default: take = 0; break;
            }
            if (take) PC = target; else PC += 4;
            break;
        }
        case OPC_JAL: {
            // JAL: jump and link (J-type immediate)
            uint32_t rd = GET_RD(inst);
            // J-type immediate: imm[20|10:1|11|19:12]
            uint32_t imm20 = (inst >> 31) & 0x1;
            uint32_t imm10_1 = (inst >> 21) & 0x3ff;
            uint32_t imm11 = (inst >> 20) & 0x1;
            uint32_t imm19_12 = (inst >> 12) & 0xff;
            uint32_t imm = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1);
            int32_t simm = sign_extend(imm, 21);
            uint32_t next_pc = PC + 4;
            uint32_t target = (uint32_t)((int32_t)PC + simm);
            wr(rd, next_pc);
            PC = target;
            break;
        }
        case OPC_SYSTEM: {
            // Handle ECALL/EBREAK: we treat EBREAK (patched ECALL -> EBREAK)
            // as a program termination request. Other SYSTEM forms are
            // silently skipped in this minimal emulator.
            // Treat both EBREAK (0x00100073) and ECALL (0x00000073) as termination
            // so that an injected ECALL (for loop-exit) will also cause simulator
            // to terminate gracefully.
            if (inst == INST_EBREAK || inst == INST_ECALL) { // EBREAK (imm=1) or ECALL
                // 使用 regs[10] (a0) 作为退出码，调用宿主侧 halt() 并退出进程。
                // 这样可以直接终止模拟器并打印寄存器状态（便于调试）。
                int exit_code = (int)(rr(10) & 0xffffffffu);
                halt(exit_code);
                /* unreachable */
            }
            // Otherwise just advance PC and continue
            PC += 4; break;
        }
        default:
            // 对未知/未实现的 opcode 静默跳过（按指令长度 4 字节推进 PC）
            PC += 4; break;
    }
    return 0;
}

int main(int argc, char **argv) {
    uint32_t *imem = NULL;
    size_t imem_len = 0;

    // 如果提供了程序二进制路径，则按原始小端 32-bit words 加载它到指令内存（imem）。
    // 该格式与简单工具链或 Logisim 测试输出一致。
    if (argc > 1) {
        // -h/--help：输出简短说明，避免主函数过度噪声
        if (argc == 2 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
            printf("用法: %s [program.bin]\n", argv[0]);
            printf("提示: 详细使用方法与原理说明，请查看 README.md\n");
            return 0;
        }

        // path: 用户提供的二进制文件路径
        const char *path = argv[1];
        FILE *f = fopen(path, "rb");
        if (!f) {
            // 打开失败时打印错误并退出
            perror("fopen 失败");
            return 1;
        }

        // 求文件长度：先 seek 到文件末尾，再用 ftell 获取大小（字节）
        if (fseek(f, 0, SEEK_END) != 0) {                   // int fseek(FILE *stream, long offset, int whence) stream文件指针，offset相对偏移 ,whence参考起点
            perror("fseek 失败"); fclose(f); return 1;
        }
        // ftell返回当前文件位置的偏移（以字节为单位），因为刚才fseek到了文件末尾，所以ftell返回的就是文件大小（字节数）
    long sz = ftell(f);
    if (sz < 0) { perror("ftell 失败"); fclose(f); return 1; }

        // 回到文件开头准备读取
    if (fseek(f, 0, SEEK_SET) != 0) { perror("fseek 失败"); fclose(f); return 1; }

        // 要求二进制大小必须是 4 的倍数（每条指令 4 字节）
        if (sz % 4 != 0) {
            fprintf(stderr, "二进制大小必须是 4 的倍数（字节）\n");
            fclose(f); return 1;
        }

        // imem_len: 指令数量（每个元素为一个 32-bit 指令）
        imem_len = (size_t)sz / 4;          // malloc, fread都用size_t，用size_t存放长度能够避免频繁的类型转换

        // 先把整个文件读入到临时字节缓冲 buf 中，然后再按 4 字节转换为 imem
        // 这样便于处理任意文件大小并在内存中直接构建 32-bit 指令数组。
        // 在堆上分配sz字节的缓冲区用于存放文件内容（按字节存放）
    uint8_t *buf = malloc(sz);
    if (!buf) { perror("malloc 失败"); fclose(f); return 1; }
        // 从文件f读取数据到buf，fread的语义是读取sz个单元，每个单元的大小为1字节，r是实际读到的字节数（size_t类型）
        size_t r = fread(buf, 1, sz, f);
        fclose(f);
    if (r != (size_t)sz) { fprintf(stderr, "读取字节数不足（short read）\n"); free(buf); return 1; }

        // 为 imem 分配空间，每个指令占用一个 uint32_t  也就是ROM
        // 为指令内存分配imem_len个32bit的指令空间
    imem = malloc(imem_len * sizeof(uint32_t));
    if (!imem) { perror("malloc 失败"); free(buf); return 1; }

        // 将 4 个小端字节组合为一个 uint32_t（与生成二进制的工具链字节序对应）
        // 把按字节读入的原始文件数据（小端序）转换成32-bit指令字。buf存储原始字节，按小端序合成uint32_t
        for (size_t i = 0; i < imem_len; i++) {
            imem[i] = (uint32_t)buf[i*4] | ((uint32_t)buf[i*4+1] << 8) | ((uint32_t)buf[i*4+2] << 16) | ((uint32_t)buf[i*4+3] << 24);
        }
        // 将程序二进制的原始字节也复制到数据内存的低地址处，   dmem,dram
        // 以模拟统一的内存空间（text 和 data 在同一地址空间）。
        // 许多测试程序会将只读数据紧跟在代码之后，直接从这些地址加载。
        size_t copy_bytes = (size_t)sz;
        if (copy_bytes > DMEM_SIZE) copy_bytes = DMEM_SIZE;
        memcpy(dmem, buf, copy_bytes);
        free(buf);
    printf("已从 %s 加载 %zu 条指令\n", path, imem_len);

        // 记录程序中任意出现的 ECALL/EBREAK 的地址，作为 "halt 函数" 的候选。
        // 我们记录最后出现的一处（靠近二进制尾部，往往是退出逻辑所在处）。
        for (long i = (long)imem_len - 1; i >= 0; --i) {
            if (imem[i] == INST_ECALL || imem[i] == INST_EBREAK) {
                g_halt_pc = (uint32_t)(i * 4);
                printf("在 PC=0x%08x 处发现程序的 halt（ECALL/EBREAK）（imem 下标 %ld）\n", g_halt_pc, i);
                break;
            }
        }
    }

    // 如果没有提供文件，则使用一个内置的回退程序（方便快速 smoke-test）
    // 这个序列非常短，主要用于确保模拟器的基本执行路径是正确的。
    uint32_t builtin_imem[] = {
        0x01400093, // addi x1, x0, 20
        0x00000113, // addi x2, x0, 0
        0x00000193, // addi x3, x0, 0
        0x00008267, // jalr x4, x1, 0
        0x00000000, // padding
        0x03700293, // addi x5, x0, 55
    };
    // 内置冒烟测试：未提供外部程序时使用；其执行解读见 README。
    size_t builtin_len = sizeof(builtin_imem)/4;
    if (!imem) {
        // 使用内置指令数组作为 imem，避免未提供外部二进制时的空指针
        imem = builtin_imem;
        imem_len = builtin_len;
    }

    // 一次性读取运行时配置（环境变量）
    load_runtime_config();

    // 初始化寄存器与 PC：清零寄存器文件并将 PC 置 0
    // 注意：regs[0] 的恒 0 语义在软件层通过避免写入来保持
    memset(regs, 0, sizeof(regs));
    PC = 0;

    // 运行主循环：不断调用 step() 执行单条指令，直到达到终止条件
    // 终止条件包括：step() 返回终止信号、PC 越界、或执行步数超过 STEP_LIMIT
    unsigned long long step_cnt = 0; // 已执行指令计数
    const unsigned long long STEP_LIMIT = 2000000000; // 安全上限（防御性）
    // 主循环：用 (PC >> 2) 计算当前指令索引（等价于 PC/4）
    while (IMEM_IDX(PC) < imem_len) {
        if (g_progress_every && (step_cnt % g_progress_every) == 0) {
            // 把进度信息输出到 stderr，这样 stdout 可被 MMIO 或用户程序使用
            fprintf(stderr, "进度: 步数=%llu PC=0x%08x\n", step_cnt, PC);
        }

        // 简单的单 PC 重复检测（仍保留）
        if (PC == g_last_pc) {
            g_repeat_pc_count++;
        } else {
            g_last_pc = PC;
            g_repeat_pc_count = 0ULL;
        }

        // 统一的循环保护处理（单点重复 或 最大步数 触发）
        handle_loop_protection(imem, imem_len, step_cnt);

        // 执行一条指令。step() 可能返回 1 表示程序要求终止（ecall/ebreak/MMIO）
            int term = step(imem, imem_len);
            step_cnt++;
            /* 更新全局步数计数器（记录已执行的指令数） */
            g_steps++;
            /* 更新全局指令执行计数（每执行一条指令计数一次） */
            g_instr_executed++;

            if (term) break; // 程序显式要求终止

        // 如果执行步数超过设定上限，则中止并报告（防止无限循环）
    if (step_cnt > STEP_LIMIT) { fprintf(stderr, "步数过多，正在中止\n"); break; }
    }

    // 运行结束后（非 ECALL/EBREAK 路径），可选打印寄存器
    if (g_show_regs_after) {
        printf("执行结束后的寄存器（前 16 个）：\n");
        for (int i = 0; i < 16; i++) {
            printf("x%-2d = 0x%08x (%d)\n", i, regs[i], (int32_t)regs[i]);
        }
    }

    /* 打印运行摘要到 stderr，单独成行以便于与 make 的输出区分 */
    fprintf(stderr, "\n=== 模拟器摘要 ===\n");
    fprintf(stderr, "已执行指令数: %llu\n", g_instr_executed);
    fprintf(stderr, "指令跟踪: %s\n", g_trace_ins ? "开启" : "关闭");
    if (g_trace_ins) fprintf(stderr, "跟踪上限: %llu\n", g_trace_limit);
    fprintf(stderr, "====================\n\n");

    // 如果 imem 是从文件分配的缓冲区，则释放它；内置 imem（builtin_imem）无需释放
    if (argc > 1) free(imem);

    return 0;
}


#include "platform/soc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*
 * 本文件封装 SoC 平台层：协调核心、内存、跟踪与视频输出等子模块，
 * 负责仿真主循环以及异常处理。
 */

/* dump_registers:
 *   打印所有通用寄存器的值，可选标题用于区分不同的快照场景。
 */
static void dump_registers(const HardwareSystem *soc, const char *title) {
    if (!soc) {
        return;
    }
    if (title) {
        printf("%s\n", title);
    }
    for (int i = 0; i < HW_GPR_COUNT; ++i) {
        printf("x%-2d = 0x%08x\n", i, soc->core.regs[i]);
    }
    fflush(stdout);
}

/* emit_summary:
 *   在程序结束时汇总执行步数、退休指令数以及追踪开关信息。
 */
static void emit_summary(const HardwareSystem *soc) {
    fprintf(stderr, "\n=== emulator summary ===\n");
    fprintf(stderr, "steps executed : %llu\n", (unsigned long long)soc->step_counter);
    fprintf(stderr, "instructions    : %llu\n", (unsigned long long)soc->retired_counter);
    fprintf(stderr, "trace enabled   : %s\n", soc->trace.enabled ? "yes" : "no");
    if (soc->trace.enabled) {
        fprintf(stderr, "trace limit     : %llu\n", (unsigned long long)soc->trace.limit);
    }
    fprintf(stderr, "========================\n");
}

/*
 * 根据运行时选项自动清理构建产物，避免长时间运行后遗留大量文件。
 */
static void perform_auto_clean(const HardwareSystem *soc) {
    if (!soc || !soc->options.auto_clean) {
        return;
    }
    const char *override = getenv("AUTO_CLEAN_DISABLE");
    if (override && atoi(override) != 0) {
        return;
    }
    FILE *mf = fopen("Makefile", "r");
    if (!mf) {
        return;
    }
    fclose(mf);
    fprintf(stderr, "[auto-clean] removing intermediate artifacts...\n");
    fflush(stderr);
    system("rm -rf build/*.o build/*.d build/native/*.o build/native/*.d 2>/dev/null");
    system("rm -f *.bin 2>/dev/null");
    fprintf(stderr, "[auto-clean] done.\n");
}

/*
 * 循环保护的核心逻辑：根据告警情况注入 ECALL 或跳转至 Halt PC，
 * 以阻断死循环并确保仿真能够退出。
 */
static void handle_loop_signal(HardwareSystem *soc, LoopSignal signal) {
    if (!soc || signal == LOOP_SIGNAL_NONE) {
        return;
    }
    uint32_t pc = core_pc(&soc->core);
    if (signal == LOOP_SIGNAL_REPEAT) {
        fprintf(stderr, "loop guard: PC=0x%08x repeated, steering to halt.\n", pc);
    } else {
        fprintf(stderr, "loop guard: step ceiling reached, steering to halt.\n");
    }
    if (soc->halt_pc != 0xffffffffu) {
        fprintf(stderr, "-> jumping to known halt at 0x%08x\n", soc->halt_pc);
        core_set_pc(&soc->core, soc->halt_pc);
    } else {
        size_t idx = (size_t)(pc >> 2);
        if (idx < soc->rom_word_count) {
            fprintf(stderr, "-> injecting ECALL at instruction index %zu\n", idx);
            soc->rom_words[idx] = HW_INST_ECALL;
        } else {
            fprintf(stderr, "-> unable to inject ECALL, index out of range\n");
        }
    }
    loopguard_reset(&soc->guard);
    fflush(stderr);
}

/* soc_bootstrap:
 *   初始化 HardwareSystem 的所有组件，为后续加载程序做准备。
 */
void soc_bootstrap(HardwareSystem *soc, const RuntimeOptions *opts) {
    if (!soc) {
        return;
    }
    memset(soc, 0, sizeof(*soc));
    soc->rom_words = NULL;
    soc->rom_word_count = 0;
    soc->halt_pc = 0xffffffffu;
    if (opts) {
        soc->options = *opts;
    } else {
        memset(&soc->options, 0, sizeof(soc->options));
    }
    soc->hold_after_halt = soc->options.hold_after_halt;
    memory_reset(&soc->memory);
    core_reset(&soc->core);
    trace_init(&soc->trace, &soc->options);
    loopguard_init(&soc->guard, &soc->options);
    soc->step_counter = 0;
    soc->retired_counter = 0;
}

/* soc_attach_program:
 *   将 ProgramImage 绑定到 SoC，后续主循环会直接从 rom_words 取指。
 */
void soc_attach_program(HardwareSystem *soc, const ProgramImage *image) {
    if (!soc || !image) {
        return;
    }
    soc->rom_words = image->words;
    soc->rom_word_count = image->word_count;
    soc->halt_pc = image->halt_pc;
}

/* soc_memory:
 *   返回内部内存指针，供加载器写入程序或其它模块访问。
 */
SystemMemory *soc_memory(HardwareSystem *soc) {
    return soc ? &soc->memory : NULL;
}

/* soc_force_hold:
 *   动态启用/禁用仿真结束后的窗口保持状态。
 */
void soc_force_hold(HardwareSystem *soc, int enable) {
    if (soc) {
        soc->hold_after_halt = (enable != 0);
    }
}

/*
 * soc_run:
 *   SoC 的主执行循环，依次完成：
 *     1. 校验 PC 合法性与进度提示；
 *     2. 调用循环保护，必要时注入退出指令；
 *     3. 取指、可选打印跟踪、执行指令；
 *     4. 处理陷入（打印寄存器、刷新视频、自动清理），然后退出循环。
 */
int soc_run(HardwareSystem *soc) {
    if (!soc || !soc->rom_words || soc->rom_word_count == 0) {
        fprintf(stderr, "no program loaded\n");
        return 1;
    }
    while (1) {
        uint32_t pc = core_pc(&soc->core);
        size_t idx = (size_t)(pc >> 2);
        if (idx >= soc->rom_word_count) {
            fprintf(stderr, "PC out of range: 0x%08x\n", pc);
            break;
        }

        if (soc->options.progress_stride && (soc->step_counter % soc->options.progress_stride) == 0) {
            fprintf(stderr, "[progress] step=%llu pc=0x%08x\n", (unsigned long long)soc->step_counter, pc);
        }

        /*
         * 环路监控在每步执行前检查是否出现 PC 重复或步数上限，
         * 一旦触发即交由 handle_loop_signal 调整执行流。
         */
        LoopSignal signal = loopguard_observe(&soc->guard, pc, soc->step_counter);
        if (signal != LOOP_SIGNAL_NONE) {
            handle_loop_signal(soc, signal);
            pc = core_pc(&soc->core);
            idx = (size_t)(pc >> 2);
            if (idx >= soc->rom_word_count) {
                fprintf(stderr, "PC out of range after loop guard adjust: 0x%08x\n", pc);
                break;
            }
        }

        uint32_t inst = soc->rom_words[idx];
        if (trace_active(&soc->trace, soc->step_counter)) {
            trace_emit(&soc->trace, soc->step_counter, pc, inst, core_regs(&soc->core));
        }

        CoreStepResult step = core_step(&soc->core, &soc->memory, inst);
        soc->step_counter++;
        soc->retired_counter++;
        if (step.state == CORE_STEP_FAULT) {
            fprintf(stderr, "illegal instruction or fault at pc=0x%08x inst=0x%08x\n", pc, inst);
            return 1;
        }
        if (step.state == CORE_STEP_TRAP) {
            printf("halt trap received (code=%d)\n", step.trap_code);
            dump_registers(soc, "register snapshot at halt:");
            video_flush(&soc->memory, true);
            if (soc->hold_after_halt) {
                video_hold_until_exit();
            }
            emit_summary(soc);
            perform_auto_clean(soc);
            return step.trap_code;
        }

        if (memory_video_dirty(&soc->memory)) {
            video_flush(&soc->memory, false);
        }
    }

    if (soc->options.show_regs_after) {
        dump_registers(soc, "register snapshot after run:");
    }
    emit_summary(soc);
    perform_auto_clean(soc);
    return 0;
}

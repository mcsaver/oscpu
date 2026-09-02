#ifndef __NEMU_CONFIG_H__
#define __NEMU_CONFIG_H__

/*
 * NEMU 内部编译期策略。
 *
 * 顶层 Kconfig 只保留会改变 guest 可观察能力、平台或构建产物的选项；
 * 只有一个合法取值、或只是实现内部条件的开关集中在这里，避免把实现细节
 * 伪装成用户可配置能力。
 */
#define NEMU_ENGINE_NAME "interpreter"
#define NEMU_SYSTEM_MODE 1

/*
 * RV64 解释器始终编译一份纯译码元数据 cache；是否使用它只由运行时总开关
 * NEMU_INTERPRETER_DECODE_CACHE=0 控制。cache 的存在不会改变 guest 能力，
 * 因而不应成为 Kconfig 能力选项，也不再拆分出第二套执行器专用 fast 开关。
 */
#ifdef CONFIG_RV64
#define NEMU_RV64_DECODE_CACHE 1
#else
#define NEMU_RV64_DECODE_CACHE 0
#endif
#define NEMU_RV64_DECODE_CACHE_ENTRIES 32768

/* 端口 I/O 是 x86 平台派生能力，不是第二个需要用户同步维护的配置项。 */
#ifdef CONFIG_ISA_x86
#define NEMU_HAS_PORT_IO 1
#endif

/* trace 的范围统一由 CONFIG_TRACE_START/CONFIG_TRACE_END 控制。 */
#define NEMU_ITRACE_COND 1
#define NEMU_DTRACE_COND 1

#endif

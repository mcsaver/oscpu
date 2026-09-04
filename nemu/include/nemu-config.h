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
 * SOC_SIM 选择一套完整的平台合同，不是 generic IOMap 的分派优先级。
 * Kconfig 会消解下列非法组合；这里的保护还覆盖手写 autoconf.h、
 * 陈旧构建输出或绕过 Kconfig 的嵌入式构建。
 */
#if defined(CONFIG_SOC_SIM) && defined(CONFIG_DEVICE_MAP_LEGACY)
#error "SOC_SIM owns the ysyxSoC address space; the legacy AM device map is incompatible"
#endif

#if defined(CONFIG_SOC_SIM) && \
    (!defined(CONFIG_ISA_riscv) || defined(CONFIG_RV64))
#error "SOC_SIM is the RV32 ysyxSoC platform profile"
#endif

#if defined(CONFIG_SOC_SIM) && defined(CONFIG_TARGET_AM)
#error "SOC_SIM requires a native simulator or DiffTest reference host, not TARGET_AM"
#endif

#if defined(CONFIG_SOC_SIM) && \
    (defined(CONFIG_HAS_SERIAL) || defined(CONFIG_HAS_TIMER) || \
     defined(CONFIG_HAS_KEYBOARD) || defined(CONFIG_HAS_VGA) || \
     defined(CONFIG_HAS_AUDIO) || defined(CONFIG_HAS_DISK) || \
     defined(CONFIG_HAS_VIRTIO_RNG) || defined(CONFIG_HAS_VIRTIO_NET) || \
     defined(CONFIG_HAS_VIRTIO_INPUT) || \
     defined(CONFIG_HAS_GOLDFISH_RTC) || defined(CONFIG_HAS_SDCARD))
#error "SOC_SIM owns its machine topology; generic device and PLIC-backed providers must be disabled"
#endif

#ifdef CONFIG_SOC_SIM
#include <platform/ysyxsoc-map.h>
#if CONFIG_MBASE != YSYXSOC_PSRAM_BASE || \
    CONFIG_MSIZE != YSYXSOC_PSRAM_SIZE
#error "SOC_SIM primary memory must exactly back the ysyxSoC PSRAM region"
#endif
#endif

/* SDL 只服务 native generic 图形/输入/音频 provider，纯 service extension 不引入它。 */
#if !defined(CONFIG_TARGET_AM) && \
    (defined(CONFIG_HAS_KEYBOARD) || defined(CONFIG_HAS_VGA) || \
     defined(CONFIG_HAS_AUDIO) || defined(CONFIG_HAS_VIRTIO_INPUT))
#define NEMU_HAS_SDL 1
#endif

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

/*
 * 下面这些量只选择宿主实现方式，不改变 guest ISA、设备集合或 ABI，因而
 * 由一处 policy header 总控，不再占用 Kconfig 用户界面。
 */
#ifdef CONFIG_PERFORMANCE
#define NEMU_DEVICE_UPDATE_CHECK_INTERVAL 512u
#else
#define NEMU_DEVICE_UPDATE_CHECK_INTERVAL 64u
#define NEMU_RUNTIME_CHECKS 1
#endif

/* NEMU native host time 始终取单调时钟，避免 wall clock 回拨。 */
#define NEMU_HOST_TIMER_USES_MONOTONIC_CLOCK 1

/* threaded virtio-blk 后端始终以 pending flag 避免空队列加锁。 */
#define NEMU_VIRTIO_BLK_ASYNC_COMPLETION_FAST_FLAG 1

/* 端口 I/O 是 x86 平台派生能力，不是第二个需要用户同步维护的配置项。 */
#ifdef CONFIG_ISA_x86
#define NEMU_HAS_PORT_IO 1
#endif

/* trace 的范围统一由 CONFIG_TRACE_START/CONFIG_TRACE_END 控制。 */
#define NEMU_ITRACE_COND 1
#define NEMU_DTRACE_COND 1

#endif

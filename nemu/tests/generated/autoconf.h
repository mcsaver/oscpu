/*
 * 仅用于单元测试的配置垫片。测试编译时把 nemu/tests 放在 nemu/include
 * 之前，避免 cache_unit.c 依赖当前工作区 .config。
 */
#define CONFIG_CACHE 1
#define CONFIG_ICACHE_SIZE 128
#define CONFIG_DCACHE_SIZE 128
#define CONFIG_CACHE_LINE_SIZE 64
#define CONFIG_MBASE 0x0
#define CONFIG_MSIZE 0x100
#define CONFIG_BPU 1
#define CONFIG_BPU_BTB_ENTRIES 4
#define CONFIG_BPU_BHT_ENTRIES 8
#define CONFIG_BPU_RAS_ENTRIES 2
#define CONFIG_BPU_COUNTER_BITS 2
#define CONFIG_BPU_COUNTER_INIT 1
#define CONFIG_BPU_GHR_BITS 0

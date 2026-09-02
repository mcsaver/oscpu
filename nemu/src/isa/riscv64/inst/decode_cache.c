/*
 * RV64 预译码缓存。
 *
 * 该文件只保存 raw instruction 对应的 RvDecodedInstruction。它不能读取或
 * 修改 GPR、CSR、PC、memory，也不能决定任何依赖当前特权级的合法性。
 * cache hit 与 miss 最终都进入 execute.c 中唯一的体系结构语义。
 */

#include <utils/profile.h>

#if NEMU_RV64_DECODE_CACHE
#define RV_DECODE_CACHE_ENTRIES NEMU_RV64_DECODE_CACHE_ENTRIES

#if (RV_DECODE_CACHE_ENTRIES & (RV_DECODE_CACHE_ENTRIES - 1)) != 0
#error "NEMU_RV64_DECODE_CACHE_ENTRIES must be a power of two"
#endif

typedef struct {
  bool valid;
  vaddr_t pc;
  uint32_t encoding;
  RvDecodedInstruction instruction;
} RvDecodeCacheEntry;

static RvDecodeCacheEntry rv_decode_cache[RV_DECODE_CACHE_ENTRIES];

static inline uint32_t rv_decode_cache_index(vaddr_t pc) {
  return (pc >> 1) & (RV_DECODE_CACHE_ENTRIES - 1);
}

static inline uint32_t rv_instruction_encoding_key(uint32_t encoding) {
#ifdef CONFIG_RISCV_EXT_C
  return (encoding & 0x3u) == 0x3u ? encoding : (encoding & 0xffffu);
#else
  return encoding;
#endif
}

static inline bool rv_decode_cache_lookup(vaddr_t pc, uint32_t encoding,
                                          RvDecodedInstruction *instruction) {
  if (unlikely(!isa_riscv64_decode_cache_runtime_enabled())) return false;

  bool profile = nemu_profile_decode_cache_enabled();
  if (profile) {
    nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_LOOKUPS, 1);
  }

  const uint32_t encoding_key = rv_instruction_encoding_key(encoding);
  const RvDecodeCacheEntry *entry =
      &rv_decode_cache[rv_decode_cache_index(pc)];
  if (!entry->valid || entry->pc != pc || entry->encoding != encoding_key) {
    if (profile) {
      nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_MISSES, 1);
    }
    return false;
  }

  if (profile) {
    nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_HITS, 1);
    if (entry->instruction.length == 2) {
      nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_HIT_RVC, 1);
    }
  }
  *instruction = entry->instruction;
  return true;
}

static inline void rv_decode_cache_insert(
    vaddr_t pc, const RvDecodedInstruction *instruction) {
  if (unlikely(!isa_riscv64_decode_cache_runtime_enabled())) return;
  if (instruction->operation == RV_OPERATION_ILLEGAL_INSTRUCTION) return;

  if (nemu_profile_decode_cache_enabled()) {
    nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_FILLS, 1);
    if (instruction->length == 2) {
      nemu_profile_count(NEMU_PROFILE_CPU_DECODE_CACHE_FILL_RVC, 1);
    }
  }

  rv_decode_cache[rv_decode_cache_index(pc)] = (RvDecodeCacheEntry) {
    .valid = true,
    .pc = pc,
    .encoding = rv_instruction_encoding_key(instruction->encoding),
    .instruction = *instruction,
  };
}

static inline void rv_decode_cache_flush(void) {
  memset(rv_decode_cache, 0, sizeof(rv_decode_cache));
}
#else
static inline bool rv_decode_cache_lookup(vaddr_t pc, uint32_t encoding,
                                          RvDecodedInstruction *instruction) {
  (void)pc;
  (void)encoding;
  (void)instruction;
  return false;
}

static inline void rv_decode_cache_insert(
    vaddr_t pc, const RvDecodedInstruction *instruction) {
  (void)pc;
  (void)instruction;
}

static inline void rv_decode_cache_flush(void) {
}
#endif

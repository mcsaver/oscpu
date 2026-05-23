#ifndef NPC_SINGLE_CSRC_MEMORY_CACHE_H_
#define NPC_SINGLE_CSRC_MEMORY_CACHE_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint64_t icache_access;
  uint64_t icache_hit;
  uint64_t icache_miss;
  uint64_t dcache_access;
  uint64_t dcache_hit;
  uint64_t dcache_miss;
  uint64_t dcache_writeback;
} NpcCacheStats;

void npc_cache_init(void);
bool npc_icache_read(uint32_t addr, uint32_t *data);
bool npc_dcache_read(uint32_t addr, uint32_t *data);
bool npc_dcache_write(uint32_t addr, uint32_t data, uint32_t mask);
void npc_cache_flush_all(void);
void npc_cache_report(void);
const NpcCacheStats *npc_cache_stats(void);

#ifdef __cplusplus
}
#endif

#endif

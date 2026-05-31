#include "memory/cache.h"

#include "memory/paddr.h"
#include "monitor/log.h"
#include "utils.h"

#include <inttypes.h>
#include <string.h>

#define NPC_CACHE_LINE_SIZE 64u
#define NPC_ICACHE_SIZE     4096u
#define NPC_DCACHE_SIZE     4096u
#define NPC_ICACHE_LINES    (NPC_ICACHE_SIZE / NPC_CACHE_LINE_SIZE)
#define NPC_DCACHE_LINES    (NPC_DCACHE_SIZE / NPC_CACHE_LINE_SIZE)

typedef struct {
  bool valid;
  uint32_t tag;
  uint8_t data[NPC_CACHE_LINE_SIZE];
} NpcICacheLine;

typedef struct {
  bool valid;
  bool dirty;
  uint32_t tag;
  uint8_t data[NPC_CACHE_LINE_SIZE];
} NpcDCacheLine;

static NpcICacheLine icache[NPC_ICACHE_LINES];
static NpcDCacheLine dcache[NPC_DCACHE_LINES];
static NpcCacheStats stats;

static uint32_t line_base(uint32_t addr) {
  return addr & ~(NPC_CACHE_LINE_SIZE - 1u);
}

static uint32_t line_offset(uint32_t addr) {
  return addr & (NPC_CACHE_LINE_SIZE - 1u);
}

static bool cacheable_range(uint32_t addr, uint32_t len) {
  if (len == 0) return false;
  uint64_t end = (uint64_t)addr + len - 1u;
  if (end > UINT32_MAX) return false;
  return npc_in_pmem(addr) && npc_in_pmem((uint32_t)end);
}

static void store_word_bytes(uint8_t *dst, uint32_t data) {
  dst[0] = (uint8_t)data;
  dst[1] = (uint8_t)(data >> 8);
  dst[2] = (uint8_t)(data >> 16);
  dst[3] = (uint8_t)(data >> 24);
}

static uint32_t load_word_bytes(const uint8_t *src) {
  return (uint32_t)src[0] |
         ((uint32_t)src[1] << 8) |
         ((uint32_t)src[2] << 16) |
         ((uint32_t)src[3] << 24);
}

static bool fill_icache_line(NpcICacheLine *line, uint32_t base) {
  for (uint32_t off = 0; off < NPC_CACHE_LINE_SIZE; off += 4) {
    npc_word_t word = 0;
    if (!npc_paddr_read((npc_paddr_t)base + off, &word, NPC_BUS_IFETCH)) return false;
    store_word_bytes(&line->data[off], (uint32_t)word);
  }
  line->valid = true;
  line->tag = (base / NPC_CACHE_LINE_SIZE) / NPC_ICACHE_LINES;
  return true;
}

static bool writeback_dcache_line(uint32_t index) {
  NpcDCacheLine *line = &dcache[index];
  if (!line->valid || !line->dirty) return true;

  uint64_t block = (uint64_t)line->tag * NPC_DCACHE_LINES + index;
  uint32_t base = (uint32_t)(block * NPC_CACHE_LINE_SIZE);
  for (uint32_t off = 0; off < NPC_CACHE_LINE_SIZE; off += 4) {
    uint32_t word = load_word_bytes(&line->data[off]);
    if (!npc_paddr_write((npc_paddr_t)base + off, word, 0xfu, NPC_BUS_STORE)) return false;
  }
  line->dirty = false;
  stats.dcache_writeback++;
  return true;
}

static bool fill_dcache_line(NpcDCacheLine *line, uint32_t base) {
  for (uint32_t off = 0; off < NPC_CACHE_LINE_SIZE; off += 4) {
    npc_word_t word = 0;
    if (!npc_paddr_read((npc_paddr_t)base + off, &word, NPC_BUS_LOAD)) return false;
    store_word_bytes(&line->data[off], (uint32_t)word);
  }
  line->valid = true;
  line->dirty = false;
  line->tag = (base / NPC_CACHE_LINE_SIZE) / NPC_DCACHE_LINES;
  return true;
}

static NpcICacheLine *get_icache_line(uint32_t addr, bool *hit) {
  uint32_t block = addr / NPC_CACHE_LINE_SIZE;
  uint32_t index = block % NPC_ICACHE_LINES;
  uint32_t tag = block / NPC_ICACHE_LINES;
  NpcICacheLine *line = &icache[index];
  *hit = line->valid && line->tag == tag;
  if (!*hit && !fill_icache_line(line, line_base(addr))) return NULL;
  return line;
}

static NpcDCacheLine *get_dcache_line(uint32_t addr, bool *hit) {
  uint32_t block = addr / NPC_CACHE_LINE_SIZE;
  uint32_t index = block % NPC_DCACHE_LINES;
  uint32_t tag = block / NPC_DCACHE_LINES;
  NpcDCacheLine *line = &dcache[index];
  *hit = line->valid && line->tag == tag;
  if (!*hit) {
    if (!writeback_dcache_line(index)) return NULL;
    if (!fill_dcache_line(line, line_base(addr))) return NULL;
  }
  return line;
}

void npc_cache_init(void) {
  memset(icache, 0, sizeof(icache));
  memset(dcache, 0, sizeof(dcache));
  memset(&stats, 0, sizeof(stats));
}

bool npc_icache_read(uint32_t addr, uint32_t *data) {
  if (!data) return false;
  if (!cacheable_range(addr, 4)) {
    npc_word_t word = 0;
    bool ok = npc_paddr_read(addr, &word, NPC_BUS_IFETCH);
    *data = (uint32_t)word;
    return ok;
  }

  stats.icache_access++;
  bool missed = false;
  uint32_t value = 0;
  for (uint32_t lane = 0; lane < 4; lane++) {
    bool hit = false;
    NpcICacheLine *line = get_icache_line(addr + lane, &hit);
    if (!line) return false;
    missed |= !hit;
    value |= (uint32_t)line->data[line_offset(addr + lane)] << (lane * 8);
  }
  if (missed) stats.icache_miss++;
  else stats.icache_hit++;
  *data = value;
  return true;
}

bool npc_dcache_read(uint32_t addr, uint32_t *data) {
  if (!data) return false;
  if (!cacheable_range(addr, 4)) {
    npc_word_t word = 0;
    bool ok = npc_paddr_read(addr, &word, NPC_BUS_LOAD);
    *data = (uint32_t)word;
    return ok;
  }

  stats.dcache_access++;
  bool missed = false;
  uint32_t value = 0;
  for (uint32_t lane = 0; lane < 4; lane++) {
    bool hit = false;
    NpcDCacheLine *line = get_dcache_line(addr + lane, &hit);
    if (!line) return false;
    missed |= !hit;
    value |= (uint32_t)line->data[line_offset(addr + lane)] << (lane * 8);
  }
  if (missed) stats.dcache_miss++;
  else stats.dcache_hit++;
  *data = value;
  return true;
}

bool npc_dcache_write(uint32_t addr, uint32_t data, uint32_t mask) {
  mask &= 0xfu;
  if (mask == 0) return true;
  if (!cacheable_range(addr, 4)) return npc_paddr_write(addr, data, mask, NPC_BUS_STORE);

  stats.dcache_access++;
  bool missed = false;
  for (uint32_t lane = 0; lane < 4; lane++) {
    if ((mask & (1u << lane)) == 0) continue;
    bool hit = false;
    NpcDCacheLine *line = get_dcache_line(addr + lane, &hit);
    if (!line) return false;
    missed |= !hit;
    line->data[line_offset(addr + lane)] = (uint8_t)(data >> (lane * 8));
    line->dirty = true;
  }
  if (missed) stats.dcache_miss++;
  else stats.dcache_hit++;
  return true;
}

void npc_cache_flush_all(void) {
  for (uint32_t i = 0; i < NPC_DCACHE_LINES; i++) {
    (void)writeback_dcache_line(i);
  }
  memset(icache, 0, sizeof(icache));
  memset(dcache, 0, sizeof(dcache));
}

void npc_cache_report(void) {
  npc_cache_flush_all();
  LogBothTag("statistic", "icache: access=%" PRIu64 ", hit=%" PRIu64 ", miss=%" PRIu64,
             stats.icache_access, stats.icache_hit, stats.icache_miss);
  LogBothTag("statistic", "dcache: access=%" PRIu64 ", hit=%" PRIu64 ", miss=%" PRIu64,
             stats.dcache_access, stats.dcache_hit, stats.dcache_miss);
  LogBothTag("statistic", "dcache writeback = %" PRIu64, stats.dcache_writeback);
}

const NpcCacheStats *npc_cache_stats(void) {
  return &stats;
}

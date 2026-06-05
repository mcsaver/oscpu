/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/cache.h>
#include <memory/paddr.h>
#include <stdio.h>

#ifdef CONFIG_CACHE

#define CACHE_LINE_SIZE CONFIG_CACHE_LINE_SIZE
#define ICACHE_LINE_NR (CONFIG_ICACHE_SIZE / CONFIG_CACHE_LINE_SIZE)
#define DCACHE_LINE_NR (CONFIG_DCACHE_SIZE / CONFIG_CACHE_LINE_SIZE)

typedef struct {
  bool valid;
  paddr_t tag;
  uint8_t data[CACHE_LINE_SIZE];
} ICacheLine;

typedef struct {
  bool valid;
  bool dirty;
  paddr_t tag;
  uint8_t data[CACHE_LINE_SIZE];
} DCacheLine;

static ICacheLine icache[ICACHE_LINE_NR];
static DCacheLine dcache[DCACHE_LINE_NR];
static CacheStats cache_stats;

static cache_test_read_t backend_read = paddr_read;
static cache_test_write_t backend_write = paddr_write;
static paddr_t cache_pmem_left = PMEM_LEFT;
static paddr_t cache_pmem_right = PMEM_RIGHT;

#ifdef CONFIG_CACHE_STATISTIC
#define CACHE_STAT_INC(field) do { cache_stats.field++; } while (0)
#else
#define CACHE_STAT_INC(field) do {} while (0)
#endif

static inline bool is_power_of_two(uint32_t x) {
  return x != 0 && (x & (x - 1)) == 0;
}

static inline paddr_t line_base_of(paddr_t addr) {
  return addr & ~(paddr_t)(CACHE_LINE_SIZE - 1);
}

static inline uint32_t line_offset_of(paddr_t addr) {
  return addr & (CACHE_LINE_SIZE - 1);
}

static bool cacheable_range(paddr_t addr, int len) {
  if (len <= 0) return false;
  paddr_t end = addr + len - 1;
  if (end < addr) return false;
  if (addr < cache_pmem_left || end > cache_pmem_right) return false;

  for (paddr_t base = line_base_of(addr); base <= line_base_of(end); base += CACHE_LINE_SIZE) {
    paddr_t line_end = base + CACHE_LINE_SIZE - 1;
    if (line_end < base || base < cache_pmem_left || line_end > cache_pmem_right) {
      return false;
    }
  }
  return true;
}

static void reset_cache_state(void) {
  memset(icache, 0, sizeof(icache));
  memset(dcache, 0, sizeof(dcache));
  memset(&cache_stats, 0, sizeof(cache_stats));
}

static void check_cache_config(void) {
  assert(is_power_of_two(CONFIG_CACHE_LINE_SIZE));
  assert(is_power_of_two(CONFIG_ICACHE_SIZE));
  assert(is_power_of_two(CONFIG_DCACHE_SIZE));
  assert(CONFIG_ICACHE_SIZE >= CONFIG_CACHE_LINE_SIZE);
  assert(CONFIG_DCACHE_SIZE >= CONFIG_CACHE_LINE_SIZE);
  assert(CONFIG_ICACHE_SIZE % CONFIG_CACHE_LINE_SIZE == 0);
  assert(CONFIG_DCACHE_SIZE % CONFIG_CACHE_LINE_SIZE == 0);
}

static void fill_icache_line(ICacheLine *line, paddr_t base) {
  line->valid = true;
  line->tag = base / CACHE_LINE_SIZE;
  for (uint32_t i = 0; i < CACHE_LINE_SIZE; i++) {
    line->data[i] = backend_read(base + i, 1);
  }
}

static void writeback_dcache_line(DCacheLine *line, uint32_t index) {
  if (!line->valid || !line->dirty) return;

  paddr_t base = ((line->tag * DCACHE_LINE_NR) + index) * CACHE_LINE_SIZE;
  for (uint32_t i = 0; i < CACHE_LINE_SIZE; i++) {
    backend_write(base + i, 1, line->data[i]);
  }
  line->dirty = false;
  CACHE_STAT_INC(dcache_writeback);
}

static void fill_dcache_line(DCacheLine *line, paddr_t base) {
  line->valid = true;
  line->dirty = false;
  line->tag = (base / CACHE_LINE_SIZE) / DCACHE_LINE_NR;
  for (uint32_t i = 0; i < CACHE_LINE_SIZE; i++) {
    line->data[i] = backend_read(base + i, 1);
  }
}

static ICacheLine *get_icache_line(paddr_t addr, bool *hit) {
  paddr_t block = addr / CACHE_LINE_SIZE;
  uint32_t index = block % ICACHE_LINE_NR;
  paddr_t tag = block / ICACHE_LINE_NR;
  ICacheLine *line = &icache[index];

  *hit = line->valid && line->tag == tag;
  if (!*hit) {
    fill_icache_line(line, line_base_of(addr));
    line->tag = tag;
  }
  return line;
}

static DCacheLine *get_dcache_line(paddr_t addr, bool *hit) {
  paddr_t block = addr / CACHE_LINE_SIZE;
  uint32_t index = block % DCACHE_LINE_NR;
  paddr_t tag = block / DCACHE_LINE_NR;
  DCacheLine *line = &dcache[index];

  *hit = line->valid && line->tag == tag;
  if (!*hit) {
    writeback_dcache_line(line, index);
    fill_dcache_line(line, line_base_of(addr));
  }
  return line;
}

static word_t uncached_read(paddr_t addr, int len) {
  return backend_read(addr, len);
}

static void uncached_write(paddr_t addr, int len, word_t data) {
  backend_write(addr, len, data);
}

void init_cache(void) {
  check_cache_config();
  backend_read = paddr_read;
  backend_write = paddr_write;
  cache_pmem_left = PMEM_LEFT;
  cache_pmem_right = PMEM_RIGHT;
  reset_cache_state();
}

void cache_init_for_test(cache_test_read_t read_cb, cache_test_write_t write_cb,
    paddr_t pmem_left, paddr_t pmem_right) {
  check_cache_config();
  backend_read = read_cb;
  backend_write = write_cb;
  cache_pmem_left = pmem_left;
  cache_pmem_right = pmem_right;
  reset_cache_state();
}

word_t icache_read(paddr_t addr, int len) {
  if (!cacheable_range(addr, len)) {
    return uncached_read(addr, len);
  }

  CACHE_STAT_INC(icache_access);
  word_t ret = 0;
  bool missed = false;
  for (int i = 0; i < len; i++) {
    bool hit = false;
    ICacheLine *line = get_icache_line(addr + i, &hit);
    missed |= !hit;
    ret |= (word_t)line->data[line_offset_of(addr + i)] << (i * 8);
  }
  if (missed) CACHE_STAT_INC(icache_miss);
  else CACHE_STAT_INC(icache_hit);
  return ret;
}

word_t dcache_read(paddr_t addr, int len) {
  if (!cacheable_range(addr, len)) {
    return uncached_read(addr, len);
  }

  CACHE_STAT_INC(dcache_access);
  word_t ret = 0;
  bool missed = false;
  for (int i = 0; i < len; i++) {
    bool hit = false;
    DCacheLine *line = get_dcache_line(addr + i, &hit);
    missed |= !hit;
    ret |= (word_t)line->data[line_offset_of(addr + i)] << (i * 8);
  }
  if (missed) CACHE_STAT_INC(dcache_miss);
  else CACHE_STAT_INC(dcache_hit);
  return ret;
}

void dcache_write(paddr_t addr, int len, word_t data) {
  if (!cacheable_range(addr, len)) {
    uncached_write(addr, len, data);
    return;
  }

  CACHE_STAT_INC(dcache_access);
  bool missed = false;
  for (int i = 0; i < len; i++) {
    bool hit = false;
    DCacheLine *line = get_dcache_line(addr + i, &hit);
    missed |= !hit;
    line->data[line_offset_of(addr + i)] = (data >> (i * 8)) & 0xffu;
    line->dirty = true;
  }
  if (missed) CACHE_STAT_INC(dcache_miss);
  else CACHE_STAT_INC(dcache_hit);
}

void cache_flush_all(void) {
  for (uint32_t i = 0; i < DCACHE_LINE_NR; i++) {
    writeback_dcache_line(&dcache[i], i);
  }
  memset(icache, 0, sizeof(icache));
  memset(dcache, 0, sizeof(dcache));
}

const CacheStats *cache_get_stats(void) {
  return &cache_stats;
}

#ifdef CONFIG_CACHE_STATISTIC
static uint64_t hit_rate_x100(uint64_t hit, uint64_t access) {
  return access == 0 ? 0 : hit * 10000 / access;
}

static void print_cache_line(const char *name, uint64_t access, uint64_t hit, uint64_t miss) {
  uint64_t rate = hit_rate_x100(hit, access);
  Log("%s access = %" PRIu64 ", hit = %" PRIu64 ", miss = %" PRIu64
      ", hit rate = %" PRIu64 ".%02" PRIu64 "%%",
      name, access, hit, miss, rate / 100, rate % 100);
}
#endif

void cache_statistic(void) {
  cache_flush_all();
#ifdef CONFIG_CACHE_STATISTIC
  print_cache_line("icache", cache_stats.icache_access,
      cache_stats.icache_hit, cache_stats.icache_miss);
  print_cache_line("dcache", cache_stats.dcache_access,
      cache_stats.dcache_hit, cache_stats.dcache_miss);
  Log("dcache writeback = %" PRIu64, cache_stats.dcache_writeback);
#endif
}

#else

static CacheStats cache_stats;

void init_cache(void) {}

word_t icache_read(paddr_t addr, int len) {
  return paddr_read(addr, len);
}

word_t dcache_read(paddr_t addr, int len) {
  return paddr_read(addr, len);
}

void dcache_write(paddr_t addr, int len, word_t data) {
  paddr_write(addr, len, data);
}

void cache_flush_all(void) {}

void cache_statistic(void) {}

const CacheStats *cache_get_stats(void) {
  return &cache_stats;
}

void cache_init_for_test(cache_test_read_t read_cb, cache_test_write_t write_cb,
    paddr_t pmem_left, paddr_t pmem_right) {
  (void)read_cb;
  (void)write_cb;
  (void)pmem_left;
  (void)pmem_right;
}

#endif

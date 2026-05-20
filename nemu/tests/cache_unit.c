#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <memory/cache.h>

static uint8_t backend[256];
static uint64_t backend_reads;
static uint64_t backend_writes;

word_t paddr_read(paddr_t addr, int len) {
  (void)addr;
  (void)len;
  assert(0);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  (void)addr;
  (void)len;
  (void)data;
  assert(0);
}

static word_t test_read(paddr_t addr, int len) {
  backend_reads++;
  word_t ret = 0;
  memcpy(&ret, backend + addr, len);
  return ret;
}

static void test_write(paddr_t addr, int len, word_t data) {
  backend_writes++;
  memcpy(backend + addr, &data, len);
}

static void reset_backend(void) {
  for (int i = 0; i < (int)sizeof(backend); i++) {
    backend[i] = (uint8_t)i;
  }
  backend_reads = 0;
  backend_writes = 0;
  cache_init_for_test(test_read, test_write, 0, sizeof(backend) - 1);
}

static void test_icache_hits_after_first_fill(void) {
  reset_backend();
  assert(icache_read(4, 4) == 0x07060504u);
  uint64_t reads_after_fill = backend_reads;
  assert(icache_read(8, 4) == 0x0b0a0908u);
  assert(backend_reads == reads_after_fill);

  const CacheStats *stats = cache_get_stats();
  assert(stats->icache_access == 2);
  assert(stats->icache_miss == 1);
  assert(stats->icache_hit == 1);
}

static void test_dcache_write_hit_reads_new_value(void) {
  reset_backend();
  dcache_write(16, 4, 0xaabbccddu);
  assert(dcache_read(16, 4) == 0xaabbccddu);
  assert(memcmp(backend + 16, "\x10\x11\x12\x13", 4) == 0);

  const CacheStats *stats = cache_get_stats();
  assert(stats->dcache_access == 2);
  assert(stats->dcache_hit >= 1);
}

static void test_dcache_dirty_line_writes_back_on_replacement(void) {
  reset_backend();
  dcache_write(0, 4, 0x11223344u);
  assert(backend_writes == 0);
  dcache_read(128, 4);
  assert(backend_writes == 64);
  assert(backend[0] == 0x44);
  assert(backend[1] == 0x33);
  assert(backend[2] == 0x22);
  assert(backend[3] == 0x11);

  const CacheStats *stats = cache_get_stats();
  assert(stats->dcache_writeback == 1);
}

static void test_cross_line_access(void) {
  reset_backend();
  dcache_write(62, 4, 0x55667788u);
  assert(dcache_read(62, 4) == 0x55667788u);
}

int main(void) {
  test_icache_hits_after_first_fill();
  test_dcache_write_hit_reads_new_value();
  test_dcache_dirty_line_writes_back_on_replacement();
  test_cross_line_access();
  puts("cache_unit PASS");
  return 0;
}

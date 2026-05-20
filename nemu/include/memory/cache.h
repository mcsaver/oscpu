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

#ifndef __MEMORY_CACHE_H__
#define __MEMORY_CACHE_H__

#include <common.h>

typedef struct {
  uint64_t icache_access;
  uint64_t icache_hit;
  uint64_t icache_miss;
  uint64_t dcache_access;
  uint64_t dcache_hit;
  uint64_t dcache_miss;
  uint64_t dcache_writeback;
} CacheStats;

void init_cache(void);
word_t icache_read(paddr_t addr, int len);
word_t dcache_read(paddr_t addr, int len);
void dcache_write(paddr_t addr, int len, word_t data);
void cache_flush_all(void);
void cache_statistic(void);
const CacheStats *cache_get_stats(void);

typedef word_t (*cache_test_read_t)(paddr_t addr, int len);
typedef void (*cache_test_write_t)(paddr_t addr, int len, word_t data);
void cache_init_for_test(cache_test_read_t read_cb, cache_test_write_t write_cb,
    paddr_t pmem_left, paddr_t pmem_right);

#endif

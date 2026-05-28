#include "trap.h"

#include <stdint.h>

static inline void mem_sb(volatile void *addr, uint32_t data) {
  asm volatile("sb %1, 0(%0)" :: "r"(addr), "r"(data) : "memory");
}

static inline void mem_sh(volatile void *addr, uint32_t data) {
  asm volatile("sh %1, 0(%0)" :: "r"(addr), "r"(data) : "memory");
}

static inline void mem_sw(volatile void *addr, uint32_t data) {
  asm volatile("sw %1, 0(%0)" :: "r"(addr), "r"(data) : "memory");
}

static inline int32_t mem_lb(volatile const void *addr) {
  int32_t data;
  asm volatile("lb %0, 0(%1)" : "=r"(data) : "r"(addr) : "memory");
  return data;
}

static inline uint32_t mem_lbu(volatile const void *addr) {
  uint32_t data;
  asm volatile("lbu %0, 0(%1)" : "=r"(data) : "r"(addr) : "memory");
  return data;
}

static inline int32_t mem_lh(volatile const void *addr) {
  int32_t data;
  asm volatile("lh %0, 0(%1)" : "=r"(data) : "r"(addr) : "memory");
  return data;
}

static inline uint32_t mem_lhu(volatile const void *addr) {
  uint32_t data;
  asm volatile("lhu %0, 0(%1)" : "=r"(data) : "r"(addr) : "memory");
  return data;
}

static inline uint32_t mem_lw(volatile const void *addr) {
  uint32_t data;
  asm volatile("lw %0, 0(%1)" : "=r"(data) : "r"(addr) : "memory");
  return data;
}

static uint32_t pattern(uint32_t idx) {
  return 0x13579bdfu ^ (idx * 0x1020304u);
}

static void check_id(bool cond, int code) {
  if (!cond) halt(code);
}

int main() {
  // 使用栈上缓冲区而不是全局数组，避免 ysyxSoC MROM 上的只读全局数据影响测试。
  volatile uint32_t scratch[16];
  volatile unsigned char *bytes = (volatile unsigned char *)scratch;
  volatile uint32_t *cacheable = (volatile uint32_t *)0x80000000u;
  volatile uint32_t *cache_alias = (volatile uint32_t *)0x80001000u;
  volatile unsigned char *cache_bytes = (volatile unsigned char *)cacheable;

  // 用显式访存指令覆盖 word 写读，确保运行期真的访问 SRAM。
  for (uint32_t i = 0; i < LENGTH(scratch); i++) {
    mem_sw(&scratch[i], pattern(i));
  }

  for (uint32_t i = 0; i < LENGTH(scratch); i++) {
    check(mem_lw(&scratch[i]) == pattern(i));
  }

  mem_sw(&scratch[0], 0x11223344u);
  check(mem_lw(&scratch[0]) == 0x11223344u);

  mem_sb(bytes + 0, 0x80u);
  check(mem_lbu(bytes + 0) == 0x80u);
  check(mem_lb(bytes + 0) == -128);
  check(mem_lw(&scratch[0]) == 0x11223380u);

  mem_sb(bytes + 3, 0x7eu);
  check(mem_lbu(bytes + 3) == 0x7eu);
  check(mem_lb(bytes + 3) == 0x7e);
  check(mem_lw(&scratch[0]) == 0x7e223380u);

  mem_sw(&scratch[1], 0xa5a55a5au);
  mem_sh(bytes + 4, 0x8001u);
  check(mem_lhu(bytes + 4) == 0x8001u);
  check(mem_lh(bytes + 4) == -32767);
  check(mem_lw(&scratch[1]) == 0xa5a58001u);

  mem_sh(bytes + 6, 0x1234u);
  check(mem_lhu(bytes + 6) == 0x1234u);
  check(mem_lh(bytes + 6) == 0x1234);
  check(mem_lw(&scratch[1]) == 0x12348001u);

  // 0x80000000 落在 CACHEABLE_BASE/LAST 内，专门覆盖 DCache miss/hit/dirty writeback。
  mem_sw(&cacheable[0], 0x55667788u);
  check_id(mem_lw(&cacheable[0]) == 0x55667788u, 101);

  mem_sb(cache_bytes + 1, 0xaau);
  check_id(mem_lbu(cache_bytes + 1) == 0xaau, 102);
  check_id(mem_lb(cache_bytes + 1) == -86, 103);
  check_id(mem_lw(&cacheable[0]) == 0x5566aa88u, 104);

  mem_sw(&cacheable[1], 0x01020304u);
  check_id(mem_lw(&cacheable[1]) == 0x01020304u, 105);

  // 4KB direct-mapped DCache 下相差 0x1000 会落到同 index 不同 tag，用于触发 dirty victim。
  mem_sw(&cache_alias[0], 0xcafebabeu);
  check_id(mem_lw(&cache_alias[0]) == 0xcafebabeu, 106);
  check_id(mem_lw(&cacheable[0]) == 0x5566aa88u, 107);
  check_id(mem_lw(&cacheable[1]) == 0x01020304u, 108);

  return 0;
}

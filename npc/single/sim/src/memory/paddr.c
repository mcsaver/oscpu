/* NPC 物理地址空间 — C 重构版
 * std::vector<uint8_t> 改为 malloc + 手动管理 */
#include "memory/paddr.h"

#include "cpu/difftest.h"
#include "device/map.h"
#include "memory/cache.h"
#include "monitor/log.h"
#include "monitor/trace.h"
#include "utils.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint8_t *g_pmem = NULL;
static size_t   g_pmem_size = 0;
static size_t   g_img_size = 0;

static uint32_t host_read_u32(const uint8_t *base) {
  return (uint32_t)base[0]
       | ((uint32_t)base[1] << 8)
       | ((uint32_t)base[2] << 16)
       | ((uint32_t)base[3] << 24);
}

static void host_write_masked(uint8_t *base, uint32_t data, uint32_t mask) {
  for (int lane = 0; lane < 4; ++lane) {
    if ((mask & (1u << lane)) != 0) {
      base[lane] = (uint8_t)(data >> (lane * 8));
    }
  }
}

static const char *access_kind_name(enum NpcBusAccess kind) {
  switch (kind) {
    case NPC_BUS_IFETCH: return "fetch";
    case NPC_BUS_LOAD:   return "load";
    case NPC_BUS_STORE:  return "store";
    default:             return "access";
  }
}

void npc_init_mem(void) {
  if (g_pmem) { free(g_pmem); }
  g_pmem_size = (size_t)NPC_PMEM_SIZE;
  g_img_size = 0;
  /* 用 calloc 代替 malloc + memset：
   * 1. 少一次显式 memset 128MB
   * 2. 大块 calloc 在 Linux 上通常由内核零页映射实现，不会真正触碰物理页 */
  g_pmem = (uint8_t *)calloc(1, g_pmem_size);
  if (!g_pmem) { perror("[npc] calloc pmem"); abort(); }
  npc_cache_init();
  LogBoth("physical memory area [0x%08x, 0x%08x]",
          NPC_PMEM_BASE, NPC_PMEM_BASE + (uint32_t)g_pmem_size - 1);
}

size_t npc_loaded_img_size(void) {
  return g_img_size;
}

bool npc_in_pmem(uint32_t addr) {
  if (addr < NPC_PMEM_BASE || !g_pmem) return false;
  uint64_t offset = (uint64_t)(addr - NPC_PMEM_BASE);
  return offset + sizeof(uint32_t) <= g_pmem_size;
}

uint8_t *npc_guest_to_host(uint32_t addr) {
  return g_pmem + (addr - NPC_PMEM_BASE);
}

bool npc_load_img(const char *image_path) {
  FILE *fp = fopen(image_path, "rb");
  if (!fp) { perror("[npc] fopen image"); return false; }

  if (fseek(fp, 0, SEEK_END) != 0) { perror("[npc] fseek"); fclose(fp); return false; }
  long image_size = ftell(fp);
  if (image_size < 0) { perror("[npc] ftell"); fclose(fp); return false; }
  if (fseek(fp, 0, SEEK_SET) != 0) { perror("[npc] rewind"); fclose(fp); return false; }

  if ((uint64_t)image_size > g_pmem_size) {
    fprintf(stderr, "[npc] image too large: %ld bytes, pmem capacity %zu\n", image_size, g_pmem_size);
    fclose(fp); return false;
  }

  /* 只清零 image 覆盖范围之外的 BSS 区域，不再整块 memset 128MB；
   * calloc 初始化时已经保证了全零基线。 */
  size_t nread = fread(npc_guest_to_host(NPC_RESET_PC), 1, (size_t)image_size, fp);
  fclose(fp);

  if (nread != (size_t)image_size) {
    fprintf(stderr, "[npc] short read: expect %ld, got %zu\n", image_size, nread);
    return false;
  }

  g_img_size = (size_t)image_size;
  /* 对齐参考工程：显示镜像路径和大小 */
  LogBoth("The image is %s, size = %ld", image_path, image_size);
  return true;
}

bool npc_paddr_read(uint32_t addr, uint32_t *data, enum NpcBusAccess kind) {
  if (!data) return false;

  if (npc_in_pmem(addr)) {
    *data = host_read_u32(npc_guest_to_host(addr));
    if (kind == NPC_BUS_LOAD && npc_mtrace_enabled()) {
      Log("mtrace load addr=0x%08x data=0x%08x", addr, *data);
    }
    return true;
  }

  /* 取指不穿过 MMIO */
  if (kind != NPC_BUS_IFETCH && npc_mmio_read(addr, data, kind)) {
    npc_difftest_skip_ref();
    return true;
  }

  fprintf(stderr, "[npc] %s out of bound at 0x%08x\n", access_kind_name(kind), addr);
  return false;
}

bool npc_paddr_write(uint32_t addr, uint32_t data, uint32_t mask, enum NpcBusAccess kind) {
  if (npc_in_pmem(addr)) {
    host_write_masked(npc_guest_to_host(addr), data, mask);
    if (kind == NPC_BUS_STORE && npc_mtrace_enabled()) {
      Log("mtrace store addr=0x%08x data=0x%08x mask=0x%x", addr, data, mask);
    }
    return true;
  }

  if (npc_mmio_write(addr, data, mask, kind)) {
    npc_difftest_skip_ref();
    return true;
  }

  fprintf(stderr, "[npc] %s out of bound at 0x%08x\n", access_kind_name(kind), addr);
  return false;
}

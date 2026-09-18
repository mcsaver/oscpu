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
static uint8_t *g_sram = NULL;
static uint8_t *g_mrom = NULL;
static size_t   g_pmem_size = 0;
static size_t   g_sram_size = 0;
static size_t   g_mrom_size = 0;
static size_t   g_img_size = 0;

static bool addr_in_region(uint32_t base, size_t size, uint32_t addr, size_t len) {
  if (size == 0 || len == 0) return false;
  if (addr < base) return false;
  uint64_t offset = (uint64_t)(addr - base);
  return offset + len <= size;
}

static uint8_t *region_guest_to_host(uint8_t *host, uint32_t base, size_t size, uint32_t addr) {
  if (!host || !addr_in_region(base, size, addr, 1)) return NULL;
  return host + (addr - base);
}

static size_t region_capacity_from(uint32_t base, size_t size, uint32_t addr) {
  if (!addr_in_region(base, size, addr, 1)) return 0;
  return size - (size_t)(addr - base);
}

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
  if (g_sram) { free(g_sram); }
  if (g_mrom) { free(g_mrom); }
  g_pmem_size = (size_t)NPC_PMEM_SIZE;
  g_sram_size = (size_t)NPC_SRAM_SIZE;
  g_mrom_size = (size_t)NPC_MROM_SIZE;
  g_img_size = 0;
  /* 用 calloc 代替 malloc + memset：
   * 1. 少一次显式 memset 128MB
   * 2. 大块 calloc 在 Linux 上通常由内核零页映射实现，不会真正触碰物理页 */
  g_pmem = (uint8_t *)calloc(1, g_pmem_size);
  g_sram = (uint8_t *)calloc(1, g_sram_size);
  g_mrom = (uint8_t *)calloc(1, g_mrom_size);
  if (!g_pmem) { perror("[npc] calloc pmem"); abort(); }
  if (!g_sram) { perror("[npc] calloc sram"); abort(); }
  if (!g_mrom) { perror("[npc] calloc mrom"); abort(); }
  npc_cache_init();
  LogBoth("mrom area [0x%08x, 0x%08x]",
          NPC_MROM_BASE, NPC_MROM_BASE + (uint32_t)g_mrom_size - 1);
  LogBoth("sram area [0x%08x, 0x%08x]",
          NPC_SRAM_BASE, NPC_SRAM_BASE + (uint32_t)g_sram_size - 1);
  LogBoth("physical memory area [0x%08x, 0x%08x]",
          NPC_PMEM_BASE, NPC_PMEM_BASE + (uint32_t)g_pmem_size - 1);
}

size_t npc_loaded_img_size(void) {
  return g_img_size;
}

size_t npc_difftest_mem_region_count(void) {
  return 2;
}

bool npc_difftest_mem_region_at(size_t index, NpcDifftestMemRegion *region) {
  if (!region) return false;
  switch (index) {
    case 0:
      region->name = "mrom";
      region->base = NPC_MROM_BASE;
      region->size = g_mrom_size;
      region->host = g_mrom;
      return region->host != NULL && region->size > 0;
    case 1:
      region->name = "sram";
      region->base = NPC_SRAM_BASE;
      region->size = g_sram_size;
      region->host = g_sram;
      return region->host != NULL && region->size > 0;
    default:
      return false;
  }
}

bool npc_in_pmem(uint32_t addr) {
  return g_pmem && addr_in_region(NPC_PMEM_BASE, g_pmem_size, addr, sizeof(uint32_t));
}

bool npc_in_sram(uint32_t addr) {
  return g_sram && addr_in_region(NPC_SRAM_BASE, g_sram_size, addr, sizeof(uint32_t));
}

bool npc_in_mrom(uint32_t addr) {
  return g_mrom && addr_in_region(NPC_MROM_BASE, g_mrom_size, addr, sizeof(uint32_t));
}

uint8_t *npc_guest_to_host(uint32_t addr) {
  uint8_t *host = region_guest_to_host(g_mrom, NPC_MROM_BASE, g_mrom_size, addr);
  if (host) return host;
  host = region_guest_to_host(g_sram, NPC_SRAM_BASE, g_sram_size, addr);
  if (host) return host;
  return region_guest_to_host(g_pmem, NPC_PMEM_BASE, g_pmem_size, addr);
}

bool npc_load_img(const char *image_path) {
  FILE *fp = fopen(image_path, "rb");
  if (!fp) { perror("[npc] fopen image"); return false; }

  if (fseek(fp, 0, SEEK_END) != 0) { perror("[npc] fseek"); fclose(fp); return false; }
  long image_size = ftell(fp);
  if (image_size < 0) { perror("[npc] ftell"); fclose(fp); return false; }
  if (fseek(fp, 0, SEEK_SET) != 0) { perror("[npc] rewind"); fclose(fp); return false; }

  uint8_t *load_host = npc_guest_to_host(NPC_RESET_PC);
  size_t load_capacity = 0;
  if (addr_in_region(NPC_MROM_BASE, g_mrom_size, NPC_RESET_PC, 1)) {
    load_capacity = region_capacity_from(NPC_MROM_BASE, g_mrom_size, NPC_RESET_PC);
  } else if (addr_in_region(NPC_SRAM_BASE, g_sram_size, NPC_RESET_PC, 1)) {
    load_capacity = region_capacity_from(NPC_SRAM_BASE, g_sram_size, NPC_RESET_PC);
  } else if (addr_in_region(NPC_PMEM_BASE, g_pmem_size, NPC_RESET_PC, 1)) {
    load_capacity = region_capacity_from(NPC_PMEM_BASE, g_pmem_size, NPC_RESET_PC);
  }
  if (!load_host || load_capacity == 0) {
    fprintf(stderr, "[npc] reset pc 0x%08x is not backed by simulated memory\n", NPC_RESET_PC);
    fclose(fp); return false;
  }
  if ((uint64_t)image_size > load_capacity) {
    fprintf(stderr, "[npc] image too large: %ld bytes, reset region capacity %zu\n",
            image_size, load_capacity);
    fclose(fp); return false;
  }

  size_t nread = fread(load_host, 1, (size_t)image_size, fp);
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

  if (npc_in_mrom(addr)) {
    *data = host_read_u32(npc_guest_to_host(addr));
    return true;
  }

  if (npc_in_sram(addr)) {
    *data = host_read_u32(npc_guest_to_host(addr));
    if (kind == NPC_BUS_LOAD && npc_mtrace_enabled()) {
      Log("mtrace load addr=0x%08x data=0x%08x", addr, *data);
    }
    return true;
  }

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
  if (npc_in_mrom(addr)) {
    fprintf(stderr, "[npc] %s to read-only mrom at 0x%08x\n", access_kind_name(kind), addr);
    return false;
  }

  if (npc_in_sram(addr)) {
    host_write_masked(npc_guest_to_host(addr), data, mask);
    if (kind == NPC_BUS_STORE && npc_mtrace_enabled()) {
      Log("mtrace store addr=0x%08x data=0x%08x mask=0x%x", addr, data, mask);
    }
    return true;
  }

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

/* NPC 物理地址空间 — C 重构版
 * std::vector<uint8_t> 改为 malloc + 手动管理 */
#include "memory/paddr.h"

#include "cpu/difftest.h"
#include "device/map.h"
#include "monitor/log.h"
#include "monitor/trace.h"
#include "utils.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint8_t *g_pmem = NULL;
static size_t   g_pmem_size = 0;
static size_t   g_img_size = 0;
static bool     g_memwatch_enabled = false;
static npc_paddr_t g_memwatch_start = 0;
static npc_paddr_t g_memwatch_end = 0;

static void init_memwatch(void) {
  const char *start_s = getenv("NPC_MEMWATCH_START");
  const char *end_s = getenv("NPC_MEMWATCH_END");
  g_memwatch_enabled = false;
  if (!start_s || !end_s || start_s[0] == '\0' || end_s[0] == '\0') return;

  char *endp = NULL;
  npc_paddr_t start = (npc_paddr_t)strtoull(start_s, &endp, 0);
  if (!endp || *endp != '\0') return;
  endp = NULL;
  npc_paddr_t end = (npc_paddr_t)strtoull(end_s, &endp, 0);
  if (!endp || *endp != '\0' || end <= start) return;

  g_memwatch_start = start;
  g_memwatch_end = end;
  g_memwatch_enabled = true;
  LogBoth("memwatch [0x%016" NPC_PRIxPADDR ", 0x%016" NPC_PRIxPADDR ")",
          g_memwatch_start, g_memwatch_end);
}

static bool memwatch_hits(npc_paddr_t addr, size_t size) {
  if (!g_memwatch_enabled) return false;
  npc_paddr_t end = addr + (npc_paddr_t)size;
  return addr < g_memwatch_end && end > g_memwatch_start;
}

static npc_word_t host_read_word(const uint8_t *base) {
  npc_word_t data = 0;
  for (int lane = 0; lane < (int)sizeof(npc_word_t); ++lane) {
    data |= ((npc_word_t)base[lane]) << (lane * 8);
  }
  return data;
}

static npc_word_t host_read_sized(const uint8_t *base, size_t size) {
  npc_word_t data = 0;
  for (size_t lane = 0; lane < size; ++lane) {
    data |= ((npc_word_t)base[lane]) << (lane * 8);
  }
  return data;
}

static void host_write_masked(uint8_t *base, npc_word_t data, npc_word_t mask) {
  for (int lane = 0; lane < (int)sizeof(npc_word_t); ++lane) {
    if ((mask & ((npc_word_t)1 << lane)) != 0) {
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
  init_memwatch();
  LogBoth("physical memory area [0x%016" NPC_PRIxPADDR ", 0x%016" NPC_PRIxPADDR "]",
          (npc_paddr_t)NPC_PMEM_BASE, (npc_paddr_t)(NPC_PMEM_BASE + (npc_paddr_t)g_pmem_size - 1));
}

size_t npc_loaded_img_size(void) {
  return g_img_size;
}

bool npc_in_pmem(npc_paddr_t addr) {
  if (addr < NPC_PMEM_BASE || !g_pmem) return false;
  uint64_t offset = (uint64_t)(addr - NPC_PMEM_BASE);
  return offset + sizeof(npc_word_t) <= g_pmem_size;
}

bool npc_pmem_range_valid(npc_paddr_t addr, size_t size) {
  if (addr < NPC_PMEM_BASE || !g_pmem) return false;
  uint64_t offset = (uint64_t)(addr - NPC_PMEM_BASE);
  return offset <= g_pmem_size && (uint64_t)size <= (uint64_t)g_pmem_size - offset;
}

uint8_t *npc_guest_to_host(npc_paddr_t addr) {
  return g_pmem + (addr - NPC_PMEM_BASE);
}

bool npc_load_img_at(const char *image_path, npc_paddr_t load_addr) {
  FILE *fp = fopen(image_path, "rb");
  if (!fp) { perror("[npc] fopen image"); return false; }

  if (fseek(fp, 0, SEEK_END) != 0) { perror("[npc] fseek"); fclose(fp); return false; }
  long image_size = ftell(fp);
  if (image_size < 0) { perror("[npc] ftell"); fclose(fp); return false; }
  if (fseek(fp, 0, SEEK_SET) != 0) { perror("[npc] rewind"); fclose(fp); return false; }

  if (!npc_pmem_range_valid(load_addr, (size_t)image_size)) {
    fprintf(stderr, "[npc] image out of pmem: %s addr=0x%016" NPC_PRIxPADDR
                    " size=%ld, pmem=[0x%016" NPC_PRIxPADDR ",0x%016" NPC_PRIxPADDR "]\n",
            image_path, load_addr, image_size,
            (npc_paddr_t)NPC_PMEM_BASE,
            (npc_paddr_t)(NPC_PMEM_BASE + (npc_paddr_t)g_pmem_size - 1));
    fclose(fp); return false;
  }

  /* 只清零 image 覆盖范围之外的 BSS 区域，不再整块 memset 128MB；
   * calloc 初始化时已经保证了全零基线。 */
  size_t nread = fread(npc_guest_to_host(load_addr), 1, (size_t)image_size, fp);
  fclose(fp);

  if (nread != (size_t)image_size) {
    fprintf(stderr, "[npc] short read: expect %ld, got %zu\n", image_size, nread);
    return false;
  }

  uint64_t image_end = (uint64_t)(load_addr - NPC_RESET_PC) + (uint64_t)image_size;
  if (load_addr >= NPC_RESET_PC && image_end > g_img_size) {
    g_img_size = (size_t)image_end;
  }

  /* 支持真实固件启动时把 OpenSBI/kernel/DTB 分别装到指定物理地址。 */
  if (load_addr == NPC_RESET_PC) {
    LogBoth("The image is %s, size = %ld", image_path, image_size);
  } else {
    LogBoth("Load image %s at 0x%016" NPC_PRIxPADDR ", size = %ld",
            image_path, load_addr, image_size);
  }
  return true;
}

bool npc_load_img(const char *image_path) {
  return npc_load_img_at(image_path, NPC_RESET_PC);
}

bool npc_paddr_read(npc_paddr_t addr, npc_word_t *data, enum NpcBusAccess kind) {
  if (!data) return false;

  /* 简易 csrc 仿真设备在 DPI 窗口 [NPC_DEVICE_BASE, NPC_DEVICE_TOP)=
   * [0x12000000, 0x14000000),已移出 pmem([0x80000000,0xbfffffff]),不再有别名遮挡。
   * 窗口内先走 MMIO;取指不穿设备。serial 由真 RTL UART 承载,不经此路径。 */
  if (kind != NPC_BUS_IFETCH && addr >= NPC_DEVICE_BASE && addr < NPC_DEVICE_TOP) {
    uint32_t mmio_data = 0;
    if (npc_mmio_read((uint32_t)addr, &mmio_data, kind)) {
      *data = (npc_word_t)mmio_data;
      npc_difftest_skip_ref();
      return true;
    }
  }

  if (npc_in_pmem(addr)) {
    *data = host_read_word(npc_guest_to_host(addr));
    if (kind == NPC_BUS_LOAD && memwatch_hits(addr, sizeof(npc_word_t))) {
      Log("memwatch load addr=0x%016" NPC_PRIxPADDR " data=0x%016" NPC_PRIxWORD, addr, *data);
    }
    if (kind == NPC_BUS_LOAD && npc_mtrace_enabled()) {
      Log("mtrace load addr=0x%016" NPC_PRIxPADDR " data=0x%016" NPC_PRIxWORD, addr, *data);
    }
    return true;
  }

  /* 取指不穿过 MMIO */
  if (kind != NPC_BUS_IFETCH) {
    uint32_t mmio_data = 0;
    if (npc_mmio_read((uint32_t)addr, &mmio_data, kind)) {
      *data = (npc_word_t)mmio_data;
      npc_difftest_skip_ref();
      return true;
    }
  }

  fprintf(stderr, "[npc] %s out of bound at 0x%016" NPC_PRIxPADDR "\n", access_kind_name(kind), addr);
  return false;
}

bool npc_paddr_read_sized(npc_paddr_t addr, size_t size,
                          npc_word_t *data, enum NpcBusAccess kind) {
  if (!data || size == 0 || size > sizeof(npc_word_t)) return false;

  // PMEM 是 sized ABI 的承重路径：只验证/读取事务声明的字节，不再把 2B IFU
  // 或边界附近的合法访问隐式扩张成宿主 8B load。
  if (npc_pmem_range_valid(addr, size)) {
    *data = host_read_sized(npc_guest_to_host(addr), size);
    if (kind == NPC_BUS_LOAD && memwatch_hits(addr, size)) {
      Log("memwatch load addr=0x%016" NPC_PRIxPADDR
          " size=%zu data=0x%016" NPC_PRIxWORD, addr, size, *data);
    }
    if (kind == NPC_BUS_LOAD && npc_mtrace_enabled()) {
      Log("mtrace load addr=0x%016" NPC_PRIxPADDR
          " size=%zu data=0x%016" NPC_PRIxWORD, addr, size, *data);
    }
    return true;
  }

  // instruction fetch 永不穿 MMIO。data MMIO 暂复用既有 exact-address/low-window
  // 设备 ABI；把 LSU cross-lane single beat 标准化属于后续 split-transaction 切片。
  if (kind == NPC_BUS_IFETCH) {
    fprintf(stderr, "[npc] %s out of bound at 0x%016" NPC_PRIxPADDR
                    " size=%zu\n", access_kind_name(kind), addr, size);
    return false;
  }
  return npc_paddr_read(addr, data, kind);
}

bool npc_paddr_write(npc_paddr_t addr, npc_word_t data, npc_word_t mask, enum NpcBusAccess kind) {
  /* 简易设备 DPI 窗口 [NPC_DEVICE_BASE, NPC_DEVICE_TOP);已移出 pmem,无别名遮挡。 */
  if (addr >= NPC_DEVICE_BASE && addr < NPC_DEVICE_TOP &&
      npc_mmio_write((uint32_t)addr, (uint32_t)data, (uint32_t)mask, kind)) {
    npc_difftest_skip_ref();
    return true;
  }

  if (npc_in_pmem(addr)) {
    host_write_masked(npc_guest_to_host(addr), data, mask);
    if (kind == NPC_BUS_STORE && memwatch_hits(addr, sizeof(npc_word_t))) {
      Log("memwatch store addr=0x%016" NPC_PRIxPADDR " data=0x%016" NPC_PRIxWORD " mask=0x%02" NPC_PRIxWORD,
          addr, data, mask);
    }
    if (kind == NPC_BUS_STORE && npc_mtrace_enabled()) {
      Log("mtrace store addr=0x%016" NPC_PRIxPADDR " data=0x%016" NPC_PRIxWORD " mask=0x%02" NPC_PRIxWORD,
          addr, data, mask);
    }
    return true;
  }

  if (npc_mmio_write((uint32_t)addr, (uint32_t)data, (uint32_t)mask, kind)) {
    npc_difftest_skip_ref();
    return true;
  }

  fprintf(stderr, "[npc] %s out of bound at 0x%016" NPC_PRIxPADDR "\n", access_kind_name(kind), addr);
  return false;
}

/* NPC MMIO 设备映射表 — C 重构版
 * std::vector<IOMap> 改为固定大小数组 */
#include "device/map.h"

#include "monitor/log.h"
#include "monitor/trace.h"

#include <stdio.h>
#include <stdlib.h>

#define NPC_MAX_MMIO_MAPS 16

static NpcIOMap g_maps[NPC_MAX_MMIO_MAPS];
static int      g_map_count = 0;

static bool is_overlap(const NpcIOMap *a, const NpcIOMap *b) {
  return !(a->high < b->low || b->high < a->low);
}

static NpcIOMap *find_map(uint32_t addr) {
  for (int i = 0; i < g_map_count; ++i) {
    if (addr >= g_maps[i].low && addr <= g_maps[i].high) {
      return &g_maps[i];
    }
  }
  return NULL;
}

static const char *dtrace_op_name(enum NpcBusAccess kind) {
  switch (kind) {
    case NPC_BUS_LOAD:   return "load";
    case NPC_BUS_STORE:  return "store";
    case NPC_BUS_IFETCH: return "ifetch";
    default:             return "access";
  }
}

void npc_init_map(void) {
  g_map_count = 0;
}

void npc_clear_map(void) {
  g_map_count = 0;
}

void npc_add_mmio_map(const char *name, uint32_t addr, uint32_t len, void *opaque,
                      npc_device_read_cb read_cb, npc_device_write_cb write_cb) {
  if (len == 0) {
    fprintf(stderr, "[npc] mmio map '%s' has zero length\n", name);
    abort();
  }
  if (g_map_count >= NPC_MAX_MMIO_MAPS) {
    fprintf(stderr, "[npc] too many mmio maps\n");
    abort();
  }

  NpcIOMap *map = &g_maps[g_map_count];
  map->name   = name;
  map->low    = addr;
  map->high   = addr + len - 1;
  map->opaque = opaque;
  map->read   = read_cb;
  map->write  = write_cb;

  for (int i = 0; i < g_map_count; ++i) {
    if (is_overlap(map, &g_maps[i])) {
      fprintf(stderr, "[npc] mmio overlap: %s[0x%08x,0x%08x] vs %s[0x%08x,0x%08x]\n",
              map->name, map->low, map->high,
              g_maps[i].name, g_maps[i].low, g_maps[i].high);
      abort();
    }
  }

  ++g_map_count;
  /* 对齐参考工程：MMIO 映射信息同时输出到终端，方便确认设备注册 */
  LogBoth("Add mmio map '%s' at [0x%08x, 0x%08x]", map->name, map->low, map->high);
}

bool npc_mmio_read(uint32_t addr, uint32_t *data, enum NpcBusAccess kind) {
  if (!data) return false;
  NpcIOMap *map = find_map(addr);
  if (!map || !map->read) return false;

  bool error = false;
  *data = map->read(map->opaque, addr - map->low, &error);
  if (error) {
    fprintf(stderr, "[npc] mmio read failed on %s at 0x%08x\n", map->name, addr);
  }
  if (!error && npc_dtrace_enabled()) {
    Log("dtrace %s %s addr=0x%08x data=0x%08x", dtrace_op_name(kind), map->name, addr, *data);
  }
  return !error;
}

bool npc_mmio_write(uint32_t addr, uint32_t data, uint32_t mask, enum NpcBusAccess kind) {
  if (mask == 0) return true;
  NpcIOMap *map = find_map(addr);
  if (!map || !map->write) return false;

  bool error = false;
  map->write(map->opaque, addr - map->low, data, mask, &error);
  if (error) {
    fprintf(stderr, "[npc] mmio write failed on %s at 0x%08x\n", map->name, addr);
  }
  if (!error && npc_dtrace_enabled()) {
    Log("dtrace %s %s addr=0x%08x data=0x%08x mask=0x%x", dtrace_op_name(kind), map->name, addr, data, mask);
  }
  return !error;
}

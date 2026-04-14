#include "device/map.h"

#include "monitor/log.h"
#include "monitor/trace.h"

#include <cstdio>
#include <cstdlib>
#include <utility>
#include <vector>

namespace npc {

namespace {

std::vector<IOMap> g_maps;

bool is_overlap(const IOMap &lhs, const IOMap &rhs) {
  return !(lhs.high < rhs.low || rhs.high < lhs.low);
}

IOMap *find_map(uint32_t addr) {
  for (auto &map : g_maps) {
    if (addr >= map.low && addr <= map.high) {
      return &map;
    }
  }
  return nullptr;
}

const char *dtrace_op_name(BusAccessKind kind) {
  switch (kind) {
    case BusAccessKind::kLoad: return "load";
    case BusAccessKind::kStore: return "store";
    case BusAccessKind::kIfetch: return "ifetch";
    default: return "access";
  }
}

}  // namespace

void init_map() {
  g_maps.clear();
  g_maps.reserve(8);
}

void clear_map() {
  g_maps.clear();
}

void add_mmio_map(const char *name, uint32_t addr, uint32_t len, void *opaque,
                  device_read_cb_t read, device_write_cb_t write) {
  if (len == 0) {
    std::fprintf(stderr, "[npc] mmio map '%s' has zero length\n", name);
    std::abort();
  }

  IOMap map;
  map.name = name;
  map.low = addr;
  map.high = addr + len - 1;
  map.opaque = opaque;
  map.read = read;
  map.write = write;

  // 这里保留 NEMU 的“先注册地址区间，再统一分发”思路，后面补更多设备时不会继续回到大 if-else。
  for (const auto &existing : g_maps) {
    if (is_overlap(map, existing)) {
      std::fprintf(stderr,
                   "[npc] mmio map overlap: %s[0x%08x,0x%08x] conflicts with %s[0x%08x,0x%08x]\n",
                   map.name.c_str(), map.low, map.high,
                   existing.name.c_str(), existing.low, existing.high);
      std::abort();
    }
  }

  g_maps.push_back(std::move(map));
  Log("Add mmio map '%s' at [0x%08x, 0x%08x]",
      g_maps.back().name.c_str(),
      g_maps.back().low,
      g_maps.back().high);
}

bool mmio_read(uint32_t addr, uint32_t *data, BusAccessKind kind) {
  if (data == nullptr) {
    return false;
  }

  IOMap *map = find_map(addr);
  if (map == nullptr || map->read == nullptr) {
    return false;
  }

  bool error = false;
  *data = map->read(map->opaque, addr - map->low, &error);
  if (error) {
    std::fprintf(stderr, "[npc] mmio read failed on %s at 0x%08x\n", map->name.c_str(), addr);
  }
  if (!error && dtrace_enabled()) {
    Log("dtrace %s %s addr=0x%08x data=0x%08x", dtrace_op_name(kind), map->name.c_str(), addr, *data);
  }
  return !error;
}

bool mmio_write(uint32_t addr, uint32_t data, uint32_t mask, BusAccessKind kind) {
  if (mask == 0) {
    return true;
  }

  IOMap *map = find_map(addr);
  if (map == nullptr || map->write == nullptr) {
    return false;
  }

  bool error = false;
  map->write(map->opaque, addr - map->low, data, mask, &error);
  if (error) {
    std::fprintf(stderr, "[npc] mmio write failed on %s at 0x%08x\n", map->name.c_str(), addr);
  }
  if (!error && dtrace_enabled()) {
    Log("dtrace %s %s addr=0x%08x data=0x%08x mask=0x%x", dtrace_op_name(kind), map->name.c_str(), addr, data, mask);
  }
  return !error;
}

}  // namespace npc
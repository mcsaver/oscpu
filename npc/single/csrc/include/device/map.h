#ifndef NPC_SINGLE_CSRC_DEVICE_MAP_H_
#define NPC_SINGLE_CSRC_DEVICE_MAP_H_

#include "../utils.h"

#include <cstdint>
#include <string>

namespace npc {

using device_read_cb_t = uint32_t (*)(void *opaque, uint32_t offset, bool *error);
using device_write_cb_t = void (*)(void *opaque, uint32_t offset, uint32_t data, uint32_t mask, bool *error);

struct IOMap {
  std::string name;
  uint32_t low = 0;
  uint32_t high = 0;
  void *opaque = nullptr;
  device_read_cb_t read = nullptr;
  device_write_cb_t write = nullptr;
};

void init_map();
void clear_map();
void add_mmio_map(const char *name, uint32_t addr, uint32_t len, void *opaque,
                  device_read_cb_t read, device_write_cb_t write);
bool mmio_read(uint32_t addr, uint32_t *data, BusAccessKind kind = BusAccessKind::kLoad);
bool mmio_write(uint32_t addr, uint32_t data, uint32_t mask, BusAccessKind kind = BusAccessKind::kStore);

}  // namespace npc

#endif
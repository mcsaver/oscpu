#include <svdpi.h>

#include <cstdint>

#include "memory/paddr.h"
#include "utils.h"

double sc_time_stamp() {
  return static_cast<double>(npc::npc_stats().sim_time);
}

extern "C" void npc_ifetch(uint32_t addr, uint32_t *data, svBit *error) {
  if (data == nullptr || error == nullptr) {
    return;
  }

  *data = 0;
  *error = 0;

  if ((addr & 0x3u) != 0) {
    *error = 1;
    return;
  }

  if (!npc::paddr_read(addr, data, npc::BusAccessKind::kIfetch)) {
    *error = 1;
  }
}

extern "C" void npc_mem_read(uint32_t addr, uint32_t *data, svBit *error) {
  if (data == nullptr || error == nullptr) {
    return;
  }

  *data = 0;
  *error = 0;

  if ((addr & 0x3u) != 0) {
    *error = 1;
    return;
  }

  if (!npc::paddr_read(addr, data, npc::BusAccessKind::kLoad)) {
    *error = 1;
  }
}

extern "C" void npc_mem_write(uint32_t addr, uint32_t data, uint32_t mask, svBit *error) {
  if (error == nullptr) {
    return;
  }

  *error = 0;
  mask &= 0xfu;

  if ((addr & 0x3u) != 0) {
    *error = 1;
    return;
  }

  if (mask == 0) {
    return;
  }

  if (!npc::paddr_write(addr, data, mask, npc::BusAccessKind::kStore)) {
    *error = 1;
  }
}
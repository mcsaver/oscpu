#ifndef NPC_SINGLE_CSRC_MEMORY_PADDR_H_
#define NPC_SINGLE_CSRC_MEMORY_PADDR_H_

#include "../utils.h"

#include <cstdint>
#include <string>

namespace npc {

void init_mem();
bool load_img(const std::string &image_path);
bool in_pmem(uint32_t addr);
uint8_t *guest_to_host(uint32_t addr);
bool paddr_read(uint32_t addr, uint32_t *data, BusAccessKind kind = BusAccessKind::kLoad);
bool paddr_write(uint32_t addr, uint32_t data, uint32_t mask, BusAccessKind kind = BusAccessKind::kStore);

}  // namespace npc

#endif
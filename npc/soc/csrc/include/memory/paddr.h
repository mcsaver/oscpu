#ifndef NPC_SINGLE_CSRC_MEMORY_PADDR_H_
#define NPC_SINGLE_CSRC_MEMORY_PADDR_H_

#include <stdbool.h>
#include <stdint.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_mem(void);
bool npc_load_img(const char *image_path);
size_t npc_loaded_img_size(void);

typedef struct {
  const char *name;
  uint32_t base;
  size_t size;
  uint8_t *host;
} NpcDifftestMemRegion;

size_t npc_difftest_mem_region_count(void);
bool npc_difftest_mem_region_at(size_t index, NpcDifftestMemRegion *region);
bool npc_in_pmem(uint32_t addr);
bool npc_in_sram(uint32_t addr);
bool npc_in_mrom(uint32_t addr);
uint8_t *npc_guest_to_host(uint32_t addr);
bool npc_paddr_read(uint32_t addr, uint32_t *data, enum NpcBusAccess kind);
bool npc_paddr_write(uint32_t addr, uint32_t data, uint32_t mask, enum NpcBusAccess kind);

#ifdef __cplusplus
}
#endif

#endif

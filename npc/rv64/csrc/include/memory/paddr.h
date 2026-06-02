#ifndef NPC_RV64_CSRC_MEMORY_PADDR_H_
#define NPC_RV64_CSRC_MEMORY_PADDR_H_

#include <stdbool.h>
#include <stdint.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_mem(void);
bool npc_load_img(const char *image_path);
bool npc_load_img_at(const char *image_path, npc_paddr_t load_addr);
size_t npc_loaded_img_size(void);
bool npc_in_pmem(npc_paddr_t addr);
bool npc_pmem_range_valid(npc_paddr_t addr, size_t size);
uint8_t *npc_guest_to_host(npc_paddr_t addr);
bool npc_paddr_read(npc_paddr_t addr, npc_word_t *data, enum NpcBusAccess kind);
bool npc_paddr_write(npc_paddr_t addr, npc_word_t data, npc_word_t mask, enum NpcBusAccess kind);

#ifdef __cplusplus
}
#endif

#endif

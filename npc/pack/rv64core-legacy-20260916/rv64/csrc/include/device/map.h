#ifndef NPC_SINGLE_CSRC_DEVICE_MAP_H_
#define NPC_SINGLE_CSRC_DEVICE_MAP_H_

#include <stdbool.h>
#include <stdint.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t (*npc_device_read_cb)(void *opaque, uint32_t offset, bool *error);
typedef void (*npc_device_write_cb)(void *opaque, uint32_t offset, uint32_t data, uint32_t mask, bool *error);

typedef struct {
  const char *name;
  uint32_t low;
  uint32_t high;
  void *opaque;
  npc_device_read_cb read;
  npc_device_write_cb write;
} NpcIOMap;

void npc_init_map(void);
void npc_clear_map(void);
void npc_add_mmio_map(const char *name, uint32_t addr, uint32_t len, void *opaque,
                      npc_device_read_cb read_cb, npc_device_write_cb write_cb);
bool npc_mmio_read(uint32_t addr, uint32_t *data, enum NpcBusAccess kind);
bool npc_mmio_write(uint32_t addr, uint32_t data, uint32_t mask, enum NpcBusAccess kind);

#ifdef __cplusplus
}
#endif

#endif

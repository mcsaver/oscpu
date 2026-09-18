#ifndef NPC_SINGLE_CSRC_DEVICE_DEVICE_H_
#define NPC_SINGLE_CSRC_DEVICE_DEVICE_H_

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_device(bool enable_stdin_keyboard, bool enable_vga);
void npc_device_update(void);
void npc_fini_device(void);

#ifdef __cplusplus
}
#endif

#endif

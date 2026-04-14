#ifndef NPC_SINGLE_CSRC_DEVICE_DEVICE_H_
#define NPC_SINGLE_CSRC_DEVICE_DEVICE_H_

namespace npc {

void init_device(bool enable_stdin_keyboard);
void device_update();
void fini_device();

}  // namespace npc

#endif
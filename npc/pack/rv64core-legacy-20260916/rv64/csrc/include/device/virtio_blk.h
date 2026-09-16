#ifndef NPC_RV64_CSRC_DEVICE_VIRTIO_BLK_H_
#define NPC_RV64_CSRC_DEVICE_VIRTIO_BLK_H_

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool npc_virtio_blk_init(const char *image_path);
void npc_virtio_blk_fini(void);

#ifdef __cplusplus
}
#endif

#endif

#include <am.h>
#include <stdint.h>

#include "../../platform/gpu_soft.h"
#include "ysyxsoc.h"

static inline bool gpu_present() {
  return YSYXSOC_HAS_GPU != 0;
}

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = gpu_present(),
    .has_accel = gpu_present(),
    .width = gpu_present() ? YSYXSOC_GPU_WIDTH : 0,
    .height = gpu_present() ? YSYXSOC_GPU_HEIGHT : 0,
    .vmemsz = gpu_present() ? AM_GPU_SOFT_VMEM_SIZE : 0,
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (!gpu_present() || ctl->pixels == NULL || ctl->w <= 0 || ctl->h <= 0) {
    return;
  }

  uint32_t *src = (uint32_t *)ctl->pixels;
  uint32_t *fb = (uint32_t *)(uintptr_t)YSYXSOC_VGA_BASE;

  // ysyxSoC 当前没有 NEMU/NPC 风格的 vgactl/sync 寄存器；可选 GPU 路径只负责写 framebuffer。
  for (int row = 0; row < ctl->h; row++) {
    int dst_y = ctl->y + row;
    if (dst_y < 0 || dst_y >= YSYXSOC_GPU_HEIGHT) {
      continue;
    }
    for (int col = 0; col < ctl->w; col++) {
      int dst_x = ctl->x + col;
      if (dst_x < 0 || dst_x >= YSYXSOC_GPU_WIDTH) {
        continue;
      }
      fb[dst_y * YSYXSOC_GPU_WIDTH + dst_x] = src[row * ctl->w + col];
    }
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = gpu_present();
}

void __am_gpu_memcpy(AM_GPU_MEMCPY_T *params) {
  if (gpu_present()) {
    am_gpu_memcpy_to_vmem(params);
  }
}

void __am_gpu_render(AM_GPU_RENDER_T *render) {
  if (gpu_present()) {
    am_gpu_render_to_fb(render->root, YSYXSOC_GPU_WIDTH, YSYXSOC_GPU_HEIGHT,
        (uint32_t *)(uintptr_t)YSYXSOC_VGA_BASE);
  }
}

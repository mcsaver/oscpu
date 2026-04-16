#include <am.h>
#include <stdint.h>

#include "../../platform/gpu_soft.h"
#include "npc.h"

#define SYNC_ADDR (VGACTL_ADDR + 4)

static inline uint32_t gpu_width() {
  return inl(VGACTL_ADDR) >> 16;
}

static inline uint32_t gpu_height() {
  return inl(VGACTL_ADDR) & 0xffffu;
}

static inline bool gpu_present() {
  return am_gpu_present(gpu_width(), gpu_height());
}

void __am_gpu_init() {
  // NPC 宿主侧在设备初始化时已经把 framebuffer 清成黑屏了；这里若再让 guest 用 store 扫满 400x300，
  // 多周期核会在真正进入测试前先白白耗掉几十万次提交。保留一次 sync 即可把干净初始帧提交出来。
  if (gpu_present()) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t width = gpu_width();
  uint32_t height = gpu_height();

  *cfg = (AM_GPU_CONFIG_T) {
    .present = am_gpu_present(width, height),
    .has_accel = true,
    .width = (int)width,
    .height = (int)height,
    .vmemsz = am_gpu_present(width, height) ? AM_GPU_SOFT_VMEM_SIZE : 0,
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (!gpu_present()) {
    return;
  }

  int x_reg = ctl->x;
  int y_reg = ctl->y;
  int w_reg = ctl->w;
  int h_reg = ctl->h;

  if (ctl->pixels != NULL && w_reg > 0 && h_reg > 0) {
    uint32_t screen_w = gpu_width();
    uint32_t screen_h = gpu_height();
    uint32_t *src = (uint32_t *)ctl->pixels;
    uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;

    // 保留基础 framebuffer 拷贝路径，video_test 仍然直接走这里；而 devscan 的 canvas/render 由软件渲染层补齐。
    for (int row = 0; row < h_reg; row++) {
      int dst_y = y_reg + row;
      if (dst_y < 0 || dst_y >= (int)screen_h) {
        continue;
      }

      for (int col = 0; col < w_reg; col++) {
        int dst_x = x_reg + col;
        if (dst_x < 0 || dst_x >= (int)screen_w) {
          continue;
        }
        fb[dst_y * screen_w + dst_x] = src[row * w_reg + col];
      }
    }
  }

  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = gpu_present();
}

void __am_gpu_memcpy(AM_GPU_MEMCPY_T *params) {
  if (!gpu_present()) {
    return;
  }

  // 这里补上 devscan 依赖的高级 GPU 输入缓冲区，让上层能先把 canvas/texture 数据组织到一块软显存里。
  am_gpu_memcpy_to_vmem(params);
}

void __am_gpu_render(AM_GPU_RENDER_T *render) {
  if (!gpu_present()) {
    return;
  }

  am_gpu_render_to_fb(render->root, gpu_width(), gpu_height(), (uint32_t *)(uintptr_t)FB_ADDR);
  outl(SYNC_ADDR, 1);
}
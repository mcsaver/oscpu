#include <am.h>
#include <nemu.h>

#include "../../gpu_soft.h"

#define SYNC_ADDR (VGACTL_ADDR + 4)

// 设备树图(riscv64-nemu)没有简易 VGA 控制器: 不读 VGACTL, gpu 一律 present=false,
// 避免 ioe_init 触碰 NEMU 未实现的 0x12000100 而抬 access-fault。VGA 属 AM 仿真扩展,
// 不在设备树; 需要显示的程序应走另有 RTL/模型的后端。
static inline uint32_t gpu_width() {
#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
  return 0;
#else
  return inl(VGACTL_ADDR) >> 16;
#endif
}

static inline uint32_t gpu_height() {
#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
  return 0;
#else
  return inl(VGACTL_ADDR) & 0xffffu;
#endif
}

static inline bool gpu_present() {
#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
  return false;
#else
  return am_gpu_present(gpu_width(), gpu_height());
#endif
}

void __am_gpu_init() {
  // NEMU 宿主侧已经把 framebuffer 初始化干净了；这里保留一次 sync，避免 guest 再做无意义整屏清零。
  if (gpu_present()) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t width = gpu_width();
  uint32_t height = gpu_height();
  *cfg = (AM_GPU_CONFIG_T) {
    .present = am_gpu_present(width, height), .has_accel = true,
    .width = width, .height = height,
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

  if (ctl->pixels && w_reg > 0 && h_reg > 0) {
    uint32_t screen_w = gpu_width();
    uint32_t screen_h = gpu_height();
    uint32_t *data = (uint32_t *)ctl->pixels;
    uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;

    // 基础 FBDRAW 仍然负责“矩形像素块 -> framebuffer”的直接拷贝；高级树形渲染留给 GPU_RENDER 复用软件渲染层处理。
    for (int y_h = 0; y_h < h_reg; y_h++) {
      int dst_y = y_reg + y_h;
      if (dst_y < 0 || dst_y >= (int)screen_h) {
        continue;
      }

      for (int x_w = 0; x_w < w_reg; x_w++) {
        int dst_x = x_reg + x_w;
        if (dst_x < 0 || dst_x >= (int)screen_w) {
          continue;
        }
        fb[dst_y * screen_w + dst_x] = data[y_h * w_reg + x_w];
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

  // devscan 依赖这层“guest 缓冲区 -> GPU 软显存”的拷贝语义；这样不同平台都能复用同一套 canvas/render ABI。
  am_gpu_memcpy_to_vmem(params);
}

void __am_gpu_render(AM_GPU_RENDER_T *render) {
  if (!gpu_present()) {
    return;
  }

  am_gpu_render_to_fb(render->root, gpu_width(), gpu_height(), (uint32_t *)(uintptr_t)FB_ADDR);
  outl(SYNC_ADDR, 1);
}

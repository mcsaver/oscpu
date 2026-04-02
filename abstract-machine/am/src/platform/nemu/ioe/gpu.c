#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
  int i;
  int w = 400;  // TODO: get the correct width
  int h = 300;  // TODO: get the correct height
  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  for (i = 0; i < w * h; i ++) fb[i] = i;
  outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  // 改成直接读取 VGACTL 的宽高寄存器，避免 AM 层一直返回 0x0 的占位分辨率。
  // 这样上层程序能拿到真实屏幕大小，后面的 framebuffer 偏移计算才有意义。
  uint32_t vga_reg = inl(VGACTL_ADDR);
  uint32_t width = vga_reg >> 16;
  uint32_t height = vga_reg & 0xffff;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = width, .height = height,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  int x_reg = ctl->x;
  int y_reg = ctl->y;
  int w_reg = ctl->w;
  int h_reg = ctl->h;

  // 这里补上真正的像素拷贝，把源图块按 (x, y) 位置写到 framebuffer。
  // 改完后 sync 不再只是“刷新空屏”，而是能把应用传来的像素块真正显示出来。
  if (ctl->pixels && w_reg > 0 && h_reg > 0) {
    uint32_t vga_reg = inl(VGACTL_ADDR);
    int screen_w = vga_reg >> 16;
    uint32_t *data = (uint32_t *)ctl->pixels;
    uint32_t *fb = (uint32_t *)FB_ADDR;

    for (int y_h = 0; y_h < h_reg; y_h++) {
      for (int x_w = 0; x_w < w_reg; x_w++) {
        fb[(y_reg + y_h) * screen_w + (x_reg + x_w)] = data[y_h * w_reg + x_w];
      }
    }
  }

  // 保留 sync 提交语义，让 guest 能把“写显存”和“提交一帧”分成两步完成。
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}

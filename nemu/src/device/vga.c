/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

// 一个典型的 framebuffer 设备模型：一块显存，加一组控制寄存器，再加一个提交刷新用的 sync 标志。
// 之所以补这段说明，是为了明确 guest 负责写像素、NEMU 负责在设备更新阶段按 sync 提交整帧。

#include <common.h>
#include <device/map.h>


#define SCREEN_W (MUXDEF(CONFIG_VGA_SIZE_800x600, 800, 400))
#define SCREEN_H (MUXDEF(CONFIG_VGA_SIZE_800x600, 600, 300))

static uint32_t screen_width() {
  return MUXDEF(CONFIG_TARGET_AM, io_read(AM_GPU_CONFIG).width, SCREEN_W);
}

static uint32_t screen_height() {
  return MUXDEF(CONFIG_TARGET_AM, io_read(AM_GPU_CONFIG).height, SCREEN_H);
}

static uint32_t screen_size() {
  return screen_width() * screen_height() * sizeof(uint32_t);
}

// vmem 是真正存像素的帧缓冲，vgactl_port_base 是控制寄存器后端内存。
// 把两者区分开可以避免把“写像素”和“触发刷新”混成同一种动作。
static void *vmem = NULL;
static uint32_t *vgactl_port_base = NULL;
/*
 * AM guest 绘图后会显式写 vgactl.sync；Linux simplefb 不知道这个私有
 * 寄存器，只会写 framebuffer 内存。通过 IOMap 回调跟踪显存写入，让两种
 * guest 契约共用同一个 SDL presenter，同时不要求 Linux 使用 NEMU 私有驱动。
 */
static bool vmem_dirty = false;

static const IoRegisterDescriptor vga_control_registers[]
    __attribute__((unused)) = {
  {
    .name = "geometry",
    .first_offset = 0,
    .last_offset = 3,
    .stride = 4,
    .width_mask = IO_WIDTH_4,
    .direction_mask = IO_TRANSACTION_READ,
    .naturally_aligned = true,
  },
  {
    .name = "sync",
    .first_offset = 4,
    .last_offset = 7,
    .stride = 4,
    .width_mask = IO_WIDTH_4,
    .direction_mask = IO_TRANSACTION_WRITE,
    .naturally_aligned = true,
  },
};

static const IoAccessPolicy vga_control_mmio_policy
    __attribute__((unused)) = {
  .registers = vga_control_registers,
  .register_count = ARRLEN(vga_control_registers),
};

static void vmem_io_handler(uint32_t offset, int len, bool is_write) {
  (void)offset;
  (void)len;
  if (is_write) vmem_dirty = true;
}

#ifdef CONFIG_VGA_SHOW_SCREEN
#ifndef CONFIG_TARGET_AM
#include <SDL2/SDL.h>

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;


static void init_screen() {
  SDL_Window *window = NULL;
  char title[128];
  snprintf(title, sizeof(title), "%s-NEMU", str(__GUEST_ISA__));
  int rc = SDL_Init(SDL_INIT_VIDEO);
  Assert(rc == 0, "SDL video 初始化失败: %s", SDL_GetError());
  rc = SDL_CreateWindowAndRenderer(
      SCREEN_W * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
      SCREEN_H * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
      0, &window, &renderer);
  Assert(rc == 0 && window != NULL && renderer != NULL,
      "SDL 窗口/renderer 创建失败: %s", SDL_GetError());
  SDL_SetWindowTitle(window, title);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
  Assert(texture != NULL, "SDL framebuffer texture 创建失败: %s", SDL_GetError());
  SDL_RenderPresent(renderer);
}

static inline void update_screen() {
  int rc = SDL_UpdateTexture(texture, NULL, vmem,
      SCREEN_W * sizeof(uint32_t));
  Assert(rc == 0, "SDL framebuffer 上传失败: %s", SDL_GetError());
  rc = SDL_RenderClear(renderer);
  Assert(rc == 0, "SDL renderer 清屏失败: %s", SDL_GetError());
  rc = SDL_RenderCopy(renderer, texture, NULL, NULL);
  Assert(rc == 0, "SDL framebuffer 呈现失败: %s", SDL_GetError());
  SDL_RenderPresent(renderer);
}
#else
static void init_screen() {}

static inline void update_screen() {
  io_write(AM_GPU_FBDRAW, 0, 0, vmem, screen_width(), screen_height(), true);
}
#endif
#endif

void vga_update_screen() {
  // 只有 guest 显式写了 sync 才刷新，目的是避免每次设备轮询都整屏重绘。
  // 这样改完后，屏幕更新频率由 guest 提交控制，既正确也更省宿主开销。
  // 修复：update_screen() 仅在 CONFIG_VGA_SHOW_SCREEN 下定义；不显示屏(如 difftest
  // 共享库构建)时本函数应为 no-op，否则 implicit-declaration 编译失败(warning-as-error)。
#ifdef CONFIG_VGA_SHOW_SCREEN
  bool auto_scanout_dirty = false;
#ifdef CONFIG_VGA_AUTO_SCANOUT
  auto_scanout_dirty = vmem_dirty;
#endif
  if (vgactl_port_base[1] != 0 || auto_scanout_dirty) {
    update_screen();
    vgactl_port_base[1] = 0;
    vmem_dirty = false;
  }
#endif
}

void init_vga() {
  //分配8字节的vgactl，并且映射到VGA控制地址
  vgactl_port_base = (uint32_t *)new_space(8);
  //初始的第一个32位存的是屏幕宽高打包后的控制寄存器
  vgactl_port_base[0] = (screen_width() << 16) | screen_height();
#ifdef NEMU_HAS_PORT_IO
  add_pio_map ("vgactl", CONFIG_VGA_CTL_PORT, vgactl_port_base, 8, NULL);
#else
  add_mmio_map_with_policy("vgactl", DEV_VGA_CTL_MMIO,
      vgactl_port_base, 8, NULL, &vga_control_mmio_policy);
#endif

  //分配一整块vmem，并映射到FB地址
  vmem = new_space(screen_size());
  add_mmio_map("vmem", DEV_FB_ADDR, vmem, screen_size(), vmem_io_handler);
  IFDEF(CONFIG_VGA_SHOW_SCREEN, init_screen());
  IFDEF(CONFIG_VGA_SHOW_SCREEN, {
    memset(vmem, 0, screen_size());
    vmem_dirty = true;
  });
}

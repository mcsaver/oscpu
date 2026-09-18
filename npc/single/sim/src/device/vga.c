/* NPC VGA 设备
 * 学习 NEMU 的 IO/设备分层：设备行为独立成文件，状态 static 管理。
 * 管理 framebuffer 和 SDL 窗口显示，SDL 键盘事件通过
 * npc_kbd_push_event() 转发到键盘设备，实现跨设备事件路由。
 * 初始化时自行注册 vgactl + framebuffer 两段 MMIO 到总线。 */
#include "device/vga.h"
#include "device/keyboard.h"
#include "device/map.h"
#include "monitor/log.h"
#include "utils.h"

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#if NPC_HAS_SDL
#include <SDL2/SDL.h>
#endif

/* ---- 辅助函数 ---- */
static uint32_t load_u32(const uint8_t *base) {
  return (uint32_t)base[0]
       | ((uint32_t)base[1] << 8)
       | ((uint32_t)base[2] << 16)
       | ((uint32_t)base[3] << 24);
}

static void store_masked(uint8_t *base, uint32_t data, uint32_t mask) {
  for (int lane = 0; lane < 4; ++lane) {
    if ((mask & (1u << lane)) != 0) {
      base[lane] = (uint8_t)(data >> (lane * 8));
    }
  }
}

/* ---- 模块内部静态状态 ---- */
typedef struct {
  uint8_t *framebuffer;
  size_t fb_size;
  uint32_t ctrl_regs[2];
  bool enabled;
  bool sync_pending;
#if NPC_HAS_SDL
  bool sdl_disabled;
  bool sdl_initialized;
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  int keymap[512]; /* SDL_NUM_SCANCODES 通常 < 512 */
#endif
} VgaState;

static VgaState g_vga;

/* ---- SDL 窗口管理 ---- */
#if NPC_HAS_SDL
static void destroy_window(VgaState *v) {
  if (v->texture)  { SDL_DestroyTexture(v->texture);   v->texture = NULL; }
  if (v->renderer) { SDL_DestroyRenderer(v->renderer); v->renderer = NULL; }
  if (v->window)   { SDL_DestroyWindow(v->window);     v->window = NULL; }
  if (v->sdl_initialized) { SDL_Quit(); v->sdl_initialized = false; }
}

static void disable_sdl(VgaState *v, const char *reason) {
  if (!v->sdl_disabled) { LogBoth("%s", reason); }
  v->sdl_disabled = true;
  destroy_window(v);
}

static bool ensure_window(VgaState *v) {
  if (v->sdl_disabled) return false;
  if (v->window && v->renderer && v->texture) return true;
  if (!v->sdl_initialized) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
      disable_sdl(v, "SDL init failed, continue headless");
      return false;
    }
    v->sdl_initialized = true;
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest");
  }
  if (SDL_CreateWindowAndRenderer((int)NPC_SCREEN_WIDTH * 2, (int)NPC_SCREEN_HEIGHT * 2,
                                  0, &v->window, &v->renderer) != 0) {
    disable_sdl(v, "SDL window creation failed");
    return false;
  }
  SDL_SetWindowTitle(v->window, "riscv32-NPC");
  v->texture = SDL_CreateTexture(v->renderer, SDL_PIXELFORMAT_ARGB8888,
                                 SDL_TEXTUREACCESS_STREAMING,
                                 (int)NPC_SCREEN_WIDTH, (int)NPC_SCREEN_HEIGHT);
  if (!v->texture) { disable_sdl(v, "SDL texture creation failed"); return false; }
  SDL_SetTextureBlendMode(v->texture, SDL_BLENDMODE_NONE);
  return true;
}

/* SDL 键盘事件路由到键盘设备 — 通过公共接口 npc_kbd_push_event() 解耦 */
static void handle_sdl_event(VgaState *v, const SDL_Event *ev) {
  switch (ev->type) {
    case SDL_QUIT:
    case SDL_WINDOWEVENT:
      if (ev->type == SDL_QUIT || ev->window.event == SDL_WINDOWEVENT_CLOSE) {
        disable_sdl(v, "NPC SDL window closed; continue headless");
      }
      return;
    case SDL_KEYDOWN: case SDL_KEYUP: {
      if (ev->key.repeat) return;
      int sc = (int)ev->key.keysym.scancode;
      if (sc < 0 || sc >= 512) return;
      int keycode = v->keymap[sc];
      if (keycode != AM_KEY_NONE) {
        npc_kbd_push_event(keycode, ev->type == SDL_KEYDOWN);
      }
      return;
    }
    default: return;
  }
}
#endif

/* ---- 内部操作 ---- */
static void vga_present(VgaState *v) {
  if (!v->enabled) return;
  v->ctrl_regs[1] = 0;
  v->sync_pending = false;
#if NPC_HAS_SDL
  if (!ensure_window(v)) return;
  SDL_UpdateTexture(v->texture, NULL, v->framebuffer,
                    (int)(NPC_SCREEN_WIDTH * sizeof(uint32_t)));
  SDL_RenderClear(v->renderer);
  SDL_RenderCopy(v->renderer, v->texture, NULL, NULL);
  SDL_RenderPresent(v->renderer);
#endif
}

/* ---- MMIO 回调 ---- */
static uint32_t vga_ctrl_read_cb(void *opaque, uint32_t offset, bool *error) {
  (void)opaque;
  if ((offset & 0x3u) || offset + 4 > sizeof(g_vga.ctrl_regs)) {
    if (error) *error = true; return 0;
  }
  return g_vga.ctrl_regs[offset >> 2];
}

static void vga_ctrl_write_cb(void *opaque, uint32_t offset, uint32_t data,
                               uint32_t mask, bool *error) {
  (void)opaque;
  if ((offset & 0x3u) || offset + 4 > sizeof(g_vga.ctrl_regs)) {
    if (error) *error = true; return;
  }
  if (!g_vga.enabled) return;
  uint32_t idx = offset >> 2;
  if (idx == 0) return; /* 宽高只读 */
  store_masked((uint8_t *)&g_vga.ctrl_regs[idx], data, mask);
  if (idx == 1 && g_vga.ctrl_regs[1] != 0) g_vga.sync_pending = true;
}

static uint32_t fb_read_cb(void *opaque, uint32_t offset, bool *error) {
  (void)opaque;
  if ((offset & 0x3u) || offset + 4 > g_vga.fb_size) {
    if (error) *error = true; return 0;
  }
  if (!g_vga.enabled) return 0;
  return load_u32(g_vga.framebuffer + offset);
}

static void fb_write_cb(void *opaque, uint32_t offset, uint32_t data,
                         uint32_t mask, bool *error) {
  (void)opaque;
  if ((offset & 0x3u) || offset + 4 > g_vga.fb_size) {
    if (error) *error = true; return;
  }
  if (!g_vga.enabled) return;
  store_masked(g_vga.framebuffer + offset, data, mask);
}

/* ---- 公共接口 ---- */
void npc_vga_init(bool enable) {
  memset(&g_vga, 0, sizeof(g_vga));
  g_vga.enabled = enable;
  g_vga.fb_size = NPC_FB_MAP_SIZE;
  g_vga.framebuffer = (uint8_t *)calloc(1, g_vga.fb_size);
  if (!g_vga.framebuffer) { perror("[npc] calloc fb"); abort(); }
  g_vga.ctrl_regs[0] = enable ? ((NPC_SCREEN_WIDTH << 16) | NPC_SCREEN_HEIGHT) : 0;
  g_vga.ctrl_regs[1] = 0;
  if (!enable) {
    LogBoth("NPC VGA disabled; GPU_CONFIG will report present=false.");
  }
#if NPC_HAS_SDL
  g_vga.sdl_disabled = false;
  g_vga.sdl_initialized = false;
  memset(g_vga.keymap, 0, sizeof(g_vga.keymap));
#define NPC_SDL_KEYMAP_ENTRY(key) g_vga.keymap[SDL_SCANCODE_##key] = AM_KEY_##key;
  NPC_AM_KEYS(NPC_SDL_KEYMAP_ENTRY)
#undef NPC_SDL_KEYMAP_ENTRY
#else
  LogBoth("SDL2 not found; NPC VGA runs headless.");
#endif

  /* 注册 vgactl 和 framebuffer 两段 MMIO */
  npc_add_mmio_map("vgactl",      NPC_VGACTL_ADDR, 8,
                   NULL, vga_ctrl_read_cb, vga_ctrl_write_cb);
  npc_add_mmio_map("framebuffer", NPC_FB_ADDR, NPC_FB_MAP_SIZE,
                   NULL, fb_read_cb, fb_write_cb);
}

void npc_vga_shutdown(void) {
#if NPC_HAS_SDL
  destroy_window(&g_vga);
#endif
  free(g_vga.framebuffer);
  g_vga.framebuffer = NULL;
  g_vga.enabled = false;
}

void npc_vga_poll(void) {
  if (!g_vga.enabled) return;
#if NPC_HAS_SDL
  if (g_vga.sdl_initialized) {
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) handle_sdl_event(&g_vga, &ev);
  }
#endif
  if (g_vga.sync_pending) vga_present(&g_vga);
}

#define _GNU_SOURCE

#include <SDL.h>

#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/*
 * 这个 preload shim 只服务于 virtio-input 回归。首次观察到 SDL 队列已经
 * 排空后开始计时，给 guest 留出配置 virtqueue 的时间，再依次合成 A 按下、
 * SDL repeat、A 抬起。它不改变 NEMU 产品代码，也不依赖真实窗口焦点。
 */
typedef int (SDLCALL *SdlPollEventFn)(SDL_Event *event);

static SdlPollEventFn real_poll_event;
static unsigned int inject_stage;
static struct timespec armed_at;

static void resolve_real_poll_event(void) {
  if (real_poll_event != NULL) return;
  void *symbol = dlsym(RTLD_NEXT, "SDL_PollEvent");
  if (symbol == NULL) {
    fprintf(stderr, "virtio-input SDL shim: dlsym failed: %s\n", dlerror());
    abort();
  }
  memcpy(&real_poll_event, &symbol, sizeof(real_poll_event));
}

static bool injection_due(void) {
  struct timespec now;
  if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) abort();
  int64_t elapsed_ms = (int64_t)(now.tv_sec - armed_at.tv_sec) * 1000 +
      (now.tv_nsec - armed_at.tv_nsec) / 1000000;
  return elapsed_ms >= 50;
}

static int inject_key(SDL_Event *event, uint32_t type, uint8_t repeat) {
  memset(event, 0, sizeof(*event));
  event->type = type;
  event->key.type = type;
  event->key.state = type == SDL_KEYDOWN ? SDL_PRESSED : SDL_RELEASED;
  event->key.repeat = repeat;
  event->key.keysym.scancode = SDL_SCANCODE_A;
  event->key.keysym.sym = SDLK_a;
  return 1;
}

int SDLCALL SDL_PollEvent(SDL_Event *event) {
  resolve_real_poll_event();

  if (inject_stage >= 1 && inject_stage <= 3 && event != NULL &&
      injection_due()) {
    unsigned int stage = inject_stage++;
    fprintf(stderr, "__NEMU_VIRTIO_INPUT_SDL_SHIM__:inject=%u\n", stage);
    if (stage == 1) return inject_key(event, SDL_KEYDOWN, 0);
    if (stage == 2) return inject_key(event, SDL_KEYDOWN, 1);
    return inject_key(event, SDL_KEYUP, 0);
  }

  int result = real_poll_event(event);
  if (inject_stage == 0 && result == 0) {
    if (clock_gettime(CLOCK_MONOTONIC, &armed_at) != 0) abort();
    inject_stage = 1;
    fprintf(stderr, "__NEMU_VIRTIO_INPUT_SDL_SHIM__:armed\n");
  }
  return result;
}

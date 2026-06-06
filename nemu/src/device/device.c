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

#include <common.h>
#include <utils.h>
#include <device/alarm.h>
#ifndef CONFIG_TARGET_AM
#include <SDL2/SDL.h>
#endif

void init_map();
void init_serial();
void serial_poll_input();
void init_timer();
void init_vga();
void init_i8042();
void init_audio();
void init_disk();
void init_syscon_reset();
void init_sdcard();
void init_alarm();

void send_key(uint8_t, bool);
void vga_update_screen();

// 先按 guest 指令数做粗粒度节流，避免每条指令都查询一次宿主时间。
// 这样做不会改变 60Hz 左右的设备刷新语义，但能显著降低 get_time() 的累计开销。
#define DEVICE_UPDATE_CHECK_INTERVAL 64

void device_update() {
  static uint32_t skip = 0;
  static uint64_t last = 0;

  if (++skip < DEVICE_UPDATE_CHECK_INTERVAL) {
    return;
  }
  skip = 0;

  uint64_t now = get_time();
  if (now - last < 1000000 / TIMER_HZ) {
    return;
  }
  last = now;

  // UART RX 来自宿主 stdin/FIFO，需要在 guest 没有主动轮询寄存器时也能触发中断。
  IFDEF(CONFIG_HAS_SERIAL, serial_poll_input());
  IFDEF(CONFIG_HAS_VGA, vga_update_screen());

#ifndef CONFIG_TARGET_AM
  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        nemu_state.state = NEMU_QUIT;
        break;
#ifdef CONFIG_HAS_KEYBOARD
      // If a key was pressed
      case SDL_KEYDOWN:
      case SDL_KEYUP: {
        uint8_t k = event.key.keysym.scancode;
        bool is_keydown = (event.key.type == SDL_KEYDOWN);
        send_key(k, is_keydown);
        break;
      }
#endif
      default: break;
    }
  }
#endif
}

void sdl_clear_event_queue() {
#ifndef CONFIG_TARGET_AM
  SDL_Event event;
  while (SDL_PollEvent(&event));
#endif
}

void init_device() {
  IFDEF(CONFIG_TARGET_AM, ioe_init());
  init_map();

  IFDEF(CONFIG_HAS_SERIAL, init_serial());
  IFDEF(CONFIG_HAS_TIMER, init_timer());
  IFDEF(CONFIG_HAS_VGA, init_vga());
  IFDEF(CONFIG_HAS_KEYBOARD, init_i8042());
  IFDEF(CONFIG_HAS_AUDIO, init_audio());
  IFDEF(CONFIG_HAS_DISK, init_disk());
  IFDEF(CONFIG_HAS_SYSCON_RESET, init_syscon_reset());
  IFDEF(CONFIG_HAS_SDCARD, init_sdcard());

  IFNDEF(CONFIG_TARGET_AM, init_alarm());
}

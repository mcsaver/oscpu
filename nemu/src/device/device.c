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
void virtio_blk_update();
void init_virtio_rng();
void init_virtio_net();
void init_goldfish_rtc();
void init_syscon_reset();
void init_sdcard();
void init_alarm();
void goldfish_rtc_update();

void send_key(uint8_t, bool);
void vga_update_screen();

// 先按 guest 指令数做粗粒度节流，避免每条指令都查询一次宿主时间。
// Ubuntu performance 配置会把该间隔调大；真正的可见刷新仍由下面的 60Hz host time gate 控制。
#define DEVICE_UPDATE_CHECK_INTERVAL ((uint64_t)CONFIG_DEVICE_UPDATE_CHECK_INTERVAL)

void device_update_after_inst(uint64_t retired) {
  static uint64_t skip = 0;
  static uint64_t last = 0;

  if (retired == 0) {
    return;
  }

  // TB 批执行时一次可能退休多条指令，这里按 guest 指令数累计，
  // 让设备刷新频率保持原语义，同时避免 CPU 热路径每条指令都调用本函数。
  skip += retired;
  if (skip < DEVICE_UPDATE_CHECK_INTERVAL) {
    return;
  }
  skip = 0;

  // virtio-blk worker 只做 host I/O；完成写回必须回到主线程轮询，避免并发写 guest PMEM。
  IFDEF(CONFIG_HAS_DISK, virtio_blk_update());

  uint64_t now = get_time();
  if (now - last < 1000000 / TIMER_HZ) {
    return;
  }
  last = now;

  // UART RX 来自宿主 stdin/FIFO，需要在 guest 没有主动轮询寄存器时也能触发中断。
  IFDEF(CONFIG_HAS_SERIAL, serial_poll_input());
  IFDEF(CONFIG_HAS_GOLDFISH_RTC, goldfish_rtc_update());
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

void device_update() {
  device_update_after_inst(1);
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
  IFDEF(CONFIG_HAS_VIRTIO_RNG, init_virtio_rng());
  IFDEF(CONFIG_HAS_VIRTIO_NET, init_virtio_net());
  IFDEF(CONFIG_HAS_GOLDFISH_RTC, init_goldfish_rtc());
  IFDEF(CONFIG_HAS_SYSCON_RESET, init_syscon_reset());
  IFDEF(CONFIG_HAS_SDCARD, init_sdcard());

  IFNDEF(CONFIG_TARGET_AM, init_alarm());
}

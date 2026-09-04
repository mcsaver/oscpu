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
#include <utils/profile.h>
#include <device/alarm.h>
#ifdef NEMU_HAS_SDL
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
void virtio_net_update();
void init_virtio_input();
void virtio_input_update();
void init_goldfish_rtc();
void init_syscon_reset();
void init_sdcard();
void init_alarm();
void goldfish_rtc_update();

void send_key(uint8_t, bool);
void virtio_input_send_sdl_key(uint32_t, bool);
void vga_update_screen();

// 先按 guest 指令数做粗粒度节流，避免每条指令都查询一次宿主时间。
// policy header 会在 performance 构建中增大该间隔；真正的可见刷新仍由
// 下面的 60Hz host time gate 控制。

void device_update_after_inst(uint64_t attempted) {
  static uint64_t skip = 0;
  static uint64_t last = 0;

  if (attempted == 0) {
    return;
  }
  bool profile_on = unlikely(nemu_profile_enabled());
  if (profile_on) {
    nemu_profile_count(NEMU_PROFILE_DEVICE_UPDATE_CALLS, 1);
    nemu_profile_count(NEMU_PROFILE_DEVICE_UPDATE_ATTEMPTS, attempted);
  }

  // TB 批执行时一次可能尝试多条指令。设备节流按尝试数累计，
  // 不冒充架构 minstret 的成功退休计数；同步异常循环仍能推进设备。
  skip += attempted;
  if (skip < (uint64_t)NEMU_DEVICE_UPDATE_CHECK_INTERVAL) {
    if (profile_on) {
      nemu_profile_count(NEMU_PROFILE_DEVICE_INTERVAL_SKIPS, 1);
    }
    return;
  }
  skip = 0;
  uint64_t interval_start = profile_on ? get_time() : 0;
  if (profile_on) {
    nemu_profile_count(NEMU_PROFILE_DEVICE_INTERVAL_FIRES, 1);
  }

  // virtio-blk worker 只做 host I/O；完成写回必须回到主线程轮询，避免并发写 guest PMEM。
#ifdef CONFIG_HAS_DISK
  uint64_t virtio_start = profile_on ? get_time() : 0;
  virtio_blk_update();
  if (profile_on) {
    nemu_profile_count(NEMU_PROFILE_DEVICE_VIRTIO_BLK_US,
        get_time() - virtio_start);
  }
#endif
  IFDEF(CONFIG_HAS_VIRTIO_NET, virtio_net_update());
  IFDEF(CONFIG_HAS_VIRTIO_INPUT, virtio_input_update());

  uint64_t now = get_time();
  if (now - last < 1000000 / TIMER_HZ) {
    if (profile_on) {
      nemu_profile_count(NEMU_PROFILE_DEVICE_TIME_SKIPS, 1);
      nemu_profile_count(NEMU_PROFILE_DEVICE_INTERVAL_US,
          get_time() - interval_start);
    }
    return;
  }
  last = now;
  uint64_t visible_start = profile_on ? get_time() : 0;

  // UART RX 来自宿主 stdin/FIFO，需要在 guest 没有主动轮询寄存器时也能触发中断。
  IFDEF(CONFIG_HAS_SERIAL, serial_poll_input());
  IFDEF(CONFIG_HAS_GOLDFISH_RTC, goldfish_rtc_update());
  IFDEF(CONFIG_HAS_VGA, vga_update_screen());

#ifdef NEMU_HAS_SDL
  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        nemu_state.state = NEMU_QUIT;
        break;
#if defined(CONFIG_HAS_KEYBOARD) || defined(CONFIG_HAS_VIRTIO_INPUT)
      // 同一个 SDL 事件可同时送往 legacy AM keyboard 和标准 virtio-input。
      case SDL_KEYDOWN:
      case SDL_KEYUP: {
        bool is_keydown = (event.key.type == SDL_KEYDOWN);
#ifdef CONFIG_HAS_KEYBOARD
        uint8_t k = event.key.keysym.scancode;
        send_key(k, is_keydown);
#endif
#ifdef CONFIG_HAS_VIRTIO_INPUT
        // Linux input core 负责 EV_REP；过滤 SDL 自动重复，避免双重 repeat。
        if (event.key.repeat == 0) {
          virtio_input_send_sdl_key(event.key.keysym.scancode, is_keydown);
        }
#endif
        break;
      }
#endif
      default: break;
    }
  }
#endif
  if (profile_on) {
    nemu_profile_count(NEMU_PROFILE_DEVICE_VISIBLE_TICKS, 1);
    nemu_profile_count(NEMU_PROFILE_DEVICE_VISIBLE_US, get_time() - visible_start);
    nemu_profile_count(NEMU_PROFILE_DEVICE_INTERVAL_US,
        get_time() - interval_start);
  }
}

void device_update() {
  device_update_after_inst(1);
}

void sdl_clear_event_queue() {
#ifdef NEMU_HAS_SDL
  SDL_Event event;
  while (SDL_PollEvent(&event));
#endif
}

//设备初始化
void init_device() {
  IFDEF(CONFIG_TARGET_AM, ioe_init());
  init_map();

  IFDEF(CONFIG_HAS_SERIAL, init_serial());
  IFDEF(CONFIG_HAS_TIMER, init_timer());
  IFDEF(CONFIG_HAS_VGA, init_vga());
  IFDEF(CONFIG_HAS_KEYBOARD, init_i8042());
  IFDEF(CONFIG_HAS_VIRTIO_INPUT, init_virtio_input());
  IFDEF(CONFIG_HAS_AUDIO, init_audio());
  IFDEF(CONFIG_HAS_DISK, init_disk());
  IFDEF(CONFIG_HAS_VIRTIO_RNG, init_virtio_rng());
  IFDEF(CONFIG_HAS_VIRTIO_NET, init_virtio_net());
  IFDEF(CONFIG_HAS_GOLDFISH_RTC, init_goldfish_rtc());
  IFDEF(CONFIG_HAS_SYSCON_RESET, init_syscon_reset());
  IFDEF(CONFIG_HAS_SDCARD, init_sdcard());

  IFNDEF(CONFIG_TARGET_AM, init_alarm());
}

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

//提供一个可读的RTC设备寄存器，以及在非AM模式下额外制造周其性时钟中断

#include <device/map.h>
#include <device/alarm.h>
#include <utils.h>

//顶一个了一个8字节的设备后端缓冲区指针rtc_port_base
static uint32_t *rtc_port_base = NULL;

static const IoRegisterDescriptor rtc_registers[] __attribute__((unused)) = {
  {
    .name = "uptime-low-high",
    .first_offset = 0,
    .last_offset = 7,
    .stride = 4,
    .width_mask = IO_WIDTH_4,
    .direction_mask = IO_TRANSACTION_READ,
    .naturally_aligned = true,
  },
};

static const IoAccessPolicy rtc_mmio_policy __attribute__((unused)) = {
  .registers = rtc_registers,
  .register_count = ARRLEN(rtc_registers),
};

//它只接受offset为0或者4也就是低32位和高32位，真正刷新时间值的动作只发生在读offset=4时候
//也就是读高32位的之后，这时候它调用get_time()取得当前微秒
//然后把低32位写道rtc_port_base[0]，高32位写道rtc_port_base[1]，与总线的时序配套

static void rtc_io_handler(uint32_t offset, int len, bool is_write) {
  assert(offset == 0 || offset == 4);
  if (!is_write && offset == 4) {
    uint64_t us = get_time();
    rtc_port_base[0] = (uint32_t)us;
    rtc_port_base[1] = us >> 32;
  }
}

#ifndef CONFIG_TARGET_AM
static void timer_intr() {
  if (nemu_state.state == NEMU_RUNNING) {
    extern void dev_raise_intr();
    dev_raise_intr();
  }
}
#endif

//初始化分配一个8字节，暴露了两个32位寄存器
void init_timer() {
  rtc_port_base = (uint32_t *)new_space(8);
#ifdef NEMU_HAS_PORT_IO
  add_pio_map ("rtc", CONFIG_RTC_PORT, rtc_port_base, 8, rtc_io_handler);
#else
  add_mmio_map_with_policy("rtc", DEV_RTC_MMIO, rtc_port_base, 8,
      rtc_io_handler, &rtc_mmio_policy);
#endif
  IFNDEF(CONFIG_TARGET_AM, add_alarm_handle(timer_intr));
}

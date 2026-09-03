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
#include <device/map.h>
#include <SDL2/SDL.h>

enum {
  reg_freq,
  reg_channels,
  reg_samples,
  reg_sbuf_size,
  reg_init,
  reg_count,
  nr_reg
};

static uint8_t *sbuf = NULL;
static uint32_t *audio_base = NULL;

static const IoRegisterDescriptor audio_control_registers[]
    __attribute__((unused)) = {
  {
    .name = "control",
    .first_offset = 0,
    .last_offset = sizeof(uint32_t) * nr_reg - 1u,
    .stride = sizeof(uint32_t),
    .width_mask = IO_WIDTH_4,
    .direction_mask = IO_TRANSACTION_READ | IO_TRANSACTION_WRITE,
    .naturally_aligned = true,
  },
};

static const IoAccessPolicy audio_control_mmio_policy
    __attribute__((unused)) = {
  .registers = audio_control_registers,
  .register_count = ARRLEN(audio_control_registers),
};

static void audio_io_handler(uint32_t offset, int len, bool is_write) {
}

void init_audio() {
  uint32_t space_size = sizeof(uint32_t) * nr_reg;
  audio_base = (uint32_t *)new_space(space_size);
#ifdef NEMU_HAS_PORT_IO
  add_pio_map ("audio", CONFIG_AUDIO_CTL_PORT, audio_base, space_size, audio_io_handler);
#else
  add_mmio_map_with_policy("audio", DEV_AUDIO_CTL_MMIO, audio_base,
      space_size, audio_io_handler, &audio_control_mmio_policy);
#endif

  sbuf = (uint8_t *)new_space(CONFIG_SB_SIZE);
  add_mmio_map("audio-sbuf", DEV_SB_ADDR, sbuf, CONFIG_SB_SIZE, NULL);
}

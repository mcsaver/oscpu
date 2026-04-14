#include <am.h>

#include "npc.h"

#define KEYDOWN_MASK 0x8000

// NPC 仿真端现在按 NEMU/AM 兼容格式返回键盘事件，高位表示 keydown，低位表示 keycode。
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t key_reg = inl(KBD_ADDR);
  kbd->keydown = (key_reg & KEYDOWN_MASK) != 0;
  kbd->keycode = key_reg & ~KEYDOWN_MASK;
}

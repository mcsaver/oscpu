#include <am.h>
#include <nemu.h>

#define KEYDOWN_MASK 0x8000

// 这里把一次寄存器读取拆成 keydown 和 keycode，避免重复读 KBD_ADDR 造成事件被多次消费。
// 改完后 AM 输入层拿到的是稳定的一次键盘事件，而不是依赖宿主终端字符流。
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t KEY_reg = inl(KBD_ADDR);
  bool key_d = (KEY_reg & KEYDOWN_MASK) != 0;
  kbd->keydown = key_d;
  kbd->keycode = KEY_reg & ~KEYDOWN_MASK;
}

#include <am.h>
#include <nemu.h>

#define KEYDOWN_MASK 0x8000

// 这里把一次寄存器读取拆成 keydown 和 keycode，避免重复读 KBD_ADDR 造成事件被多次消费。
// 改完后 AM 输入层拿到的是稳定的一次键盘事件，而不是依赖宿主终端字符流。
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
  // 设备树无简易键盘: 恒返回无按键, 不触碰 NEMU 未实现的 KBD_ADDR。
  kbd->keydown = false;
  kbd->keycode = AM_KEY_NONE;
#else
  uint32_t KEY_reg = inl(KBD_ADDR);
  bool key_d = (KEY_reg & KEYDOWN_MASK) != 0;
  kbd->keydown = key_d;
  kbd->keycode = KEY_reg & ~KEYDOWN_MASK;
#endif
}

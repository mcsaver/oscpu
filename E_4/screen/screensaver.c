#include <am.h>
#include <stdbool.h>

/*
 * 可定制化屏幕保护程序：
 * - 固定窗口分辨率 400x300（题目要求）
 * - 在 COLORS 列表中随机选取目标颜色，并在 STEPS 步间线性插值完成一次渐变
 * - 每步停留 STEP_MS 毫秒
 * - draw() 使用静态复用的行缓冲，避免频繁 malloc/free
 */

#define W_PIXELS 400
#define H_PIXELS 300

/* 渐变步数（每轮的细分步数，越大越平滑） */
#define STEPS 100
/* 每步的默认持续时间（毫秒） */
#define STEP_MS 50
/* 按键加速时的最小每步时间（毫秒） */
#define MIN_STEP_MS 5
/* 恢复速率：每步恢复的毫秒数（用于释放按键后逐步恢复到 STEP_MS） */
#define RECOVER_STEP 1

/* 可配置颜色表（0xRRGGBB）——你可以按需修改或拓展 */
static const uint32_t COLORS[] = {
  0x000000, 0xff0000, 0x00ff00, 0x0000ff,
  0xffff00, 0xff00ff, 0x00ffff, 0xffffff
};
static const int NUM_COLORS = sizeof(COLORS) / sizeof(COLORS[0]);

/* 键名表，便于打印按键名称（参照 am-kernels/tests/am-tests/src/tests/keyboard.c） */
#define NAMEINIT(key)  [ AM_KEY_##key ] = #key,
static const char *key_names[] = {
  AM_KEYS(NAMEINIT)
};

/* 复用的行缓冲 */
static uint32_t row_buf[W_PIXELS];

/* 极简 PRNG：线性同余发生器 */
static unsigned rng_state = 1u;
static inline void my_srand(unsigned s){ rng_state = s ? s : 1u; }
static inline int  my_rand(){ rng_state = rng_state * 1103515245u + 12345u; return (int)((rng_state >> 16) & 0x7fff); }

/* helper: 线性插值颜色（i 从 0..steps） */
//uint32_t c = lerp_color(cur, target, step, STEPS); cur为颜色，target为目标颜色，step是现在平滑的进程数，STEPS是总进程数，在宏定义中
static uint32_t lerp_color(uint32_t c0, uint32_t c1, int i, int steps) {
  int r0 = (c0 >> 16) & 0xff;
  int g0 = (c0 >> 8) & 0xff;
  int b0 = c0 & 0xff;
  int r1 = (c1 >> 16) & 0xff;
  int g1 = (c1 >> 8) & 0xff;
  int b1 = c1 & 0xff;
  int r = r0 + (r1 - r0) * i / steps;
  int g = g0 + (g1 - g0) * i / steps;
  int b = b0 + (b1 - b0) * i / steps;
  return ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
}

/* draw: 使用复用行缓冲把屏幕填充为 color（400x300） */
void draw(uint32_t color) {
  const int W = W_PIXELS;
  const int H = H_PIXELS;
  for (int x = 0; x < W; x++) row_buf[x] = color;
  for (int y = 0; y < H; y++) {
    AM_GPU_FBDRAW_T ctl = { .x = 0, .y = y, .pixels = row_buf, .w = W, .h = 1, .sync = false };
    ioe_write(AM_GPU_FBDRAW, &ctl);
  }
  AM_GPU_FBDRAW_T sync = { .x = 0, .y = 0, .pixels = NULL, .w = 0, .h = 0, .sync = true };
  ioe_write(AM_GPU_FBDRAW, &sync);
}

/* 获取当前毫秒（从 AM_TIMER_UPTIME） */
static unsigned long now_ms() {
  AM_TIMER_UPTIME_T t; ioe_read(AM_TIMER_UPTIME, &t);
  return (unsigned long)(t.us / 1000);
}

int main() {
  ioe_init();

  /* 随机种子，用 uptime 的低位 */
  unsigned long seed = now_ms();
  my_srand((unsigned)seed);

  /* 初始颜色索引 */
  int idx = my_rand() % NUM_COLORS;
  uint32_t cur = COLORS[idx];
  draw(cur);

  int current_ms = STEP_MS;
  int target_ms = STEP_MS;

  while (1) {
    /* 选择一个不同的目标颜色 */
  int target_idx = idx;
  while (target_idx == idx) target_idx = my_rand() % NUM_COLORS;
    uint32_t target = COLORS[target_idx];

    /* 在 STEPS 步内从 cur -> target 线性插值 */
    for (int step = 1; step <= STEPS; step++) {
      uint32_t c = lerp_color(cur, target, step, STEPS);

      /* 读取键盘状态：如果按下 ESC 则退出；按下其他任意键则进入加速模式
       * 同时把按键打印到终端，便于调试和观察。参考 keyboard_test 的实现。
       */
  AM_INPUT_KEYBRD_T kbd; ioe_read(AM_INPUT_KEYBRD, &kbd);
      (void)key_names; // 本地最简实现：不打印按键信息，避免依赖 printf
      if (kbd.keydown) {
        if (kbd.keycode == AM_KEY_ESCAPE) {
          /* 退出程序，释放缓冲（可选）并返回 */
          return 0;
        } else {
          /* 任何其它按键按下都使目标每步时间变小（加速） */
          target_ms = MIN_STEP_MS;
        }
      } else {
        /* 未按键：目标恢复到默认值 */
        target_ms = STEP_MS;
      }

      /* 逐步将 current_ms 朝 target_ms 靠拢，以实现按键释放后渐进恢复的效果 */
      if (current_ms > target_ms) {
        current_ms -= RECOVER_STEP;
        if (current_ms < target_ms) current_ms = target_ms;
      } else if (current_ms < target_ms) {
        current_ms += 1;
        if (current_ms > target_ms) current_ms = target_ms;
      }

      unsigned long t0 = now_ms();
      draw(c);
      /* 等待 current_ms 毫秒（粗略 busy-wait） */
      while (now_ms() - t0 < (unsigned long)current_ms) ;
    }

    /* 切换到下一个颜色 */
    idx = target_idx;
    cur = target;
  }

  return 0;
}
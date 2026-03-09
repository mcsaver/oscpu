#include <amtest.h>

#define FPS 30
#define N   32

static inline uint32_t pixel(uint8_t r, uint8_t g, uint8_t b) {
  return (r << 16) | (g << 8) | b;
}
static inline uint8_t R(uint32_t p) { return p >> 16; }
static inline uint8_t G(uint32_t p) { return p >> 8; }
static inline uint8_t B(uint32_t p) { return p; }

//保存每个方块的当前颜色
static uint32_t canvas[N][N];
//标记每个方块是否已被本轮访问
static int used[N][N];
//临时缓冲区，用于批量写入一块区域的像素
static uint32_t color_buf[32 * 32];

//计算每个方块在屏幕上的实际像素区域（根据屏幕分辨率和N)
//用io_write把每个方块颜色批量写道显存
//最后用io_write刷新屏幕
void redraw() {
  int w = io_read(AM_GPU_CONFIG).width / N;
  int h = io_read(AM_GPU_CONFIG).height / N;
  int block_size = w * h;
  assert((uint32_t)block_size <= LENGTH(color_buf));

  int x, y, k;
  for (y = 0; y < N; y ++) {
    for (x = 0; x < N; x ++) {
      for (k = 0; k < block_size; k ++) {
        color_buf[k] = canvas[y][x];
      }
      io_write(AM_GPU_FBDRAW, x * w, y * h, color_buf, w, h, false);
    }
  }
  io_write(AM_GPU_FBDRAW, 0, 0, NULL, 0, 0, true);
}

//生成一个RGB颜色，颜色随时间变化，形成动态渐变
static uint32_t p(int tsc) {
  int b = tsc & 0xff;
  return pixel(b * 6, b * 7, b);
}

//以螺旋的顺序从(0,0)开始依次填充所有方块
//每个方块的颜色由p(tsc+step/2)决定，tsc随时间递增，保证动画不断变化
//used数组保证每个方块只被访问以此
void update() {
  static int tsc = 0;
  static int dx[4] = {0, 1, 0, -1};
  static int dy[4] = {1, 0, -1, 0};

  tsc ++;

  for (int i = 0; i < N; i ++)
    for (int j = 0; j < N; j ++) {
      used[i][j] = 0;
    }

  int init = tsc * 1;
  canvas[0][0] = p(init); used[0][0] = 1;
  int x = 0, y = 0, d = 0;
  for (int step = 1; step < N * N; step ++) {
    for (int t = 0; t < 4; t ++) {
      int x1 = x + dx[d], y1 = y + dy[d];
      if (x1 >= 0 && x1 < N && y1 >= 0 && y1 < N && !used[x1][y1]) {
        x = x1; y = y1;
        used[x][y] = 1;
        canvas[x][y] = p(init + step / 2);
        break;
      }
      d = (d + 1) % 4;
    }
  }
}

//主循环
//持续循环，每隔1/FPS秒刷新以此画面
//每秒统计并打印以此FPS
void video_test() {
  unsigned long last = 0;
  unsigned long fps_last = 0;
  int fps = 0;

  while (1) {
    unsigned long upt = io_read(AM_TIMER_UPTIME).us / 1000;
    if (upt - last > 1000 / FPS) {
      update();
      redraw();
      last = upt;
      fps ++;
    }
    if (upt - fps_last > 1000) {
      // display fps every 1s
      printf("%d: FPS = %d\n", upt, fps);
      fps_last = upt;
      fps = 0;
    }
  }
}

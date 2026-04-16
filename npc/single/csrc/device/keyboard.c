/* NPC 键盘设备
 * 学习 NEMU 的 IO/设备分层：设备行为独立成文件，状态 static 管理。
 * 支持 TTY raw mode 和 scripted stdin 两种模式，
 * 把宿主输入编码成 NEMU/AM 兼容的 keydown/keycode 事件流。
 * VGA 的 SDL 事件通过 npc_kbd_push_event() 推入同一个环形缓冲区。 */
#include "device/keyboard.h"
#include "device/map.h"
#include "utils.h"

#include <ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include <fcntl.h>
#include <poll.h>
#include <termios.h>
#include <unistd.h>

/* ---- 模块内部静态状态 ---- */
#define KBD_RING_SIZE 256

typedef struct {
  bool enabled;
  bool terminal_configured;
  struct termios saved_termios;
  int saved_flags;
  uint32_t ring[KBD_RING_SIZE];
  int ring_head;
  int ring_tail;
} KbdState;

static KbdState g_kbd;

/* ---- 环形缓冲区 ---- */
static bool ring_empty(const KbdState *k) { return k->ring_head == k->ring_tail; }

static void ring_push(KbdState *k, uint32_t ev) {
  int next = (k->ring_tail + 1) % KBD_RING_SIZE;
  if (next == k->ring_head) return; /* 满则丢弃 */
  k->ring[k->ring_tail] = ev;
  k->ring_tail = next;
}

static uint32_t ring_pop(KbdState *k) {
  if (ring_empty(k)) return (uint32_t)AM_KEY_NONE;
  uint32_t ev = k->ring[k->ring_head];
  k->ring_head = (k->ring_head + 1) % KBD_RING_SIZE;
  return ev;
}

static void push_event(KbdState *k, int keycode, bool keydown) {
  if (keycode == AM_KEY_NONE) return;
  ring_push(k, (keydown ? NPC_KEYDOWN_MASK : 0u) | (uint32_t)keycode);
}

static void enqueue_tap(KbdState *k, int keycode) {
  push_event(k, keycode, true);
  push_event(k, keycode, false);
}

/* ---- stdin 读取辅助 ---- */
static bool try_read_byte(uint8_t *byte) {
  struct pollfd pfd = { .fd = STDIN_FILENO, .events = POLLIN, .revents = 0 };
  if (poll(&pfd, 1, 0) <= 0 || !(pfd.revents & POLLIN)) return false;
  return read(STDIN_FILENO, byte, 1) == 1;
}

/* ---- ASCII -> AM 键码翻译 ---- */
static int translate_ascii(uint8_t ch) {
  switch (ch) {
    case '`': case '~': return AM_KEY_GRAVE;
    case '1': case '!': return AM_KEY_1;
    case '2': case '@': return AM_KEY_2;
    case '3': case '#': return AM_KEY_3;
    case '4': case '$': return AM_KEY_4;
    case '5': case '%': return AM_KEY_5;
    case '6': case '^': return AM_KEY_6;
    case '7': case '&': return AM_KEY_7;
    case '8': case '*': return AM_KEY_8;
    case '9': case '(': return AM_KEY_9;
    case '0': case ')': return AM_KEY_0;
    case '-': case '_': return AM_KEY_MINUS;
    case '=': case '+': return AM_KEY_EQUALS;
    case '\t':          return AM_KEY_TAB;
    case '[': case '{': return AM_KEY_LEFTBRACKET;
    case ']': case '}': return AM_KEY_RIGHTBRACKET;
    case '\\': case '|': return AM_KEY_BACKSLASH;
    case ';': case ':': return AM_KEY_SEMICOLON;
    case '\'': case '"': return AM_KEY_APOSTROPHE;
    case ',': case '<': return AM_KEY_COMMA;
    case '.': case '>': return AM_KEY_PERIOD;
    case '/': case '?': return AM_KEY_SLASH;
    case ' ':           return AM_KEY_SPACE;
    case '\r': case '\n': return AM_KEY_RETURN;
    case 0x08: case 0x7f: return AM_KEY_BACKSPACE;
    default: break;
  }
  switch (tolower((unsigned char)ch)) {
    case 'a': return AM_KEY_A; case 'b': return AM_KEY_B;
    case 'c': return AM_KEY_C; case 'd': return AM_KEY_D;
    case 'e': return AM_KEY_E; case 'f': return AM_KEY_F;
    case 'g': return AM_KEY_G; case 'h': return AM_KEY_H;
    case 'i': return AM_KEY_I; case 'j': return AM_KEY_J;
    case 'k': return AM_KEY_K; case 'l': return AM_KEY_L;
    case 'm': return AM_KEY_M; case 'n': return AM_KEY_N;
    case 'o': return AM_KEY_O; case 'p': return AM_KEY_P;
    case 'q': return AM_KEY_Q; case 'r': return AM_KEY_R;
    case 's': return AM_KEY_S; case 't': return AM_KEY_T;
    case 'u': return AM_KEY_U; case 'v': return AM_KEY_V;
    case 'w': return AM_KEY_W; case 'x': return AM_KEY_X;
    case 'y': return AM_KEY_Y; case 'z': return AM_KEY_Z;
    default: return AM_KEY_NONE;
  }
}

/* ---- 转义序列处理 ---- */
static void handle_escape(KbdState *k) {
  uint8_t first = 0;
  if (!try_read_byte(&first)) { enqueue_tap(k, AM_KEY_ESCAPE); return; }
  if (first == '[') {
    uint8_t second = 0;
    if (!try_read_byte(&second)) { enqueue_tap(k, AM_KEY_ESCAPE); return; }
    switch (second) {
      case 'A': enqueue_tap(k, AM_KEY_UP); return;
      case 'B': enqueue_tap(k, AM_KEY_DOWN); return;
      case 'C': enqueue_tap(k, AM_KEY_RIGHT); return;
      case 'D': enqueue_tap(k, AM_KEY_LEFT); return;
      case 'H': enqueue_tap(k, AM_KEY_HOME); return;
      case 'F': enqueue_tap(k, AM_KEY_END); return;
      case '2': case '3': case '5': case '6': {
        uint8_t third = 0;
        if (try_read_byte(&third) && third == '~') {
          switch (second) {
            case '2': enqueue_tap(k, AM_KEY_INSERT); return;
            case '3': enqueue_tap(k, AM_KEY_DELETE); return;
            case '5': enqueue_tap(k, AM_KEY_PAGEUP); return;
            case '6': enqueue_tap(k, AM_KEY_PAGEDOWN); return;
          }
        }
        break;
      }
    }
  } else if (first == 'O') {
    uint8_t second = 0;
    if (try_read_byte(&second)) {
      switch (second) {
        case 'H': enqueue_tap(k, AM_KEY_HOME); return;
        case 'F': enqueue_tap(k, AM_KEY_END); return;
      }
    }
  }
  enqueue_tap(k, AM_KEY_ESCAPE);
}

static void handle_byte(KbdState *k, uint8_t ch) {
  if (ch == 0x1b) { handle_escape(k); return; }
  enqueue_tap(k, translate_ascii(ch));
}

/* ---- MMIO 回调 ---- */
static uint32_t kbd_read_cb(void *opaque, uint32_t offset, bool *error) {
  (void)opaque; (void)error;
  if (offset != 0) return 0;
  return ring_pop(&g_kbd);
}

static void kbd_write_cb(void *o, uint32_t off, uint32_t d, uint32_t m, bool *e) {
  (void)o; (void)off; (void)d; (void)m; (void)e;
}

/* ---- 公共接口 ---- */
void npc_kbd_init(bool enable) {
  memset(&g_kbd, 0, sizeof(g_kbd));
  g_kbd.enabled = false;
  g_kbd.terminal_configured = false;

  /* 无论是否启用，都注册 MMIO 占位，保证 guest 读 KBD_ADDR 不会触发总线错误 */
  npc_add_mmio_map("keyboard", NPC_KBD_ADDR, 4, NULL, kbd_read_cb, kbd_write_cb);

  if (!enable) return;

  if (isatty(STDIN_FILENO) == 0) {
    g_kbd.enabled = true;
    fprintf(stderr, "[npc] stdin keyboard enabled in scripted mode\n");
    return;
  }
  if (tcgetattr(STDIN_FILENO, &g_kbd.saved_termios) != 0) { perror("[npc] tcgetattr"); return; }
  g_kbd.saved_flags = fcntl(STDIN_FILENO, F_GETFL, 0);
  if (g_kbd.saved_flags < 0) { perror("[npc] fcntl(F_GETFL)"); return; }

  struct termios raw = g_kbd.saved_termios;
  raw.c_lflag &= (tcflag_t)~(ICANON | ECHO);
  raw.c_iflag &= (tcflag_t)~(IXON | ICRNL);
  raw.c_oflag &= (tcflag_t)~(OPOST);
  raw.c_cc[VMIN] = 0;
  raw.c_cc[VTIME] = 0;

  if (tcsetattr(STDIN_FILENO, TCSANOW, &raw) != 0) { perror("[npc] tcsetattr"); return; }
  if (fcntl(STDIN_FILENO, F_SETFL, g_kbd.saved_flags | O_NONBLOCK) != 0) {
    perror("[npc] fcntl(F_SETFL)");
    tcsetattr(STDIN_FILENO, TCSANOW, &g_kbd.saved_termios);
    return;
  }
  g_kbd.terminal_configured = true;
  g_kbd.enabled = true;
  fprintf(stderr, "[npc] stdin keyboard enabled\n");
}

void npc_kbd_shutdown(void) {
  g_kbd.ring_head = g_kbd.ring_tail = 0;
  g_kbd.enabled = false;
  if (!g_kbd.terminal_configured) return;
  tcsetattr(STDIN_FILENO, TCSANOW, &g_kbd.saved_termios);
  fcntl(STDIN_FILENO, F_SETFL, g_kbd.saved_flags);
  g_kbd.terminal_configured = false;
}

void npc_kbd_poll(void) {
  if (!g_kbd.enabled) return;
  struct pollfd pfd = { .fd = STDIN_FILENO, .events = POLLIN, .revents = 0 };
  while (poll(&pfd, 1, 0) > 0 && (pfd.revents & POLLIN)) {
    uint8_t ch = 0;
    if (read(STDIN_FILENO, &ch, 1) != 1) break;
    handle_byte(&g_kbd, ch);
    pfd.revents = 0;
  }
}

void npc_kbd_push_event(int keycode, bool keydown) {
  push_event(&g_kbd, keycode, keydown);
}

#include "device/device.h"

#include "device/map.h"
#include "utils.h"

#include <cctype>
#include <cstdio>
#include <cstdint>
#include <deque>

#include <fcntl.h>
#include <poll.h>
#include <termios.h>
#include <unistd.h>

namespace npc {

namespace {

class KeyboardDevice {
 public:
  void Init(bool enable_stdin_keyboard) {
    enabled_ = false;
    terminal_configured_ = false;
    queue_.clear();

    if (!enable_stdin_keyboard) {
      return;
    }

    if (::isatty(STDIN_FILENO) == 0) {
      // 非 TTY 时仍然允许把 stdin 当作脚本化事件源，这样测试环境可以通过管道把按键序列喂给 NPC。
      enabled_ = true;
      std::fprintf(stderr, "[npc] stdin keyboard enabled in scripted mode\n");
      return;
    }

    if (::tcgetattr(STDIN_FILENO, &saved_termios_) != 0) {
      std::perror("[npc] tcgetattr");
      return;
    }

    saved_flags_ = ::fcntl(STDIN_FILENO, F_GETFL, 0);
    if (saved_flags_ < 0) {
      std::perror("[npc] fcntl(F_GETFL)");
      return;
    }

    termios raw = saved_termios_;
    // 这里只关掉规范模式和回显，保留 Ctrl+C 这类信号，让键盘设备可交互但不劫持终端的基本退出行为。
    raw.c_lflag &= static_cast<tcflag_t>(~(ICANON | ECHO));
    raw.c_iflag &= static_cast<tcflag_t>(~(IXON | ICRNL));
    raw.c_oflag &= static_cast<tcflag_t>(~(OPOST));
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 0;

    if (::tcsetattr(STDIN_FILENO, TCSANOW, &raw) != 0) {
      std::perror("[npc] tcsetattr");
      return;
    }

    if (::fcntl(STDIN_FILENO, F_SETFL, saved_flags_ | O_NONBLOCK) != 0) {
      std::perror("[npc] fcntl(F_SETFL)");
      ::tcsetattr(STDIN_FILENO, TCSANOW, &saved_termios_);
      return;
    }

    terminal_configured_ = true;
    enabled_ = true;
    std::fprintf(stderr, "[npc] stdin keyboard enabled\n");
  }

  void Shutdown() {
    queue_.clear();
    enabled_ = false;
    if (!terminal_configured_) {
      return;
    }

    ::tcsetattr(STDIN_FILENO, TCSANOW, &saved_termios_);
    ::fcntl(STDIN_FILENO, F_SETFL, saved_flags_);
    terminal_configured_ = false;
  }

  void PollHostInput() {
    if (!enabled_) {
      return;
    }

    pollfd pfd = {
      .fd = STDIN_FILENO,
      .events = POLLIN,
      .revents = 0,
    };

    while (::poll(&pfd, 1, 0) > 0 && (pfd.revents & POLLIN) != 0) {
      uint8_t ch = 0;
      const ssize_t read_bytes = ::read(STDIN_FILENO, &ch, 1);
      if (read_bytes != 1) {
        break;
      }
      HandleByte(ch);
      pfd.revents = 0;
    }
  }

  uint32_t ReadEvent() {
    if (queue_.empty()) {
      return static_cast<uint32_t>(AM_KEY_NONE);
    }

    const uint32_t event = queue_.front();
    queue_.pop_front();
    return event;
  }

 private:
  bool TryReadByte(uint8_t *byte) {
    if (byte == nullptr) {
      return false;
    }

    pollfd pfd = {
      .fd = STDIN_FILENO,
      .events = POLLIN,
      .revents = 0,
    };
    if (::poll(&pfd, 1, 0) <= 0 || (pfd.revents & POLLIN) == 0) {
      return false;
    }

    return ::read(STDIN_FILENO, byte, 1) == 1;
  }

  void EnqueueTap(int keycode) {
    if (keycode == AM_KEY_NONE) {
      return;
    }
    queue_.push_back(kKeydownMask | static_cast<uint32_t>(keycode));
    queue_.push_back(static_cast<uint32_t>(keycode));
  }

  int TranslateAscii(uint8_t ch) const {
    switch (ch) {
      case '`':
      case '~': return AM_KEY_GRAVE;
      case '1':
      case '!': return AM_KEY_1;
      case '2':
      case '@': return AM_KEY_2;
      case '3':
      case '#': return AM_KEY_3;
      case '4':
      case '$': return AM_KEY_4;
      case '5':
      case '%': return AM_KEY_5;
      case '6':
      case '^': return AM_KEY_6;
      case '7':
      case '&': return AM_KEY_7;
      case '8':
      case '*': return AM_KEY_8;
      case '9':
      case '(': return AM_KEY_9;
      case '0':
      case ')': return AM_KEY_0;
      case '-':
      case '_': return AM_KEY_MINUS;
      case '=':
      case '+': return AM_KEY_EQUALS;
      case '\t': return AM_KEY_TAB;
      case '[':
      case '{': return AM_KEY_LEFTBRACKET;
      case ']':
      case '}': return AM_KEY_RIGHTBRACKET;
      case '\\':
      case '|': return AM_KEY_BACKSLASH;
      case ';':
      case ':': return AM_KEY_SEMICOLON;
      case '\'':
      case '"': return AM_KEY_APOSTROPHE;
      case ',':
      case '<': return AM_KEY_COMMA;
      case '.':
      case '>': return AM_KEY_PERIOD;
      case '/':
      case '?': return AM_KEY_SLASH;
      case ' ': return AM_KEY_SPACE;
      case '\r':
      case '\n': return AM_KEY_RETURN;
      case 0x08:
      case 0x7f: return AM_KEY_BACKSPACE;
      default: break;
    }

    switch (std::tolower(static_cast<unsigned char>(ch))) {
      case 'a': return AM_KEY_A;
      case 'b': return AM_KEY_B;
      case 'c': return AM_KEY_C;
      case 'd': return AM_KEY_D;
      case 'e': return AM_KEY_E;
      case 'f': return AM_KEY_F;
      case 'g': return AM_KEY_G;
      case 'h': return AM_KEY_H;
      case 'i': return AM_KEY_I;
      case 'j': return AM_KEY_J;
      case 'k': return AM_KEY_K;
      case 'l': return AM_KEY_L;
      case 'm': return AM_KEY_M;
      case 'n': return AM_KEY_N;
      case 'o': return AM_KEY_O;
      case 'p': return AM_KEY_P;
      case 'q': return AM_KEY_Q;
      case 'r': return AM_KEY_R;
      case 's': return AM_KEY_S;
      case 't': return AM_KEY_T;
      case 'u': return AM_KEY_U;
      case 'v': return AM_KEY_V;
      case 'w': return AM_KEY_W;
      case 'x': return AM_KEY_X;
      case 'y': return AM_KEY_Y;
      case 'z': return AM_KEY_Z;
      default: return AM_KEY_NONE;
    }
  }

  void HandleEscape() {
    uint8_t first = 0;
    if (!TryReadByte(&first)) {
      EnqueueTap(AM_KEY_ESCAPE);
      return;
    }

    if (first == '[') {
      uint8_t second = 0;
      if (!TryReadByte(&second)) {
        EnqueueTap(AM_KEY_ESCAPE);
        return;
      }

      switch (second) {
        case 'A': EnqueueTap(AM_KEY_UP); return;
        case 'B': EnqueueTap(AM_KEY_DOWN); return;
        case 'C': EnqueueTap(AM_KEY_RIGHT); return;
        case 'D': EnqueueTap(AM_KEY_LEFT); return;
        case 'H': EnqueueTap(AM_KEY_HOME); return;
        case 'F': EnqueueTap(AM_KEY_END); return;
        case '2':
        case '3':
        case '5':
        case '6': {
          uint8_t third = 0;
          if (TryReadByte(&third) && third == '~') {
            switch (second) {
              case '2': EnqueueTap(AM_KEY_INSERT); return;
              case '3': EnqueueTap(AM_KEY_DELETE); return;
              case '5': EnqueueTap(AM_KEY_PAGEUP); return;
              case '6': EnqueueTap(AM_KEY_PAGEDOWN); return;
              default: break;
            }
          }
          break;
        }
        default: break;
      }
    } else if (first == 'O') {
      uint8_t second = 0;
      if (TryReadByte(&second)) {
        switch (second) {
          case 'H': EnqueueTap(AM_KEY_HOME); return;
          case 'F': EnqueueTap(AM_KEY_END); return;
          default: break;
        }
      }
    }

    EnqueueTap(AM_KEY_ESCAPE);
  }

  void HandleByte(uint8_t ch) {
    if (ch == 0x1b) {
      HandleEscape();
      return;
    }

    EnqueueTap(TranslateAscii(ch));
  }

  bool enabled_ = false;
  bool terminal_configured_ = false;
  termios saved_termios_ = {};
  int saved_flags_ = 0;
  std::deque<uint32_t> queue_;
};

KeyboardDevice g_keyboard;

uint32_t serial_read(void *, uint32_t offset, bool *) {
  if (offset == 4) {
    // 把 LSR 的 THRE/TEMT 位置成常 1，给后续更完整 UART 模型留出兼容的状态寄存器位置。
    return 0x00006000u;
  }
  return 0;
}

void serial_write(void *, uint32_t offset, uint32_t data, uint32_t mask, bool *) {
  for (int lane = 0; lane < 4; ++lane) {
    if ((mask & (1u << lane)) == 0) {
      continue;
    }

    if (offset + static_cast<uint32_t>(lane) == 0) {
      std::fputc(static_cast<int>((data >> (lane * 8)) & 0xffu), stdout);
      std::fflush(stdout);
    }
  }
}

uint32_t rtc_read(void *, uint32_t offset, bool *) {
  const uint64_t now = get_time_us();
  if (offset == 4) {
    return static_cast<uint32_t>(now >> 32);
  }
  return static_cast<uint32_t>(now & 0xffffffffu);
}

void rtc_write(void *, uint32_t, uint32_t, uint32_t, bool *) {
}

uint32_t keyboard_read(void *opaque, uint32_t offset, bool *) {
  if (offset != 0) {
    return 0;
  }
  return static_cast<KeyboardDevice *>(opaque)->ReadEvent();
}

void keyboard_write(void *, uint32_t, uint32_t, uint32_t, bool *) {
}

}  // namespace

void init_device(bool enable_stdin_keyboard) {
  init_map();

  // 设备初始化阶段只负责“注册地址区间 + 绑定回调”，后续扩 VGA、mtime 或块设备时可以沿着同一条总线边界继续生长。
  add_mmio_map("serial", kSerialPort, 8, nullptr, serial_read, serial_write);
  add_mmio_map("rtc", kRtcAddr, 8, nullptr, rtc_read, rtc_write);

  g_keyboard.Init(enable_stdin_keyboard);
  add_mmio_map("keyboard", kKbdAddr, 4, &g_keyboard, keyboard_read, keyboard_write);
}

void device_update() {
  g_keyboard.PollHostInput();
}

void fini_device() {
  g_keyboard.Shutdown();
  clear_map();
}

}  // namespace npc
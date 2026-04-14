
#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdint.h>

//条件编译开关，非native平台总是编译，native平台只有定义__NATIVE_USE_KLIB__的时候才编译这份实现

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

//格式化输出：
//1.遍历fmt，如果没有字符%，就当普通字符直接输出
//2.解析当前支持的格式符
//3.把结果写入缓冲区，但是遵守长度限制
//4.统计本来应该输出多少字符
static int kvsnprintf(char *out, size_t n, const char *fmt, va_list ap);

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);

  va_list ap_copy;
  va_copy(ap_copy, ap);
  int ret = kvsnprintf(NULL, 0, fmt, ap_copy);
  va_end(ap_copy);

  char buf[(size_t)ret + 1];
  kvsnprintf(buf, (size_t)ret + 1, fmt, ap);
  va_end(ap);

  putstr(buf);
  return ret;
}

//字符输出专用：写入缓冲区，并统计总输出长度
static void out_ch(char *out, size_t n, int *total, char c) {
  if (out != NULL && n > 0 &&(size_t)(*total) < n - 1)
  {
    out[*total] = c;
  }
  (*total)++;
}

static int prefix_width(const char *prefix) {
  int width = 0;
  while (prefix != NULL && prefix[width] != '\0') {
    width++;
  }
  return width;
}

// 用统一的无符号整数输出路径承接十进制/十六进制/指针，避免每种格式各写一套逻辑后再次出现能力缺口。
static void out_uint(char *out, size_t n, int *total, unsigned long long value,
                     unsigned int base, int width, int zero_pad,
                     int uppercase, const char *prefix) {
  char tmp[sizeof(unsigned long long) * 8];
  const char *digits = uppercase ? "0123456789ABCDEF" : "0123456789abcdef";
  int prefix_len = prefix_width(prefix);
  int digit_count = 0;
  int pad = 0;

  do {
    tmp[digit_count++] = digits[value % base];
    value /= base;
  } while (value > 0);

  pad = width - digit_count - prefix_len;
  if (pad < 0) {
    pad = 0;
  }

  if (!zero_pad) {
    while (pad-- > 0) {
      out_ch(out, n, total, ' ');
    }
  }

  while (prefix != NULL && *prefix != '\0') {
    out_ch(out, n, total, *prefix++);
  }

  if (zero_pad) {
    while (pad-- > 0) {
      out_ch(out, n, total, '0');
    }
  }

  while (digit_count > 0) {
    out_ch(out, n, total, tmp[--digit_count]);
  }
}

// 有符号十进制只负责判定符号，真正的补零/补空格仍走统一整数输出路径，保证行为一致。
static void out_dec(char *out, size_t n, int *total, long long val, int width, int zero_pad) {
  unsigned long long magnitude = (val < 0)
    ? (unsigned long long)(-(val + 1)) + 1ULL
    : (unsigned long long)val;
  const char *prefix = (val < 0) ? "-" : NULL;

  out_uint(out, n, total, magnitude, 10, width, zero_pad, 0, prefix);
}

//核心格式化函数
// 核心格式化函数
static int kvsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  int total = 0;

  while (*fmt) {
    if (*fmt != '%') {
      out_ch(out, n, &total, *fmt++);
      continue;
    }

    fmt++;
    if (*fmt == '\0') break;

    int zero_pad = 0;
    int width = 0;
    int length = 0;

    if (*fmt == '0') {
      zero_pad = 1;
      fmt++;
    }

    while (*fmt >= '0' && *fmt <= '9') {
      width = width * 10 + (*fmt - '0');
      fmt++;
    }

    if (*fmt == 'l') {
      length = 1;
      fmt++;
      if (*fmt == 'l') {
        length = 2;
        fmt++;
      }
    }

    if (*fmt == 'd' || *fmt == 'i') {
      long long val = 0;
      if (length == 2) {
        val = va_arg(ap, long long);
      } else if (length == 1) {
        val = va_arg(ap, long);
      } else {
        val = va_arg(ap, int);
      }
      out_dec(out, n, &total, val, width, zero_pad);
    } else if (*fmt == 'u') {
      unsigned long long val = 0;
      if (length == 2) {
        val = va_arg(ap, unsigned long long);
      } else if (length == 1) {
        val = va_arg(ap, unsigned long);
      } else {
        val = va_arg(ap, unsigned int);
      }
      out_uint(out, n, &total, val, 10, width, zero_pad, 0, NULL);
    } else if (*fmt == 'x' || *fmt == 'X') {
      unsigned long long val = 0;
      if (length == 2) {
        val = va_arg(ap, unsigned long long);
      } else if (length == 1) {
        val = va_arg(ap, unsigned long);
      } else {
        val = va_arg(ap, unsigned int);
      }
      out_uint(out, n, &total, val, 16, width, zero_pad, *fmt == 'X', NULL);
    } else if (*fmt == 'p') {
      uintptr_t ptr = (uintptr_t)va_arg(ap, void *);
      out_uint(out, n, &total, (unsigned long long)ptr, 16, width, zero_pad, 0, "0x");
    } else if (*fmt == 's') {
      const char *s = va_arg(ap, const char *);
      if (s == NULL) s = "(null)";
      while (*s) {
        out_ch(out, n, &total, *s++);
      }
    } else if (*fmt == 'c') {
      out_ch(out, n, &total, (char)va_arg(ap, int));
    } else if (*fmt == '%') {
      out_ch(out, n, &total, '%');
    } else {
      out_ch(out, n, &total, '%');
      if (length >= 1) {
        out_ch(out, n, &total, 'l');
      }
      if (length == 2) {
        out_ch(out, n, &total, 'l');
      }
      out_ch(out, n, &total, *fmt);
    }

    if (*fmt != '\0') {
      fmt++;
    }
  }

  if (out != NULL && n > 0) {
    if ((size_t)total < n) out[total] = '\0';
    else out[n - 1] = '\0';
  }

  return total;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  return kvsnprintf(out, (size_t)-1, fmt, ap);
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = kvsnprintf(out, (size_t)-1, fmt, ap);
  va_end(ap);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = kvsnprintf(out, n, fmt, ap);
  va_end(ap);
  return ret;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  return kvsnprintf(out, n, fmt, ap);
}

#endif

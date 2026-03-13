
#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

//条件编译开关，非native平台总是编译，native平台只有定义__NATIVE_USE_KLIB__的时候才编译这份实现

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

//字符输出专用，往缓冲区写一个字符
static int out_ch(char *out, size_t n, int *total, char c) {
  if (n > 1) {
    *out = c;
    return 1;
  }
  (*total)++;
  return 0;
}

//十进制整数输出
static int out_dec(char *out, size_t n, int *total, int val) {
  char tmp[16];
  int len = 0;
  unsigned int u;

  if (val < 0) {
    int w = out_ch(out, n, total, '-');
    out += w;
    n -= (size_t)w;
    len += w;
    u = (unsigned int)(-(long long)val);
  } else {
    u = (unsigned int)val;
  }

  if (u == 0) {
    len += out_ch(out, n, total, '0');
    return len;
  }

  int i = 0;
  while (u > 0) {
    tmp[i++] = (char)('0' + (u % 10));
    u /= 10;
  }
  while (i > 0) {
    int w = out_ch(out, n, total, tmp[--i]);
    out += w;
    n -= (size_t)w;
    len += w;
  }
  return len;
}

//核心格式化函数
static int kvsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  char *p = out;
  size_t rem = n;
  int total = 0;

  while (*fmt) {
    if (*fmt != '%') {
      int w = out_ch(p, rem, &total, *fmt++);
      p += w;
      rem -= (size_t)w;
      if (w) total++;
      continue;
    }

    fmt++;
    if (*fmt == '\0') break;

    if (*fmt == 'd') {
      int w = out_dec(p, rem, &total, va_arg(ap, int));
      p += w;
      rem -= (size_t)w;
      total += w;
    } else if (*fmt == 's') {
      const char *s = va_arg(ap, const char *);
      if (s == NULL) s = "(null)";
      while (*s) {
        int w = out_ch(p, rem, &total, *s++);
        p += w;
        rem -= (size_t)w;
        if (w) total++;
      }
    } else if (*fmt == 'c') {
      int w = out_ch(p, rem, &total, (char)va_arg(ap, int));
      p += w;
      rem -= (size_t)w;
      if (w) total++;
    } else if (*fmt == '%') {
      int w = out_ch(p, rem, &total, '%');
      p += w;
      rem -= (size_t)w;
      if (w) total++;
    } else {
      int w = out_ch(p, rem, &total, '%');
      p += w;
      rem -= (size_t)w;
      if (w) total++;

      w = out_ch(p, rem, &total, *fmt);
      p += w;
      rem -= (size_t)w;
      if (w) total++;
    }
    fmt++;
  }

  if (n > 0) {
    if (rem > 0) *p = '\0';
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

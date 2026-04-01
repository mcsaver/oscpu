
#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

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

static int dec_width_unsigned(unsigned int u) {
  int width = 1;
  while (u >= 10)
  {
    u /= 10;
    width++;
  }
  return width;
}

static void out_udec(char *out, size_t n, int *total, unsigned int u) {
  char tmp[16];
  int i = 0;
  do
  {
    tmp[i++] = (char)('0' + (u % 10));
    u /= 10;
  } while (u > 0);

  while (i > 0)
  {
    out_ch(out, n, total, tmp[--i]);
  }
}

//十进制整数输出，支持宽度和前导0
static void out_dec(char *out, size_t n, int *total, int val, int width, int zero_pad) {
  unsigned int u = (val < 0) ? (unsigned int)(-(long long)val) : (unsigned int)val;
  int negative = (val < 0);
  int digits = dec_width_unsigned(u);
  int pad = width - digits - negative;

  if (pad < 0)
  {
    pad = 0;
  }

  if (negative && zero_pad)
  {
    out_ch(out, n, total, '-');
    negative = 0;
  }

  while ((pad--) > 0)
  {
    out_ch(out, n, total, zero_pad ? '0' : ' ');
  }
  
  if (negative)
  {
    out_ch(out, n, total, '-');
  }
  
  out_udec(out, n, total, u);
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

    if (*fmt == '0') {
      zero_pad = 1;
      fmt++;
    }

    while (*fmt >= '0' && *fmt <= '9') {
      width = width * 10 + (*fmt - '0');
      fmt++;
    }

    if (*fmt == 'd') {
      out_dec(out, n, &total, va_arg(ap, int), width, zero_pad);
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

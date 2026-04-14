#include "trap.h"
#include <stdint.h>
#include <stdarg.h>

//---此测试程序专用与测试格式化输出函数
//核心构建：用格式化输出函数把结果写到缓冲区，验证返回值和字符串内容是否符合预期

//out：输出缓冲区首地址；n：缓冲区总容量；fmt：格式串；...：真正要格式化的参数列表
static int call_vsnprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = vsnprintf(out, n, fmt, ap);
  va_end(ap);
  return ret;
}

static int call_vsprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = vsprintf(out, fmt, ap);
  va_end(ap);
  return ret;
}

int main() {
  char buf[64];
  char tiny[8];

  int n = sprintf(buf, "A=%d B=%s C=%c %%", 123, "ok", 'Z');
  check(n == 16);
  check(strcmp(buf, "A=123 B=ok C=Z %") == 0);

  n = sprintf(buf, "%d %d %d", 0, -1, -2147483648);
  check(n == 16);
  check(strcmp(buf, "0 -1 -2147483648") == 0);

  n = snprintf(tiny, sizeof(tiny), "%s-%d", "abcdef", 99);
  check(n == 9);
  check(strcmp(tiny, "abcdef-") == 0);

  tiny[0] = 'X';
  n = snprintf(tiny, 0, "%s", "abc");
  check(n == 3);
  check(tiny[0] == 'X');

  n = call_vsnprintf(buf, sizeof(buf), "V:%d:%s", 7, "x");
  check(n == 5);
  check(strcmp(buf, "V:7:x") == 0);

  n = call_vsprintf(buf, "W:%d:%c", 42, 'q');
  check(n == 6);
  check(strcmp(buf, "W:42:q") == 0);

  // 覆盖 CoreMark 和 devscan 依赖的整数格式，保证十六进制/无符号数不再把格式串原样吐出来。
  n = sprintf(buf, "U=%u H=%04x X=%X", 123u, 0x2au, 0x2au);
  check(n == 17);
  check(strcmp(buf, "U=123 H=002a X=2A") == 0);

  n = snprintf(tiny, sizeof(tiny), "%08x", 0x1234u);
  check(n == 8);
  check(strcmp(tiny, "0000123") == 0);

  n = sprintf(buf, "P=%p", (void *)(uintptr_t)0x1234);
  check(n == 8);
  check(strcmp(buf, "P=0x1234") == 0);

  return 0;
}

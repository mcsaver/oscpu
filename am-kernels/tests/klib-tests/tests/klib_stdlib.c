#include "trap.h"

#include <limits.h>
#include <stdint.h>

int main() {
  const char *invalid = "xyz";
  char *end = NULL;

  check(abs(-7) == 7);
  check(labs(-1234567L) == 1234567L);
  check(atoi("  -42rest") == -42);
  check(atol(" +314159") == 314159L);

  end = NULL;
  check(strtol("  -0x1fZ", &end, 0) == -31);
  check(end != NULL && *end == 'Z');

  end = NULL;
  check(strtoul("0755!", &end, 0) == 493UL);
  check(end != NULL && *end == '!');

  end = NULL;
  check(strtoul("0xff", &end, 16) == 255UL);
  check(end != NULL && *end == '\0');

  end = NULL;
  check(strtol(invalid, &end, 10) == 0);
  check(end == invalid);

  check(strtol("999999999999999999999999", NULL, 10) == LONG_MAX);
  check(strtoul("184467440737095516161234", NULL, 10) == ULONG_MAX);

  free(NULL);

  // 这组用例同时验证对齐、零填充、内容保留和 free 之后的空间复用，避免 bump allocator 伪通过。
  void *aligned = malloc(3);
  check(aligned != NULL);
  check((((uintptr_t)aligned) & 0x7u) == 0);
  free(aligned);

  char *grow = malloc(16);
  check(grow != NULL);
  memset(grow, 'A', 16);
  grow = realloc(grow, 64);
  check(grow != NULL);
  for (int i = 0; i < 16; ++i) {
    check(grow[i] == 'A');
  }

  grow = realloc(grow, 8);
  check(grow != NULL);
  for (int i = 0; i < 8; ++i) {
    check(grow[i] == 'A');
  }
  free(grow);

  unsigned char *zero = calloc(32, sizeof(unsigned char));
  check(zero != NULL);
  for (int i = 0; i < 32; ++i) {
    check(zero[i] == 0);
  }
  free(zero);

  void *tmp = realloc(NULL, 24);
  check(tmp != NULL);
  tmp = realloc(tmp, 0);
  check(tmp == NULL);

  for (int i = 0; i < 160; ++i) {
    unsigned char *buf = malloc(1024 * 1024);
    check(buf != NULL);
    buf[0] = (unsigned char)i;
    buf[1024 * 1024 - 1] = (unsigned char)(i + 1);
    free(buf);
  }

  return 0;
}
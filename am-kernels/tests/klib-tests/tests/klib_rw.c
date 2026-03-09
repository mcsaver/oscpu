#include "trap.h"

int main() {
  char buf[32];
  char src[] = "abcdef";

  // memset + memcmp
  memset(buf, 0, sizeof(buf));
  memset(buf, '#', 6);
  check(memcmp(buf, "######", 6) == 0);

  // strcpy/strcat
  strcpy(buf, "hello");
  strcat(buf, " world");
  check(strcmp(buf, "hello world") == 0);

  // strncpy should pad with '\0' when n > src length
  memset(buf, 'X', sizeof(buf));
  strncpy(buf, "ab", 5);
  check(buf[0] == 'a' && buf[1] == 'b');
  check(buf[2] == '\0' && buf[3] == '\0' && buf[4] == '\0');

  // memcpy on non-overlapping regions
  memset(buf, 0, sizeof(buf));
  memcpy(buf, src, 7);
  check(strcmp(buf, "abcdef") == 0);

  // memmove on overlapping regions: move right
  strcpy(buf, "0123456789");
  memmove(buf + 2, buf, 8);
  check(memcmp(buf, "0101234567", 10) == 0);

  // memmove on overlapping regions: move left
  strcpy(buf, "0123456789");
  memmove(buf, buf + 2, 8);
  check(memcmp(buf, "2345678989", 10) == 0);

  return 0;
}

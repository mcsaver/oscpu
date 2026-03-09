#include "trap.h"

int main() {
  const char *a = "alpha";
  const char *b = "alphabet";
  const char *c = "alpha";

  // strlen
  check(strlen("") == 0);
  check(strlen("a") == 1);
  check(strlen("alpha") == 5);

  // strcmp / strncmp
  check(strcmp(a, c) == 0);
  check(strcmp(a, b) < 0);
  check(strcmp(b, a) > 0);
  check(strncmp(a, b, 5) == 0);
  check(strncmp(a, b, 6) < 0);

  // memcmp
  check(memcmp("abc", "abc", 3) == 0);
  check(memcmp("abc", "abd", 3) < 0);
  check(memcmp("abe", "abd", 3) > 0);

  return 0;
}

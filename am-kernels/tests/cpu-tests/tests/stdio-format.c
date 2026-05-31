#include "trap.h"

int main() {
  char buf[128];
  int ret;

  sprintf(buf, "[%d]crclist       : 0x%04x\n", 0, 0xe714);
  check(strcmp(buf, "[0]crclist       : 0xe714\n") == 0);

  ret = snprintf(buf, sizeof(buf), "seedcrc          : 0x%04x\n", 0xe9f5);
  check(ret == strlen("seedcrc          : 0xe9f5\n"));
  check(strcmp(buf, "seedcrc          : 0xe9f5\n") == 0);

  return 0;
}

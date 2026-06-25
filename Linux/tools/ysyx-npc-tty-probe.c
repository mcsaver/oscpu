#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

static int env_int(const char *name, int fallback)
{
  const char *value = getenv(name);
  char *end = NULL;
  long parsed;

  if (value == NULL || value[0] == '\0') {
    return fallback;
  }
  errno = 0;
  parsed = strtol(value, &end, 10);
  if (errno != 0 || end == value || *end != '\0' || parsed < 0 || parsed > 1000000) {
    return fallback;
  }
  return (int)parsed;
}

static void print_hex_marker(const char *marker, const unsigned char *buf, size_t len)
{
  size_t i;

  printf("%s", marker);
  for (i = 0; i < len; i++) {
    printf("%s%02x", i == 0 ? "" : " ", buf[i]);
  }
  putchar('\n');
}

static void print_line_marker(const unsigned char *buf, size_t len)
{
  size_t i;

  printf("__NPC_TTY_READER_LINE__:");
  for (i = 0; i < len; i++) {
    unsigned char ch = buf[i];

    if (ch == '\n') {
      break;
    }
    if (ch >= 32 && ch < 127) {
      putchar((int)ch);
    } else {
      putchar('.');
    }
  }
  putchar('\n');
}

static void print_termios_marker(const char *marker, const struct termios *term)
{
  printf("%s:iflag=0x%lx oflag=0x%lx cflag=0x%lx lflag=0x%lx vmin=%u vtime=%u\n",
         marker,
         (unsigned long)term->c_iflag,
         (unsigned long)term->c_oflag,
         (unsigned long)term->c_cflag,
         (unsigned long)term->c_lflag,
         (unsigned int)term->c_cc[VMIN],
         (unsigned int)term->c_cc[VTIME]);
}

static void make_rawish(struct termios *term)
{
  term->c_iflag &= (tcflag_t) ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
  term->c_oflag &= (tcflag_t) ~OPOST;
  term->c_lflag &= (tcflag_t) ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
  term->c_cflag &= (tcflag_t) ~(CSIZE | PARENB);
  term->c_cflag |= CS8 | CREAD | CLOCAL;
  term->c_cc[VMIN] = 0;
  term->c_cc[VTIME] = 2;
}

int main(int argc, char **argv)
{
  static const unsigned char expected[] = "__NPC_TTY_READER_PING__\n";
  unsigned char buf[128];
  size_t total = 0;
  const char *path = (argc > 1 && argv[1][0] != '\0') ? argv[1] : "/dev/ttyS0";
  int loops = env_int("YSYX_NPC_TTY_PROBE_LOOPS", 64);
  int poll_ms = env_int("YSYX_NPC_TTY_PROBE_POLL_MS", 10);
  int fd;
  int rc;
  struct termios term;
  struct pollfd pfd;
  int i;

  setvbuf(stdout, NULL, _IONBF, 0);

  printf("__NPC_TTY_C_PROBE_BEGIN__:path=%s loops=%d poll_ms=%d expected=%zu\n",
         path, loops, poll_ms, sizeof(expected) - 1);

  fd = open(path, O_RDONLY | O_NOCTTY | O_NONBLOCK);
  if (fd < 0) {
    printf("__NPC_TTY_C_PROBE_OPEN_ERR__:errno=%d\n", errno);
    printf("__NPC_TTY_READER_DONE__ rc=5\n");
    return 5;
  }
  printf("__NPC_TTY_C_PROBE_OPEN__:fd=%d\n", fd);

  if (tcgetattr(fd, &term) == 0) {
    print_termios_marker("__NPC_TTY_C_PROBE_TERMIOS_BEFORE__", &term);
    make_rawish(&term);
    if (tcsetattr(fd, TCSANOW, &term) != 0) {
      printf("__NPC_TTY_C_PROBE_TCSET_ERR__:errno=%d\n", errno);
    } else if (tcgetattr(fd, &term) == 0) {
      print_termios_marker("__NPC_TTY_C_PROBE_TERMIOS_RAW__", &term);
    }
  } else {
    printf("__NPC_TTY_C_PROBE_TCGET_ERR__:errno=%d\n", errno);
  }

  rc = -1;
  errno = 0;
  if (ioctl(fd, FIONREAD, &rc) == 0) {
    printf("__NPC_TTY_C_PROBE_FIONREAD_BEFORE__:avail=%d\n", rc);
  } else {
    printf("__NPC_TTY_C_PROBE_FIONREAD_BEFORE_ERR__:errno=%d\n", errno);
  }

  printf("__NPC_TTY_C_PROBE_READY__\n");
  printf("__NPC_TTY_READER_READY__\n");

  for (i = 0; i < loops && total < sizeof(expected) - 1 && total < sizeof(buf); i++) {
    int avail = -1;
    int saved_errno;
    ssize_t n;

    errno = 0;
    if (ioctl(fd, FIONREAD, &avail) != 0) {
      avail = -1;
      saved_errno = errno;
    } else {
      saved_errno = 0;
    }

    pfd.fd = fd;
    pfd.events = POLLIN | POLLPRI;
    pfd.revents = 0;
    errno = 0;
    rc = poll(&pfd, 1, poll_ms);
    printf("__NPC_TTY_C_PROBE_POLL__:iter=%d rc=%d errno=%d revents=0x%x avail_before=%d avail_errno=%d total=%zu\n",
           i, rc, errno, pfd.revents, avail, saved_errno, total);

    while (total < sizeof(buf)) {
      errno = 0;
      n = read(fd, buf + total, sizeof(buf) - total);
      saved_errno = errno;
      if (n > 0) {
        total += (size_t)n;
        printf("__NPC_TTY_C_PROBE_READ__:iter=%d rc=%zd errno=0 total=%zu\n", i, n, total);
        print_hex_marker("__NPC_TTY_C_PROBE_PARTIAL_HEX__:", buf, total);
        if (total >= sizeof(expected) - 1) {
          break;
        }
        continue;
      }
      if (n == 0) {
        printf("__NPC_TTY_C_PROBE_READ__:iter=%d rc=0 errno=0 total=%zu\n", i, total);
        break;
      }
      if (saved_errno == EAGAIN || saved_errno == EWOULDBLOCK) {
        break;
      }
      printf("__NPC_TTY_C_PROBE_READ_ERR__:iter=%d errno=%d total=%zu\n", i, saved_errno, total);
      break;
    }
  }

  printf("__NPC_TTY_READER_BYTES__:%zu\n", total);
  print_hex_marker("__NPC_TTY_READER_HEX__:", buf, total);
  print_line_marker(buf, total);

  if (total == sizeof(expected) - 1 && memcmp(buf, expected, sizeof(expected) - 1) == 0) {
    printf("__NPC_TTY_READER_DONE__ rc=0\n");
    return 0;
  }
  if (total == 0) {
    printf("__NPC_TTY_C_PROBE_EMPTY__\n");
    printf("__NPC_TTY_READER_DONE__ rc=6\n");
    return 6;
  }

  printf("__NPC_TTY_C_PROBE_MISMATCH__\n");
  printf("__NPC_TTY_READER_DONE__ rc=3\n");
  return 3;
}

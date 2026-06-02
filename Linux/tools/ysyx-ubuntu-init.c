// Minimal Linux /init for the NPC Ubuntu 22.04 initramfs smoke.
//
// This file is intentionally libc-free and built as rv64imac/lp64 so it can
// run before the core has F/D support.  Official Ubuntu riscv64 userland is
// rv64gc/lp64d, so /bin/sh is a later-stage target.

#define AT_FDCWD (-100)

#define SYS_mkdirat 34
#define SYS_mount 40
#define SYS_openat 56
#define SYS_close 57
#define SYS_read 63
#define SYS_write 64
#define SYS_exit 93
#define SYS_nanosleep 101

#define O_RDONLY 0
#define O_WRONLY 1

struct timespec {
  long tv_sec;
  long tv_nsec;
};

static inline long syscall0(long nr) {
  register long a7 __asm__("a7") = nr;
  register long a0 __asm__("a0");
  __asm__ volatile("ecall" : "=r"(a0) : "r"(a7) : "memory");
  return a0;
}

static inline long syscall1(long nr, long arg0) {
  register long a7 __asm__("a7") = nr;
  register long a0 __asm__("a0") = arg0;
  __asm__ volatile("ecall" : "+r"(a0) : "r"(a7) : "memory");
  return a0;
}

static inline long syscall2(long nr, long arg0, long arg1) {
  register long a7 __asm__("a7") = nr;
  register long a0 __asm__("a0") = arg0;
  register long a1 __asm__("a1") = arg1;
  __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a7) : "memory");
  return a0;
}

static inline long syscall3(long nr, long arg0, long arg1, long arg2) {
  register long a7 __asm__("a7") = nr;
  register long a0 __asm__("a0") = arg0;
  register long a1 __asm__("a1") = arg1;
  register long a2 __asm__("a2") = arg2;
  __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");
  return a0;
}

static inline long syscall5(long nr, long arg0, long arg1, long arg2,
                            long arg3, long arg4) {
  register long a7 __asm__("a7") = nr;
  register long a0 __asm__("a0") = arg0;
  register long a1 __asm__("a1") = arg1;
  register long a2 __asm__("a2") = arg2;
  register long a3 __asm__("a3") = arg3;
  register long a4 __asm__("a4") = arg4;
  __asm__ volatile("ecall"
                   : "+r"(a0)
                   : "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a7)
                   : "memory");
  return a0;
}

static unsigned long cstrlen(const char *s) {
  unsigned long n = 0;
  while (s[n] != '\0') n++;
  return n;
}

static long g_console_fd = -2;

static void write_all(int fd, const char *buf, unsigned long len) {
  while (len > 0) {
    long n = syscall3(SYS_write, fd, (long)buf, (long)len);
    if (n <= 0) return;
    buf += n;
    len -= (unsigned long)n;
  }
}

static long console_fd(void) {
  if (g_console_fd == -2) {
    g_console_fd = syscall3(SYS_openat, AT_FDCWD, (long)"/dev/console", O_WRONLY);
  }
  return g_console_fd;
}

static void putstr(const char *s) {
  unsigned long len = cstrlen(s);
  long fd = console_fd();
  if (fd >= 0) {
    write_all((int)fd, s, len);
  } else {
    write_all(1, s, len);
  }
}

static void putstr_stdout(const char *s) {
  write_all(1, s, cstrlen(s));
}

static void mkdir_p(const char *path) {
  (void)syscall3(SYS_mkdirat, AT_FDCWD, (long)path, 0755);
}

static void mount_fs(const char *source, const char *target,
                     const char *fstype) {
  (void)syscall5(SYS_mount, (long)source, (long)target, (long)fstype, 0, 0);
}

static long open_ro(const char *path) {
  return syscall3(SYS_openat, AT_FDCWD, (long)path, O_RDONLY);
}

static void cat_file(const char *path) {
  char buf[512];
  long fd = open_ro(path);
  if (fd < 0) {
    putstr("[ysyx-init] cannot open ");
    putstr(path);
    putstr("\n");
    return;
  }
  for (;;) {
    long n = syscall3(SYS_read, fd, (long)buf, (long)sizeof(buf));
    if (n <= 0) break;
    long out = console_fd();
    if (out >= 0) {
      write_all((int)out, buf, (unsigned long)n);
    } else {
      write_all(1, buf, (unsigned long)n);
    }
  }
  (void)syscall1(SYS_close, fd);
}

static void sleep_forever(void) {
  static struct timespec ts = {1, 0};
  for (;;) {
    (void)syscall2(SYS_nanosleep, (long)&ts, 0);
  }
}

void _start(void) {
  putstr_stdout("[ysyx-init] early-entry\n");
  mkdir_p("/dev");
  mkdir_p("/proc");
  mkdir_p("/sys");
  mkdir_p("/run");
  mkdir_p("/tmp");
  putstr_stdout("[ysyx-init] after-mkdir\n");
  mount_fs("devtmpfs", "/dev", "devtmpfs");
  mount_fs("proc", "/proc", "proc");
  mount_fs("sysfs", "/sys", "sysfs");
  putstr_stdout("[ysyx-init] after-mount\n");

  putstr("[ysyx-init] Ubuntu 22.04 initramfs reached on NPC rv64imac core\n");
  putstr("[ysyx-init] /etc/os-release follows:\n");
  cat_file("/etc/os-release");
  putstr("[ysyx-init] syscall-only init is alive; Ubuntu /bin/sh needs F/D (rv64gc/lp64d)\n");

  sleep_forever();
  (void)syscall1(SYS_exit, 0);
}

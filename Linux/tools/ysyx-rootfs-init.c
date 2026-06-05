// Minimal static stage-1 init for the Ubuntu rootfs boot path.
//
// This binary is intentionally libc-free.  It gives the kernel a cheap PID1,
// mounts the pseudo filesystems systemd expects, then execs systemd or /bin/sh.

#define AT_FDCWD (-100)

#define SYS_dup3 24
#define SYS_fcntl 25
#define SYS_mknodat 33
#define SYS_mkdirat 34
#define SYS_symlinkat 36
#define SYS_mount 40
#define SYS_openat 56
#define SYS_close 57
#define SYS_read 63
#define SYS_write 64
#define SYS_exit 93
#define SYS_nanosleep 101
#define SYS_clone 220
#define SYS_execve 221
#define SYS_wait4 260

#define SIGCHLD 17

#define O_RDONLY 0
#define O_WRONLY 1
#define O_NONBLOCK 04000

#define F_GETFL 3
#define F_SETFL 4

#define S_IFCHR 0020000

struct timespec {
  long tv_sec;
  long tv_nsec;
};

void *memcpy(void *dst, const void *src, unsigned long n) {
  char *d = (char *)dst;
  const char *s = (const char *)src;
  for (unsigned long i = 0; i < n; i++) d[i] = s[i];
  return dst;
}

void *memset(void *dst, int c, unsigned long n) {
  char *d = (char *)dst;
  for (unsigned long i = 0; i < n; i++) d[i] = (char)c;
  return dst;
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

static inline long syscall4(long nr, long arg0, long arg1, long arg2,
                            long arg3) {
  register long a7 __asm__("a7") = nr;
  register long a0 __asm__("a0") = arg0;
  register long a1 __asm__("a1") = arg1;
  register long a2 __asm__("a2") = arg2;
  register long a3 __asm__("a3") = arg3;
  __asm__ volatile("ecall"
                   : "+r"(a0)
                   : "r"(a1), "r"(a2), "r"(a3), "r"(a7)
                   : "memory");
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

static int streq(const char *a, const char *b) {
  unsigned long i = 0;
  while (a[i] != '\0' && b[i] != '\0') {
    if (a[i] != b[i]) return 0;
    i++;
  }
  return a[i] == b[i];
}

static int starts_with(const char *s, const char *prefix) {
  unsigned long i = 0;
  while (prefix[i] != '\0') {
    if (s[i] != prefix[i]) return 0;
    i++;
  }
  return 1;
}

static int contains(const char *buf, long len, const char *needle) {
  unsigned long n = cstrlen(needle);
  if (n == 0 || len <= 0) return 0;
  for (long i = 0; i + (long)n <= len; i++) {
    unsigned long j = 0;
    while (j < n && buf[i + (long)j] == needle[j]) j++;
    if (j == n) return 1;
  }
  return 0;
}

static unsigned long makedev_nr(unsigned long major, unsigned long minor) {
  return (minor & 0xffUL) | ((major & 0xfffUL) << 8) |
         ((minor & ~0xffUL) << 12) | ((major & ~0xfffUL) << 32);
}

static long console_fd = -2;

static void write_all(int fd, const char *buf, unsigned long len) {
  while (len > 0) {
    long n = syscall3(SYS_write, fd, (long)buf, (long)len);
    if (n <= 0) return;
    buf += n;
    len -= (unsigned long)n;
  }
}

static long open_file(const char *path, long flags) {
  return syscall3(SYS_openat, AT_FDCWD, (long)path, flags);
}

static void close_file(long fd) {
  if (fd >= 0) (void)syscall1(SYS_close, fd);
}

static long open_console(void) {
  if (console_fd == -2) {
    console_fd = open_file("/dev/console", O_WRONLY | O_NONBLOCK);
  }
  return console_fd;
}

static void putstr_stdout(const char *s) {
  write_all(1, s, cstrlen(s));
}

static void write_stage_piece(const char *s) {
  unsigned long len = cstrlen(s);
  long flags = syscall3(SYS_fcntl, 1, F_GETFL, 0);
  int restore = flags >= 0 && (flags & O_NONBLOCK) == 0;
  if (restore) (void)syscall3(SYS_fcntl, 1, F_SETFL, flags | O_NONBLOCK);
  while (len > 0) {
    long n = syscall3(SYS_write, 1, (long)s, (long)len);
    if (n <= 0) break;
    s += n;
    len -= (unsigned long)n;
  }
  if (restore) (void)syscall3(SYS_fcntl, 1, F_SETFL, flags);
}

static void putstr(const char *s) {
  long fd = open_console();
  if (fd >= 0) {
    write_all((int)fd, s, cstrlen(s));
  } else {
    putstr_stdout(s);
  }
}

static void stage_stdout(const char *s) {
  // stage1 日志只用于定位进度，必须是 best-effort，不能让串口等待挡住 systemd 启动。
  write_stage_piece("[ysyx-rootfs] ");
  write_stage_piece(s);
  write_stage_piece("\n");
}

static void mkdir_one(const char *path) {
  (void)syscall3(SYS_mkdirat, AT_FDCWD, (long)path, 0755);
}

static void mknod_chr(const char *path, unsigned long mode,
                      unsigned long major, unsigned long minor) {
  (void)syscall4(SYS_mknodat, AT_FDCWD, (long)path,
                 S_IFCHR | mode, (long)makedev_nr(major, minor));
}

static long mount_fs(const char *source, const char *target,
                     const char *fstype, const char *data) {
  return syscall5(SYS_mount, (long)source, (long)target,
                  (long)fstype, 0, (long)data);
}

static long read_file(const char *path, char *buf, unsigned long size) {
  long fd = open_file(path, O_RDONLY);
  if (fd < 0) return fd;
  long total = 0;
  while ((unsigned long)total + 1 < size) {
    long n = syscall3(SYS_read, fd, (long)(buf + total),
                      (long)(size - (unsigned long)total - 1));
    if (n <= 0) break;
    total += n;
  }
  buf[total] = '\0';
  close_file(fd);
  return total;
}

static int path_exists(const char *path) {
  long fd = open_file(path, O_RDONLY);
  if (fd < 0) return 0;
  close_file(fd);
  return 1;
}

static void print_mount_summary(void) {
  char buf[4096];
  long n = read_file("/proc/mounts", buf, sizeof(buf));
  int missing = 0;
  const char *names[] = {
      "/dev", "/proc", "/sys", "/run", "/dev/pts", "/dev/shm",
      "/sys/fs/cgroup", 0,
  };
  const char *needles[] = {
      " /dev ", " /proc ", " /sys ", " /run ", " /dev/pts ", " /dev/shm ",
      " /sys/fs/cgroup ", 0,
  };

  // 只输出关键挂载点摘要，避免完整 /proc/mounts 占用太多串口预算。
  for (int i = 0; names[i] != 0; i++) {
    if (!contains(buf, n, needles[i])) {
      missing++;
      putstr("[ysyx-rootfs] missing mount ");
      putstr(names[i]);
      putstr("\n");
    }
  }
  if (missing == 0) {
    putstr("[ysyx-rootfs] all required mounts present\n");
  }
}

static void cat_file(const char *path) {
  char buf[512];
  long fd = open_file(path, O_RDONLY);
  if (fd < 0) {
    putstr("[ysyx-rootfs] cannot open ");
    putstr(path);
    putstr("\n");
    return;
  }
  for (;;) {
    long n = syscall3(SYS_read, fd, (long)buf, (long)sizeof(buf));
    if (n <= 0) break;
    long out = open_console();
    if (out >= 0) {
      write_all((int)out, buf, (unsigned long)n);
    } else {
      write_all(1, buf, (unsigned long)n);
    }
  }
  close_file(fd);
}

static int os_release_key(const char *line) {
  return starts_with(line, "PRETTY_NAME=");
}

static void cat_os_release_summary(void) {
  char buf[128];
  char line[256];
  unsigned long used = 0;
  long fd = open_file("/etc/os-release", O_RDONLY);
  if (fd < 0) {
    putstr("[ysyx-rootfs] cannot open /etc/os-release\n");
    return;
  }

  for (;;) {
    long n = syscall3(SYS_read, fd, (long)buf, (long)sizeof(buf));
    if (n <= 0) break;
    for (long i = 0; i < n; i++) {
      char ch = buf[i];
      if (ch == '\n') {
        line[used] = '\0';
        if (os_release_key(line)) {
          putstr(line);
          putstr("\n");
          close_file(fd);
          return;
        }
        used = 0;
      } else if (used + 1 < sizeof(line)) {
        line[used++] = ch;
      }
    }
  }
  if (used > 0) {
    line[used] = '\0';
    if (os_release_key(line)) {
      putstr(line);
      putstr("\n");
      close_file(fd);
      return;
    }
  }
  close_file(fd);
}

static void setup_console_fds(void) {
  long fd = open_console();
  if (fd < 0) return;
  if (fd != 0) (void)syscall3(SYS_dup3, fd, 0, 0);
  if (fd != 1) (void)syscall3(SYS_dup3, fd, 1, 0);
  if (fd != 2) (void)syscall3(SYS_dup3, fd, 2, 0);
  if (fd > 2) {
    close_file(fd);
    console_fd = 1;
  }
}

static void set_stdout_blocking(void) {
  long flags = syscall3(SYS_fcntl, 1, F_GETFL, 0);
  if (flags >= 0) {
    (void)syscall3(SYS_fcntl, 1, F_SETFL, flags & ~O_NONBLOCK);
  }
}

static void copy_init_mode(char *mode, unsigned long mode_size) {
  char cmdline[1024];
  long n = read_file("/proc/cmdline", cmdline, sizeof(cmdline));
  const char key[] = "ysyx_init=";
  mode[0] = 'a';
  mode[1] = 'u';
  mode[2] = 't';
  mode[3] = 'o';
  mode[4] = '\0';
  if (n <= 0) return;
  for (long i = 0; i < n; i++) {
    if (starts_with(cmdline + i, key)) {
      i += (long)cstrlen(key);
      unsigned long j = 0;
      while (i < n && cmdline[i] != ' ' && cmdline[i] != '\n' &&
             cmdline[i] != '\0' && j + 1 < mode_size) {
        mode[j++] = cmdline[i++];
      }
      mode[j] = '\0';
      return;
    }
  }
}

static void sleep_forever(void) {
  static struct timespec ts = {1, 0};
  for (;;) {
    (void)syscall2(SYS_nanosleep, (long)&ts, 0);
  }
}

static long exec_path(const char *path, char *const argv[], char *const envp[]) {
  return syscall3(SYS_execve, (long)path, (long)argv, (long)envp);
}

static long fork_child(void) {
  return syscall5(SYS_clone, SIGCHLD, 0, 0, 0, 0);
}

static const char *systemd_candidates[] = {
    "/lib/systemd/systemd",
    "/usr/lib/systemd/systemd",
    "/sbin/init",
    "/usr/sbin/init",
    0,
};

static int has_systemd_candidate(void) {
  for (int i = 0; systemd_candidates[i] != 0; i++) {
    if (path_exists(systemd_candidates[i])) return 1;
  }
  return 0;
}

static int try_exec_systemd(char *const envp[]) {
  for (int i = 0; systemd_candidates[i] != 0; i++) {
    if (!path_exists(systemd_candidates[i])) continue;
    putstr("[ysyx-rootfs] launching systemd: ");
    putstr(systemd_candidates[i]);
    putstr("\n");
    char *argv[] = {(char *)systemd_candidates[i], 0};
    (void)exec_path(systemd_candidates[i], argv, envp);
    putstr("[ysyx-rootfs] exec failed: ");
    putstr(systemd_candidates[i]);
    putstr("\n");
  }
  return 0;
}

static void exec_shell(char *const envp[]) {
  stage_stdout("exec /bin/sh fallback");
  char *argv[] = {
      "/bin/sh",
      "-c",
      "echo \"[ysyx-rootfs-sh] /bin/sh -c marker\"; "
      "while :; do sleep 3600; done",
      0,
  };
  (void)exec_path("/bin/sh", argv, envp);
  putstr("[ysyx-rootfs] exec /bin/sh failed\n");
  sleep_forever();
}

void _start(void) {
  stage_stdout("static stage1 begin");

  stage_stdout("mkdir pseudo fs");
  mkdir_one("/dev");
  mkdir_one("/proc");
  mkdir_one("/sys");
  mkdir_one("/run");
  mkdir_one("/tmp");
  mkdir_one("/sys/fs");

  // 尽早接管 /dev/console，后续日志不再依赖 kernel 传入的早期 stdout。
  mknod_chr("/dev/console", 0600, 5, 1);
  mknod_chr("/dev/null", 0666, 1, 3);
  mknod_chr("/dev/tty", 0666, 5, 0);

  stage_stdout("mount proc");
  (void)mount_fs("proc", "/proc", "proc", "");

  char mode[16];
  stage_stdout("read cmdline");
  copy_init_mode(mode, sizeof(mode));
  int need_systemd_mounts =
      streq(mode, "systemd") || (streq(mode, "auto") && has_systemd_candidate());
  stage_stdout("systemd gate checked");

  if (need_systemd_mounts) {
    // systemd/udevd 期望 /dev 是 devtmpfs；挂载后重建最小控制台节点，避免旧根目录节点被遮住。
    stage_stdout("mount devtmpfs");
    (void)mount_fs("devtmpfs", "/dev", "devtmpfs", "mode=0755");
    mknod_chr("/dev/console", 0600, 5, 1);
    mknod_chr("/dev/null", 0666, 1, 3);
    mknod_chr("/dev/tty", 0666, 5, 0);
    stage_stdout("mount devtmpfs done");

    // 只有 systemd gate 才需要这些更重的伪文件系统；shell fallback 先保持最小闭环。
    stage_stdout("mount sysfs");
    (void)mount_fs("sysfs", "/sys", "sysfs", "");
    stage_stdout("mount sysfs done");

    mkdir_one("/dev/pts");
    mkdir_one("/dev/shm");
    mkdir_one("/run/lock");
    mkdir_one("/sys/fs");
    mkdir_one("/sys/fs/cgroup");

    putstr("[ysyx-rootfs] mount run tmpfs\n");
    (void)mount_fs("tmpfs", "/run", "tmpfs", "mode=0755");
    mkdir_one("/run/lock");

    putstr("[ysyx-rootfs] mount devpts\n");
    (void)mount_fs("devpts", "/dev/pts", "devpts",
                   "gid=5,mode=620,ptmxmode=666");
    (void)syscall3(SYS_symlinkat, (long)"pts/ptmx", AT_FDCWD,
                   (long)"/dev/ptmx");

    putstr("[ysyx-rootfs] mount dev shm\n");
    (void)mount_fs("tmpfs", "/dev/shm", "tmpfs", "mode=1777");

    putstr("[ysyx-rootfs] mount cgroup2\n");
    if (mount_fs("cgroup2", "/sys/fs/cgroup", "cgroup2", "nsdelegate") < 0) {
      (void)mount_fs("cgroup2", "/sys/fs/cgroup", "cgroup2", "");
    }
  } else {
    stage_stdout("skip sysfs for shell fallback");
  }
  if (need_systemd_mounts) {
    print_mount_summary();
  }
  char *envp[] = {
      "HOME=/",
      "TERM=linux",
      "PATH=/usr/sbin:/usr/bin:/sbin:/bin",
      0,
  };

  if (streq(mode, "static")) {
    putstr("[ysyx-rootfs] staying in static stage1\n");
    sleep_forever();
  }
  if (need_systemd_mounts) {
    (void)try_exec_systemd(envp);
    if (streq(mode, "systemd")) {
      putstr("[ysyx-rootfs] requested systemd but no systemd binary found\n");
    }
  }
  exec_shell(envp);
  sleep_forever();
  (void)syscall1(SYS_exit, 1);
}

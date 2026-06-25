// NPC systemd generator diagnostic wrapper.
//
// This binary is intentionally libc-free.  The shell-based generator wrapper
// already proved that systemd can dispatch successive generator children, but
// several children crashed in libc after printing END.  This wrapper keeps the
// skip-all control path to direct Linux syscalls so the next run can separate
// /bin/sh/glibc exit cleanup from systemd's generator scheduling.

#define AT_FDCWD (-100)

#define SYS_openat 56
#define SYS_close 57
#define SYS_read 63
#define SYS_write 64
#define SYS_exit 93
#define SYS_clone 220
#define SYS_execve 221
#define SYS_wait4 260

#define O_RDONLY 0
#define O_WRONLY 1

#define SIGCHLD 17

#define MAX_SKIP_LIST 512
#define MAX_REAL_MODE 32
#define MAX_REAL_PATH 512
#define MAX_EXEC_ARGC 64

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
  if (!s) return 0;
  while (s[n] != '\0') n++;
  return n;
}

static int streqn(const char *a, unsigned long alen, const char *b) {
  unsigned long i = 0;
  while (i < alen && b[i] != '\0') {
    if (a[i] != b[i]) return 0;
    i++;
  }
  return i == alen && b[i] == '\0';
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

static const char *basename_ptr(const char *path) {
  const char *base = path;
  if (!path) return "unknown";
  for (unsigned long i = 0; path[i] != '\0'; i++) {
    if (path[i] == '/') base = path + i + 1;
  }
  return base && base[0] ? base : "unknown";
}

static int is_sep(char c) {
  return c == '\0' || c == ' ' || c == '\t' || c == '\n' || c == '\r' ||
         c == ',';
}

static int token_list_matches(const char *buf, long len, const char *name) {
  long i = 0;
  if (len <= 0) return 0;
  while (i < len) {
    while (i < len && is_sep(buf[i])) i++;
    long start = i;
    while (i < len && !is_sep(buf[i])) i++;
    unsigned long tok_len = (unsigned long)(i - start);
    if (tok_len == 0) continue;
    if (streqn(buf + start, tok_len, "all") ||
        streqn(buf + start, tok_len, name)) {
      return 1;
    }
  }
  return 0;
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
  long fd = console_fd();
  if (fd >= 0) {
    write_all((int)fd, s, cstrlen(s));
  } else {
    write_all(2, s, cstrlen(s));
  }
}

static void put_uint(unsigned long value) {
  char buf[32];
  unsigned long i = sizeof(buf);
  if (value == 0) {
    putstr("0");
    return;
  }
  while (value > 0 && i > 0) {
    buf[--i] = (char)('0' + (value % 10));
    value /= 10;
  }
  write_all((int)(console_fd() >= 0 ? console_fd() : 2), buf + i,
            (unsigned long)(sizeof(buf) - i));
}

static void put_long(long value) {
  if (value < 0) {
    putstr("-");
    put_uint((unsigned long)(-value));
  } else {
    put_uint((unsigned long)value);
  }
}

static long read_skip_list(char *buf, unsigned long cap) {
  long fd = syscall3(SYS_openat, AT_FDCWD,
                     (long)"/etc/ysyx-npc-generator-skip-list", O_RDONLY);
  if (fd < 0) return fd;
  unsigned long off = 0;
  while (off + 1 < cap) {
    long n = syscall3(SYS_read, fd, (long)(buf + off), (long)(cap - off - 1));
    if (n <= 0) break;
    off += (unsigned long)n;
  }
  (void)syscall1(SYS_close, fd);
  buf[off] = '\0';
  return (long)off;
}

static long read_real_mode(char *buf, unsigned long cap) {
  long fd = syscall3(SYS_openat, AT_FDCWD,
                     (long)"/etc/ysyx-npc-generator-real-mode", O_RDONLY);
  if (fd < 0 || cap == 0) {
    if (cap > 0) buf[0] = '\0';
    return fd;
  }
  long n = syscall3(SYS_read, fd, (long)buf, (long)(cap - 1));
  (void)syscall1(SYS_close, fd);
  if (n < 0) {
    buf[0] = '\0';
    return n;
  }
  unsigned long len = (unsigned long)n;
  while (len > 0 && is_sep(buf[len - 1])) len--;
  buf[len] = '\0';
  return (long)len;
}

static int copy_real_path(char *dst, unsigned long cap, const char *path) {
  const char *name = basename_ptr(path);
  const char *prefix = 0;
  const char lib_prefix[] = "/lib/systemd/system-generators/";
  const char usr_prefix[] = "/usr/lib/systemd/system-generators/";
  const char real_lib_prefix[] =
      "/usr/local/lib/ysyx-npc-system-generators/lib/";
  const char real_usr_prefix[] =
      "/usr/local/lib/ysyx-npc-system-generators/usr-lib/";

  if (starts_with(path, lib_prefix)) {
    prefix = real_lib_prefix;
  } else if (starts_with(path, usr_prefix)) {
    prefix = real_usr_prefix;
  }
  if (prefix) {
    unsigned long prefix_len = cstrlen(prefix);
    unsigned long name_len = cstrlen(name);
    if (prefix_len + name_len + 1 > cap) return 0;
    for (unsigned long i = 0; i < prefix_len; i++) dst[i] = prefix[i];
    for (unsigned long i = 0; i < name_len; i++) dst[prefix_len + i] = name[i];
    dst[prefix_len + name_len] = '\0';
    return 1;
  }

  unsigned long len = cstrlen(path);
  const char suffix[] = ".ysyx-real";
  unsigned long suffix_len = sizeof(suffix) - 1;
  if (len + suffix_len + 1 > cap) return 0;
  for (unsigned long i = 0; i < len; i++) dst[i] = path[i];
  for (unsigned long i = 0; i < suffix_len; i++) dst[len + i] = suffix[i];
  dst[len + suffix_len] = '\0';
  return 1;
}

static void print_begin(const char *name, long argc, char **argv) {
  putstr("__NPC_GENERATOR_BEGIN__:");
  putstr(name);
  putstr(" static=1 argc=");
  put_uint(argc > 0 ? (unsigned long)(argc - 1) : 0);
  putstr(" argv=");
  for (long i = 1; i < argc; i++) {
    if (i > 1) putstr(" ");
    putstr(argv[i] ? argv[i] : "");
  }
  putstr("\n");
}

static void print_skip_and_exit(const char *name) {
  putstr("__NPC_GENERATOR_STATIC_SKIP__:");
  putstr(name);
  putstr(" mode=direct-syscall\n");
  putstr("__NPC_GENERATOR_SKIP__:");
  putstr(name);
  putstr(" match=static-list\n");
  putstr("__NPC_GENERATOR_END__:");
  putstr(name);
  putstr(" rc=0 skipped=1 static=1\n");
  (void)syscall1(SYS_exit, 0);
  for (;;) {
  }
}

static void print_exec_failed(const char *name) {
  putstr("__NPC_GENERATOR_END__:");
  putstr(name);
  putstr(" rc=127 static=1 error=exec-real-failed\n");
}

static int supervise_real_generator(const char *name, const char *real_path,
                                    char **exec_argv, char **envp) {
  int status = 0;
  putstr("__NPC_GENERATOR_REAL_BEGIN__:");
  putstr(name);
  putstr(" mode=wait path=");
  putstr(real_path);
  putstr("\n");

  long pid = syscall5(SYS_clone, SIGCHLD, 0, 0, 0, 0);
  if (pid == 0) {
    (void)syscall3(SYS_execve, (long)real_path, (long)exec_argv, (long)envp);
    putstr("__NPC_GENERATOR_CHILD_EXEC_FAILED__:");
    putstr(name);
    putstr("\n");
    (void)syscall1(SYS_exit, 127);
    for (;;) {
    }
  }
  if (pid < 0) {
    putstr("__NPC_GENERATOR_END__:");
    putstr(name);
    putstr(" rc=127 static=1 error=clone-failed errno=");
    put_long(-pid);
    putstr("\n");
    return 127;
  }

  long wait_rc = syscall4(SYS_wait4, pid, (long)&status, 0, 0);
  if (wait_rc < 0) {
    putstr("__NPC_GENERATOR_END__:");
    putstr(name);
    putstr(" rc=127 static=1 error=wait4-failed errno=");
    put_long(-wait_rc);
    putstr("\n");
    return 127;
  }

  putstr("__NPC_GENERATOR_REAL_STATUS__:");
  putstr(name);
  putstr(" pid=");
  put_uint((unsigned long)pid);
  putstr(" raw=");
  put_uint((unsigned long)status);

  int term_sig = status & 0x7f;
  if (term_sig == 0) {
    int code = (status >> 8) & 0xff;
    putstr(" exit=");
    put_uint((unsigned long)code);
    putstr("\n");
    putstr("__NPC_GENERATOR_END__:");
    putstr(name);
    putstr(" rc=");
    put_uint((unsigned long)code);
    putstr(" static=1 real=wait\n");
    return code;
  }

  putstr(" signal=");
  put_uint((unsigned long)term_sig);
  if (status & 0x80) putstr(" core=1");
  putstr("\n");
  putstr("__NPC_GENERATOR_END__:");
  putstr(name);
  putstr(" rc=");
  put_uint((unsigned long)(128 + term_sig));
  putstr(" static=1 real=wait signal=");
  put_uint((unsigned long)term_sig);
  putstr("\n");
  return 128 + term_sig;
}

static int ysyx_main(long argc, char **argv, char **envp) {
  static char skip_buf[MAX_SKIP_LIST];
  static char real_mode[MAX_REAL_MODE];
  static char real_path[MAX_REAL_PATH];
  static char *exec_argv[MAX_EXEC_ARGC];

  const char *self = argc > 0 && argv[0] ? argv[0] : "";
  const char *name = basename_ptr(self);
  long skip_len = read_skip_list(skip_buf, sizeof(skip_buf));
  long real_mode_len = read_real_mode(real_mode, sizeof(real_mode));
  if (real_mode_len <= 0) {
    real_mode[0] = 'e';
    real_mode[1] = 'x';
    real_mode[2] = 'e';
    real_mode[3] = 'c';
    real_mode[4] = '\0';
  }

  print_begin(name, argc, argv);
  if (skip_len > 0 && token_list_matches(skip_buf, skip_len, name)) {
    print_skip_and_exit(name);
  }

  if (!copy_real_path(real_path, sizeof(real_path), self)) {
    putstr("__NPC_GENERATOR_END__:");
    putstr(name);
    putstr(" rc=127 static=1 error=real-path-too-long\n");
    return 127;
  }

  long exec_argc = argc;
  if (exec_argc >= MAX_EXEC_ARGC) exec_argc = MAX_EXEC_ARGC - 1;
  exec_argv[0] = real_path;
  for (long i = 1; i < exec_argc; i++) exec_argv[i] = argv[i];
  exec_argv[exec_argc] = 0;
  if (streq(real_mode, "wait")) {
    return supervise_real_generator(name, real_path, exec_argv, envp);
  }

  (void)syscall3(SYS_execve, (long)real_path, (long)exec_argv, (long)envp);

  print_exec_failed(name);
  return 127;
}

void ysyx_start(unsigned long *sp) {
  long argc = (long)sp[0];
  char **argv = (char **)&sp[1];
  char **envp = &argv[argc + 1];
  int rc = ysyx_main(argc, argv, envp);
  (void)syscall1(SYS_exit, rc);
  for (;;) {
  }
}

__attribute__((naked)) void _start(void) {
  __asm__ volatile("mv a0, sp\n"
                   "tail ysyx_start\n");
}

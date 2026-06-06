// NEMU Ubuntu systemd guest-check 的用户态 syscall probe。
// 它在 guest 内作为 riscv64 ELF 执行，用真实 Linux syscall 路径覆盖
// mmap/msync/mremap/mprotect/madvise/mincore/ftruncate/openat2/statx/getdents64/
// faccessat2/renameat2/lock/socketpair/SCM_RIGHTS/pipe2/dup3/eventfd/epoll/
// timerfd/POSIX timer/futex/O_DIRECT/sendfile/splice 等 shell 难以直接验证的行为。

#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <linux/futex.h>
#include <linux/openat2.h>
#include <linux/random.h>
#include <poll.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/prctl.h>
#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <sys/file.h>
#include <sys/inotify.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/sendfile.h>
#include <sys/signalfd.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/wait.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include <asm/unistd.h>

#if !defined(SYS_pidfd_open) && defined(__NR_pidfd_open)
#define SYS_pidfd_open __NR_pidfd_open
#endif

#if !defined(SYS_pidfd_send_signal) && defined(__NR_pidfd_send_signal)
#define SYS_pidfd_send_signal __NR_pidfd_send_signal
#endif

#if !defined(SYS_openat2) && defined(__NR_openat2)
#define SYS_openat2 __NR_openat2
#endif

#if !defined(SYS_statx) && defined(__NR_statx)
#define SYS_statx __NR_statx
#endif

#if !defined(SYS_renameat2) && defined(__NR_renameat2)
#define SYS_renameat2 __NR_renameat2
#endif

#if !defined(SYS_copy_file_range) && defined(__NR_copy_file_range)
#define SYS_copy_file_range __NR_copy_file_range
#endif

#if !defined(SYS_close_range) && defined(__NR_close_range)
#define SYS_close_range __NR_close_range
#endif

#if !defined(SYS_getdents64) && defined(__NR_getdents64)
#define SYS_getdents64 __NR_getdents64
#endif

#if !defined(SYS_faccessat2) && defined(__NR_faccessat2)
#define SYS_faccessat2 __NR_faccessat2
#endif

#ifndef RENAME_NOREPLACE
#define RENAME_NOREPLACE (1u << 0)
#endif

#ifndef AT_EACCESS
#define AT_EACCESS 0x200
#endif

#ifndef STATX_INO
#define STATX_INO 0x00000100U
#endif

#ifndef STATX_NLINK
#define STATX_NLINK 0x00000004U
#endif

#ifndef P_PIDFD
#define P_PIDFD ((idtype_t)3)
#endif

struct probe_linux_dirent64 {
  uint64_t d_ino;
  int64_t d_off;
  unsigned short d_reclen;
  unsigned char d_type;
  char d_name[];
};

static int failures = 0;

static void pass(const char *name) {
  printf("__NEMU_SYSCALL_PROBE_PASS__:%s\n", name);
}

static void fail_errno(const char *name) {
  printf("__NEMU_SYSCALL_PROBE_FAIL__:%s:%s\n", name, strerror(errno));
  failures++;
}

static void fail_msg(const char *name, const char *msg) {
  printf("__NEMU_SYSCALL_PROBE_FAIL__:%s:%s\n", name, msg);
  failures++;
}

static void fill_pattern(uint8_t *buf, size_t len, uint8_t seed) {
  for (size_t i = 0; i < len; i++) {
    buf[i] = (uint8_t)(seed + (i * 37u) + (i >> 3));
  }
}

static int check_pattern(const uint8_t *buf, size_t len, uint8_t seed) {
  for (size_t i = 0; i < len; i++) {
    uint8_t expected = (uint8_t)(seed + (i * 37u) + (i >> 3));
    if (buf[i] != expected) {
      return -1;
    }
  }
  return 0;
}

static int verify_fd_pattern(int fd, size_t len, uint8_t seed) {
  uint8_t *buf = malloc(len);
  if (buf == NULL) {
    return -1;
  }
  ssize_t got = pread(fd, buf, len, 0);
  int ok = got == (ssize_t)len && check_pattern(buf, len, seed) == 0;
  free(buf);
  return ok ? 0 : -1;
}

static void sleep_ms(long ms) {
  struct timespec req = {
    .tv_sec = ms / 1000,
    .tv_nsec = (ms % 1000) * 1000000,
  };
  while (nanosleep(&req, &req) != 0 && errno == EINTR) {
  }
}

static void timespec_add_ns(struct timespec *ts, long ns) {
  ts->tv_nsec += ns;
  while (ts->tv_nsec >= 1000000000L) {
    ts->tv_sec++;
    ts->tv_nsec -= 1000000000L;
  }
}

static int timespec_cmp(const struct timespec *a, const struct timespec *b) {
  if (a->tv_sec != b->tv_sec) {
    return a->tv_sec < b->tv_sec ? -1 : 1;
  }
  if (a->tv_nsec != b->tv_nsec) {
    return a->tv_nsec < b->tv_nsec ? -1 : 1;
  }
  return 0;
}

static void probe_mmap_file(const char *dir) {
  char path[512];
  snprintf(path, sizeof(path), "%s/probe-mmap.bin", dir);

  int fd = open(path, O_CREAT | O_TRUNC | O_RDWR, 0640);
  if (fd < 0) {
    fail_errno("open-mmap-file");
    return;
  }
  if (ftruncate(fd, 8192) != 0) {
    fail_errno("ftruncate");
    close(fd);
    return;
  }
  void *map = mmap(NULL, 8192, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (map == MAP_FAILED) {
    fail_errno("mmap-shared");
    close(fd);
    return;
  }

  fill_pattern((uint8_t *)map, 8192, 0x31);
  if (msync(map, 8192, MS_SYNC) != 0) {
    fail_errno("msync");
  } else {
    pass("mmap-msync");
  }
  if (munmap(map, 8192) != 0) {
    fail_errno("munmap");
  }

  uint8_t verify[8192];
  ssize_t got = pread(fd, verify, sizeof(verify), 0);
  if (got != (ssize_t)sizeof(verify)) {
    fail_msg("pread-mmap-file", "short-read");
  } else if (check_pattern(verify, sizeof(verify), 0x31) != 0) {
    fail_msg("pread-mmap-file", "pattern-mismatch");
  } else {
    pass("pread-mmap-file");
  }

  if (posix_fallocate(fd, 0, 16384) != 0) {
    fail_errno("posix-fallocate");
  } else {
    pass("posix-fallocate");
  }

  if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
    fail_errno("flock-exclusive");
  } else if (flock(fd, LOCK_UN) != 0) {
    fail_errno("flock-unlock");
  } else {
    pass("flock");
  }

  if (syncfs(fd) != 0) {
    fail_errno("syncfs");
  } else {
    pass("syncfs");
  }

  close(fd);
}

static void probe_vm_remap_protect(void) {
  const size_t page_size = 4096;
  void *map = mmap(NULL, page_size, PROT_READ | PROT_WRITE,
      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (map == MAP_FAILED) {
    fail_errno("mmap-anon");
    return;
  }

  fill_pattern((uint8_t *)map, page_size, 0x44);
  void *grown = mremap(map, page_size, page_size * 2, MREMAP_MAYMOVE);
  if (grown == MAP_FAILED) {
    fail_errno("mremap-anon");
    munmap(map, page_size);
    return;
  }
  map = grown;
  if (check_pattern((const uint8_t *)map, page_size, 0x44) != 0) {
    fail_msg("mremap-anon", "pattern-mismatch");
  } else {
    fill_pattern((uint8_t *)map + page_size, page_size, 0x99);
    pass("mremap-anon");
  }

  if (mprotect(map, page_size, PROT_READ) != 0) {
    fail_errno("mprotect-readonly-page");
  } else if (check_pattern((const uint8_t *)map, page_size, 0x44) != 0) {
    fail_msg("mprotect-readonly-page", "readback-mismatch");
  } else {
    pass("mprotect-readonly-page");
  }
  if (mprotect(map, page_size, PROT_READ | PROT_WRITE) != 0) {
    fail_errno("mprotect-restore-page");
  }
  munmap(map, page_size * 2);
}

static void probe_vm_advice_residency(void) {
  long sys_page_size = sysconf(_SC_PAGESIZE);
  size_t page_size = sys_page_size > 0 ? (size_t)sys_page_size : 4096u;
  size_t len = page_size * 2u;
  void *map = mmap(NULL, len, PROT_READ | PROT_WRITE,
      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (map == MAP_FAILED) {
    fail_errno("mmap-advice-anon");
    return;
  }

  /*
   * systemd/ld.so 常见的 VM hint 不改变可见数据，但会穿过真实内核
   * VMA/page residency 路径；触页后再 mincore，避免只测到空洞映射。
   */
  fill_pattern((uint8_t *)map, len, 0x65);
  if (madvise(map, len, MADV_WILLNEED) != 0) {
    fail_errno("madvise-willneed");
  } else {
    pass("madvise-willneed");
  }

  size_t pages = (len + page_size - 1u) / page_size;
  unsigned char *vec = calloc(pages, sizeof(*vec));
  if (vec == NULL) {
    fail_msg("mincore-resident", "alloc");
    munmap(map, len);
    return;
  }
  if (mincore(map, len, vec) != 0) {
    fail_errno("mincore-resident");
  } else {
    bool resident = true;
    for (size_t i = 0; i < pages; i++) {
      resident = resident && ((vec[i] & 1u) != 0);
    }
    if (resident) {
      pass("mincore-resident");
    } else {
      fail_msg("mincore-resident", "page-not-resident");
    }
  }
  free(vec);
  munmap(map, len);
}

static void probe_modern_fs_syscalls(const char *dir) {
#if defined(SYS_openat2) && defined(SYS_statx)
  int dirfd = open(dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
  if (dirfd < 0) {
    fail_errno("modern-fs-open-dir");
    return;
  }

  struct statx stx;
  memset(&stx, 0, sizeof(stx));
  if (syscall(SYS_statx, AT_FDCWD, dir, AT_SYMLINK_NOFOLLOW,
        STATX_TYPE | STATX_MODE, &stx) != 0) {
    fail_errno("statx-dir");
  } else if ((stx.stx_mode & S_IFMT) != S_IFDIR) {
    fail_msg("statx-dir", "not-directory");
  } else {
    pass("statx-dir");
  }

  struct open_how how;
  memset(&how, 0, sizeof(how));
  how.flags = O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC;
  how.mode = 0640;
  how.resolve = RESOLVE_BENEATH;

  int srcfd = (int)syscall(SYS_openat2, dirfd, "probe-openat2-src",
      &how, sizeof(how));
  if (srcfd < 0) {
    fail_errno("openat2-create");
    close(dirfd);
    return;
  }

  const char payload[] = "modern-fs-syscalls-ok";
  size_t payload_len = sizeof(payload);
  if (write(srcfd, payload, payload_len) != (ssize_t)payload_len ||
      fsync(srcfd) != 0) {
    fail_msg("openat2-write-fsync", "write-or-fsync-failed");
  } else {
    pass("openat2-create-write");
  }

  memset(&stx, 0, sizeof(stx));
  if (syscall(SYS_statx, dirfd, "probe-openat2-src", 0,
        STATX_SIZE, &stx) != 0) {
    fail_errno("statx-file");
  } else if (stx.stx_size != (uint64_t)payload_len) {
    fail_msg("statx-file", "bad-size");
  } else {
    pass("statx-file-size");
  }

#ifdef SYS_copy_file_range
  int dstfd = openat(dirfd, "probe-copy-range-dst",
      O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC, 0640);
  if (dstfd < 0) {
    fail_errno("copy-file-range-open-dst");
  } else if (lseek(srcfd, 0, SEEK_SET) != 0) {
    fail_errno("copy-file-range-lseek");
  } else {
    ssize_t copied = syscall(SYS_copy_file_range, srcfd, NULL,
        dstfd, NULL, payload_len, 0);
    if (copied != (ssize_t)payload_len) {
      fail_msg("copy-file-range", "short-copy");
    } else if (lseek(dstfd, 0, SEEK_SET) != 0) {
      fail_errno("copy-file-range-dst-lseek");
    } else {
      char verify[sizeof(payload)] = {0};
      ssize_t got = read(dstfd, verify, sizeof(verify));
      if (got != (ssize_t)sizeof(verify) ||
          memcmp(verify, payload, sizeof(payload)) != 0) {
        fail_msg("copy-file-range-readback", "mismatch");
      } else {
        pass("copy-file-range");
      }
    }
  }
  if (dstfd >= 0) {
    close(dstfd);
  }
#else
  pass("copy-file-range-skip-no-syscall-number");
#endif

#ifdef SYS_renameat2
  if (syscall(SYS_renameat2, dirfd, "probe-copy-range-dst",
        dirfd, "probe-renameat2-dst", RENAME_NOREPLACE) != 0) {
    fail_errno("renameat2-noreplace");
  } else {
    pass("renameat2-noreplace");
  }
#else
  pass("renameat2-skip-no-syscall-number");
#endif

  unlinkat(dirfd, "probe-meta-dir/probe-hardlink", 0);
  unlinkat(dirfd, "probe-meta-dir", AT_REMOVEDIR);
  if (mkdirat(dirfd, "probe-meta-dir", 0700) != 0) {
    fail_errno("mkdirat-metadata-dir");
  } else if (linkat(dirfd, "probe-openat2-src",
        dirfd, "probe-meta-dir/probe-hardlink", 0) != 0) {
    fail_errno("linkat-hardlink");
  } else {
    struct statx src_stx;
    struct statx link_stx;
    memset(&src_stx, 0, sizeof(src_stx));
    memset(&link_stx, 0, sizeof(link_stx));
    if (syscall(SYS_statx, dirfd, "probe-openat2-src", 0,
          STATX_INO | STATX_NLINK, &src_stx) != 0 ||
        syscall(SYS_statx, dirfd, "probe-meta-dir/probe-hardlink", 0,
          STATX_INO | STATX_NLINK, &link_stx) != 0) {
      fail_errno("statx-hardlink");
    } else if (src_stx.stx_ino != link_stx.stx_ino ||
        src_stx.stx_nlink < 2 || link_stx.stx_nlink < 2) {
      fail_msg("linkat-hardlink", "inode-or-nlink-mismatch");
    } else {
      pass("linkat-hardlink");
    }

    if (fchmodat(dirfd, "probe-meta-dir/probe-hardlink", 0600, 0) != 0) {
      fail_errno("fchmodat-hardlink");
    } else {
      memset(&link_stx, 0, sizeof(link_stx));
      if (syscall(SYS_statx, dirfd, "probe-meta-dir/probe-hardlink", 0,
            STATX_MODE, &link_stx) != 0) {
        fail_errno("statx-hardlink-mode");
      } else if ((link_stx.stx_mode & 0777) != 0600) {
        fail_msg("fchmodat-hardlink", "mode-mismatch");
      } else {
        pass("fchmodat-hardlink");
      }
    }

    struct timespec ts[2] = {
      { .tv_sec = 1700000000, .tv_nsec = 123456789 },
      { .tv_sec = 1700000001, .tv_nsec = 987654321 },
    };
    if (utimensat(dirfd, "probe-meta-dir/probe-hardlink", ts, 0) != 0) {
      fail_errno("utimensat-hardlink");
    } else {
      memset(&link_stx, 0, sizeof(link_stx));
      if (syscall(SYS_statx, dirfd, "probe-meta-dir/probe-hardlink", 0,
            STATX_MTIME, &link_stx) != 0) {
        fail_errno("statx-hardlink-mtime");
      } else if (link_stx.stx_mtime.tv_sec != ts[1].tv_sec) {
        fail_msg("utimensat-hardlink", "mtime-mismatch");
      } else {
        pass("utimensat-hardlink");
      }
    }

    if (fsync(dirfd) != 0) {
      fail_errno("directory-fsync");
    } else {
      pass("directory-fsync");
    }
  }

  unlinkat(dirfd, "probe-meta-dir/probe-hardlink", 0);
  unlinkat(dirfd, "probe-meta-dir", AT_REMOVEDIR);
  unlinkat(dirfd, "probe-openat2-src", 0);
  unlinkat(dirfd, "probe-copy-range-dst", 0);
  unlinkat(dirfd, "probe-renameat2-dst", 0);
  close(srcfd);
  close(dirfd);
#else
  pass("modern-fs-skip-no-openat2-statx");
#endif
}

static void probe_dirent_access_lock(const char *dir) {
  char path[512];
  snprintf(path, sizeof(path), "%s/probe-getdents-entry", dir);

  int fd = open(path, O_CREAT | O_TRUNC | O_RDWR, 0640);
  if (fd < 0) {
    fail_errno("open-getdents-entry");
    return;
  }
  if (write(fd, "dirent", 6) != 6) {
    fail_msg("write-getdents-entry", "short-write");
  }

  struct flock lock = {
    .l_type = F_WRLCK,
    .l_whence = SEEK_SET,
    .l_start = 0,
    .l_len = 0,
  };
  if (fcntl(fd, F_SETLK, &lock) != 0) {
    fail_errno("fcntl-record-lock");
  } else {
    lock.l_type = F_UNLCK;
    if (fcntl(fd, F_SETLK, &lock) != 0) {
      fail_errno("fcntl-record-unlock");
    } else {
      pass("fcntl-record-lock");
    }
  }
  close(fd);

#ifdef SYS_faccessat2
  if (syscall(SYS_faccessat2, AT_FDCWD, path, R_OK | W_OK, AT_EACCESS) != 0) {
    if (errno == ENOSYS) {
      pass("faccessat2-skip-enosys");
    } else {
      fail_errno("faccessat2-eaccess");
    }
  } else {
    pass("faccessat2-eaccess");
  }
#else
  pass("faccessat2-skip-no-syscall-number");
#endif

#ifdef SYS_getdents64
  int dfd = open(dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
  if (dfd < 0) {
    fail_errno("open-getdents-dir");
    return;
  }
  char buf[4096];
  ssize_t got = syscall(SYS_getdents64, dfd, buf, sizeof(buf));
  if (got < 0) {
    fail_errno("getdents64-dir");
  } else {
    bool found = false;
    bool malformed = false;
    for (ssize_t off = 0; off < got; ) {
      if (got - off < (ssize_t)offsetof(struct probe_linux_dirent64, d_name)) {
        malformed = true;
        break;
      }
      const struct probe_linux_dirent64 *ent =
          (const struct probe_linux_dirent64 *)(buf + off);
      if (ent->d_reclen == 0 || off + (ssize_t)ent->d_reclen > got) {
        malformed = true;
        break;
      }
      if (strcmp(ent->d_name, "probe-getdents-entry") == 0) {
        found = true;
      }
      off += (ssize_t)ent->d_reclen;
    }
    if (malformed) {
      fail_msg("getdents64-dir", "malformed-dirent");
    } else if (!found) {
      fail_msg("getdents64-dir", "entry-missing");
    } else {
      pass("getdents64-dir");
    }
  }
  close(dfd);
#else
  pass("getdents64-skip-no-syscall-number");
#endif
}

static void probe_close_range(void) {
#ifdef SYS_close_range
  int first = open("/dev/null", O_RDONLY | O_CLOEXEC);
  int second = open("/dev/zero", O_RDONLY | O_CLOEXEC);
  if (first < 0 || second < 0) {
    fail_errno("close-range-open");
    if (first >= 0) close(first);
    if (second >= 0) close(second);
    return;
  }

  unsigned int lo = (unsigned int)(first < second ? first : second);
  unsigned int hi = (unsigned int)(first < second ? second : first);
  if (syscall(SYS_close_range, lo, hi, 0) != 0) {
    fail_errno("close-range");
    close(first);
    close(second);
    return;
  }

  if (fcntl(first, F_GETFD) == -1 && errno == EBADF &&
      fcntl(second, F_GETFD) == -1 && errno == EBADF) {
    pass("close-range");
  } else {
    fail_msg("close-range", "fd-still-open");
    close(first);
    close(second);
  }
#else
  pass("close-range-skip-no-syscall-number");
#endif
}

static void probe_pipe2_dup3(void) {
  int fds[2];
  if (pipe2(fds, O_CLOEXEC | O_NONBLOCK) != 0) {
    fail_errno("pipe2");
    return;
  }

  int fd_flags = fcntl(fds[0], F_GETFD);
  int status_flags = fcntl(fds[0], F_GETFL);
  if (fd_flags < 0 || status_flags < 0) {
    fail_errno("pipe2-fcntl");
  } else if ((fd_flags & FD_CLOEXEC) == 0 ||
      (status_flags & O_NONBLOCK) == 0) {
    fail_msg("pipe2-cloexec-nonblock", "flags-missing");
  } else {
    pass("pipe2-cloexec-nonblock");
  }

  int target = fcntl(fds[1], F_DUPFD_CLOEXEC, 128);
  if (target >= 0) {
    close(target);
  } else {
    target = 128;
  }

  int dupfd = dup3(fds[1], target, O_CLOEXEC);
  if (dupfd < 0) {
    fail_errno("dup3-pipe-write");
  } else {
    uint8_t byte = 0x5a;
    uint8_t got = 0;
    if (write(dupfd, &byte, 1) != 1) {
      fail_msg("dup3-pipe-write", "short-write");
    } else if (read(fds[0], &got, 1) != 1 || got != byte) {
      fail_msg("dup3-pipe-write", "bad-readback");
    } else {
      pass("dup3-pipe-write");
    }
    close(dupfd);
  }

  close(fds[0]);
  close(fds[1]);
}

static void probe_odirect(const char *dir) {
  char path[512];
  snprintf(path, sizeof(path), "%s/probe-odirect.bin", dir);

  int fd = open(path, O_CREAT | O_TRUNC | O_RDWR | O_DIRECT, 0640);
  if (fd < 0) {
    fail_errno("open-odirect");
    return;
  }

  void *buf = NULL;
  if (posix_memalign(&buf, 4096, 4096) != 0) {
    fail_msg("posix-memalign", "failed");
    close(fd);
    return;
  }
  fill_pattern((uint8_t *)buf, 4096, 0x73);
  ssize_t wrote = write(fd, buf, 4096);
  if (wrote != 4096) {
    fail_msg("write-odirect", "short-write");
  } else if (fsync(fd) != 0) {
    fail_errno("fsync-odirect");
  } else {
    pass("odirect-write-fsync");
  }
  free(buf);
  close(fd);
}

static void probe_socketpair_eventfd(void) {
  int sv[2];
  if (socketpair(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0, sv) != 0) {
    fail_errno("socketpair");
    return;
  }

  const char msg[] = "socketpair-ok";
  if (write(sv[0], msg, sizeof(msg)) != (ssize_t)sizeof(msg)) {
    fail_msg("socketpair-write", "short-write");
  } else {
    char buf[sizeof(msg)] = {0};
    ssize_t got = read(sv[1], buf, sizeof(buf));
    if (got != (ssize_t)sizeof(msg) || memcmp(buf, msg, sizeof(msg)) != 0) {
      fail_msg("socketpair-read", "mismatch");
    } else {
      pass("socketpair");
    }
  }
  close(sv[0]);
  close(sv[1]);

  int efd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
  if (efd < 0) {
    fail_errno("eventfd");
    return;
  }
  uint64_t one = 1;
  if (write(efd, &one, sizeof(one)) != (ssize_t)sizeof(one)) {
    fail_msg("eventfd-write", "short-write");
    close(efd);
    return;
  }
  struct pollfd pfd = { .fd = efd, .events = POLLIN };
  if (poll(&pfd, 1, 1000) != 1 || (pfd.revents & POLLIN) == 0) {
    fail_msg("eventfd-poll", "not-readable");
  } else {
    uint64_t value = 0;
    if (read(efd, &value, sizeof(value)) != (ssize_t)sizeof(value) || value != 1) {
      fail_msg("eventfd-read", "bad-value");
    } else {
      pass("eventfd-poll-read");
    }
  }
  close(efd);
}

static void probe_unix_scm_rights(const char *dir) {
  char path[512];
  snprintf(path, sizeof(path), "%s/probe-scm-rights.txt", dir);

  int fd = open(path, O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC, 0640);
  if (fd < 0) {
    fail_errno("scm-rights-open");
    return;
  }
  const char payload[] = "scm-rights-ok";
  if (write(fd, payload, sizeof(payload)) != (ssize_t)sizeof(payload) ||
      lseek(fd, 0, SEEK_SET) != 0) {
    fail_msg("scm-rights-write", "write-or-lseek-failed");
    close(fd);
    unlink(path);
    return;
  }

  int sv[2];
  if (socketpair(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0, sv) != 0) {
    fail_errno("scm-rights-socketpair");
    close(fd);
    unlink(path);
    return;
  }

  char tag = 'F';
  struct iovec iov = {
    .iov_base = &tag,
    .iov_len = sizeof(tag),
  };
  char control[CMSG_SPACE(sizeof(fd))];
  memset(control, 0, sizeof(control));
  struct msghdr msg;
  memset(&msg, 0, sizeof(msg));
  msg.msg_iov = &iov;
  msg.msg_iovlen = 1;
  msg.msg_control = control;
  msg.msg_controllen = sizeof(control);

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  cmsg->cmsg_len = CMSG_LEN(sizeof(fd));
  memcpy(CMSG_DATA(cmsg), &fd, sizeof(fd));
  msg.msg_controllen = cmsg->cmsg_len;

  if (sendmsg(sv[0], &msg, 0) != (ssize_t)sizeof(tag)) {
    fail_msg("scm-rights-sendmsg", "short-send");
    close(sv[0]);
    close(sv[1]);
    close(fd);
    unlink(path);
    return;
  }

  char rtag = 0;
  struct iovec riov = {
    .iov_base = &rtag,
    .iov_len = sizeof(rtag),
  };
  char rcontrol[CMSG_SPACE(sizeof(fd))];
  memset(rcontrol, 0, sizeof(rcontrol));
  struct msghdr rmsg;
  memset(&rmsg, 0, sizeof(rmsg));
  rmsg.msg_iov = &riov;
  rmsg.msg_iovlen = 1;
  rmsg.msg_control = rcontrol;
  rmsg.msg_controllen = sizeof(rcontrol);

  int received_fd = -1;
  if (recvmsg(sv[1], &rmsg, 0) != (ssize_t)sizeof(rtag) || rtag != tag) {
    fail_msg("scm-rights-recvmsg", "bad-message");
  } else {
    struct cmsghdr *rcmsg = CMSG_FIRSTHDR(&rmsg);
    if (rcmsg == NULL || rcmsg->cmsg_level != SOL_SOCKET ||
        rcmsg->cmsg_type != SCM_RIGHTS ||
        rcmsg->cmsg_len < CMSG_LEN(sizeof(received_fd))) {
      fail_msg("scm-rights-recvmsg", "missing-fd");
    } else {
      memcpy(&received_fd, CMSG_DATA(rcmsg), sizeof(received_fd));
      char verify[sizeof(payload)] = {0};
      ssize_t got = read(received_fd, verify, sizeof(verify));
      if (got != (ssize_t)sizeof(verify) ||
          memcmp(verify, payload, sizeof(payload)) != 0) {
        fail_msg("scm-rights-fd-read", "payload-mismatch");
      } else {
        pass("unix-scm-rights");
      }
    }
  }

  if (received_fd >= 0) {
    close(received_fd);
  }
  close(sv[0]);
  close(sv[1]);
  close(fd);
  unlink(path);
}

static void probe_sendfile_splice(const char *dir) {
  char src_path[512];
  char sendfile_path[512];
  char splice_path[512];
  snprintf(src_path, sizeof(src_path), "%s/probe-zerocopy-src.bin", dir);
  snprintf(sendfile_path, sizeof(sendfile_path), "%s/probe-sendfile-dst.bin", dir);
  snprintf(splice_path, sizeof(splice_path), "%s/probe-splice-dst.bin", dir);

  int srcfd = open(src_path, O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC, 0640);
  if (srcfd < 0) {
    fail_errno("zerocopy-open-src");
    return;
  }
  uint8_t payload[8192];
  fill_pattern(payload, sizeof(payload), 0xc6);
  if (write(srcfd, payload, sizeof(payload)) != (ssize_t)sizeof(payload) ||
      fsync(srcfd) != 0) {
    fail_msg("zerocopy-write-src", "write-or-fsync-failed");
    close(srcfd);
    unlink(src_path);
    return;
  }

  int dstfd = open(sendfile_path, O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC, 0640);
  if (dstfd < 0) {
    fail_errno("sendfile-open-dst");
  } else {
    off_t off = 0;
    size_t total = 0;
    while (total < sizeof(payload)) {
      ssize_t sent = sendfile(dstfd, srcfd, &off, sizeof(payload) - total);
      if (sent > 0) {
        total += (size_t)sent;
        continue;
      }
      if (sent < 0 && errno == EINTR) {
        continue;
      }
      fail_msg("sendfile-regular-file", "short-or-failed");
      break;
    }
    if (total == sizeof(payload) && off == (off_t)sizeof(payload) &&
        fsync(dstfd) == 0 && verify_fd_pattern(dstfd, sizeof(payload), 0xc6) == 0) {
      pass("sendfile-regular-file");
    } else if (total == sizeof(payload)) {
      fail_msg("sendfile-regular-file", "verify-failed");
    }
    close(dstfd);
  }

  int pipefd[2];
  int splicefd = open(splice_path, O_CREAT | O_TRUNC | O_RDWR | O_CLOEXEC, 0640);
  if (splicefd < 0) {
    fail_errno("splice-open-dst");
  } else if (pipe2(pipefd, O_CLOEXEC) != 0) {
    fail_errno("splice-pipe2");
    close(splicefd);
  } else if (lseek(srcfd, 0, SEEK_SET) != 0) {
    fail_errno("splice-lseek-src");
    close(pipefd[0]);
    close(pipefd[1]);
    close(splicefd);
  } else {
    size_t total = 0;
    bool ok = true;
    while (total < sizeof(payload)) {
      size_t request = sizeof(payload) - total;
      if (request > 4096) {
        request = 4096;
      }
      ssize_t moved_in = splice(srcfd, NULL, pipefd[1], NULL, request, 0);
      if (moved_in < 0 && errno == EINTR) {
        continue;
      }
      if (moved_in <= 0) {
        ok = false;
        break;
      }
      ssize_t left = moved_in;
      while (left > 0) {
        ssize_t moved_out = splice(pipefd[0], NULL, splicefd, NULL,
            (size_t)left, 0);
        if (moved_out < 0 && errno == EINTR) {
          continue;
        }
        if (moved_out <= 0) {
          ok = false;
          break;
        }
        left -= moved_out;
      }
      if (!ok) {
        break;
      }
      total += (size_t)moved_in;
    }
    if (ok && total == sizeof(payload) && fsync(splicefd) == 0 &&
        verify_fd_pattern(splicefd, sizeof(payload), 0xc6) == 0) {
      pass("splice-file-pipe-file");
    } else {
      fail_msg("splice-file-pipe-file", "copy-or-verify-failed");
    }
    close(pipefd[0]);
    close(pipefd[1]);
    close(splicefd);
  }

  close(srcfd);
  unlink(src_path);
  unlink(sendfile_path);
  unlink(splice_path);
}

static void probe_epoll_timerfd(void) {
  int epfd = epoll_create1(EPOLL_CLOEXEC);
  if (epfd < 0) {
    fail_errno("epoll-create");
    return;
  }
  int tfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
  if (tfd < 0) {
    fail_errno("timerfd-create");
    close(epfd);
    return;
  }

  struct epoll_event ev = {
    .events = EPOLLIN,
    .data.fd = tfd,
  };
  if (epoll_ctl(epfd, EPOLL_CTL_ADD, tfd, &ev) != 0) {
    fail_errno("epoll-ctl-add-timerfd");
    close(tfd);
    close(epfd);
    return;
  }

  struct itimerspec its = {
    .it_value = { .tv_sec = 0, .tv_nsec = 10000000 },
  };
  if (timerfd_settime(tfd, 0, &its, NULL) != 0) {
    fail_errno("timerfd-settime");
    close(tfd);
    close(epfd);
    return;
  }

  struct epoll_event out = {0};
  if (epoll_wait(epfd, &out, 1, 1000) != 1 ||
      out.data.fd != tfd || (out.events & EPOLLIN) == 0) {
    fail_msg("epoll-timerfd", "not-readable");
  } else {
    uint64_t expirations = 0;
    if (read(tfd, &expirations, sizeof(expirations)) != (ssize_t)sizeof(expirations) ||
        expirations == 0) {
      fail_msg("timerfd-read", "bad-expiration-count");
    } else {
      pass("epoll-timerfd");
    }
  }
  close(tfd);
  close(epfd);
}

static void probe_periodic_timerfd(void) {
  int tfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
  if (tfd < 0) {
    fail_errno("periodic-timerfd-create");
    return;
  }

  struct itimerspec its = {
    .it_value = { .tv_sec = 0, .tv_nsec = 5000000 },
    .it_interval = { .tv_sec = 0, .tv_nsec = 5000000 },
  };
  if (timerfd_settime(tfd, 0, &its, NULL) != 0) {
    fail_errno("periodic-timerfd-settime");
    close(tfd);
    return;
  }

  uint64_t total = 0;
  struct pollfd pfd = { .fd = tfd, .events = POLLIN };
  for (int i = 0; i < 5 && total < 3; i++) {
    int rc = poll(&pfd, 1, 1000);
    if (rc < 0 && errno == EINTR) {
      i--;
      continue;
    }
    if (rc != 1 || (pfd.revents & POLLIN) == 0) {
      break;
    }

    uint64_t expirations = 0;
    ssize_t got = read(tfd, &expirations, sizeof(expirations));
    if (got != (ssize_t)sizeof(expirations) || expirations == 0) {
      fail_msg("periodic-timerfd-read", "bad-expiration-count");
      close(tfd);
      return;
    }
    total += expirations;
  }

  if (total >= 3) {
    pass("periodic-timerfd");
  } else {
    fail_msg("periodic-timerfd", "too-few-expirations");
  }
  close(tfd);
}

static void probe_ppoll_pselect(void) {
  int pipefd[2];
  if (pipe2(pipefd, O_CLOEXEC | O_NONBLOCK) != 0) {
    fail_errno("ppoll-pselect-pipe2");
    return;
  }

  pid_t pid = fork();
  if (pid < 0) {
    fail_errno("ppoll-pselect-fork");
    close(pipefd[0]);
    close(pipefd[1]);
    return;
  }
  if (pid == 0) {
    close(pipefd[0]);
    sleep_ms(5);
    char first = 'p';
    if (write(pipefd[1], &first, sizeof(first)) != (ssize_t)sizeof(first)) {
      _exit(126);
    }
    sleep_ms(5);
    char second = 's';
    if (write(pipefd[1], &second, sizeof(second)) != (ssize_t)sizeof(second)) {
      _exit(126);
    }
    close(pipefd[1]);
    _exit(0);
  }

  close(pipefd[1]);

  struct pollfd pfd = { .fd = pipefd[0], .events = POLLIN };
  struct timespec poll_timeout = { .tv_sec = 1, .tv_nsec = 0 };
  int ppoll_rc = ppoll(&pfd, 1, &poll_timeout, NULL);
  char ch = 0;
  if (ppoll_rc != 1 || (pfd.revents & POLLIN) == 0 ||
      read(pipefd[0], &ch, sizeof(ch)) != (ssize_t)sizeof(ch) || ch != 'p') {
    fail_msg("ppoll-pipe", "not-readable");
  } else {
    pass("ppoll-pipe");
  }

  fd_set readfds;
  FD_ZERO(&readfds);
  FD_SET(pipefd[0], &readfds);
  struct timespec select_timeout = { .tv_sec = 1, .tv_nsec = 0 };
  int pselect_rc = pselect(pipefd[0] + 1, &readfds, NULL, NULL,
      &select_timeout, NULL);
  ch = 0;
  if (pselect_rc != 1 || !FD_ISSET(pipefd[0], &readfds) ||
      read(pipefd[0], &ch, sizeof(ch)) != (ssize_t)sizeof(ch) || ch != 's') {
    fail_msg("pselect-pipe", "not-readable");
  } else {
    pass("pselect-pipe");
  }

  close(pipefd[0]);
  int status = 0;
  if (waitpid(pid, &status, 0) != pid) {
    fail_errno("ppoll-pselect-waitpid");
  } else if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
    fail_msg("ppoll-pselect-child", "bad-exit");
  }
}

static volatile sig_atomic_t timer_got_sigalrm = 0;

static void timer_sigalrm_handler(int signo) {
  (void)signo;
  timer_got_sigalrm = 1;
}

static void probe_interval_timer_signal(void) {
  struct sigaction sa;
  struct sigaction old_sa;
  memset(&sa, 0, sizeof(sa));
  sa.sa_handler = timer_sigalrm_handler;
  sigemptyset(&sa.sa_mask);
  if (sigaction(SIGALRM, &sa, &old_sa) != 0) {
    fail_errno("sigaction-sigalrm");
    return;
  }

  timer_got_sigalrm = 0;
  struct itimerval it = {
    .it_value = { .tv_sec = 0, .tv_usec = 10000 },
  };
  if (setitimer(ITIMER_REAL, &it, NULL) != 0) {
    fail_errno("setitimer-real");
    sigaction(SIGALRM, &old_sa, NULL);
    return;
  }

  for (int i = 0; i < 100 && !timer_got_sigalrm; i++) {
    sleep_ms(1);
  }

  struct itimerval disarm;
  memset(&disarm, 0, sizeof(disarm));
  (void)setitimer(ITIMER_REAL, &disarm, NULL);
  sigaction(SIGALRM, &old_sa, NULL);

  if (timer_got_sigalrm) {
    pass("setitimer-sigalrm");
  } else {
    fail_msg("setitimer-sigalrm", "not-delivered");
  }
}

static volatile sig_atomic_t posix_timer_fired = 0;

static void posix_timer_handler(int signo, siginfo_t *info, void *ctx) {
  (void)signo;
  (void)info;
  (void)ctx;
  posix_timer_fired = 1;
}

static void probe_posix_timer_signal(void) {
  const int signo = SIGUSR2;
  struct sigaction sa;
  struct sigaction old_sa;
  memset(&sa, 0, sizeof(sa));
  sa.sa_sigaction = posix_timer_handler;
  sa.sa_flags = SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  if (sigaction(signo, &sa, &old_sa) != 0) {
    fail_errno("posix-timer-sigaction");
    return;
  }

  struct sigevent sev;
  memset(&sev, 0, sizeof(sev));
  sev.sigev_notify = SIGEV_SIGNAL;
  sev.sigev_signo = signo;

  timer_t timerid;
  if (timer_create(CLOCK_MONOTONIC, &sev, &timerid) != 0) {
    fail_errno("posix-timer-create");
    sigaction(signo, &old_sa, NULL);
    return;
  }

  posix_timer_fired = 0;
  struct itimerspec its = {
    .it_value = { .tv_sec = 0, .tv_nsec = 10000000 },
  };
  if (timer_settime(timerid, 0, &its, NULL) != 0) {
    fail_errno("posix-timer-settime");
    timer_delete(timerid);
    sigaction(signo, &old_sa, NULL);
    return;
  }

  for (int i = 0; i < 100 && !posix_timer_fired; i++) {
    sleep_ms(1);
  }

  timer_delete(timerid);
  sigaction(signo, &old_sa, NULL);

  if (posix_timer_fired) {
    pass("posix-timer-signal");
  } else {
    fail_msg("posix-timer-signal", "not-delivered");
  }
}

static void probe_signalfd(void) {
  sigset_t mask;
  sigset_t oldmask;
  sigemptyset(&mask);
  sigaddset(&mask, SIGUSR1);
  if (sigprocmask(SIG_BLOCK, &mask, &oldmask) != 0) {
    fail_errno("sigprocmask-block");
    return;
  }

  int sfd = signalfd(-1, &mask, SFD_CLOEXEC | SFD_NONBLOCK);
  if (sfd < 0) {
    fail_errno("signalfd-create");
    sigprocmask(SIG_SETMASK, &oldmask, NULL);
    return;
  }
  if (kill(getpid(), SIGUSR1) != 0) {
    fail_errno("signalfd-kill");
    close(sfd);
    sigprocmask(SIG_SETMASK, &oldmask, NULL);
    return;
  }

  struct pollfd pfd = { .fd = sfd, .events = POLLIN };
  if (poll(&pfd, 1, 1000) != 1 || (pfd.revents & POLLIN) == 0) {
    fail_msg("signalfd-poll", "not-readable");
  } else {
    struct signalfd_siginfo info;
    ssize_t got = read(sfd, &info, sizeof(info));
    if (got != (ssize_t)sizeof(info) || info.ssi_signo != SIGUSR1) {
      fail_msg("signalfd-read", "bad-signal");
    } else {
      pass("signalfd");
    }
  }

  close(sfd);
  sigprocmask(SIG_SETMASK, &oldmask, NULL);
}

static void probe_pty_termios(void) {
  int master = posix_openpt(O_RDWR | O_NOCTTY | O_CLOEXEC);
  if (master < 0) {
    fail_errno("posix-openpt");
    return;
  }
  if (grantpt(master) != 0) {
    fail_errno("grantpt");
    close(master);
    return;
  }
  if (unlockpt(master) != 0) {
    fail_errno("unlockpt");
    close(master);
    return;
  }

  char *slave_name = ptsname(master);
  if (slave_name == NULL) {
    fail_errno("ptsname");
    close(master);
    return;
  }

  int slave = open(slave_name, O_RDWR | O_NOCTTY | O_NONBLOCK | O_CLOEXEC);
  if (slave < 0) {
    fail_errno("open-pty-slave");
    close(master);
    return;
  }

  struct termios tio;
  if (tcgetattr(slave, &tio) != 0) {
    fail_errno("tcgetattr-pty");
  } else {
    struct termios raw = tio;
    raw.c_lflag &= (tcflag_t)~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_iflag &= (tcflag_t)~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= (tcflag_t)~OPOST;
    raw.c_cflag |= CS8;
    raw.c_cc[VMIN] = 1;
    raw.c_cc[VTIME] = 0;
    if (tcsetattr(slave, TCSANOW, &raw) != 0) {
      fail_errno("tcsetattr-pty");
    } else {
      pass("pty-termios");
    }
  }

  struct winsize ws = {
    .ws_row = 24,
    .ws_col = 80,
  };
  if (ioctl(slave, TIOCSWINSZ, &ws) != 0) {
    fail_errno("pty-tiocswinsz");
  } else {
    struct winsize got_ws = {0};
    if (ioctl(slave, TIOCGWINSZ, &got_ws) != 0) {
      fail_errno("pty-tiocgwinsz");
    } else if (got_ws.ws_row != ws.ws_row || got_ws.ws_col != ws.ws_col) {
      fail_msg("pty-winsize", "mismatch");
    } else {
      pass("pty-winsize");
    }
  }

  const char msg[] = "pty-ok";
  size_t msg_len = strlen(msg);
  if (write(master, msg, msg_len) != (ssize_t)msg_len) {
    fail_msg("pty-master-write", "short-write");
  } else {
    struct pollfd pfd = { .fd = slave, .events = POLLIN };
    if (poll(&pfd, 1, 1000) != 1 || (pfd.revents & POLLIN) == 0) {
      fail_msg("pty-slave-poll", "not-readable");
    } else {
      char buf[16] = {0};
      ssize_t got = read(slave, buf, sizeof(buf));
      if (got != (ssize_t)msg_len || memcmp(buf, msg, msg_len) != 0) {
        fail_msg("pty-slave-read", "mismatch");
      } else {
        pass("pty-master-slave");
      }
    }
  }

  close(slave);
  close(master);
}

static volatile sig_atomic_t pty_got_sigwinch = 0;

static void pty_sigwinch_handler(int signo) {
  (void)signo;
  pty_got_sigwinch = 1;
}

static void probe_pty_job_control(void) {
  int master = posix_openpt(O_RDWR | O_NOCTTY | O_CLOEXEC);
  if (master < 0) {
    fail_errno("job-pty-openpt");
    return;
  }
  if (grantpt(master) != 0 || unlockpt(master) != 0) {
    fail_errno("job-pty-grant-unlock");
    close(master);
    return;
  }
  char *slave_name = ptsname(master);
  if (slave_name == NULL) {
    fail_errno("job-pty-ptsname");
    close(master);
    return;
  }

  int result_pipe[2];
  if (pipe2(result_pipe, O_CLOEXEC) != 0) {
    fail_errno("job-pty-pipe2");
    close(master);
    return;
  }

  fflush(NULL);
  pid_t pid = fork();
  if (pid < 0) {
    fail_errno("job-pty-fork");
    close(result_pipe[0]);
    close(result_pipe[1]);
    close(master);
    return;
  }

  if (pid == 0) {
    close(result_pipe[0]);
    close(master);

    uint32_t passed = 0;
    if (setsid() >= 0) {
      int slave = open(slave_name, O_RDWR | O_CLOEXEC);
      if (slave >= 0) {
        if (ioctl(slave, TIOCSCTTY, 0) == 0 &&
            tcgetsid(slave) == getsid(0)) {
          passed |= 0x1u;
        }

        pid_t pgrp = getpgrp();
        if (tcsetpgrp(slave, pgrp) == 0 && tcgetpgrp(slave) == pgrp) {
          passed |= 0x2u;
        }

        struct winsize base = { .ws_row = 25, .ws_col = 81 };
        (void)ioctl(slave, TIOCSWINSZ, &base);

        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = pty_sigwinch_handler;
        sigemptyset(&sa.sa_mask);
        if (sigaction(SIGWINCH, &sa, NULL) == 0) {
          struct winsize changed = { .ws_row = 33, .ws_col = 101 };
          if (ioctl(slave, TIOCSWINSZ, &changed) == 0) {
            for (int i = 0; i < 100 && !pty_got_sigwinch; i++) {
              struct timespec req = { .tv_sec = 0, .tv_nsec = 1000000 };
              nanosleep(&req, NULL);
            }
            if (pty_got_sigwinch) {
              passed |= 0x4u;
            }
          }
        }
        close(slave);
      }
    }

    size_t written = 0;
    while (written < sizeof(passed)) {
      ssize_t nwrite = write(result_pipe[1],
          (const uint8_t *)&passed + written, sizeof(passed) - written);
      if (nwrite > 0) {
        written += (size_t)nwrite;
      } else if (nwrite < 0 && errno == EINTR) {
        continue;
      } else {
        break;
      }
    }
    close(result_pipe[1]);
    _exit(written == sizeof(passed) && passed == 0x7u ? 0 : 1);
  }

  close(result_pipe[1]);
  uint32_t passed = 0;
  ssize_t got = read(result_pipe[0], &passed, sizeof(passed));
  close(result_pipe[0]);

  int status = 0;
  if (waitpid(pid, &status, 0) != pid) {
    fail_errno("job-pty-waitpid");
  } else if (got != (ssize_t)sizeof(passed)) {
    fail_msg("job-pty-result", "missing-child-result");
  } else {
    if (passed & 0x1u) {
      pass("pty-controlling-tty");
    } else {
      fail_msg("pty-controlling-tty", "not-acquired");
    }
    if (passed & 0x2u) {
      pass("pty-foreground-pgrp");
    } else {
      fail_msg("pty-foreground-pgrp", "mismatch");
    }
    if (passed & 0x4u) {
      pass("pty-sigwinch");
    } else {
      fail_msg("pty-sigwinch", "not-delivered");
    }
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
      fail_msg("job-pty-child", "bad-exit");
    }
  }

  close(master);
}

static void probe_inotify(const char *dir) {
  int ifd = inotify_init1(IN_CLOEXEC | IN_NONBLOCK);
  if (ifd < 0) {
    fail_errno("inotify-init");
    return;
  }
  int wd = inotify_add_watch(ifd, dir, IN_CREATE | IN_CLOSE_WRITE | IN_DELETE);
  if (wd < 0) {
    fail_errno("inotify-add-watch");
    close(ifd);
    return;
  }

  char path[512];
  snprintf(path, sizeof(path), "%s/probe-inotify-event", dir);
  int fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0640);
  if (fd < 0) {
    fail_errno("inotify-open-target");
    inotify_rm_watch(ifd, wd);
    close(ifd);
    return;
  }
  if (write(fd, "inotify", 7) != 7) {
    fail_msg("inotify-write-target", "short-write");
  }
  close(fd);

  struct pollfd pfd = { .fd = ifd, .events = POLLIN };
  if (poll(&pfd, 1, 1000) != 1 || (pfd.revents & POLLIN) == 0) {
    fail_msg("inotify-poll", "not-readable");
  } else {
    char buf[1024];
    ssize_t got = read(ifd, buf, sizeof(buf));
    bool saw_event = false;
    for (ssize_t off = 0; got > 0 && off + (ssize_t)sizeof(struct inotify_event) <= got; ) {
      const struct inotify_event *ev = (const struct inotify_event *)(buf + off);
      if (ev->wd == wd && (ev->mask & (IN_CREATE | IN_CLOSE_WRITE)) != 0) {
        saw_event = true;
      }
      off += (ssize_t)sizeof(struct inotify_event) + ev->len;
    }
    if (saw_event) {
      pass("inotify-create-close");
    } else {
      fail_msg("inotify-read", "event-missing");
    }
  }

  unlink(path);
  inotify_rm_watch(ifd, wd);
  close(ifd);
}

static void probe_futex_wait_wake(void) {
#ifdef SYS_futex
  int *word = mmap(NULL, sizeof(*word), PROT_READ | PROT_WRITE,
      MAP_SHARED | MAP_ANONYMOUS, -1, 0);
  if (word == MAP_FAILED) {
    fail_errno("futex-mmap");
    return;
  }
  *word = 0;

  pid_t pid = fork();
  if (pid < 0) {
    fail_errno("futex-fork");
    munmap(word, sizeof(*word));
    return;
  }
  if (pid == 0) {
    struct timespec req = { .tv_sec = 0, .tv_nsec = 5000000 };
    nanosleep(&req, NULL);
    *word = 1;
    syscall(SYS_futex, word, FUTEX_WAKE, 1, NULL, NULL, 0);
    _exit(0);
  }

  int ok = 1;
  while (*word == 0) {
    struct timespec timeout = { .tv_sec = 1, .tv_nsec = 0 };
    errno = 0;
    long rc = syscall(SYS_futex, word, FUTEX_WAIT, 0, &timeout, NULL, 0);
    if (rc != 0 && errno != EAGAIN && errno != EINTR) {
      ok = 0;
      fail_errno("futex-wait");
      break;
    }
  }

  int status = 0;
  if (waitpid(pid, &status, 0) != pid) {
    ok = 0;
    fail_errno("futex-waitpid");
  }
  if (ok && (!WIFEXITED(status) || WEXITSTATUS(status) != 0)) {
    ok = 0;
    fail_msg("futex-child", "bad-exit");
  }
  if (ok && *word == 1) {
    pass("futex-wait-wake");
  } else if (ok) {
    fail_msg("futex-wait-wake", "word-not-updated");
  }
  munmap(word, sizeof(*word));
#else
  pass("futex-skip-no-syscall-number");
#endif
}

static void probe_memfd(void) {
#ifdef SYS_memfd_create
  int fd = (int)syscall(SYS_memfd_create, "nemu-probe-memfd", MFD_CLOEXEC);
  if (fd < 0) {
    fail_errno("memfd-create");
    return;
  }
  if (ftruncate(fd, 4096) != 0) {
    fail_errno("memfd-ftruncate");
    close(fd);
    return;
  }
  void *map = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (map == MAP_FAILED) {
    fail_errno("memfd-mmap");
    close(fd);
    return;
  }
  fill_pattern((uint8_t *)map, 4096, 0xa5);
  if (check_pattern((uint8_t *)map, 4096, 0xa5) != 0) {
    fail_msg("memfd-pattern", "mismatch");
  } else {
    pass("memfd-mmap");
  }
  munmap(map, 4096);
  close(fd);
#else
  pass("memfd-skip-no-syscall-number");
#endif
}

static void probe_fork_pipe_exec(void) {
  int pipefd[2];
  if (pipe2(pipefd, O_CLOEXEC) != 0) {
    fail_errno("pipe2");
    return;
  }

  pid_t pid = fork();
  if (pid < 0) {
    fail_errno("fork");
    close(pipefd[0]);
    close(pipefd[1]);
    return;
  }
  if (pid == 0) {
    close(pipefd[0]);
    const char child_msg[] = "child-ok";
    if (write(pipefd[1], child_msg, sizeof(child_msg)) != (ssize_t)sizeof(child_msg)) {
      _exit(126);
    }
    close(pipefd[1]);
    execl("/usr/bin/true", "true", (char *)NULL);
    execlp("true", "true", (char *)NULL);
    _exit(127);
  }

  close(pipefd[1]);
  char buf[16] = {0};
  ssize_t got = read(pipefd[0], buf, sizeof(buf));
  close(pipefd[0]);
  int status = 0;
  if (waitpid(pid, &status, 0) != pid) {
    fail_errno("waitpid");
  } else if (got <= 0 || memcmp(buf, "child-ok", 8) != 0) {
    fail_msg("fork-pipe", "bad-child-message");
  } else if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
    fail_msg("execve-true", "bad-exit");
  } else {
    pass("fork-pipe-execve");
  }
}

static void probe_pidfd_waitid(void) {
#ifdef SYS_pidfd_open
  pid_t pid = fork();
  if (pid < 0) {
    fail_errno("pidfd-fork");
    return;
  }
  if (pid == 0) {
    for (;;) {
      pause();
    }
  }

  int pidfd = (int)syscall(SYS_pidfd_open, pid, 0);
  if (pidfd < 0) {
    int saved_errno = errno;
    kill(pid, SIGKILL);
    waitpid(pid, NULL, 0);
    errno = saved_errno;
    if (errno == ENOSYS) {
      pass("pidfd-skip-enosys");
    } else {
      fail_errno("pidfd-open");
    }
    return;
  }
  pass("pidfd-open");

#ifdef SYS_pidfd_send_signal
  if (syscall(SYS_pidfd_send_signal, pidfd, SIGTERM, NULL, 0) != 0) {
    fail_errno("pidfd-send-signal");
    kill(pid, SIGKILL);
  } else {
    pass("pidfd-send-signal");
  }
#else
  if (kill(pid, SIGTERM) != 0) {
    fail_errno("pidfd-kill-fallback");
  }
#endif

  struct pollfd pfd = { .fd = pidfd, .events = POLLIN };
  if (poll(&pfd, 1, 1000) != 1 || (pfd.revents & POLLIN) == 0) {
    fail_msg("pidfd-poll-exit", "not-readable");
  } else {
    pass("pidfd-poll-exit");
  }

  siginfo_t info;
  memset(&info, 0, sizeof(info));
  if (waitid(P_PIDFD, (id_t)pidfd, &info, WEXITED) != 0) {
    fail_errno("waitid-pidfd");
    waitpid(pid, NULL, 0);
  } else if (info.si_pid != pid || info.si_code != CLD_KILLED ||
      info.si_status != SIGTERM) {
    fail_msg("waitid-pidfd", "bad-siginfo");
  } else {
    pass("waitid-pidfd");
  }
  close(pidfd);
#else
  pass("pidfd-skip-no-syscall-number");
#endif
}

static void probe_process_misc(void) {
  const char name[] = "nemu-probe";
  if (prctl(PR_SET_NAME, name, 0, 0, 0) != 0) {
    fail_errno("prctl-set-name");
  } else {
    char got[16] = {0};
    if (prctl(PR_GET_NAME, got, 0, 0, 0) != 0) {
      fail_errno("prctl-get-name");
    } else if (strncmp(got, name, sizeof(got)) != 0) {
      fail_msg("prctl-name", "mismatch");
    } else {
      pass("prctl-name");
    }
  }

#ifdef SYS_getrandom
  uint8_t random_bytes[16];
  ssize_t got = syscall(SYS_getrandom, random_bytes,
      sizeof(random_bytes), GRND_NONBLOCK);
  if (got != (ssize_t)sizeof(random_bytes)) {
    fail_msg("getrandom", "short-read");
  } else {
    pass("getrandom");
  }
#else
  pass("getrandom-skip-no-syscall-number");
#endif
}

static void probe_clock_sleep(void) {
  struct timespec a, b;
  if (clock_gettime(CLOCK_MONOTONIC, &a) != 0) {
    fail_errno("clock-gettime-a");
    return;
  }
  struct timespec req = { .tv_sec = 0, .tv_nsec = 5000000 };
  if (nanosleep(&req, NULL) != 0) {
    fail_errno("nanosleep");
    return;
  }
  if (clock_gettime(CLOCK_MONOTONIC, &b) != 0) {
    fail_errno("clock-gettime-b");
    return;
  }
  if (b.tv_sec < a.tv_sec || (b.tv_sec == a.tv_sec && b.tv_nsec <= a.tv_nsec)) {
    fail_msg("clock-nanosleep", "time-not-forward");
  } else {
    pass("clock-nanosleep");
  }
}

static void probe_clock_nanosleep_abstime(void) {
  struct timespec target;
  if (clock_gettime(CLOCK_MONOTONIC, &target) != 0) {
    fail_errno("clock-abstime-gettime-a");
    return;
  }
  timespec_add_ns(&target, 10000000L);

  for (;;) {
    int rc = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &target, NULL);
    if (rc == 0) {
      break;
    }
    if (rc == EINTR) {
      continue;
    }
    errno = rc;
    fail_errno("clock-nanosleep-abstime");
    return;
  }

  struct timespec now;
  if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
    fail_errno("clock-abstime-gettime-b");
    return;
  }
  if (timespec_cmp(&now, &target) < 0) {
    fail_msg("clock-nanosleep-abstime", "returned-before-target");
  } else {
    pass("clock-nanosleep-abstime");
  }
}

int main(int argc, char **argv) {
  const char *dir = argc > 1 ? argv[1] : "/tmp";
  printf("__NEMU_SYSCALL_PROBE_BEGIN__:%s\n", dir);

  probe_mmap_file(dir);
  probe_vm_remap_protect();
  probe_vm_advice_residency();
  probe_modern_fs_syscalls(dir);
  probe_dirent_access_lock(dir);
  probe_close_range();
  probe_pipe2_dup3();
  probe_odirect(dir);
  probe_socketpair_eventfd();
  probe_unix_scm_rights(dir);
  probe_sendfile_splice(dir);
  probe_epoll_timerfd();
  probe_periodic_timerfd();
  probe_ppoll_pselect();
  probe_interval_timer_signal();
  probe_posix_timer_signal();
  probe_signalfd();
  probe_pty_termios();
  probe_pty_job_control();
  probe_inotify(dir);
  probe_futex_wait_wake();
  probe_memfd();
  probe_fork_pipe_exec();
  probe_pidfd_waitid();
  probe_process_misc();
  probe_clock_sleep();
  probe_clock_nanosleep_abstime();

  printf("__NEMU_SYSCALL_PROBE_DONE__ rc=%d\n", failures == 0 ? 0 : 1);
  return failures == 0 ? 0 : 1;
}

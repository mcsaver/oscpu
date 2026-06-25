#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static volatile sig_atomic_t keep_running = 1;

static void handle_signal(int signum) {
  (void)signum;
  keep_running = 0;
}

static size_t parse_mib(const char *text, size_t fallback) {
  char *end = NULL;
  unsigned long value;

  if (text == NULL || *text == '\0') {
    return fallback;
  }
  errno = 0;
  value = strtoul(text, &end, 10);
  if (errno != 0 || end == text || *end != '\0') {
    return fallback;
  }
  return (size_t)value;
}

static void touch_chunk(unsigned char *chunk, size_t bytes, size_t stride) {
  size_t offset;

  if (stride == 0) {
    stride = 4096;
  }
  for (offset = 0; offset < bytes; offset += stride) {
    chunk[offset] = (unsigned char)(chunk[offset] + 1U);
  }
  if (bytes > 0) {
    chunk[bytes - 1] = (unsigned char)(chunk[bytes - 1] + 1U);
  }
}

static int write_all(int fd, const unsigned char *buffer, size_t bytes) {
  size_t done = 0;

  while (done < bytes) {
    ssize_t rc = write(fd, buffer + done, bytes - done);
    if (rc < 0) {
      if (errno == EINTR) {
        continue;
      }
      return -1;
    }
    if (rc == 0) {
      errno = EIO;
      return -1;
    }
    done += (size_t)rc;
  }
  return 0;
}

static void fill_pattern(unsigned char *buffer, size_t bytes, unsigned int seed) {
  size_t i;

  for (i = 0; i < bytes; i++) {
    buffer[i] = (unsigned char)((i + seed) & 0xffU);
  }
}

static int read_cache_file(const char *path, unsigned char *buffer, size_t bytes, int pass) {
  int fd = open(path, O_RDONLY);
  size_t total = 0;

  if (fd < 0) {
    return -1;
  }
  while (keep_running) {
    ssize_t rc = read(fd, buffer, bytes);
    if (rc < 0) {
      if (errno == EINTR) {
        continue;
      }
      close(fd);
      return -1;
    }
    if (rc == 0) {
      break;
    }
    total += (size_t)rc;
    touch_chunk(buffer, (size_t)rc, 4096);
  }
  close(fd);
  printf("oomd-pressure-probe-cache-read pass=%d bytes=%zu\n", pass, total);
  return 0;
}

static int run_cache_pressure(const char *path, size_t cache_mib, size_t io_mib,
                              size_t page_size) {
  size_t mib = 1024U * 1024U;
  size_t io_bytes;
  size_t target_bytes;
  size_t written = 0;
  unsigned char *buffer;
  int fd;

  if (cache_mib == 0) {
    printf("oomd-pressure-probe-cache-skip cache_mib=0\n");
    return 0;
  }
  if (io_mib == 0) {
    io_mib = 1;
  }
  io_bytes = io_mib * mib;
  target_bytes = cache_mib * mib;
  buffer = malloc(io_bytes);
  if (buffer == NULL || target_bytes == 0 || io_bytes == 0) {
    fprintf(stderr, "oomd-pressure-probe-cache-init-fail cache_mib=%zu io_mib=%zu errno=%d\n",
            cache_mib, io_mib, errno);
    free(buffer);
    return -1;
  }

  /* systemd-oomd 会结合 reclaim/pgscan 判断压力；file-cache 压力用于补足匿名内存没有 pgscan 的缺口。 */
  printf("oomd-pressure-probe-cache-start cache_mib=%zu io_mib=%zu path=%s\n",
         cache_mib, io_mib, path);
  fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0600);
  if (fd < 0) {
    fprintf(stderr, "oomd-pressure-probe-cache-open-fail path=%s errno=%d\n", path, errno);
    free(buffer);
    return -1;
  }

  while (keep_running && written < target_bytes) {
    size_t todo = target_bytes - written;
    if (todo > io_bytes) {
      todo = io_bytes;
    }
    fill_pattern(buffer, todo, (unsigned int)(written / mib));
    touch_chunk(buffer, todo, page_size);
    if (write_all(fd, buffer, todo) != 0) {
      fprintf(stderr, "oomd-pressure-probe-cache-write-fail written_mib=%zu errno=%d\n",
              written / mib, errno);
      close(fd);
      free(buffer);
      return -1;
    }
    written += todo;
    if (((written / mib) % 16U) == 0U) {
      fsync(fd);
    }
    printf("oomd-pressure-probe-cache-write written_mib=%zu\n", written / mib);
  }
  fsync(fd);
  close(fd);

  if (!keep_running) {
    free(buffer);
    return 0;
  }
  if (read_cache_file(path, buffer, io_bytes, 1) != 0 ||
      read_cache_file(path, buffer, io_bytes, 2) != 0) {
    fprintf(stderr, "oomd-pressure-probe-cache-read-fail path=%s errno=%d\n", path, errno);
    free(buffer);
    return -1;
  }
  free(buffer);
  printf("oomd-pressure-probe-cache-ok cache_mib=%zu\n", cache_mib);
  return 0;
}

int main(int argc, char **argv) {
  size_t target_mib = parse_mib(argc > 1 ? argv[1] : NULL, 512);
  size_t chunk_mib = parse_mib(argc > 2 ? argv[2] : NULL, 4);
  size_t cache_mib = parse_mib(argc > 3 ? argv[3] : NULL, 128);
  const char *cache_path = argc > 4 ? argv[4] : "/var/tmp/nemu-full-oomd-pressure-cache.bin";
  long page_size_long = sysconf(_SC_PAGESIZE);
  size_t page_size = page_size_long > 0 ? (size_t)page_size_long : 4096;
  size_t chunk_bytes = chunk_mib * 1024U * 1024U;
  size_t max_chunks = chunk_mib == 0 ? 0 : (target_mib + chunk_mib - 1U) / chunk_mib;
  unsigned char **chunks = calloc(max_chunks, sizeof(*chunks));
  size_t chunk_count = 0;
  size_t allocated_mib = 0;
  unsigned long heartbeat = 0;
  int cache_rc;

  setvbuf(stdout, NULL, _IOLBF, 0);
  signal(SIGTERM, handle_signal);
  signal(SIGINT, handle_signal);

  if (chunks == NULL || chunk_bytes == 0 || max_chunks == 0) {
    fprintf(stderr, "oomd-pressure-probe-init-fail target_mib=%zu chunk_mib=%zu errno=%d\n",
            target_mib, chunk_mib, errno);
    free(chunks);
    return 2;
  }

  printf("oomd-pressure-probe-start target_mib=%zu chunk_mib=%zu cache_mib=%zu page_size=%zu\n",
         target_mib, chunk_mib, cache_mib, page_size);
  cache_rc = run_cache_pressure(cache_path, cache_mib, chunk_mib, page_size);
  printf("oomd-pressure-probe-cache-rc rc=%d\n", cache_rc);
  if (cache_rc != 0) {
    free(chunks);
    return 4;
  }

  while (keep_running && allocated_mib < target_mib) {
    unsigned char *chunk = malloc(chunk_bytes);
    if (chunk == NULL) {
      fprintf(stderr, "oomd-pressure-probe-malloc-fail allocated_mib=%zu errno=%d\n",
              allocated_mib, errno);
      return 3;
    }
    memset(chunk, 0xa5, chunk_bytes);
    touch_chunk(chunk, chunk_bytes, page_size);
    chunks[chunk_count++] = chunk;
    allocated_mib += chunk_mib;
    printf("oomd-pressure-probe-allocated allocated_mib=%zu chunks=%zu\n",
           allocated_mib, chunk_count);
    usleep(20000);
  }

  printf("oomd-pressure-probe-target-reached allocated_mib=%zu chunks=%zu\n",
         allocated_mib, chunk_count);

  while (keep_running) {
    size_t i;
    for (i = 0; i < chunk_count; i++) {
      touch_chunk(chunks[i], chunk_bytes, page_size * 16U);
    }
    heartbeat++;
    if ((heartbeat % 20UL) == 0UL) {
      printf("oomd-pressure-probe-heartbeat loops=%lu allocated_mib=%zu\n",
             heartbeat, allocated_mib);
    }
    usleep(50000);
  }

  printf("oomd-pressure-probe-exit allocated_mib=%zu\n", allocated_mib);
  return 0;
}

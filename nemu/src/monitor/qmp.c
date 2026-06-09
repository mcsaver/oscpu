/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "qmp.h"

#ifndef CONFIG_TARGET_AM

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdatomic.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <utils.h>

#ifdef CONFIG_HAS_DISK
void virtio_blk_qmp_query_block(char *out, size_t out_size);
void virtio_blk_qmp_query_blockstats(char *out, size_t out_size);
#endif

static int qmp_port = 0;
static atomic_bool qmp_cont_requested;
static atomic_bool qmp_stop_requested;
static atomic_bool qmp_cpu_paused;
static pthread_mutex_t qmp_pause_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t qmp_pause_cond = PTHREAD_COND_INITIALIZER;

void qmp_set_port(int port) {
  Assert(port > 0 && port <= 65535, "invalid --qmp port: %d", port);
  qmp_port = port;
}

bool qmp_is_enabled(void) {
  return qmp_port > 0;
}

const char *qmp_capability(void) {
  return "startup-query-cont-stop-runtime-query";
}

static void qmp_format_status(char *reply, size_t reply_size) {
  const char *status = "prelaunch";
  bool running = false;

  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    if (atomic_load_explicit(&qmp_stop_requested, memory_order_acquire) ||
        atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire)) {
      status = "paused";
    } else {
      switch (nemu_state.state) {
        case NEMU_RUNNING:
          status = "running";
          running = true;
          break;
        case NEMU_STOP:
          status = "paused";
          break;
        case NEMU_ABORT:
          status = "internal-error";
          break;
        case NEMU_END:
        case NEMU_QUIT:
          status = "shutdown";
          break;
        default:
          status = "running";
          running = true;
          break;
      }
    }
  }

  snprintf(reply, reply_size,
      "{\"return\":{\"status\":\"%s\",\"running\":%s,\"singlestep\":false}}",
      status, running ? "true" : "false");
}

static void qmp_resume_cpu(void) {
  pthread_mutex_lock(&qmp_pause_lock);
  atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
  pthread_cond_broadcast(&qmp_pause_cond);
  pthread_mutex_unlock(&qmp_pause_lock);
}

void qmp_cpu_pause_point(void) {
  if (!atomic_load_explicit(&qmp_cont_requested, memory_order_acquire) ||
      !atomic_load_explicit(&qmp_stop_requested, memory_order_acquire)) {
    return;
  }

  bool entered_pause = false;
  pthread_mutex_lock(&qmp_pause_lock);
  while (atomic_load_explicit(&qmp_stop_requested, memory_order_acquire) &&
      nemu_state.state == NEMU_RUNNING) {
    if (!entered_pause) {
      entered_pause = true;
      atomic_store_explicit(&qmp_cpu_paused, true, memory_order_release);
      Log("QMP CPU paused");
    }
    pthread_cond_wait(&qmp_pause_cond, &qmp_pause_lock);
  }
  pthread_mutex_unlock(&qmp_pause_lock);

  if (entered_pause) {
    atomic_store_explicit(&qmp_cpu_paused, false, memory_order_release);
    Log("QMP CPU resumed");
  }
}

static ssize_t write_all(int fd, const void *buf, size_t len) {
  const uint8_t *p = buf;
  size_t done = 0;
  while (done < len) {
    ssize_t n = write(fd, p + done, len - done);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) return n;
    done += (size_t)n;
  }
  return (ssize_t)done;
}

static bool qmp_write_line(int fd, const char *line) {
  return write_all(fd, line, strlen(line)) > 0 && write_all(fd, "\r\n", 2) == 2;
}

static bool qmp_read_line(int fd, char *line, size_t cap) {
  size_t len = 0;
  while (len + 1 < cap) {
    char ch;
    ssize_t n = read(fd, &ch, 1);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) return false;
    if (ch == '\n') {
      break;
    }
    if (ch != '\r') {
      line[len++] = ch;
    }
  }
  line[len] = '\0';
  return len > 0;
}

static bool qmp_command_is(const char *line, const char *cmd) {
  char pattern[96];
  snprintf(pattern, sizeof(pattern), "\"%s\"", cmd);
  return strstr(line, pattern) != NULL;
}

typedef enum {
  QMP_ACTION_KEEP_GOING,
  QMP_ACTION_CONTINUE,
  QMP_ACTION_QUIT,
} QMPAction;

static QMPAction qmp_handle_command(int fd, const char *line) {
  char reply[4096];

  if (qmp_command_is(line, "qmp_capabilities")) {
    snprintf(reply, sizeof(reply), "{\"return\":{}}");
  } else if (qmp_command_is(line, "query-status")) {
    qmp_format_status(reply, sizeof(reply));
  } else if (qmp_command_is(line, "query-memory-size-summary")) {
    snprintf(reply, sizeof(reply),
        "{\"return\":{\"base-memory\":%llu,\"plugged-memory\":0}}",
        (unsigned long long)CONFIG_MSIZE);
  } else if (qmp_command_is(line, "query-machines")) {
    snprintf(reply, sizeof(reply),
        "{\"return\":[{\"name\":\"%s-nemu\",\"cpu-max\":1,"
        "\"hotpluggable-cpus\":false,\"is-default\":true}]}",
        CONFIG_ISA);
  } else if (qmp_command_is(line, "query-cpus-fast")) {
    snprintf(reply, sizeof(reply),
        "{\"return\":[{\"cpu-index\":0,\"qom-path\":\"/machine/unattached/device[0]\","
        "\"thread-id\":0,\"props\":{\"core-id\":0,\"thread-id\":0,\"socket-id\":0}}]}");
  } else if (qmp_command_is(line, "query-block")) {
#ifdef CONFIG_HAS_DISK
    virtio_blk_qmp_query_block(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (qmp_command_is(line, "query-blockstats")) {
#ifdef CONFIG_HAS_DISK
    virtio_blk_qmp_query_blockstats(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (qmp_command_is(line, "query-pci")) {
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
  } else if (qmp_command_is(line, "query-version")) {
    snprintf(reply, sizeof(reply),
        "{\"return\":{\"qemu\":{\"major\":0,\"minor\":0,\"micro\":1},"
        "\"package\":\"ysyx-nemu\"}}");
  } else if (qmp_command_is(line, "query-kvm")) {
    snprintf(reply, sizeof(reply), "{\"return\":{\"enabled\":false,\"present\":false}}");
  } else if (qmp_command_is(line, "query-commands")) {
    snprintf(reply, sizeof(reply),
        "{\"return\":["
        "{\"name\":\"qmp_capabilities\"},{\"name\":\"query-status\"},"
        "{\"name\":\"query-memory-size-summary\"},{\"name\":\"query-machines\"},"
        "{\"name\":\"query-cpus-fast\"},{\"name\":\"query-block\"},"
        "{\"name\":\"query-blockstats\"},"
        "{\"name\":\"query-pci\"},{\"name\":\"query-version\"},"
        "{\"name\":\"query-kvm\"},{\"name\":\"query-commands\"},"
        "{\"name\":\"cont\"},{\"name\":\"stop\"},{\"name\":\"quit\"}]}");
  } else if (qmp_command_is(line, "cont")) {
    (void)qmp_write_line(fd, "{\"return\":{}}");
    bool was_cont_requested = atomic_exchange_explicit(&qmp_cont_requested,
        true, memory_order_acq_rel);
    if (!was_cont_requested) {
      qmp_resume_cpu();
      Log("QMP cont requested");
      return QMP_ACTION_CONTINUE;
    }
    if (atomic_load_explicit(&qmp_stop_requested, memory_order_acquire) ||
        atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire)) {
      qmp_resume_cpu();
      Log("QMP cont requested from paused state");
      return QMP_ACTION_KEEP_GOING;
    }
    Log("QMP cont requested while already running");
    return QMP_ACTION_KEEP_GOING;
  } else if (qmp_command_is(line, "stop")) {
    (void)qmp_write_line(fd, "{\"return\":{}}");
    if (!atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
      Log("QMP stop requested while prelaunch");
      return QMP_ACTION_KEEP_GOING;
    }
    bool was_stop_requested = atomic_exchange_explicit(&qmp_stop_requested,
        true, memory_order_acq_rel);
    Log("QMP stop requested%s", was_stop_requested ? " while already paused" : "");
    return QMP_ACTION_KEEP_GOING;
  } else if (qmp_command_is(line, "quit")) {
    (void)qmp_write_line(fd, "{\"return\":{}}");
    Log("QMP quit requested");
    if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
      nemu_state.state = NEMU_QUIT;
    }
    qmp_resume_cpu();
    return QMP_ACTION_QUIT;
  } else {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"CommandNotFound\",\"desc\":\"unsupported QMP command\"}}");
  }

  return qmp_write_line(fd, reply) ? QMP_ACTION_KEEP_GOING : QMP_ACTION_QUIT;
}

static void *qmp_runtime_client_main(void *opaque) {
  int client_fd = (int)(intptr_t)opaque;
  Log("QMP runtime client active");

  char line[4096];
  while (qmp_read_line(client_fd, line, sizeof(line))) {
    QMPAction action = qmp_handle_command(client_fd, line);
    if (action == QMP_ACTION_QUIT) {
      break;
    }
  }

  close(client_fd);
  Log("QMP runtime client disconnected");
  return NULL;
}

static void qmp_start_runtime_client(int client_fd) {
  pthread_t thread;
  int ret = pthread_create(&thread, NULL, qmp_runtime_client_main,
      (void *)(intptr_t)client_fd);
  Assert(ret == 0, "Can not start QMP runtime thread: %s", strerror(ret));
  pthread_detach(thread);
}

bool qmp_wait_for_client_if_enabled(void) {
  if (!qmp_is_enabled()) {
    return false;
  }

  int listen_fd = socket(AF_INET, SOCK_STREAM, 0);
  Assert(listen_fd >= 0, "Can not create QMP socket");

  int yes = 1;
  setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons((uint16_t)qmp_port);
  int rc = bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr));
  Assert(rc == 0, "Can not bind QMP port %d", qmp_port);
  rc = listen(listen_fd, 1);
  Assert(rc == 0, "Can not listen on QMP port %d", qmp_port);

  Log("QMP listening on 127.0.0.1:%d (%s)", qmp_port, qmp_capability());
  int client_fd = accept(listen_fd, NULL, NULL);
  Assert(client_fd >= 0, "Can not accept QMP client");
  close(listen_fd);
  Log("QMP client connected");

  bool quit_requested = false;
  bool runtime_client = false;
  (void)qmp_write_line(client_fd,
      "{\"QMP\":{\"version\":{\"qemu\":{\"major\":0,\"minor\":0,\"micro\":1},"
      "\"package\":\"ysyx-nemu\"},\"capabilities\":[]}}");

  char line[4096];
  while (qmp_read_line(client_fd, line, sizeof(line))) {
    QMPAction action = qmp_handle_command(client_fd, line);
    if (action == QMP_ACTION_CONTINUE) {
      // cont 之后保留同一个 QMP 连接到后台线程，用于运行期只读查询与 quit。
      qmp_start_runtime_client(client_fd);
      runtime_client = true;
      break;
    }
    if (action == QMP_ACTION_QUIT) {
      quit_requested = true;
      break;
    }
  }

  if (!runtime_client) {
    close(client_fd);
  }
  return quit_requested;
}

#else

void qmp_set_port(int port) {
  (void)port;
}

bool qmp_is_enabled(void) {
  return false;
}

const char *qmp_capability(void) {
  return "unsupported";
}

bool qmp_wait_for_client_if_enabled(void) {
  return false;
}

void qmp_cpu_pause_point(void) {
}

#endif

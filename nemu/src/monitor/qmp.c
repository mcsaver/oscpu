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

#if defined(CONFIG_ISA_riscv)
#include <isa.h>
#endif
#include <ctype.h>
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <time.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <utils.h>

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

#ifdef CONFIG_HAS_DISK
void virtio_blk_qmp_query_block(char *out, size_t out_size);
void virtio_blk_qmp_query_blockstats(char *out, size_t out_size);
#endif
#ifdef CONFIG_HAS_SERIAL
void serial_qmp_query_chardev(char *out, size_t out_size);
void serial_qmp_query_serial(char *out, size_t out_size);
#endif
#ifdef CONFIG_HAS_VIRTIO_NET
void virtio_net_qmp_query_netdev(char *out, size_t out_size);
#endif
#ifdef CONFIG_HAS_VIRTIO_RNG
void virtio_rng_qmp_query_rng(char *out, size_t out_size);
#endif
#ifdef CONFIG_HAS_GOLDFISH_RTC
void goldfish_rtc_qmp_query_rtc(char *out, size_t out_size);
#endif

static int qmp_port = 0;
bool qmp_runtime_enabled = false;
static atomic_bool qmp_cont_requested;
static atomic_bool qmp_stop_requested;
static atomic_bool qmp_cpu_paused;
static atomic_bool qmp_shutdown_event_sent;
static atomic_int qmp_runtime_client_fd = ATOMIC_VAR_INIT(-1);
static pthread_mutex_t qmp_pause_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t qmp_pause_cond = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t qmp_write_lock = PTHREAD_MUTEX_INITIALIZER;

void qmp_set_port(int port) {
  Assert(port > 0 && port <= 65535, "invalid --qmp port: %d", port);
  qmp_port = port;
  qmp_runtime_enabled = true;
}

bool qmp_is_enabled(void) {
  return qmp_port > 0;
}

const char *qmp_capability(void) {
  return "startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown";
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

#if defined(CONFIG_ISA_riscv) && defined(CONFIG_ISA64)
static void qmp_query_interrupts(char *reply, size_t reply_size) {
  char clint[1024];
  char plic[4096];
  isa_riscv64_clint_qmp_snapshot(clint, sizeof(clint));
  isa_riscv64_plic_qmp_snapshot(plic, sizeof(plic));
  snprintf(reply, reply_size, "{\"return\":{\"clint\":%s,\"plic\":%s}}",
      clint, plic);
}
#endif

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
    ssize_t n = send(fd, p + done, len - done, MSG_NOSIGNAL);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) return n;
    done += (size_t)n;
  }
  return (ssize_t)done;
}

static bool qmp_write_line_unlocked(int fd, const char *line) {
  return write_all(fd, line, strlen(line)) > 0 && write_all(fd, "\r\n", 2) == 2;
}

static bool qmp_write_line(int fd, const char *line) {
  pthread_mutex_lock(&qmp_write_lock);
  bool ok = qmp_write_line_unlocked(fd, line);
  pthread_mutex_unlock(&qmp_write_lock);
  return ok;
}

static bool qmp_write_event(int fd, const char *event) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);

  char line[256];
  snprintf(line, sizeof(line),
      "{\"event\":\"%s\",\"timestamp\":{\"seconds\":%lld,"
      "\"microseconds\":%ld},\"data\":{}}",
      event, (long long)ts.tv_sec, (long)(ts.tv_nsec / 1000));
  return qmp_write_line(fd, line);
}

static bool qmp_emit_shutdown_event(int fd) {
  bool expected = false;
  if (!atomic_compare_exchange_strong_explicit(&qmp_shutdown_event_sent,
        &expected, true, memory_order_acq_rel, memory_order_acquire)) {
    return true;
  }
  return qmp_write_event(fd, "SHUTDOWN");
}

void qmp_notify_shutdown_event(void) {
  if (!qmp_is_enabled() ||
      !atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    return;
  }

  int fd = atomic_load_explicit(&qmp_runtime_client_fd, memory_order_acquire);
  if (fd < 0) {
    return;
  }

  // guest 自然 poweroff 不经过 QMP command handler，这里补上管理端可见的关机事件。
  if (qmp_emit_shutdown_event(fd)) {
    Log("QMP guest shutdown event emitted");
  } else {
    Log("QMP guest shutdown event failed");
  }
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

static const char *qmp_skip_ws(const char *p) {
  while (*p != '\0' && isspace((unsigned char)*p)) {
    p++;
  }
  return p;
}

static const char *qmp_find_json_key(const char *line, const char *key) {
  char pattern[32];
  snprintf(pattern, sizeof(pattern), "\"%s\"", key);
  const char *p = strstr(line, pattern);
  if (p == NULL) {
    return NULL;
  }

  p += strlen(pattern);
  p = qmp_skip_ws(p);
  if (*p != ':') {
    return NULL;
  }
  return qmp_skip_ws(p + 1);
}

static bool qmp_parse_json_string_value(const char **cursor, char *out, size_t out_size) {
  const char *p = qmp_skip_ws(*cursor);
  if (*p != '"' || out_size == 0) {
    return false;
  }
  p++;

  size_t used = 0;
  while (*p != '\0' && *p != '"') {
    char ch = *p++;
    if (ch == '\\') {
      if (*p == '\0') {
        return false;
      }
      ch = *p++;
    }
    if (used + 1 < out_size) {
      out[used++] = ch;
    }
  }
  if (*p != '"') {
    return false;
  }
  out[used] = '\0';
  *cursor = p + 1;
  return true;
}

static bool qmp_extract_execute(const char *line, char *command, size_t command_size) {
  const char *p = qmp_find_json_key(line, "execute");
  if (p == NULL) {
    return false;
  }
  return qmp_parse_json_string_value(&p, command, command_size);
}

static bool qmp_extract_request_id(const char *line, char *id, size_t id_size) {
  const char *p = qmp_find_json_key(line, "id");
  if (p == NULL) {
    id[0] = '\0';
    return false;
  }

  if (*p == '"') {
    size_t used = 0;
    if (id_size == 0) {
      return false;
    }
    id[used++] = *p++;
    while (*p != '\0') {
      char ch = *p++;
      if (used + 1 >= id_size) {
        return false;
      }
      id[used++] = ch;
      if (ch == '\\') {
        if (*p == '\0' || used + 1 >= id_size) {
          return false;
        }
        id[used++] = *p++;
        continue;
      }
      if (ch == '"') {
        id[used] = '\0';
        return true;
      }
    }
    return false;
  }

  const char *start = p;
  while (*p != '\0' && *p != ',' && *p != '}' && *p != '\r' && *p != '\n') {
    p++;
  }
  const char *end = p;
  while (end > start && isspace((unsigned char)end[-1])) {
    end--;
  }
  size_t len = (size_t)(end - start);
  if (len == 0 || len >= id_size) {
    return false;
  }
  memcpy(id, start, len);
  id[len] = '\0';
  return true;
}

static bool qmp_write_reply(int fd, const char *reply, const char *id) {
  if (id == NULL || id[0] == '\0') {
    return qmp_write_line(fd, reply);
  }

  size_t reply_len = strlen(reply);
  if (reply_len < 2 || reply[0] != '{' || reply[reply_len - 1] != '}') {
    return qmp_write_line(fd, reply);
  }

  char with_id[9216];
  // QMP 客户端依赖 id 回显来关联请求/响应；事件仍按协议不带 id。
  int n = snprintf(with_id, sizeof(with_id), "%.*s,\"id\":%s}",
      (int)(reply_len - 1), reply, id);
  if (n < 0 || (size_t)n >= sizeof(with_id)) {
    return false;
  }
  return qmp_write_line(fd, with_id);
}

typedef struct {
  const char *name;
  const char *ret_type;
} QMPCommandInfo;

static const QMPCommandInfo qmp_commands[] = {
  {"qmp_capabilities", "q_empty"},
  {"query-status", "StatusInfo"},
  {"query-memory-size-summary", "MemoryInfo"},
  {"query-machines", "MachineInfoList"},
  {"query-cpus-fast", "CpuInfoFastList"},
  {"query-block", "BlockInfoList"},
  {"query-blockstats", "BlockStatsList"},
  {"query-chardev", "ChardevInfoList"},
  {"query-serial", "NemuSerialInfoList"},
  {"query-netdev", "NemuNetdevInfoList"},
  {"query-rng", "NemuRngInfoList"},
  {"query-rtc", "NemuRtcInfoList"},
  {"query-interrupts", "NemuInterruptInfo"},
  {"query-pci", "PciInfoList"},
  {"query-version", "VersionInfo"},
  {"query-kvm", "KvmInfo"},
  {"query-qmp-schema", "SchemaInfoList"},
  {"query-events", "EventInfoList"},
  {"query-commands", "CommandInfoList"},
  {"cont", "q_empty"},
  {"stop", "q_empty"},
  {"system_reset", "q_empty"},
  {"system_powerdown", "q_empty"},
  {"quit", "q_empty"},
};

static const char *qmp_events[] = {
  "RESET",
  "RESUME",
  "STOP",
  "SHUTDOWN",
};

static void qmp_append(char *out, size_t out_size, size_t *used,
    const char *fmt, ...) {
  if (*used >= out_size) return;

  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(out + *used, out_size - *used, fmt, ap);
  va_end(ap);
  if (n < 0) return;

  size_t written = (size_t)n;
  if (written >= out_size - *used) {
    *used = out_size;
  } else {
    *used += written;
  }
}

static void qmp_format_command_list(char *reply, size_t reply_size) {
  size_t used = 0;
  qmp_append(reply, reply_size, &used, "{\"return\":[");
  for (size_t i = 0; i < ARRLEN(qmp_commands); i++) {
    qmp_append(reply, reply_size, &used, "%s{\"name\":\"%s\"}",
        i == 0 ? "" : ",", qmp_commands[i].name);
  }
  qmp_append(reply, reply_size, &used, "]}");
}

static void qmp_format_schema(char *reply, size_t reply_size) {
  size_t used = 0;
  qmp_append(reply, reply_size, &used, "{\"return\":[");
  for (size_t i = 0; i < ARRLEN(qmp_commands); i++) {
    // 这是 NEMU 当前 command 级最小 schema introspection，不等同于完整 QAPI 类型系统。
    qmp_append(reply, reply_size, &used,
        "%s{\"name\":\"%s\",\"meta-type\":\"command\","
        "\"arg-type\":\"q_empty\",\"ret-type\":\"%s\",\"features\":[]}",
        i == 0 ? "" : ",", qmp_commands[i].name, qmp_commands[i].ret_type);
  }
  qmp_append(reply, reply_size, &used, "]}");
}

static void qmp_format_event_list(char *reply, size_t reply_size) {
  size_t used = 0;
  qmp_append(reply, reply_size, &used, "{\"return\":[");
  for (size_t i = 0; i < ARRLEN(qmp_events); i++) {
    // QMP 事件已经真实发送；这里给管理端提供同源事件清单，避免文档和实现漂移。
    qmp_append(reply, reply_size, &used, "%s{\"name\":\"%s\"}",
        i == 0 ? "" : ",", qmp_events[i]);
  }
  qmp_append(reply, reply_size, &used, "]}");
}

typedef enum {
  QMP_ACTION_KEEP_GOING,
  QMP_ACTION_CONTINUE,
  QMP_ACTION_QUIT,
} QMPAction;

static QMPAction qmp_request_system_reset(int fd, const char *request_id) {
  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    char reply[256];
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\",\"desc\":\"system_reset is only supported before cont in this NEMU QMP baseline\"}}");
    return qmp_write_reply(fd, reply, request_id) ? QMP_ACTION_KEEP_GOING : QMP_ACTION_QUIT;
  }

#if defined(CONFIG_ISA_riscv)
  Log("QMP system_reset requested");
  // 当前基线只做 startup/prelaunch reset：重置 CPU/CLINT/PLIC/PC，不重写 PMEM 镜像。
  isa_riscv_restart();
  nemu_state.state = NEMU_STOP;
  nemu_state.halt_pc = cpu.pc;
  nemu_state.halt_ret = 0;
  atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
  atomic_store_explicit(&qmp_cpu_paused, false, memory_order_release);
  atomic_store_explicit(&qmp_shutdown_event_sent, false, memory_order_release);
  if (!qmp_write_event(fd, "RESET") ||
      !qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
    return QMP_ACTION_QUIT;
  }
  return QMP_ACTION_KEEP_GOING;
#else
  char reply[256];
  snprintf(reply, sizeof(reply),
      "{\"error\":{\"class\":\"GenericError\",\"desc\":\"system_reset is unsupported for this ISA\"}}");
  return qmp_write_reply(fd, reply, request_id) ? QMP_ACTION_KEEP_GOING : QMP_ACTION_QUIT;
#endif
}

static QMPAction qmp_request_powerdown(int fd, const char *request_id,
    const char *command_name) {
  Log("QMP %s requested", command_name);
  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    nemu_state.state = NEMU_QUIT;
  }
  // QMP 主动关机和 quit 都走同一条停机/事件路径，避免管理面命令语义漂移。
  qmp_resume_cpu();
  if (!qmp_emit_shutdown_event(fd) ||
      !qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
    return QMP_ACTION_QUIT;
  }
  return QMP_ACTION_QUIT;
}

static QMPAction qmp_handle_command(int fd, const char *line) {
  char reply[8192];
  char command[96];
  char request_id[256];
  request_id[0] = '\0';
  qmp_extract_request_id(line, request_id, sizeof(request_id));

  if (!qmp_extract_execute(line, command, sizeof(command))) {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\",\"desc\":\"invalid QMP request\"}}");
  } else if (strcmp(command, "qmp_capabilities") == 0) {
    snprintf(reply, sizeof(reply), "{\"return\":{}}");
  } else if (strcmp(command, "query-status") == 0) {
    qmp_format_status(reply, sizeof(reply));
  } else if (strcmp(command, "query-memory-size-summary") == 0) {
    snprintf(reply, sizeof(reply),
        "{\"return\":{\"base-memory\":%llu,\"plugged-memory\":0}}",
        (unsigned long long)CONFIG_MSIZE);
  } else if (strcmp(command, "query-machines") == 0) {
    snprintf(reply, sizeof(reply),
        "{\"return\":[{\"name\":\"%s-nemu\",\"cpu-max\":1,"
        "\"hotpluggable-cpus\":false,\"is-default\":true}]}",
        CONFIG_ISA);
  } else if (strcmp(command, "query-cpus-fast") == 0) {
    snprintf(reply, sizeof(reply),
        "{\"return\":[{\"cpu-index\":0,\"qom-path\":\"/machine/unattached/device[0]\","
        "\"thread-id\":0,\"props\":{\"core-id\":0,\"thread-id\":0,\"socket-id\":0}}]}");
  } else if (strcmp(command, "query-block") == 0) {
#ifdef CONFIG_HAS_DISK
    virtio_blk_qmp_query_block(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-blockstats") == 0) {
#ifdef CONFIG_HAS_DISK
    virtio_blk_qmp_query_blockstats(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-chardev") == 0) {
#ifdef CONFIG_HAS_SERIAL
    serial_qmp_query_chardev(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-serial") == 0) {
#ifdef CONFIG_HAS_SERIAL
    serial_qmp_query_serial(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-netdev") == 0) {
#ifdef CONFIG_HAS_VIRTIO_NET
    virtio_net_qmp_query_netdev(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-rng") == 0) {
#ifdef CONFIG_HAS_VIRTIO_RNG
    virtio_rng_qmp_query_rng(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-rtc") == 0) {
#ifdef CONFIG_HAS_GOLDFISH_RTC
    goldfish_rtc_qmp_query_rtc(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
#endif
  } else if (strcmp(command, "query-interrupts") == 0) {
#if defined(CONFIG_ISA_riscv) && defined(CONFIG_ISA64)
    qmp_query_interrupts(reply, sizeof(reply));
#else
    snprintf(reply, sizeof(reply), "{\"return\":{}}");
#endif
  } else if (strcmp(command, "query-pci") == 0) {
    snprintf(reply, sizeof(reply), "{\"return\":[]}");
  } else if (strcmp(command, "query-version") == 0) {
    snprintf(reply, sizeof(reply),
        "{\"return\":{\"qemu\":{\"major\":0,\"minor\":0,\"micro\":1},"
        "\"package\":\"ysyx-nemu\"}}");
  } else if (strcmp(command, "query-kvm") == 0) {
    snprintf(reply, sizeof(reply), "{\"return\":{\"enabled\":false,\"present\":false}}");
  } else if (strcmp(command, "query-qmp-schema") == 0) {
    qmp_format_schema(reply, sizeof(reply));
  } else if (strcmp(command, "query-events") == 0) {
    qmp_format_event_list(reply, sizeof(reply));
  } else if (strcmp(command, "query-commands") == 0) {
    qmp_format_command_list(reply, sizeof(reply));
  } else if (strcmp(command, "cont") == 0) {
    bool was_cont_requested = atomic_exchange_explicit(&qmp_cont_requested,
        true, memory_order_acq_rel);
    if (!was_cont_requested) {
      qmp_resume_cpu();
      Log("QMP cont requested");
      if (!qmp_write_event(fd, "RESUME") ||
          !qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
        return QMP_ACTION_QUIT;
      }
      return QMP_ACTION_CONTINUE;
    }
    if (atomic_load_explicit(&qmp_stop_requested, memory_order_acquire) ||
        atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire)) {
      qmp_resume_cpu();
      Log("QMP cont requested from paused state");
      if (!qmp_write_event(fd, "RESUME") ||
          !qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
        return QMP_ACTION_QUIT;
      }
      return QMP_ACTION_KEEP_GOING;
    }
    Log("QMP cont requested while already running");
    if (!qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
      return QMP_ACTION_QUIT;
    }
    return QMP_ACTION_KEEP_GOING;
  } else if (strcmp(command, "stop") == 0) {
    if (!atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
      Log("QMP stop requested while prelaunch");
      if (!qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
        return QMP_ACTION_QUIT;
      }
      return QMP_ACTION_KEEP_GOING;
    }
    bool was_stop_requested = atomic_exchange_explicit(&qmp_stop_requested,
        true, memory_order_acq_rel);
    Log("QMP stop requested%s", was_stop_requested ? " while already paused" : "");
    if (!was_stop_requested && !qmp_write_event(fd, "STOP")) {
      return QMP_ACTION_QUIT;
    }
    if (!qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
      return QMP_ACTION_QUIT;
    }
    return QMP_ACTION_KEEP_GOING;
  } else if (strcmp(command, "system_reset") == 0) {
    return qmp_request_system_reset(fd, request_id);
  } else if (strcmp(command, "system_powerdown") == 0) {
    return qmp_request_powerdown(fd, request_id, "system_powerdown");
  } else if (strcmp(command, "quit") == 0) {
    return qmp_request_powerdown(fd, request_id, "quit");
  } else {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"CommandNotFound\",\"desc\":\"unsupported QMP command\"}}");
  }

  return qmp_write_reply(fd, reply, request_id) ? QMP_ACTION_KEEP_GOING : QMP_ACTION_QUIT;
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

  int expected_fd = client_fd;
  atomic_compare_exchange_strong_explicit(&qmp_runtime_client_fd, &expected_fd,
      -1, memory_order_acq_rel, memory_order_acquire);
  close(client_fd);
  Log("QMP runtime client disconnected");
  return NULL;
}

static void qmp_start_runtime_client(int client_fd) {
  pthread_t thread;
  atomic_store_explicit(&qmp_runtime_client_fd, client_fd, memory_order_release);
  int ret = pthread_create(&thread, NULL, qmp_runtime_client_main,
      (void *)(intptr_t)client_fd);
  Assert(ret == 0, "Can not start QMP runtime thread: %s", strerror(ret));
  pthread_detach(thread);
}

bool qmp_wait_for_client_if_enabled(void) {
  if (!qmp_is_enabled()) {
    return false;
  }

  atomic_store_explicit(&qmp_shutdown_event_sent, false, memory_order_release);
  atomic_store_explicit(&qmp_runtime_client_fd, -1, memory_order_release);

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

void qmp_notify_shutdown_event(void) {
}

#endif

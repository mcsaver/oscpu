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
#include "monitor.h"

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
static atomic_bool qmp_cpu_active;
static atomic_bool qmp_quit_requested;
static atomic_bool qmp_control_failed;
static atomic_bool qmp_initial_cont_pending;
static atomic_bool qmp_shutdown_event_sent;
static atomic_bool qmp_reset_event_sent;
static atomic_int qmp_runtime_client_fd = ATOMIC_VAR_INIT(-1);
static char qmp_initial_cont_request_id[256];
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
  return "startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown-quit";
}

static void qmp_format_status(char *reply, size_t reply_size) {
  const char *status = "prelaunch";
  bool running = false;

  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    int state = atomic_load_explicit(&nemu_state.state, memory_order_acquire);
    if (state == NEMU_ABORT) {
      status = "internal-error";
    } else if (state == NEMU_END || state == NEMU_QUIT || state == NEMU_REBOOT ||
        atomic_load_explicit(&qmp_quit_requested, memory_order_acquire)) {
      status = "shutdown";
    } else if (atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire)) {
      status = "paused";
    } else if (atomic_load_explicit(&qmp_cpu_active, memory_order_acquire)) {
      status = "running";
      running = true;
    } else {
      // cont 已经执行、但 cpu_exec() 已返回时，机器处于稳定的 STOP 状态。
      status = "paused";
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

static int qmp_requested_terminal_state(void) {
  return atomic_load_explicit(&qmp_control_failed, memory_order_acquire) ?
    NEMU_ABORT : NEMU_QUIT;
}

static void qmp_publish_requested_terminal_state(void) {
  int terminal_state = qmp_requested_terminal_state();
  atomic_store_explicit(&nemu_state.state, terminal_state, memory_order_release);
}

static void qmp_request_cpu_exit(bool control_failed) {
  pthread_mutex_lock(&qmp_pause_lock);
  if (control_failed) {
    atomic_store_explicit(&qmp_control_failed, true, memory_order_release);
  }
  atomic_store_explicit(&qmp_quit_requested, true, memory_order_release);
  atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
  if (!atomic_load_explicit(&qmp_cpu_active, memory_order_acquire)) {
    int expected = NEMU_STOP;
    int terminal_state = qmp_requested_terminal_state();
    atomic_compare_exchange_strong_explicit(&nemu_state.state, &expected,
        terminal_state, memory_order_acq_rel, memory_order_acquire);
  }
  pthread_cond_broadcast(&qmp_pause_cond);
  pthread_mutex_unlock(&qmp_pause_lock);
}

static bool qmp_mutable_query_is_safe(void) {
  if (!atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    return true;
  }
  if (atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire)) {
    return true;
  }
  // qmp_cpu_stopped_point() 用 release 发布 CPU/设备侧最后一次写入；这里的
  // acquire 保证终止或执行额度耗尽后的 snapshot 也有完整的一致视图。
  return !atomic_load_explicit(&qmp_cpu_active, memory_order_acquire);
}

static bool qmp_command_reads_mutable_device_state(const char *command) {
  return strcmp(command, "query-block") == 0 ||
    strcmp(command, "query-blockstats") == 0 ||
    strcmp(command, "query-chardev") == 0 ||
    strcmp(command, "query-serial") == 0 ||
    strcmp(command, "query-netdev") == 0 ||
    strcmp(command, "query-rng") == 0 ||
    strcmp(command, "query-rtc") == 0 ||
    strcmp(command, "query-interrupts") == 0;
}

void qmp_cpu_pause_point(void) {
  if (!atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    return;
  }
  if (atomic_load_explicit(&qmp_quit_requested, memory_order_acquire)) {
    qmp_publish_requested_terminal_state();
    return;
  }
  if (!atomic_load_explicit(&qmp_stop_requested, memory_order_acquire)) return;

  bool entered_pause = false;
  pthread_mutex_lock(&qmp_pause_lock);
  while (atomic_load_explicit(&qmp_stop_requested, memory_order_acquire) &&
      !atomic_load_explicit(&qmp_quit_requested, memory_order_acquire) &&
      atomic_load_explicit(&nemu_state.state, memory_order_acquire) == NEMU_RUNNING) {
    if (!entered_pause) {
      entered_pause = true;
      atomic_store_explicit(&qmp_cpu_paused, true, memory_order_release);
      pthread_cond_broadcast(&qmp_pause_cond);
      Log("QMP CPU paused");
    }
    pthread_cond_wait(&qmp_pause_cond, &qmp_pause_lock);
  }

  if (entered_pause) {
    atomic_store_explicit(&qmp_cpu_paused, false, memory_order_release);
    pthread_cond_broadcast(&qmp_pause_cond);
    Log("QMP CPU resumed");
  }
  if (atomic_load_explicit(&qmp_quit_requested, memory_order_acquire)) {
    qmp_publish_requested_terminal_state();
  }
  pthread_mutex_unlock(&qmp_pause_lock);
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

static bool qmp_write_event_unlocked(int fd, const char *event) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);

  char line[256];
  snprintf(line, sizeof(line),
      "{\"event\":\"%s\",\"timestamp\":{\"seconds\":%lld,"
      "\"microseconds\":%ld},\"data\":{}}",
      event, (long long)ts.tv_sec, (long)(ts.tv_nsec / 1000));
  return qmp_write_line_unlocked(fd, line);
}

static bool qmp_write_event(int fd, const char *event) {
  pthread_mutex_lock(&qmp_write_lock);
  bool ok = qmp_write_event_unlocked(fd, event);
  pthread_mutex_unlock(&qmp_write_lock);
  return ok;
}

static bool qmp_emit_shutdown_event(int fd) {
  // Claim, wire write and publication form one ordered transaction with every
  // other event/reply writer.  Publishing the flag before send() would let a
  // concurrent quit close the fd while the guest-shutdown event is in flight.
  pthread_mutex_lock(&qmp_write_lock);
  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire) &&
      atomic_load_explicit(&qmp_runtime_client_fd, memory_order_acquire) != fd) {
    pthread_mutex_unlock(&qmp_write_lock);
    return false;
  }
  bool sent = atomic_load_explicit(&qmp_shutdown_event_sent,
      memory_order_acquire);
  bool ok = true;
  if (!sent) {
    ok = qmp_write_event_unlocked(fd, "SHUTDOWN");
    if (ok) {
      atomic_store_explicit(&qmp_shutdown_event_sent, true,
          memory_order_release);
    }
  }
  pthread_mutex_unlock(&qmp_write_lock);
  return ok;
}

static bool qmp_emit_reset_event(int fd) {
  pthread_mutex_lock(&qmp_write_lock);
  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire) &&
      atomic_load_explicit(&qmp_runtime_client_fd, memory_order_acquire) != fd) {
    pthread_mutex_unlock(&qmp_write_lock);
    return false;
  }
  bool sent = atomic_load_explicit(&qmp_reset_event_sent,
      memory_order_acquire);
  bool ok = true;
  if (!sent) {
    ok = qmp_write_event_unlocked(fd, "RESET");
    if (ok) {
      atomic_store_explicit(&qmp_reset_event_sent, true,
          memory_order_release);
    }
  }
  pthread_mutex_unlock(&qmp_write_lock);
  return ok;
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

void qmp_notify_reset_event(void) {
  if (!qmp_is_enabled() ||
      !atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    return;
  }

  int fd = atomic_load_explicit(&qmp_runtime_client_fd, memory_order_acquire);
  if (fd < 0) {
    return;
  }

  // guest reboot 是独立机器生命周期事件，不能伪装成自然关机。
  if (qmp_emit_reset_event(fd)) {
    Log("QMP guest reset event emitted");
  } else {
    Log("QMP guest reset event failed");
  }
}

typedef enum {
  QMP_READ_EOF,
  QMP_READ_LINE,
  QMP_READ_INVALID,
  QMP_READ_OVERSIZED,
} QMPReadResult;

static inline bool qmp_utf8_continuation(unsigned char ch) {
  return ch >= 0x80 && ch <= 0xbf;
}

static bool qmp_utf8_valid(const char *text, size_t len) {
  const unsigned char *bytes = (const unsigned char *)text;
  size_t i = 0;
  while (i < len) {
    unsigned char first = bytes[i];
    if (first <= 0x7f) {
      i++;
      continue;
    }

    if (first >= 0xc2 && first <= 0xdf) {
      if (len - i < 2 || !qmp_utf8_continuation(bytes[i + 1])) return false;
      i += 2;
      continue;
    }

    if (first >= 0xe0 && first <= 0xef) {
      if (len - i < 3 || !qmp_utf8_continuation(bytes[i + 1]) ||
          !qmp_utf8_continuation(bytes[i + 2])) {
        return false;
      }
      // E0 80..9f is overlong; ED a0..bf encodes UTF-16 surrogates.
      if ((first == 0xe0 && bytes[i + 1] < 0xa0) ||
          (first == 0xed && bytes[i + 1] > 0x9f)) {
        return false;
      }
      i += 3;
      continue;
    }

    if (first >= 0xf0 && first <= 0xf4) {
      if (len - i < 4 || !qmp_utf8_continuation(bytes[i + 1]) ||
          !qmp_utf8_continuation(bytes[i + 2]) ||
          !qmp_utf8_continuation(bytes[i + 3])) {
        return false;
      }
      // F0 80..8f is overlong; F4 90..bf is above U+10ffff.
      if ((first == 0xf0 && bytes[i + 1] < 0x90) ||
          (first == 0xf4 && bytes[i + 1] > 0x8f)) {
        return false;
      }
      i += 4;
      continue;
    }

    // Continuation bytes, C0/C1 overlong leaders and F5..FF are invalid.
    return false;
  }
  return true;
}

static QMPReadResult qmp_read_line(int fd, char *line, size_t cap) {
  if (cap == 0) {
    return QMP_READ_EOF;
  }

  size_t len = 0;
  bool invalid = false;
  bool oversized = false;
  while (true) {
    char ch;
    ssize_t n = read(fd, &ch, 1);
    if (n < 0 && errno == EINTR) continue;
    // A request is a newline-delimited JSON frame.  Never execute an
    // unterminated prefix when the peer disconnects midway through a frame.
    if (n <= 0) return QMP_READ_EOF;
    if (ch == '\n') {
      break;
    }
    // The parser operates on a NUL-terminated C string.  A raw NUL on the
    // wire must invalidate the entire frame; otherwise a valid destructive
    // prefix followed by NUL and garbage would be dispatched unchecked.
    if (ch == '\0') {
      invalid = true;
      continue;
    }
    if (len + 1 < cap) {
      line[len++] = ch;
    } else {
      // Count every wire byte, including CR.  Silently dropping embedded CR
      // would both normalize malformed JSON into an executable command and
      // allow an unbounded CR stream to evade the frame limit.
      oversized = true;
    }
  }
  if (!oversized && len > 0 && line[len - 1] == '\r') len--;
  line[len] = '\0';
  // RFC 8259 JSON exchanged across systems must be UTF-8.  Validate the
  // complete frame before parsing any command so invalid bytes hidden in an
  // ignored field or request id can neither trigger a side effect nor be
  // reflected into an invalid JSON reply.
  if (!invalid && !oversized && !qmp_utf8_valid(line, len)) invalid = true;
  if (invalid) return QMP_READ_INVALID;
  return oversized ? QMP_READ_OVERSIZED : QMP_READ_LINE;
}

static bool qmp_reject_invalid_frame(int fd) {
  return qmp_write_line(fd,
      "{\"error\":{\"class\":\"GenericError\","
      "\"desc\":\"invalid QMP request\"}}");
}

static bool qmp_reject_oversized_frame(int fd) {
  return qmp_write_line(fd,
      "{\"error\":{\"class\":\"GenericError\","
      "\"desc\":\"oversized QMP request frame\"}}");
}

static const char *qmp_skip_ws(const char *p) {
  // RFC 8259 JSON whitespace is exactly SP, HT, LF and CR.  C isspace()
  // additionally accepts VT/FF, which could normalize malformed input into a
  // destructive command such as system_powerdown.
  while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') {
    p++;
  }
  return p;
}

typedef enum {
  QMP_ID_ABSENT,
  QMP_ID_VALID,
  QMP_ID_INVALID,
} QMPIdParseResult;

static bool qmp_json_parse_string(const char **cursor, char *out,
    size_t out_size, bool *overflow) {
  const char *p = *cursor;
  size_t used = 0;
  bool too_long = false;
  if (*p != '"') return false;
  p++;

  while (*p != '\0') {
    unsigned char ch = (unsigned char)*p++;
    if (ch == '"') {
      if (out_size > 0) out[used] = '\0';
      if (overflow != NULL) *overflow = too_long;
      *cursor = p;
      return true;
    }
    if (ch < 0x20) return false;
    if (ch == '\\') {
      unsigned char escaped = (unsigned char)*p++;
      if (escaped == '\0') return false;
      switch (escaped) {
        case '"': case '\\': case '/': ch = escaped; break;
        case 'b': ch = '\b'; break;
        case 'f': ch = '\f'; break;
        case 'n': ch = '\n'; break;
        case 'r': ch = '\r'; break;
        case 't': ch = '\t'; break;
        case 'u': {
          unsigned value = 0;
          for (int i = 0; i < 4; i++) {
            unsigned char hex = (unsigned char)*p++;
            if (!isxdigit(hex)) return false;
            value <<= 4;
            if (hex >= '0' && hex <= '9') value |= hex - '0';
            else value |= (unsigned)(tolower(hex) - 'a' + 10);
          }
          // Control keys and commands are ASCII.  Decode ASCII escapes for
          // exact matching; a non-ASCII string stays syntactically valid but
          // cannot be mistaken for a recognized key or command.
          ch = value > 0 && value <= 0x7f ? (unsigned char)value : 0x80;
          break;
        }
        default: return false;
      }
    }
    if (out_size > 0) {
      if (used + 1 < out_size) out[used++] = (char)ch;
      else too_long = true;
    }
  }
  return false;
}

static bool qmp_json_skip_number(const char **cursor) {
  const char *p = *cursor;
  if (*p == '-') p++;
  if (*p == '0') {
    p++;
  } else if (*p >= '1' && *p <= '9') {
    do p++; while (isdigit((unsigned char)*p));
  } else {
    return false;
  }
  if (*p == '.') {
    p++;
    if (!isdigit((unsigned char)*p)) return false;
    do p++; while (isdigit((unsigned char)*p));
  }
  if (*p == 'e' || *p == 'E') {
    p++;
    if (*p == '+' || *p == '-') p++;
    if (!isdigit((unsigned char)*p)) return false;
    do p++; while (isdigit((unsigned char)*p));
  }
  *cursor = p;
  return true;
}

static bool qmp_json_skip_value(const char **cursor, unsigned depth) {
  if (depth > 32) return false;
  const char *p = qmp_skip_ws(*cursor);
  if (*p == '"') {
    if (!qmp_json_parse_string(&p, NULL, 0, NULL)) return false;
  } else if (*p == '{') {
    p = qmp_skip_ws(p + 1);
    if (*p != '}') {
      while (true) {
        if (!qmp_json_parse_string(&p, NULL, 0, NULL)) return false;
        p = qmp_skip_ws(p);
        if (*p++ != ':') return false;
        if (!qmp_json_skip_value(&p, depth + 1)) return false;
        p = qmp_skip_ws(p);
        if (*p == '}') break;
        if (*p++ != ',') return false;
        p = qmp_skip_ws(p);
      }
    }
    p++;
  } else if (*p == '[') {
    p = qmp_skip_ws(p + 1);
    if (*p != ']') {
      while (true) {
        if (!qmp_json_skip_value(&p, depth + 1)) return false;
        p = qmp_skip_ws(p);
        if (*p == ']') break;
        if (*p++ != ',') return false;
        p = qmp_skip_ws(p);
      }
    }
    p++;
  } else if (strncmp(p, "true", 4) == 0) {
    p += 4;
  } else if (strncmp(p, "false", 5) == 0) {
    p += 5;
  } else if (strncmp(p, "null", 4) == 0) {
    p += 4;
  } else if (!qmp_json_skip_number(&p)) {
    return false;
  }
  *cursor = p;
  return true;
}

static bool qmp_parse_request(const char *line, char *command,
    size_t command_size, bool *has_command, char *id, size_t id_size,
    QMPIdParseResult *id_result) {
  const char *p = qmp_skip_ws(line);
  bool execute_seen = false;
  bool id_seen = false;
  if (command_size == 0 || id_size == 0 || *p != '{') return false;
  command[0] = '\0';
  id[0] = '\0';
  *has_command = false;
  *id_result = QMP_ID_ABSENT;
  p = qmp_skip_ws(p + 1);

  if (*p != '}') {
    while (true) {
      char key[32];
      bool key_overflow = false;
      if (!qmp_json_parse_string(&p, key, sizeof(key), &key_overflow)) {
        return false;
      }
      p = qmp_skip_ws(p);
      if (*p++ != ':') return false;
      p = qmp_skip_ws(p);

      bool is_execute = !key_overflow && strcmp(key, "execute") == 0;
      bool is_id = !key_overflow && strcmp(key, "id") == 0;
      if (is_execute) {
        bool command_overflow = false;
        if (execute_seen || !qmp_json_parse_string(&p, command,
              command_size, &command_overflow) || command_overflow) {
          return false;
        }
        execute_seen = true;
        *has_command = true;
      } else if (is_id) {
        if (id_seen) return false;
        id_seen = true;
        const char *id_start = p;
        if (*p == '"') {
          if (!qmp_json_parse_string(&p, NULL, 0, NULL)) return false;
        } else if (!qmp_json_skip_number(&p)) {
          *id_result = QMP_ID_INVALID;
          if (!qmp_json_skip_value(&p, 1)) return false;
        }
        if (*id_result != QMP_ID_INVALID) {
          size_t id_len = (size_t)(p - id_start);
          if (id_len == 0 || id_len >= id_size) {
            *id_result = QMP_ID_INVALID;
          } else {
            memcpy(id, id_start, id_len);
            id[id_len] = '\0';
            *id_result = QMP_ID_VALID;
          }
        }
      } else if (!qmp_json_skip_value(&p, 1)) {
        return false;
      }

      p = qmp_skip_ws(p);
      if (*p == '}') break;
      if (*p++ != ',') return false;
      p = qmp_skip_ws(p);
    }
  }
  p = qmp_skip_ws(p + 1);
  return *p == '\0';
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

void qmp_cpu_running_point(void) {
  if (!qmp_is_enabled()) return;

  char request_id[sizeof(qmp_initial_cont_request_id)];
  request_id[0] = '\0';

  pthread_mutex_lock(&qmp_pause_lock);
  atomic_store_explicit(&qmp_cpu_active, true, memory_order_release);
  bool initial_cont = atomic_load_explicit(&qmp_initial_cont_pending,
      memory_order_acquire);
  if (initial_cont) {
    snprintf(request_id, sizeof(request_id), "%s", qmp_initial_cont_request_id);
  }
  pthread_cond_broadcast(&qmp_pause_cond);
  pthread_mutex_unlock(&qmp_pause_lock);

  if (!initial_cont) return;

  // 首次 cont 的成功回复是一个 CPU 线程确认点：只有 STOP->RUNNING 已经
  // 完成，管理端才会收到 RESUME 和 reply。这样 query-status 不会观察到
  // “cont 已成功但 CPU 仍未启动”的伪 paused 窗口。
  int fd = atomic_load_explicit(&qmp_runtime_client_fd, memory_order_acquire);
  bool delivered = fd >= 0 && qmp_write_event(fd, "RESUME") &&
    qmp_write_reply(fd, "{\"return\":{}}", request_id);

  pthread_mutex_lock(&qmp_pause_lock);
  atomic_store_explicit(&qmp_initial_cont_pending, false, memory_order_release);
  if (!delivered) {
    atomic_store_explicit(&qmp_control_failed, true, memory_order_release);
    atomic_store_explicit(&qmp_quit_requested, true, memory_order_release);
    atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
    // 这里运行在 CPU 线程上，不会与客户机执行路径竞争状态所有权。
    qmp_publish_requested_terminal_state();
  }
  pthread_cond_broadcast(&qmp_pause_cond);
  pthread_mutex_unlock(&qmp_pause_lock);

  if (delivered) {
    Log("QMP initial cont acknowledged after CPU entered RUNNING");
  } else {
    Log("QMP initial cont reply failed; requesting NEMU quit");
  }
}

void qmp_cpu_stopped_point(void) {
  if (!qmp_is_enabled()) return;

  pthread_mutex_lock(&qmp_pause_lock);
  if (atomic_load_explicit(&qmp_quit_requested, memory_order_acquire)) {
    int state = atomic_load_explicit(&nemu_state.state, memory_order_acquire);
    int terminal_state = qmp_requested_terminal_state();
    while (state == NEMU_RUNNING || state == NEMU_STOP) {
      if (atomic_compare_exchange_weak_explicit(&nemu_state.state, &state,
            terminal_state, memory_order_acq_rel, memory_order_acquire)) {
        break;
      }
    }
  }

  atomic_store_explicit(&qmp_cpu_paused, false, memory_order_release);
  atomic_store_explicit(&qmp_cpu_active, false, memory_order_release);
  pthread_cond_broadcast(&qmp_pause_cond);
  pthread_mutex_unlock(&qmp_pause_lock);
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
  QMP_ACTION_CLEAN_EXIT,
  QMP_ACTION_IO_ERROR,
} QMPAction;

static QMPAction qmp_request_system_reset(int fd, const char *request_id) {
  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    char reply[256];
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\",\"desc\":\"system_reset is only supported before cont in this NEMU QMP baseline\"}}");
    return qmp_write_reply(fd, reply, request_id) ?
      QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
  }

#if defined(CONFIG_ISA_riscv)
  Log("QMP system_reset requested");
  // 当前基线只做 startup/prelaunch reset：重置 CPU/CLINT/PLIC/PC，不重写 PMEM 镜像。
  isa_riscv_restart();
  // isa_riscv_restart() 会清空全部 GPR；QMP reset 后必须恢复 Linux/OpenSBI
  // 启动 ABI，否则 --boot-hartid/--boot-dtb 会在 cont 前静默丢失。
  monitor_apply_boot_arguments();
  nemu_state.state = NEMU_STOP;
  nemu_state.halt_pc = cpu.pc;
  nemu_state.halt_ret = 0;
  atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
  atomic_store_explicit(&qmp_cpu_paused, false, memory_order_release);
  atomic_store_explicit(&qmp_shutdown_event_sent, false, memory_order_release);
  atomic_store_explicit(&qmp_reset_event_sent, false, memory_order_release);
  if (!qmp_write_event(fd, "RESET") ||
      !qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
    return QMP_ACTION_IO_ERROR;
  }
  return QMP_ACTION_KEEP_GOING;
#else
  char reply[256];
  snprintf(reply, sizeof(reply),
      "{\"error\":{\"class\":\"GenericError\",\"desc\":\"system_reset is unsupported for this ISA\"}}");
  return qmp_write_reply(fd, reply, request_id) ?
    QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
#endif
}

static QMPAction qmp_request_powerdown(int fd, const char *request_id,
    const char *command_name) {
  Log("QMP %s requested", command_name);
  // 先把完整事件和 reply 交给管理端，再发布退出请求；否则 detached QMP
  // worker 可能在 send() 前被随主线程进程退出截断。
  bool delivered = qmp_emit_shutdown_event(fd) &&
    qmp_write_reply(fd, "{\"return\":{}}", request_id);
  if (atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    qmp_request_cpu_exit(false);
  }
  return delivered ? QMP_ACTION_CLEAN_EXIT : QMP_ACTION_IO_ERROR;
}

static QMPAction qmp_handle_command(int fd, const char *line) {
  char reply[8192];
  char command[96];
  char request_id[256];
  bool has_command = false;
  QMPIdParseResult id_result = QMP_ID_ABSENT;
  if (!qmp_parse_request(line, command, sizeof(command), &has_command,
        request_id, sizeof(request_id), &id_result)) {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\","
        "\"desc\":\"invalid QMP request\"}}");
    return qmp_write_reply(fd, reply, NULL) ?
      QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
  }
  if (id_result == QMP_ID_INVALID) {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\","
        "\"desc\":\"invalid or oversized QMP request id\"}}");
    return qmp_write_reply(fd, reply, NULL) ?
      QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
  }
  bool mutable_query = has_command &&
    qmp_command_reads_mutable_device_state(command);
  bool mutable_query_safe = true;
  bool mutable_query_locked = false;

  if (mutable_query) {
    // 与 cpu_running/stopped/pause 三个确认点共用同一把锁。CPU 即使已完成
    // STOP->RUNNING CAS，也必须等 snapshot 结束才能进入设备执行路径。
    pthread_mutex_lock(&qmp_pause_lock);
    mutable_query_safe = qmp_mutable_query_is_safe();
    mutable_query_locked = mutable_query_safe;
    if (!mutable_query_safe) pthread_mutex_unlock(&qmp_pause_lock);
  }

  if (!has_command) {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\",\"desc\":\"invalid QMP request\"}}");
  } else if (mutable_query && !mutable_query_safe) {
    snprintf(reply, sizeof(reply),
        "{\"error\":{\"class\":\"GenericError\","
        "\"desc\":\"%s requires the CPU to be prelaunch, paused, or stopped\"}}",
        command);
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
      pthread_mutex_lock(&qmp_pause_lock);
      snprintf(qmp_initial_cont_request_id,
          sizeof(qmp_initial_cont_request_id), "%s", request_id);
      atomic_store_explicit(&qmp_initial_cont_pending, true,
          memory_order_release);
      pthread_mutex_unlock(&qmp_pause_lock);
      Log("QMP cont requested");
      // 首次回复由 cpu_exec() 的 RUNNING 确认点发送。
      return QMP_ACTION_CONTINUE;
    }
    pthread_mutex_lock(&qmp_pause_lock);
    bool cpu_active = atomic_load_explicit(&qmp_cpu_active,
        memory_order_acquire);
    bool cpu_paused = atomic_load_explicit(&qmp_cpu_paused,
        memory_order_acquire);
    bool stop_requested = atomic_load_explicit(&qmp_stop_requested,
        memory_order_acquire);
    bool quitting = atomic_load_explicit(&qmp_quit_requested,
        memory_order_acquire);
    int cpu_state = atomic_load_explicit(&nemu_state.state,
        memory_order_acquire);
    if (!cpu_active || cpu_state != NEMU_RUNNING || quitting) {
      pthread_mutex_unlock(&qmp_pause_lock);
      snprintf(reply, sizeof(reply),
          "{\"error\":{\"class\":\"GenericError\","
          "\"desc\":\"CPU execution loop is no longer active\"}}");
      return qmp_write_reply(fd, reply, request_id) ?
        QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
    }
    if (stop_requested || cpu_paused) {
      atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
      pthread_cond_broadcast(&qmp_pause_cond);
      while (atomic_load_explicit(&qmp_cpu_active, memory_order_acquire) &&
          atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire) &&
          !atomic_load_explicit(&qmp_quit_requested, memory_order_acquire) &&
          atomic_load_explicit(&nemu_state.state, memory_order_acquire) ==
            NEMU_RUNNING) {
        pthread_cond_wait(&qmp_pause_cond, &qmp_pause_lock);
      }
      bool resumed = atomic_load_explicit(&qmp_cpu_active,
          memory_order_acquire) &&
        !atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire) &&
        !atomic_load_explicit(&qmp_quit_requested, memory_order_acquire) &&
        atomic_load_explicit(&nemu_state.state, memory_order_acquire) ==
          NEMU_RUNNING;
      pthread_mutex_unlock(&qmp_pause_lock);
      Log("QMP cont requested from paused state");
      if (!resumed) {
        snprintf(reply, sizeof(reply),
            "{\"error\":{\"class\":\"GenericError\","
            "\"desc\":\"CPU terminated before the cont request completed\"}}");
        return qmp_write_reply(fd, reply, request_id) ?
          QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
      }
      if (!qmp_write_event(fd, "RESUME") ||
          !qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
        return QMP_ACTION_IO_ERROR;
      }
      return QMP_ACTION_KEEP_GOING;
    }
    pthread_mutex_unlock(&qmp_pause_lock);
    Log("QMP cont requested while already running");
    if (!qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
      return QMP_ACTION_IO_ERROR;
    }
    return QMP_ACTION_KEEP_GOING;
  } else if (strcmp(command, "stop") == 0) {
    if (!atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
      Log("QMP stop requested while prelaunch");
      if (!qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
        return QMP_ACTION_IO_ERROR;
      }
      return QMP_ACTION_KEEP_GOING;
    }
    pthread_mutex_lock(&qmp_pause_lock);
    bool was_stop_requested = atomic_load_explicit(&qmp_stop_requested,
        memory_order_acquire);
    atomic_store_explicit(&qmp_stop_requested, true, memory_order_release);
    while (atomic_load_explicit(&qmp_cpu_active, memory_order_acquire) &&
        !atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire) &&
        !atomic_load_explicit(&qmp_quit_requested, memory_order_acquire)) {
      pthread_cond_wait(&qmp_pause_cond, &qmp_pause_lock);
    }
    bool stopped = atomic_load_explicit(&qmp_cpu_paused, memory_order_acquire) ||
      (!atomic_load_explicit(&qmp_cpu_active, memory_order_acquire) &&
       atomic_load_explicit(&nemu_state.state, memory_order_acquire) == NEMU_STOP);
    if (!stopped) {
      atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
    }
    pthread_mutex_unlock(&qmp_pause_lock);
    Log("QMP stop requested%s", was_stop_requested ? " while already paused" : "");
    if (!stopped) {
      snprintf(reply, sizeof(reply),
          "{\"error\":{\"class\":\"GenericError\","
          "\"desc\":\"CPU terminated before the stop request completed\"}}");
      return qmp_write_reply(fd, reply, request_id) ?
        QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
    }
    if (!was_stop_requested && !qmp_write_event(fd, "STOP")) {
      return QMP_ACTION_IO_ERROR;
    }
    if (!qmp_write_reply(fd, "{\"return\":{}}", request_id)) {
      return QMP_ACTION_IO_ERROR;
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

  if (mutable_query_locked) pthread_mutex_unlock(&qmp_pause_lock);
  return qmp_write_reply(fd, reply, request_id) ?
    QMP_ACTION_KEEP_GOING : QMP_ACTION_IO_ERROR;
}

static void *qmp_runtime_client_main(void *opaque) {
  int client_fd = (int)(intptr_t)opaque;
  bool clean_exit = false;

  // qmp_wait_for_client_if_enabled() 必须先返回，CPU 才能进入 cpu_exec()；
  // runtime reader 在首次 cont 的 CPU-side reply 完成前不得处理流水化请求。
  pthread_mutex_lock(&qmp_pause_lock);
  while (atomic_load_explicit(&qmp_initial_cont_pending, memory_order_acquire) &&
      !atomic_load_explicit(&qmp_quit_requested, memory_order_acquire)) {
    pthread_cond_wait(&qmp_pause_cond, &qmp_pause_lock);
  }
  bool startup_failed = atomic_load_explicit(&qmp_quit_requested,
      memory_order_acquire);
  pthread_mutex_unlock(&qmp_pause_lock);
  Log("QMP runtime client active");

  char line[4096];
  while (!startup_failed) {
    QMPReadResult read_result = qmp_read_line(client_fd, line, sizeof(line));
    if (read_result == QMP_READ_EOF) {
      break;
    }
    if (read_result == QMP_READ_INVALID) {
      if (!qmp_reject_invalid_frame(client_fd)) {
        break;
      }
      continue;
    }
    if (read_result == QMP_READ_OVERSIZED) {
      if (!qmp_reject_oversized_frame(client_fd)) {
        break;
      }
      continue;
    }
    QMPAction action = qmp_handle_command(client_fd, line);
    if (action == QMP_ACTION_CLEAN_EXIT) {
      clean_exit = true;
      break;
    }
    if (action == QMP_ACTION_IO_ERROR) {
      break;
    }
  }

  // Pair fd retirement/close with CPU-side event sends.  A notifier that
  // sampled the old integer must revalidate it after taking qmp_write_lock,
  // so an OS-reused descriptor can never receive a stale QMP event.
  pthread_mutex_lock(&qmp_write_lock);
  int expected_fd = client_fd;
  atomic_compare_exchange_strong_explicit(&qmp_runtime_client_fd, &expected_fd,
      -1, memory_order_acq_rel, memory_order_acquire);
  close(client_fd);
  pthread_mutex_unlock(&qmp_write_lock);
  if (!clean_exit &&
      atomic_load_explicit(&qmp_cont_requested, memory_order_acquire)) {
    Log("QMP runtime client disconnected unexpectedly; requesting NEMU abort");
    // stop 后 CPU 可能正睡在 qmp_pause_cond；退出请求同时解除等待，并由
    // CPU 线程在安全点发布 NEMU_ABORT，避免覆盖 guest
    // END/REBOOT；管理连接异常丢失必须向 supervisor 返回失败。
    qmp_request_cpu_exit(true);
  } else {
    Log("QMP runtime client disconnected");
  }
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

QMPStartupResult qmp_wait_for_client_if_enabled(void) {
  if (!qmp_is_enabled()) {
    return QMP_STARTUP_RUN_GUEST;
  }

  atomic_store_explicit(&qmp_shutdown_event_sent, false, memory_order_release);
  atomic_store_explicit(&qmp_reset_event_sent, false, memory_order_release);
  atomic_store_explicit(&qmp_runtime_client_fd, -1, memory_order_release);
  atomic_store_explicit(&qmp_cont_requested, false, memory_order_release);
  atomic_store_explicit(&qmp_stop_requested, false, memory_order_release);
  atomic_store_explicit(&qmp_cpu_paused, false, memory_order_release);
  atomic_store_explicit(&qmp_cpu_active, false, memory_order_release);
  atomic_store_explicit(&qmp_quit_requested, false, memory_order_release);
  atomic_store_explicit(&qmp_control_failed, false, memory_order_release);
  atomic_store_explicit(&qmp_initial_cont_pending, false, memory_order_release);
  qmp_initial_cont_request_id[0] = '\0';

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

  bool runtime_client = false;
  QMPStartupResult result = QMP_STARTUP_EXIT_FAILURE;
  if (!qmp_write_line(client_fd,
      "{\"QMP\":{\"version\":{\"qemu\":{\"major\":0,\"minor\":0,\"micro\":1},"
      "\"package\":\"ysyx-nemu\"},\"capabilities\":[]}}")) {
    close(client_fd);
    return QMP_STARTUP_EXIT_FAILURE;
  }

  char line[4096];
  while (true) {
    QMPReadResult read_result = qmp_read_line(client_fd, line, sizeof(line));
    if (read_result == QMP_READ_EOF) {
      break;
    }
    if (read_result == QMP_READ_INVALID) {
      if (!qmp_reject_invalid_frame(client_fd)) {
        result = QMP_STARTUP_EXIT_FAILURE;
        break;
      }
      continue;
    }
    if (read_result == QMP_READ_OVERSIZED) {
      if (!qmp_reject_oversized_frame(client_fd)) {
        result = QMP_STARTUP_EXIT_FAILURE;
        break;
      }
      continue;
    }
    QMPAction action = qmp_handle_command(client_fd, line);
    if (action == QMP_ACTION_CONTINUE) {
      // cont 之后保留同一个 QMP 连接到后台线程，用于运行期只读查询与 quit。
      qmp_start_runtime_client(client_fd);
      runtime_client = true;
      result = QMP_STARTUP_RUN_GUEST;
      break;
    }
    if (action == QMP_ACTION_CLEAN_EXIT) {
      result = QMP_STARTUP_EXIT_SUCCESS;
      break;
    }
    if (action == QMP_ACTION_IO_ERROR) {
      result = QMP_STARTUP_EXIT_FAILURE;
      break;
    }
  }

  if (!runtime_client) {
    close(client_fd);
  }
  return result;
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

QMPStartupResult qmp_wait_for_client_if_enabled(void) {
  return QMP_STARTUP_RUN_GUEST;
}

void qmp_cpu_running_point(void) {
}

void qmp_cpu_pause_point(void) {
}

void qmp_cpu_stopped_point(void) {
}

void qmp_notify_shutdown_event(void) {
}

void qmp_notify_reset_event(void) {
}

#endif

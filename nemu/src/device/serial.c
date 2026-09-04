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

#include <utils.h>
#include <utils/profile.h>
#include <device/map.h>
#include <device/uart16550.h>
#include <isa.h>
#include <memory/paddr.h>
#include <memory/vaddr.h>

#ifndef CONFIG_TARGET_AM
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

/*
 * NEMU serial front-end.
 *
 * The 16550A device model lives in uart16550.c.  This file owns only the
 * platform shell around it: NEMU IOMap registration, host input endpoints,
 * TX output, and the RISC-V PLIC IRQ wire.
 */

#define SERIAL_UART0_IRQ 1u
#define SERIAL_HOST_RX_POLL_CHUNK 512u
#define SERIAL_HOST_RX_POLL_BUDGET 16u
#define SERIAL_HOST_RX_STAGING_CAP 1048576u
#define SERIAL_TX_BUFFER_CAP 4096u
#define SERIAL_TRACE_MARKER_LINE_CAP 512u
#define SERIAL_QMP_FILENAME_CAP 6144u
#ifdef CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL
#define SERIAL_INPUT_HOST_POLL_INTERVAL_VALUE CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL
#else
#define SERIAL_INPUT_HOST_POLL_INTERVAL_VALUE 1
#endif

#if SERIAL_INPUT_HOST_POLL_INTERVAL_VALUE <= 0
#error "CONFIG_SERIAL_INPUT_HOST_POLL_INTERVAL must be positive"
#endif

#define SERIAL_INPUT_HOST_POLL_INTERVAL \
  ((uint32_t)SERIAL_INPUT_HOST_POLL_INTERVAL_VALUE)

#if !defined(CONFIG_TARGET_AM) && \
    (defined(CONFIG_SERIAL_INPUT_STDIN) || defined(CONFIG_SERIAL_INPUT_FIFO))
#define SERIAL_HAS_HOST_RX 1
#endif

#ifdef SERIAL_HAS_HOST_RX
typedef struct {
  uint8_t *data;
  uint32_t capacity;
  uint32_t head;
  uint32_t tail;
  uint32_t count;
} SerialByteFifo;
#endif

typedef struct {
  const char *name;
  uint32_t irq;
  Uart16550 *uart;
  Uart16550BusProfile bus_profile;
  uint32_t bus_map_size;
  uint8_t *bus_space;

#ifdef SERIAL_HAS_HOST_RX
  SerialByteFifo host_rx;
  uint8_t *host_rx_storage;
  uint64_t host_rx_dropped;
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_STDIN)
  bool stdin_eof;
  bool stdin_enabled;
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_FIFO)
  int fifo_fd;
  const char *fifo_path;
#endif
#ifndef CONFIG_TARGET_AM
  uint8_t tx_buffer[SERIAL_TX_BUFFER_CAP];
  uint32_t tx_count;
#endif
} SerialPort;

static SerialPort serial0 = {
  .name = "serial",
  .irq = SERIAL_UART0_IRQ,
  .bus_profile = UART16550_BUS_PROFILE_8BIT,
#if !defined(CONFIG_TARGET_AM) && defined(CONFIG_SERIAL_INPUT_STDIN)
  .stdin_enabled = true,
#endif
#if !defined(CONFIG_TARGET_AM) && defined(CONFIG_SERIAL_INPUT_FIFO)
  .fifo_fd = -1,
  .fifo_path = "/tmp/nemu.serial",
#endif
};

#ifndef CONFIG_TARGET_AM
static void serial_port_flush_tx(SerialPort *port);

static const char *serial_json_bool(bool value) {
  return value ? "true" : "false";
}

static const char *serial_host_backend_name(void) {
#if defined(CONFIG_SERIAL_INPUT_STDIN) && defined(CONFIG_SERIAL_INPUT_FIFO)
  static char backend[512];
  const char *fifo_path = serial0.fifo_path != NULL ? serial0.fifo_path : "/tmp/nemu.serial";
  if (serial0.stdin_enabled) {
    snprintf(backend, sizeof(backend), "stderr,stdin,fifo:%s", fifo_path);
  } else {
    snprintf(backend, sizeof(backend), "stderr,fifo:%s", fifo_path);
  }
  return backend;
#elif defined(CONFIG_SERIAL_INPUT_STDIN)
  return serial0.stdin_enabled ? "stderr,stdin" : "stderr";
#elif defined(CONFIG_SERIAL_INPUT_FIFO)
  static char backend[512];
  const char *fifo_path = serial0.fifo_path != NULL ? serial0.fifo_path : "/tmp/nemu.serial";
  snprintf(backend, sizeof(backend), "stderr,fifo:%s", fifo_path);
  return backend;
#else
  return "stderr";
#endif
}

static size_t serial_utf8_sequence_length(const uint8_t *text) {
  uint8_t first = text[0];
  if (first < 0x80u) return 1;
  if (first >= 0xc2u && first <= 0xdfu) {
    return text[1] >= 0x80u && text[1] <= 0xbfu ? 2 : 0;
  }
  if (first >= 0xe0u && first <= 0xefu) {
    uint8_t second = text[1];
    if (second == '\0') return 0;
    bool second_ok = first == 0xe0u ? second >= 0xa0u && second <= 0xbfu :
      first == 0xedu ? second >= 0x80u && second <= 0x9fu :
      second >= 0x80u && second <= 0xbfu;
    return second_ok && text[2] >= 0x80u && text[2] <= 0xbfu ? 3 : 0;
  }
  if (first >= 0xf0u && first <= 0xf4u) {
    uint8_t second = text[1];
    if (second == '\0') return 0;
    bool second_ok = first == 0xf0u ? second >= 0x90u && second <= 0xbfu :
      first == 0xf4u ? second >= 0x80u && second <= 0x8fu :
      second >= 0x80u && second <= 0xbfu;
    if (!second_ok || text[2] == '\0') return 0;
    return text[2] >= 0x80u && text[2] <= 0xbfu &&
      text[3] >= 0x80u && text[3] <= 0xbfu ? 4 : 0;
  }
  return 0;
}

static bool serial_json_append_string_bytes(char *out, size_t out_size,
    size_t *out_len, const char *value) {
  static const char hex[] = "0123456789abcdef";
  const uint8_t *cursor = (const uint8_t *)value;
  while (*cursor != '\0') {
    char escaped[6];
    const char *encoded = (const char *)cursor;
    size_t encoded_len = 1;
    if (*cursor == '"' || *cursor == '\\') {
      escaped[0] = '\\';
      escaped[1] = (char)*cursor;
      encoded = escaped;
      encoded_len = 2;
    } else if (*cursor < 0x20u) {
      escaped[0] = '\\';
      escaped[1] = 'u';
      escaped[2] = '0';
      escaped[3] = '0';
      escaped[4] = hex[*cursor >> 4];
      escaped[5] = hex[*cursor & 0x0fu];
      encoded = escaped;
      encoded_len = sizeof(escaped);
    } else if (*cursor >= 0x80u) {
      encoded_len = serial_utf8_sequence_length(cursor);
      if (encoded_len == 0) {
        escaped[0] = '\\';
        escaped[1] = 'u';
        escaped[2] = '0';
        escaped[3] = '0';
        escaped[4] = hex[*cursor >> 4];
        escaped[5] = hex[*cursor & 0x0fu];
        encoded = escaped;
        encoded_len = sizeof(escaped);
      }
    }

    /* Keep room for the caller's closing quote and trailing NUL. */
    if (*out_len > out_size || encoded_len > out_size - *out_len ||
        out_size - *out_len - encoded_len < 2) {
      return false;
    }
    memcpy(out + *out_len, encoded, encoded_len);
    *out_len += encoded_len;
    cursor += encoded == (const char *)cursor ? encoded_len : 1;
  }
  return true;
}

static bool serial_qmp_host_backend_json(char *out, size_t out_size) {
  if (out == NULL || out_size < 3) return false;
  size_t out_len = 0;
  out[out_len++] = '"';

  const char *base = "stderr";
#if defined(CONFIG_SERIAL_INPUT_STDIN)
  if (serial0.stdin_enabled) base = "stderr,stdin";
#endif
  if (!serial_json_append_string_bytes(out, out_size, &out_len, base)) {
    out[0] = '\0';
    return false;
  }
#if defined(CONFIG_SERIAL_INPUT_FIFO)
  const char *fifo_path = serial0.fifo_path != NULL ?
    serial0.fifo_path : "/tmp/nemu.serial";
  if (!serial_json_append_string_bytes(out, out_size, &out_len, ",fifo:") ||
      !serial_json_append_string_bytes(out, out_size, &out_len, fifo_path)) {
    out[0] = '\0';
    return false;
  }
#endif
  out[out_len++] = '"';
  out[out_len] = '\0';
  return true;
}

static void serial_qmp_backend_error(char *out, size_t out_size) {
  snprintf(out, out_size,
      "{\"error\":{\"class\":\"GenericError\","
      "\"desc\":\"serial host backend is too large for a QMP reply\"}}");
}

static bool serial_env_false(const char *value) {
  return value != NULL &&
    (strcmp(value, "0") == 0 ||
     strcmp(value, "false") == 0 ||
     strcmp(value, "FALSE") == 0 ||
     strcmp(value, "no") == 0 ||
     strcmp(value, "NO") == 0);
}

static bool serial_env_true(const char *value) {
  return value != NULL && value[0] != '\0' && !serial_env_false(value);
}

static bool serial_env_u64(const char *name, uint64_t *value) {
  const char *env = getenv(name);
  if (env == NULL || env[0] == '\0') {
    return false;
  }
  errno = 0;
  char *end = NULL;
  uint64_t parsed = strtoull(env, &end, 0);
  Assert(errno == 0 && end != env && *end == '\0',
      "invalid %s=%s, expect an integer", name, env);
  *value = parsed;
  return true;
}

static bool serial_trace_marker_enabled = false;
static const char *serial_trace_marker =
  "__PYTHON_INT_PREFLIGHT_PYLONG_ARGS_LOOPS_EARLY_ID__:";
static const char *serial_trace_paddr_marker =
  "__PYTHON_INT_PREFLIGHT_PYLONG_ARGS_LOOPS_EARLY_OB_SIZE_PADDR__:";
static const char *serial_trace_value_marker =
  "__PYTHON_INT_PREFLIGHT_PYLONG_ARGS_LOOPS_PREPARSE_CANDIDATE__:";
static const char *serial_trace_end_marker =
  "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__:";
static uint64_t serial_trace_marker_offset = 16;
static uint64_t serial_trace_marker_bytes = 8;
static uint64_t serial_trace_marker_max = 4096;
static bool serial_trace_marker_user_only = true;
static bool serial_trace_value_enabled = false;
static uint64_t serial_trace_value = 0x8000000000000001ull;
static uint64_t serial_trace_value_mask = UINT64_MAX;
static char serial_trace_marker_line[SERIAL_TRACE_MARKER_LINE_CAP];
static uint32_t serial_trace_marker_line_len = 0;

static void serial_trace_marker_init(void) {
  serial_trace_marker_enabled =
    serial_env_true(getenv("NEMU_SERIAL_TRACE_PYLONG_ID"));
  const char *marker_env = getenv("NEMU_SERIAL_TRACE_PYLONG_ID_MARKER");
  if (marker_env != NULL && marker_env[0] != '\0') {
    serial_trace_marker = marker_env;
  }
  const char *paddr_marker_env = getenv("NEMU_SERIAL_TRACE_PYLONG_PADDR_MARKER");
  if (paddr_marker_env != NULL && paddr_marker_env[0] != '\0') {
    serial_trace_paddr_marker = paddr_marker_env;
  }
  const char *value_marker_env = getenv("NEMU_SERIAL_TRACE_PYLONG_VALUE_MARKER");
  if (value_marker_env != NULL && value_marker_env[0] != '\0') {
    serial_trace_value_marker = value_marker_env;
  }
  const char *end_marker_env = getenv("NEMU_SERIAL_TRACE_PYLONG_END_MARKER");
  if (end_marker_env != NULL && end_marker_env[0] != '\0') {
    serial_trace_end_marker = end_marker_env;
  }
  serial_env_u64("NEMU_SERIAL_TRACE_PYLONG_ID_OFFSET",
      &serial_trace_marker_offset);
  serial_env_u64("NEMU_SERIAL_TRACE_PYLONG_ID_BYTES",
      &serial_trace_marker_bytes);
  serial_env_u64("NEMU_SERIAL_TRACE_PYLONG_ID_MAX",
      &serial_trace_marker_max);
  serial_trace_marker_user_only =
    !serial_env_false(getenv("NEMU_SERIAL_TRACE_PYLONG_ID_USER_ONLY"));
  serial_trace_value_enabled =
    serial_env_true(getenv("NEMU_SERIAL_TRACE_PYLONG_VALUE"));
  serial_env_u64("NEMU_SERIAL_TRACE_PYLONG_VALUE_WORD",
      &serial_trace_value);
  serial_env_u64("NEMU_SERIAL_TRACE_PYLONG_VALUE_MASK",
      &serial_trace_value_mask);
  if (serial_trace_marker_enabled) {
    Assert(serial_trace_marker_bytes > 0,
        "NEMU_SERIAL_TRACE_PYLONG_ID_BYTES must be positive");
  }
}

static void serial_trace_marker_process_line(void) {
  if (!serial_trace_marker_enabled || serial_trace_marker_line_len == 0) {
    return;
  }
  serial_trace_marker_line[serial_trace_marker_line_len] = '\0';
  if (strstr(serial_trace_marker_line, serial_trace_end_marker) != NULL) {
    vaddr_write_trace_disarm("serial-end-marker");
    vaddr_write_value_trace_disarm("serial-end-marker");
    paddr_write_trace_disarm("serial-end-marker");
    paddr_write_value_trace_disarm("serial-end-marker");
    return;
  }
  if (serial_trace_value_enabled &&
      strstr(serial_trace_marker_line, serial_trace_value_marker) != NULL) {
    vaddr_write_value_trace_set_user_only(serial_trace_marker_user_only);
    vaddr_write_value_trace_arm((word_t)serial_trace_value,
        (word_t)serial_trace_value_mask, serial_trace_marker_max,
        "serial-value-marker");
    paddr_write_value_trace_arm((word_t)serial_trace_value,
        (word_t)serial_trace_value_mask, serial_trace_marker_max,
        "serial-value-marker");
    return;
  }
  const char *paddr_hit = strstr(serial_trace_marker_line, serial_trace_paddr_marker);
  if (paddr_hit != NULL) {
    const char *value_text = paddr_hit + strlen(serial_trace_paddr_marker);
    errno = 0;
    char *end = NULL;
    uint64_t paddr_value = strtoull(value_text, &end, 0);
    if (errno != 0 || end == value_text) {
      Log("serial paddr trace marker parse failed line=%s",
          serial_trace_marker_line);
      return;
    }
    uint64_t paddr_end = paddr_value + serial_trace_marker_bytes - 1;
    Assert(paddr_end >= paddr_value, "serial paddr trace marker range overflow");
    paddr_write_trace_arm_range((paddr_t)paddr_value, (paddr_t)paddr_end,
        serial_trace_marker_max, "serial-paddr-marker");
    Log("serial paddr trace marker armed paddr_start=0x%016" PRIx64
        " paddr_end=0x%016" PRIx64,
        paddr_value, paddr_end);
    return;
  }
  const char *hit = strstr(serial_trace_marker_line, serial_trace_marker);
  if (hit == NULL) {
    return;
  }
  const char *value_text = hit + strlen(serial_trace_marker);
  errno = 0;
  char *end = NULL;
  uint64_t object_addr = strtoull(value_text, &end, 0);
  if (errno != 0 || end == value_text) {
    Log("serial trace marker parse failed line=%s", serial_trace_marker_line);
    return;
  }
  uint64_t start = object_addr + serial_trace_marker_offset;
  uint64_t end_addr = start + serial_trace_marker_bytes - 1;
  Assert(end_addr >= start, "serial trace marker range overflow");
  vaddr_write_trace_arm_range((vaddr_t)start, (vaddr_t)end_addr,
      serial_trace_marker_max, serial_trace_marker_user_only, "serial-marker");
  bool paddr_armed = false;
  paddr_t paddr_start = 0;
#if defined(CONFIG_ISA_riscv) && defined(CONFIG_ISA64)
  if (isa_riscv64_mmu_debug_translate_user((vaddr_t)start,
        (int)serial_trace_marker_bytes, MEM_TYPE_READ, &paddr_start)) {
    paddr_t paddr_end = paddr_start + (paddr_t)serial_trace_marker_bytes - 1;
    if (paddr_end >= paddr_start) {
      paddr_write_trace_arm_range(paddr_start, paddr_end,
          serial_trace_marker_max, "serial-marker");
      paddr_armed = true;
    }
  }
#endif
  Log("serial trace marker armed object=0x%016" PRIx64
      " trace_start=0x%016" PRIx64 " trace_end=0x%016" PRIx64
      " paddr_armed=%d paddr_start=" FMT_PADDR,
      object_addr, start, end_addr, paddr_armed ? 1 : 0, paddr_start);
}

static void serial_trace_marker_consume(uint8_t ch) {
  if (!serial_trace_marker_enabled) {
    return;
  }
  if (ch == '\r' || ch == '\n') {
    serial_trace_marker_process_line();
    serial_trace_marker_line_len = 0;
    return;
  }
  if (serial_trace_marker_line_len + 1u < SERIAL_TRACE_MARKER_LINE_CAP) {
    serial_trace_marker_line[serial_trace_marker_line_len++] = (char)ch;
  } else {
    serial_trace_marker_line_len = 0;
  }
}

static uint32_t serial_host_rx_count(const SerialPort *port) {
#ifdef SERIAL_HAS_HOST_RX
  return port->host_rx.count;
#else
  (void)port;
  return 0;
#endif
}

static uint32_t serial_host_rx_capacity(const SerialPort *port) {
#ifdef SERIAL_HAS_HOST_RX
  return port->host_rx.capacity;
#else
  (void)port;
  return 0;
#endif
}

static uint64_t serial_host_rx_dropped_count(const SerialPort *port) {
#ifdef SERIAL_HAS_HOST_RX
  return port->host_rx_dropped;
#else
  (void)port;
  return 0;
#endif
}

void serial_dump_machine_info(FILE *out) {
  Uart16550Snapshot snap;
  if (serial0.uart != NULL) {
    uart16550_snapshot(serial0.uart, &snap);
  } else {
    memset(&snap, 0, sizeof(snap));
  }

  // UART core 与宿主输入 staging 分开导出，避免把自动化大缓冲误读成硬件 FIFO。
  fprintf(out, "device.serial.model=ns16550a\n");
  fprintf(out, "device.serial.backend=nemu-16550a\n");
  fprintf(out, "device.serial.host_backend=%s\n", serial_host_backend_name());
#if defined(CONFIG_SERIAL_INPUT_STDIN)
  fprintf(out, "device.serial.host_stdin_enabled=%u\n",
      serial0.stdin_enabled ? 1u : 0u);
#endif
#if defined(CONFIG_SERIAL_INPUT_FIFO)
  fprintf(out, "device.serial.host_fifo_path=%s\n",
      serial0.fifo_path != NULL ? serial0.fifo_path : "");
#endif
  fprintf(out, "device.serial.bus_profile=8bit\n");
  fprintf(out, "device.serial.map_size=0x%08x\n", serial0.bus_map_size);
  fprintf(out, "device.serial.rx_fifo_capacity=%u\n", snap.rx_fifo_capacity);
  fprintf(out, "device.serial.rx_fifo_visible_capacity=%u\n",
      snap.rx_fifo_visible_capacity);
  fprintf(out, "device.serial.rx_fifo_count=%u\n", snap.rx_fifo_count);
  fprintf(out, "device.serial.rx_trigger=%u\n", snap.rx_trigger);
  fprintf(out, "device.serial.fifo_enabled=%u\n", snap.fifo_enabled ? 1u : 0u);
  fprintf(out, "device.serial.irq_level=%u\n", snap.irq_level ? 1u : 0u);
  fprintf(out, "device.serial.ier=0x%02x\n", snap.ier);
  fprintf(out, "device.serial.iir=0x%02x\n", snap.iir);
  fprintf(out, "device.serial.lcr=0x%02x\n", snap.lcr);
  fprintf(out, "device.serial.lsr=0x%02x\n", snap.lsr);
  fprintf(out, "device.serial.host_rx_staging_capacity=%u\n",
      serial_host_rx_capacity(&serial0));
  fprintf(out, "device.serial.host_rx_staging_count=%u\n",
      serial_host_rx_count(&serial0));
  fprintf(out, "device.serial.host_rx_dropped=%" PRIu64 "\n",
      serial_host_rx_dropped_count(&serial0));
  fprintf(out, "device.serial.host_rx_poll_interval=%u\n",
      SERIAL_INPUT_HOST_POLL_INTERVAL);
  fprintf(out, "device.serial.tx_buffer_capacity=%u\n", SERIAL_TX_BUFFER_CAP);
  fprintf(out, "device.serial.tx_buffer_count=%u\n", serial0.tx_count);
}
#endif

static void serial_port_tx(void *opaque, uint8_t ch) {
  SerialPort *port = (SerialPort *)opaque;
#ifdef CONFIG_TARGET_AM
  (void)port;
  putch(ch);
#else
  if (port->tx_count == SERIAL_TX_BUFFER_CAP) {
    serial_port_flush_tx(port);
  }

  port->tx_buffer[port->tx_count++] = ch;
  if (ch == '\n' || ch == '\r' || port->tx_count == SERIAL_TX_BUFFER_CAP) {
    serial_port_flush_tx(port);
  }
#endif
}

#ifndef CONFIG_TARGET_AM
static void serial_port_flush_tx(SerialPort *port) {
  if (port->tx_count == 0) {
    return;
  }
  bool profile_on = unlikely(nemu_profile_enabled());
  uint32_t bytes = port->tx_count;
  uint64_t profile_start = profile_on ? get_time() : 0;

  /*
   * Ubuntu 启动日志会经 8250 驱动逐字节写 THR；缓冲只属于宿主前端，
   * 不改变 guest 可见的 16550A THRE/TEMT/IRQ 语义，却能减少 host write 次数。
   */
  (void)fwrite(port->tx_buffer, 1, bytes, stderr);
  // marker 处理会写 NEMU Log；放在 guest 文本之后，避免 trace 日志插进 Python marker 行。
  for (uint32_t i = 0; i < bytes; i++) {
    serial_trace_marker_consume(port->tx_buffer[i]);
  }
  port->tx_count = 0;
  fflush(stderr);
  if (profile_on) {
    nemu_profile_count(NEMU_PROFILE_SERIAL_TX_FLUSHES, 1);
    nemu_profile_count(NEMU_PROFILE_SERIAL_TX_BYTES, bytes);
    nemu_profile_count(NEMU_PROFILE_SERIAL_TX_FLUSH_US,
        get_time() - profile_start);
  }
}

static void serial_flush_all(void) {
  serial_port_flush_tx(&serial0);
}

void serial_qmp_query_chardev(char *out, size_t out_size) {
  Assert(out != NULL && out_size > 0, "invalid query-chardev output buffer");
  char filename[SERIAL_QMP_FILENAME_CAP];
  if (!serial_qmp_host_backend_json(filename, sizeof(filename))) {
    serial_qmp_backend_error(out, out_size);
    return;
  }

  /*
   * QMP 只暴露当前 console chardev 的只读状态，避免管理面审计时还得解析
   * machine-info 文本；这不是 chardev-add/remove 或多串口热插拔实现。
   */
  int written = snprintf(out, out_size,
      "{\"return\":[{\"label\":\"serial0\",\"filename\":%s,"
      "\"frontend-open\":true,\"backend\":\"nemu-16550a\"}]}",
      filename);
  if (written < 0 || (size_t)written >= out_size) {
    serial_qmp_backend_error(out, out_size);
  }
}

void serial_qmp_query_serial(char *out, size_t out_size) {
  Assert(out != NULL && out_size > 0, "invalid query-serial output buffer");
  char filename[SERIAL_QMP_FILENAME_CAP];
  if (!serial_qmp_host_backend_json(filename, sizeof(filename))) {
    serial_qmp_backend_error(out, out_size);
    return;
  }

  Uart16550Snapshot snap;
  if (serial0.uart != NULL) {
    uart16550_snapshot(serial0.uart, &snap);
  } else {
    memset(&snap, 0, sizeof(snap));
  }

  int written = snprintf(out, out_size,
      "{\"return\":[{\"id\":\"serial0\",\"type\":\"uart\","
      "\"model\":\"ns16550a\",\"backend\":\"nemu-16550a\","
      "\"filename\":%s,\"frontend-open\":true,"
      "\"nemu\":{\"mmio\":\"0x%08x\",\"irq\":%u,"
      "\"bus-profile\":\"8bit\",\"map-size\":%u,"
      "\"registers\":{\"ier\":\"0x%02x\",\"iir\":\"0x%02x\","
      "\"fcr\":\"0x%02x\",\"lcr\":\"0x%02x\",\"mcr\":\"0x%02x\","
      "\"lsr\":\"0x%02x\",\"msr\":\"0x%02x\",\"scr\":\"0x%02x\","
      "\"dll\":\"0x%02x\",\"dlm\":\"0x%02x\",\"dlab\":%s},"
      "\"rx-fifo\":{\"capacity\":%u,\"visible-capacity\":%u,"
      "\"count\":%u,\"room\":%u,\"trigger\":%u,"
      "\"fifo-enabled\":%s},"
      "\"host-rx\":{\"staging-capacity\":%u,\"staging-count\":%u,"
      "\"poll-interval\":%u,\"dropped\":%" PRIu64 ","
      "\"stdin-enabled\":%s},"
      "\"tx-buffer\":{\"capacity\":%u,\"count\":%u},"
      "\"irq-level\":%s,\"thr-irq-pending\":%s}}]}",
      filename, DEV_SERIAL_MMIO, serial0.irq,
      serial0.bus_map_size, snap.ier, snap.iir, snap.fcr, snap.lcr,
      snap.mcr, snap.lsr, snap.msr, snap.scr, snap.dll, snap.dlm,
      serial_json_bool(snap.dlab), snap.rx_fifo_capacity,
      snap.rx_fifo_visible_capacity, snap.rx_fifo_count, snap.rx_fifo_room,
      snap.rx_trigger, serial_json_bool(snap.fifo_enabled),
      serial_host_rx_capacity(&serial0), serial_host_rx_count(&serial0),
      SERIAL_INPUT_HOST_POLL_INTERVAL, serial_host_rx_dropped_count(&serial0),
      MUXDEF(CONFIG_SERIAL_INPUT_STDIN, serial_json_bool(serial0.stdin_enabled), "false"),
      SERIAL_TX_BUFFER_CAP, serial0.tx_count, serial_json_bool(snap.irq_level),
      serial_json_bool(snap.thr_irq_pending));
  if (written < 0 || (size_t)written >= out_size) {
    serial_qmp_backend_error(out, out_size);
  }
}
#endif

static void serial_port_irq(void *opaque, bool level) {
  SerialPort *port = (SerialPort *)opaque;
#ifdef CONFIG_ISA_riscv
  isa_riscv_plic_set_irq(port->irq, level);
#else
  (void)port;
  (void)level;
#endif
}

#ifdef SERIAL_HAS_HOST_RX
static void serial_fifo_bind(SerialByteFifo *fifo, uint8_t *data,
    uint32_t capacity) {
  fifo->data = data;
  fifo->capacity = capacity;
  fifo->head = fifo->tail = fifo->count = 0;
}

static bool serial_fifo_empty(const SerialByteFifo *fifo) {
  return fifo->count == 0;
}

static bool serial_fifo_full(const SerialByteFifo *fifo) {
  return fifo->count == fifo->capacity;
}

static bool serial_fifo_push(SerialByteFifo *fifo, uint8_t value) {
  if (serial_fifo_full(fifo)) {
    return false;
  }
  fifo->data[fifo->tail] = value;
  fifo->tail = (fifo->tail + 1u) % fifo->capacity;
  fifo->count++;
  return true;
}

static bool serial_fifo_pop(SerialByteFifo *fifo, uint8_t *value) {
  if (serial_fifo_empty(fifo)) {
    return false;
  }
  *value = fifo->data[fifo->head];
  fifo->head = (fifo->head + 1u) % fifo->capacity;
  fifo->count--;
  return true;
}

static void serial_host_rx_init(SerialPort *port) {
  /*
   * 宿主可能一次性写入整段 guest-check 脚本；这是仿真前端能力，
   * 不是 16550A 硬件 FIFO，所以大缓冲放在 SerialPort 层维护。
   */
  port->host_rx_storage =
      (uint8_t *)calloc(SERIAL_HOST_RX_STAGING_CAP, sizeof(uint8_t));
  Assert(port->host_rx_storage != NULL,
      "can not allocate serial host RX staging queue");
  serial_fifo_bind(&port->host_rx, port->host_rx_storage,
      SERIAL_HOST_RX_STAGING_CAP);
}

static void serial_host_rx_enqueue(SerialPort *port, const uint8_t *data,
    size_t len) {
  for (size_t i = 0; i < len; i++) {
    if (!serial_fifo_push(&port->host_rx, data[i])) {
      uint8_t dropped = 0;
      (void)serial_fifo_pop(&port->host_rx, &dropped);
      (void)serial_fifo_push(&port->host_rx, data[i]);
      port->host_rx_dropped++;
    }
  }
}

static void serial_host_rx_drain_to_uart(SerialPort *port) {
  if (port->uart == NULL) {
    return;
  }

  uint8_t chunk[SERIAL_HOST_RX_POLL_CHUNK];
  while (!serial_fifo_empty(&port->host_rx)) {
    uint32_t room = uart16550_rx_room(port->uart);
    if (room == 0) {
      break;
    }

    size_t n = 0;
    while (n < sizeof(chunk) && n < room &&
        serial_fifo_pop(&port->host_rx, &chunk[n])) {
      n++;
    }
    if (n == 0) {
      break;
    }
    size_t consumed = uart16550_receive(port->uart, chunk, n);
    Assert(consumed == n, "serial host RX drain lost bytes: consumed=%zu n=%zu",
        consumed, n);
  }
}

static bool serial_fd_ready(int fd) {
  fd_set readfds;
  struct timeval timeout = {0, 0};
  FD_ZERO(&readfds);
  FD_SET(fd, &readfds);
  return select(fd + 1, &readfds, NULL, NULL, &timeout) > 0;
}

static void serial_host_poll_fd(SerialPort *port, int fd, bool *eof_seen) {
  if (fd < 0 || (eof_seen != NULL && *eof_seen)) {
    return;
  }

  for (uint32_t chunk = 0; chunk < SERIAL_HOST_RX_POLL_BUDGET; chunk++) {
    if (!serial_fd_ready(fd)) {
      break;
    }

    uint8_t buf[SERIAL_HOST_RX_POLL_CHUNK];
    ssize_t nread = read(fd, buf, sizeof(buf));
    if (nread > 0) {
      nemu_profile_count_if(NEMU_PROFILE_SERIAL_RX_BYTES, (uint64_t)nread);
      serial_host_rx_enqueue(port, buf, (size_t)nread);
    } else if (nread == 0 && eof_seen != NULL) {
      *eof_seen = true;
      break;
    } else if (nread < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
        break;
      }
      if (eof_seen != NULL) {
        *eof_seen = true;
      }
      break;
    }
  }
  serial_host_rx_drain_to_uart(port);
}
#endif

static uint64_t serial_bus_load(const SerialPort *port, uint32_t offset,
    int len) {
  uint64_t value = 0;
  if (port->bus_space == NULL) {
    return value;
  }

  for (int i = 0; i < len; i++) {
    uint32_t pos = offset + (uint32_t)i;
    if (pos < port->bus_map_size) {
      value |= (uint64_t)port->bus_space[pos] << (i * 8);
    }
  }
  return value;
}

static void serial_bus_store(SerialPort *port, uint32_t offset, int len,
    uint64_t value) {
  if (port->bus_space == NULL) {
    return;
  }

  for (int i = 0; i < len; i++) {
    uint32_t pos = offset + (uint32_t)i;
    if (pos < port->bus_map_size) {
      port->bus_space[pos] = (uint8_t)(value >> (i * 8));
    }
  }
}

static void serial_port_service(SerialPort *port) {
  if (port->uart == NULL) {
    return;
  }
#ifdef SERIAL_HAS_HOST_RX
  serial_host_rx_drain_to_uart(port);
#endif
  if (port->bus_space != NULL) {
    uart16550_service(port->uart);
  }
#ifndef CONFIG_TARGET_AM
  serial_port_flush_tx(port);
#endif
}

static void serial_port_poll_host(SerialPort *port) {
  if (port->uart == NULL) {
    return;
  }
  nemu_profile_count_if(NEMU_PROFILE_SERIAL_RX_POLLS, 1);
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_STDIN)
  if (port->stdin_enabled) {
    serial_host_poll_fd(port, STDIN_FILENO, &port->stdin_eof);
  }
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_FIFO)
  serial_host_poll_fd(port, port->fifo_fd, NULL);
#endif
  serial_port_service(port);
}

void serial_poll_input(void) {
  /*
   * 全局 device tick 只按配置轮询宿主 fd，降低 Ubuntu 空闲长跑中的
   * select/read 频率；guest 主动读 UART 寄存器时仍会走 serial_port_poll_host()。
   */
  // difftest 共享库配置下 SERIAL_HAS_HOST_RX 关闭,此变量未用;标记 unused 避免 -Werror。
  static uint32_t host_poll_skip __attribute__((unused)) = 0;
#ifdef SERIAL_HAS_HOST_RX
  if (host_poll_skip == 0) {
    serial_port_poll_host(&serial0);
  } else {
    serial_port_service(&serial0);
  }
  host_poll_skip++;
  if (host_poll_skip >= SERIAL_INPUT_HOST_POLL_INTERVAL) {
    host_poll_skip = 0;
  }
#else
  serial_port_service(&serial0);
#endif
}

static void serial_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len >= 1 && len <= 8);
  SerialPort *port = &serial0;
  if (port->uart == NULL) {
    return;
  }

  if (is_write) {
    uint64_t value = serial_bus_load(port, offset, len);
    uart16550_bus_write(port->uart, &port->bus_profile, offset, len, value);
#ifdef SERIAL_HAS_HOST_RX
    serial_host_rx_drain_to_uart(port);
#endif
    uart16550_service(port->uart);
    return;
  }

  serial_port_poll_host(port);
  uint64_t value = uart16550_bus_read(port->uart, &port->bus_profile,
      offset, len);
  serial_bus_store(port, offset, len, value);
#ifdef SERIAL_HAS_HOST_RX
  serial_host_rx_drain_to_uart(port);
#endif
  uart16550_service(port->uart);
}

static void serial_register_bus(SerialPort *port) {
  /*
   * 当前 Linux DTS 是 ns16550a + reg-shift=0；这里仍通过 profile 计算 PIO
   * span，避免前端重新隐含“offset 就是寄存器号”的旧 mini UART 假设。
   */
  port->bus_map_size = MUXDEF(NEMU_HAS_PORT_IO,
      uart16550_bus_profile_span(&port->bus_profile),
      UART16550_MMIO_MAP_SIZE);
  port->bus_space = new_space(port->bus_map_size);
#ifdef NEMU_HAS_PORT_IO
  add_pio_map(port->name, CONFIG_SERIAL_PORT, port->bus_space,
      port->bus_map_size, serial_io_handler);
#else
  add_mmio_map(port->name, DEV_SERIAL_MMIO, port->bus_space,
      port->bus_map_size, serial_io_handler);
#endif
}

static void serial_open_host_inputs(SerialPort *port) {
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_STDIN)
  const char *stdin_env = getenv("NEMU_SERIAL_INPUT_STDIN");
  port->stdin_enabled = !serial_env_false(stdin_env);
  port->stdin_eof = !port->stdin_enabled;
#endif
#if defined(SERIAL_HAS_HOST_RX) && defined(CONFIG_SERIAL_INPUT_FIFO)
  const char *fifo_env = getenv("NEMU_SERIAL_FIFO");
  if (fifo_env != NULL && fifo_env[0] != '\0') {
    port->fifo_path = fifo_env;
  }
  if (mkfifo(port->fifo_path, 0600) != 0 && errno != EEXIST) {
    Log("serial: cannot create input FIFO %s: %s", port->fifo_path,
        strerror(errno));
  }
  port->fifo_fd = open(port->fifo_path, O_RDWR | O_NONBLOCK);
  if (port->fifo_fd < 0) {
    Log("serial: cannot open input FIFO %s: %s", port->fifo_path,
        strerror(errno));
  }
#else
  (void)port;
#endif
}

void init_serial() {
  SerialPort *port = &serial0;
  Uart16550Ops ops = {
    .tx = serial_port_tx,
    .irq = serial_port_irq,
  };
  Uart16550Config config = {
    .ops = &ops,
    .opaque = port,
  };
  port->uart = uart16550_create(&config);
  Assert(port->uart != NULL, "can not create serial 16550A device");
#ifdef SERIAL_HAS_HOST_RX
  serial_host_rx_init(port);
#endif
  serial_register_bus(port);
  serial_open_host_inputs(port);
#ifndef CONFIG_TARGET_AM
  serial_trace_marker_init();
  atexit(serial_flush_all);
#endif
  uart16550_service(port->uart);
}

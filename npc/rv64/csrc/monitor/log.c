/* NPC 日志子系统 — C 重构版
 * std::filesystem 改为手写递归 mkdir，std::string 缓冲区改为 char 数组 */
#include "monitor/log.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdlib.h>

static FILE *g_log_file = NULL;
static char  g_guest_buf[4096];
static int   g_guest_buf_len = 0;
static bool  g_guest_expect_inited = false;
static bool  g_guest_expect_matched = false;
static const char *g_guest_expect = NULL;

static const char *short_file_name(const char *file) {
  const char *slash = strrchr(file, '/');
  return slash ? slash + 1 : file;
}

static void vprint_to_file(const char *fmt, va_list args) {
  if (!g_log_file) return;
  vfprintf(g_log_file, fmt, args);
  fflush(g_log_file);
}

static void init_guest_expect(void) {
  if (g_guest_expect_inited) return;
  g_guest_expect_inited = true;
  g_guest_expect = getenv("NPC_GUEST_EXPECT");
  if (g_guest_expect && g_guest_expect[0] == '\0') {
    g_guest_expect = NULL;
  }
}

void npc_reset_guest_expect(void) {
  g_guest_expect_inited = false;
  g_guest_expect_matched = false;
  g_guest_expect = NULL;
}

bool npc_guest_expect_matched(void) {
  init_guest_expect();
  return g_guest_expect_matched;
}

const char *npc_guest_expect_text(void) {
  init_guest_expect();
  return g_guest_expect ? g_guest_expect : "";
}

static void check_guest_expect_line(const char *line) {
  init_guest_expect();
  if (!g_guest_expect || g_guest_expect_matched) return;
  if (strstr(line, g_guest_expect)) {
    g_guest_expect_matched = true;
  }
}

static void flush_guest_line_buffer(void) {
  if (g_guest_buf_len == 0) return;
  g_guest_buf[g_guest_buf_len] = '\0';
  check_guest_expect_line(g_guest_buf);
  if (g_log_file) {
    fprintf(g_log_file, "[guest] %s\n", g_guest_buf);
    fflush(g_log_file);
  }
  g_guest_buf_len = 0;
}

/* 手写递归 mkdir，替代 std::filesystem::create_directories */
static void mkdirs(const char *path) {
  char tmp[NPC_PATH_MAX];
  strncpy(tmp, path, sizeof(tmp) - 1);
  tmp[sizeof(tmp) - 1] = '\0';
  for (char *p = tmp + 1; *p; ++p) {
    if (*p == '/') {
      *p = '\0';
      mkdir(tmp, 0755);
      *p = '/';
    }
  }
  mkdir(tmp, 0755);
}

void npc_init_log(const NpcSimConfig *config) {
  if (!config->log_to_file) return;

  /* 从 log_path 中提取父目录并创建 */
  char parent[NPC_PATH_MAX];
  strncpy(parent, config->log_path, sizeof(parent) - 1);
  parent[sizeof(parent) - 1] = '\0';
  char *last_slash = strrchr(parent, '/');
  if (last_slash) {
    *last_slash = '\0';
    mkdirs(parent);
  }

  g_log_file = fopen(config->log_path, "w");
  if (!g_log_file) {
    perror("[npc] fopen log");
  } else {
    /* 对齐参考工程：日志文件打开后在终端显示写入路径 */
    LogBoth("Log is written to %s", config->log_path);
  }
}

void npc_close_log(void) {
  if (g_log_file) {
    flush_guest_line_buffer();
    fclose(g_log_file);
    g_log_file = NULL;
  }
}

bool npc_log_enable(void) { return true; }

void npc_log_putchar(char ch) {
  fputc((unsigned char)ch, stdout);
  fflush(stdout);
  if (ch == '\n') { flush_guest_line_buffer(); return; }
  if (ch == '\r') return;
  if (g_guest_buf_len >= (int)sizeof(g_guest_buf) - 1) {
    flush_guest_line_buffer();
  }
  g_guest_buf[g_guest_buf_len++] = ch;
  g_guest_buf[g_guest_buf_len] = '\0';
  check_guest_expect_line(g_guest_buf);
}

void npc_log_impl(const char *file, int line, const char *func, const char *fmt, ...) {
  if (!npc_log_enable() || !g_log_file) return;
  va_list args;
  va_start(args, fmt);
  fprintf(g_log_file, "[%s:%d %s] ", short_file_name(file), line, func);
  vprint_to_file(fmt, args);
  fprintf(g_log_file, "\n");
  fflush(g_log_file);
  va_end(args);
}

void npc_log_both_impl(const char *file, int line, const char *func, const char *fmt, ...) {
  if (!npc_log_enable()) return;
  va_list args, console_args, file_args;
  va_start(args, fmt);
  va_copy(console_args, args);
  va_copy(file_args, args);

/* 整行蓝色高亮（含消息体），对齐参考工程的终端输出风格 */
#if CONFIG_NPC_COLORED_LOG
  printf(ANSI_FG_BLUE "[%s:%d %s] ", short_file_name(file), line, func);
  vprintf(fmt, console_args);
  printf(ANSI_NONE "\n");
#else
  printf("[%s:%d %s] ", short_file_name(file), line, func);
  vprintf(fmt, console_args);
  printf("\n");
#endif
  va_end(console_args);

  if (g_log_file) {
    fprintf(g_log_file, "[%s:%d %s] ", short_file_name(file), line, func);
    vprint_to_file(fmt, file_args);
    fprintf(g_log_file, "\n");
    fflush(g_log_file);
  }
  va_end(file_args);
  va_end(args);
}

void npc_log_plain(const char *fmt, ...) {
  va_list args, console_args, file_args;
  va_start(args, fmt);
  va_copy(console_args, args);
  va_copy(file_args, args);
  vprintf(fmt, console_args);
  fflush(stdout);
  va_end(console_args);
  if (g_log_file) { vprint_to_file(fmt, file_args); }
  va_end(file_args);
  va_end(args);
}

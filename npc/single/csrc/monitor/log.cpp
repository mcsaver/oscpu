#include "monitor/log.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <filesystem>

namespace npc {

namespace {

FILE *g_log_file = nullptr;

const char *short_file_name(const char *file) {
  const char *slash = std::strrchr(file, '/');
  return slash ? slash + 1 : file;
}

void vprint_to_file(const char *fmt, va_list args) {
  if (g_log_file == nullptr) {
    return;
  }
  std::vfprintf(g_log_file, fmt, args);
  std::fflush(g_log_file);
}

}  // namespace

void init_log(const SimConfig &config) {
  if (!config.log_to_file) {
    return;
  }

  std::filesystem::path log_path(config.log_path);
  if (log_path.has_parent_path()) {
    std::filesystem::create_directories(log_path.parent_path());
  }

  g_log_file = std::fopen(config.log_path.c_str(), "w");
  if (g_log_file == nullptr) {
    std::perror("[npc] fopen log");
  }
}

void close_log() {
  if (g_log_file != nullptr) {
    std::fclose(g_log_file);
    g_log_file = nullptr;
  }
}

bool log_enable() {
  return true;
}

void log_impl(const char *file, int line, const char *func, const char *fmt, ...) {
  if (!log_enable()) {
    return;
  }

  std::va_list args;
  va_start(args, fmt);
  std::va_list console_args;
  std::va_list file_args;
  va_copy(console_args, args);
  va_copy(file_args, args);

#if CONFIG_NPC_COLORED_LOG
  std::printf(ANSI_FG_BLUE "[%s:%d %s] " ANSI_NONE, short_file_name(file), line, func);
#else
  std::printf("[%s:%d %s] ", short_file_name(file), line, func);
#endif
  std::vprintf(fmt, console_args);
  std::printf("\n");
  va_end(console_args);

  if (g_log_file != nullptr) {
    std::fprintf(g_log_file, "[%s:%d %s] ", short_file_name(file), line, func);
    vprint_to_file(fmt, file_args);
    std::fprintf(g_log_file, "\n");
    std::fflush(g_log_file);
  }
  va_end(file_args);

  va_end(args);
}

void log_plain(const char *fmt, ...) {
  std::va_list args;
  va_start(args, fmt);
  std::va_list console_args;
  std::va_list file_args;
  va_copy(console_args, args);
  va_copy(file_args, args);
  std::vprintf(fmt, console_args);
  va_end(console_args);
  if (g_log_file != nullptr) {
    vprint_to_file(fmt, file_args);
  }
  va_end(file_args);
  va_end(args);
}

}  // namespace npc
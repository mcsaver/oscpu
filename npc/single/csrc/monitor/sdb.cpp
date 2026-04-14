#include "monitor/sdb.h"

#include "cpu/cpu.h"
#include "memory/paddr.h"
#include "monitor/expr.h"
#include "monitor/trace.h"
#include "monitor/watchpoint.h"
#include "utils.h"

#include <cstdio>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include <vector>

namespace npc {

namespace {

struct Command {
  const char *name;
  const char *description;
  int (*handler)(const std::string &args);
};

int state_to_exit_code() {
  switch (npc_state().state) {
    case NPC_END: return static_cast<int>(npc_state().halt_ret);
    case NPC_ABORT: return 2;
    case NPC_TRAP: return 1;
    case NPC_STOP:
    case NPC_WATCHPOINT_HIT:
    case NPC_QUIT:
    default:
      return 0;
  }
}

std::string trim(const std::string &text) {
  const std::size_t begin = text.find_first_not_of(" \t\r\n");
  if (begin == std::string::npos) {
    return "";
  }
  const std::size_t end = text.find_last_not_of(" \t\r\n");
  return text.substr(begin, end - begin + 1);
}

int cmd_c(const std::string &) {
  cpu_exec(std::numeric_limits<uint64_t>::max());
  return 0;
}

int cmd_q(const std::string &) {
  npc_state().state = NPC_QUIT;
  return -1;
}

int cmd_si(const std::string &args) {
  std::string trimmed = trim(args);
  uint64_t steps = 1;
  if (!trimmed.empty()) {
    steps = std::strtoull(trimmed.c_str(), nullptr, 0);
  }
  if (steps == 0) {
    std::printf("si expects a positive step count.\n");
    return 0;
  }
  cpu_exec(steps);
  return 0;
}

int cmd_info(const std::string &args) {
  const std::string trimmed = trim(args);
  if (trimmed == "r") {
    cpu_reg_display();
    return 0;
  }
  if (trimmed == "w") {
    watchpoint_display();
    return 0;
  }
  if (trimmed == "s") {
    cpu_info_display();
    return 0;
  }
  if (trimmed == "t") {
    trace_info_display();
    return 0;
  }

  std::printf("Usage: info r|w|s|t\n");
  return 0;
}

int cmd_x(const std::string &args) {
  std::istringstream iss(args);
  int count = 0;
  iss >> count;
  std::string expr_text;
  std::getline(iss, expr_text);
  expr_text = trim(expr_text);
  if (count <= 0 || expr_text.empty()) {
    std::printf("Usage: x N EXPR\n");
    return 0;
  }

  uint32_t base = 0;
  if (!expr(expr_text, &base)) {
    std::printf("Bad expression: %s\n", expr_text.c_str());
    return 0;
  }

  for (int index = 0; index < count; ++index) {
    uint32_t data = 0;
    const uint32_t addr = base + static_cast<uint32_t>(index * 4);
    if (!paddr_read(addr, &data)) {
      std::printf("0x%08x: <invalid>\n", addr);
      break;
    }
    std::printf("0x%08x: 0x%08x\n", addr, data);
  }
  return 0;
}

int cmd_p(const std::string &args) {
  const std::string expr_text = trim(args);
  if (expr_text.empty()) {
    std::printf("Usage: p EXPR\n");
    return 0;
  }

  uint32_t value = 0;
  if (!expr(expr_text, &value)) {
    std::printf("Bad expression: %s\n", expr_text.c_str());
    return 0;
  }
  std::printf("%s = 0x%08x (%u)\n", expr_text.c_str(), value, value);
  return 0;
}

int cmd_w(const std::string &args) {
  const std::string expr_text = trim(args);
  if (expr_text.empty()) {
    std::printf("Usage: w EXPR\n");
    return 0;
  }
  new_watchpoint(expr_text);
  return 0;
}

int cmd_d(const std::string &args) {
  const std::string trimmed = trim(args);
  if (trimmed.empty()) {
    std::printf("Usage: d N\n");
    return 0;
  }
  free_watchpoint(std::atoi(trimmed.c_str()));
  return 0;
}

int cmd_trace(const std::string &args) {
  const std::string trimmed = trim(args);
  if (trimmed.empty()) {
    trace_info_display();
    return 0;
  }

  std::istringstream iss(trimmed);
  std::string target;
  iss >> target;

  if (target == "cond") {
    std::string expr_text;
    std::getline(iss, expr_text);
    expr_text = trim(expr_text);
    std::string message;
    if (!trace_set_itrace_condition(expr_text, &message)) {
      std::printf("%s\n", message.c_str());
      return 0;
    }
    std::printf("%s\n", message.c_str());
    return 0;
  }

  std::string state;
  iss >> state;
  if (state != "on" && state != "off") {
    std::printf("Usage: trace <itrace|mtrace|dtrace> <on|off> | trace cond EXPR\n");
    return 0;
  }

  std::string message;
  if (!trace_set_mode(target, state == "on", &message)) {
    std::printf("%s\n", message.c_str());
    return 0;
  }

  std::printf("%s\n", message.c_str());
  return 0;
}

int cmd_help(const std::string &args);

const Command kCommands[] = {
  {"help", "Display information about all supported commands", cmd_help},
  {"c", "Continue program execution", cmd_c},
  {"q", "Exit NPC monitor", cmd_q},
  {"si", "Step N committed instructions (default 1)", cmd_si},
  {"info", "Print register/watchpoint/state info", cmd_info},
  {"x", "Examine memory: x N EXPR", cmd_x},
  {"p", "Evaluate expression", cmd_p},
  {"w", "Set watchpoint", cmd_w},
  {"d", "Delete watchpoint", cmd_d},
  {"trace", "Show or toggle itrace/mtrace/dtrace state", cmd_trace},
};

int cmd_help(const std::string &args) {
  const std::string trimmed = trim(args);
  if (trimmed.empty()) {
    for (const auto &cmd : kCommands) {
      std::printf("%-8s - %s\n", cmd.name, cmd.description);
    }
    return 0;
  }

  for (const auto &cmd : kCommands) {
    if (trimmed == cmd.name) {
      std::printf("%-8s - %s\n", cmd.name, cmd.description);
      return 0;
    }
  }
  std::printf("Unknown command '%s'\n", trimmed.c_str());
  return 0;
}

}  // namespace

int sdb_mainloop() {
#if !CONFIG_NPC_SDB
  cpu_exec(std::numeric_limits<uint64_t>::max());
  return state_to_exit_code();
#else
  std::string line;
  while (true) {
    std::cout << "(npc) " << std::flush;
    if (!std::getline(std::cin, line)) {
      if (consume_sigint_request()) {
        // Ctrl-C 落在 monitor 提示符上时，直接退出整个 NPC 进程，避免用户看到 ^C 但进程还挂着。
        std::cin.clear();
        std::printf("\n[npc] monitor interrupted by Ctrl-C, quitting.\n");
        npc_state().state = NPC_QUIT;
        break;
      }
      npc_state().state = NPC_QUIT;
      break;
    }

    const std::string trimmed = trim(line);
    if (trimmed.empty()) {
      continue;
    }

    std::istringstream iss(trimmed);
    std::string cmd_name;
    iss >> cmd_name;
    std::string args;
    std::getline(iss, args);

    bool handled = false;
    for (const auto &cmd : kCommands) {
      if (cmd_name != cmd.name) {
        continue;
      }
      handled = true;
      if (cmd.handler(args) < 0) {
        return state_to_exit_code();
      }
      break;
    }

    if (!handled) {
      std::printf("Unknown command '%s'\n", cmd_name.c_str());
    }
  }

  return state_to_exit_code();
#endif
}

}  // namespace npc
#include "monitor/trace.h"

#include "monitor/expr.h"

#include <cstdio>
#include <sstream>

namespace npc {

namespace {

struct TraceRuntimeState {
  bool itrace = false;
  bool mtrace = false;
  bool dtrace = false;
  std::string itrace_cond = CONFIG_NPC_ITRACE_COND;
};

TraceRuntimeState g_trace_state;

const char *on_off(bool enabled) {
  return enabled ? "on" : "off";
}

bool parse_bool_literal(const std::string &expression, bool *value) {
  if (value == nullptr) {
    return false;
  }

  if (expression == "true" || expression == "1") {
    *value = true;
    return true;
  }
  if (expression == "false" || expression == "0") {
    *value = false;
    return true;
  }
  return false;
}

bool validate_itrace_condition(const std::string &expression) {
  bool literal_value = false;
  if (parse_bool_literal(expression, &literal_value)) {
    return true;
  }

#if CONFIG_NPC_EXPR
  uint32_t result = 0;
  return expr(expression, &result);
#else
  return false;
#endif
}

bool evaluate_itrace_condition(const std::string &expression) {
  bool literal_value = false;
  if (parse_bool_literal(expression, &literal_value)) {
    return literal_value;
  }

#if CONFIG_NPC_EXPR
  uint32_t result = 0;
  return expr(expression, &result) && result != 0;
#else
  return false;
#endif
}

bool set_flag(const char *name, bool compiled, bool enabled, bool *slot, std::string *message) {
  if (!compiled) {
    if (message != nullptr) {
      std::ostringstream oss;
      oss << name << " support is not built. Enable it in menuconfig and rebuild.";
      *message = oss.str();
    }
    return false;
  }

  *slot = enabled;
  if (message != nullptr) {
    std::ostringstream oss;
    oss << name << " is now " << on_off(enabled) << ".";
    *message = oss.str();
  }
  return true;
}

}  // namespace

bool itrace_compiled() {
#if CONFIG_NPC_ITRACE
  return true;
#else
  return false;
#endif
}

bool mtrace_compiled() {
#if CONFIG_NPC_MTRACE
  return true;
#else
  return false;
#endif
}

bool dtrace_compiled() {
#if CONFIG_NPC_DTRACE
  return true;
#else
  return false;
#endif
}

void init_trace(const SimConfig &config) {
  // 这里把“编译支持”和“运行期开关”拆开：默认构建可带上调试能力，但实际是否输出日志仍由 CLI / monitor 控制。
  g_trace_state.itrace = itrace_compiled() ? config.itrace : false;
  g_trace_state.mtrace = mtrace_compiled() ? config.mtrace : false;
  g_trace_state.dtrace = dtrace_compiled() ? config.dtrace : false;
  g_trace_state.itrace_cond = config.itrace_cond.empty() ? "true" : config.itrace_cond;

  if (config.itrace && !itrace_compiled()) {
    std::printf("[npc] itrace requested but support is not built. Enable NPC_ITRACE in menuconfig and rebuild.\n");
  }
  if (config.mtrace && !mtrace_compiled()) {
    std::printf("[npc] mtrace requested but support is not built. Enable NPC_MTRACE in menuconfig and rebuild.\n");
  }
  if (config.dtrace && !dtrace_compiled()) {
    std::printf("[npc] dtrace requested but support is not built. Enable NPC_DTRACE in menuconfig and rebuild.\n");
  }

  if (itrace_compiled() && !validate_itrace_condition(g_trace_state.itrace_cond)) {
    std::printf("[npc] bad itrace condition '%s', fallback to true.\n", g_trace_state.itrace_cond.c_str());
    g_trace_state.itrace_cond = "true";
  }
}

bool itrace_configured() {
  return itrace_compiled() && g_trace_state.itrace;
}

bool mtrace_configured() {
  return mtrace_compiled() && g_trace_state.mtrace;
}

bool dtrace_configured() {
  return dtrace_compiled() && g_trace_state.dtrace;
}

bool itrace_enabled() {
  if (!itrace_configured()) {
    return false;
  }

  return evaluate_itrace_condition(g_trace_state.itrace_cond);
}

bool mtrace_enabled() {
  return mtrace_configured();
}

bool dtrace_enabled() {
  return dtrace_configured();
}

const std::string &itrace_condition() {
  return g_trace_state.itrace_cond;
}

void trace_info_display() {
  std::printf("itrace   : %s (build=%s)\n", on_off(itrace_configured()), itrace_compiled() ? "y" : "n");
  std::printf("cond     : %s\n", itrace_condition().c_str());
  std::printf("mtrace   : %s (build=%s)\n", on_off(mtrace_configured()), mtrace_compiled() ? "y" : "n");
  std::printf("dtrace   : %s (build=%s)\n", on_off(dtrace_configured()), dtrace_compiled() ? "y" : "n");
}

bool trace_set_mode(const std::string &name, bool enabled, std::string *message) {
  if (name == "itrace") {
    return set_flag("itrace", itrace_compiled(), enabled, &g_trace_state.itrace, message);
  }
  if (name == "mtrace") {
    return set_flag("mtrace", mtrace_compiled(), enabled, &g_trace_state.mtrace, message);
  }
  if (name == "dtrace") {
    return set_flag("dtrace", dtrace_compiled(), enabled, &g_trace_state.dtrace, message);
  }
  if (message != nullptr) {
    *message = "unknown trace category, expect itrace|mtrace|dtrace";
  }
  return false;
}

bool trace_set_itrace_condition(const std::string &expression, std::string *message) {
  if (!itrace_compiled()) {
    if (message != nullptr) {
      *message = "itrace support is not built. Enable NPC_ITRACE in menuconfig and rebuild.";
    }
    return false;
  }

  if (expression.empty()) {
    if (message != nullptr) {
      *message = "trace cond expects a non-empty expression.";
    }
    return false;
  }

  if (!validate_itrace_condition(expression)) {
    if (message != nullptr) {
      *message = "bad itrace condition expression.";
    }
    return false;
  }

  g_trace_state.itrace_cond = expression;
  if (message != nullptr) {
    std::ostringstream oss;
    oss << "itrace condition updated to: " << g_trace_state.itrace_cond;
    *message = oss.str();
  }
  return true;
}

}  // namespace npc
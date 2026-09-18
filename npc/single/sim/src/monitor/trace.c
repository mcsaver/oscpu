/* NPC Trace 子系统 — C 重构版
 * std::string/ostringstream 改为 char 缓冲区 + snprintf */
#include "monitor/trace.h"

#include "monitor/disasm.h"
#include "monitor/expr.h"

#include <stdio.h>
#include <string.h>

typedef struct {
  bool itrace;
  bool mtrace;
  bool dtrace;
  char itrace_cond[NPC_EXPR_MAX];
} TraceState;

static TraceState g_trace;

static const char *on_off(bool v) { return v ? "on" : "off"; }

static bool parse_bool_literal(const char *expr, bool *val) {
  if (!val) return false;
  if (strcmp(expr, "true") == 0 || strcmp(expr, "1") == 0) { *val = true; return true; }
  if (strcmp(expr, "false") == 0 || strcmp(expr, "0") == 0) { *val = false; return true; }
  return false;
}

static bool validate_itrace_cond(const char *expr) {
  bool v;
  if (parse_bool_literal(expr, &v)) return true;
#if CONFIG_NPC_EXPR
  uint32_t r = 0;
  return npc_expr(expr, &r);
#else
  return false;
#endif
}

static bool evaluate_itrace_cond(const char *expr) {
  bool v;
  if (parse_bool_literal(expr, &v)) return v;
#if CONFIG_NPC_EXPR
  uint32_t r = 0;
  return npc_expr(expr, &r) && r != 0;
#else
  return false;
#endif
}

bool npc_itrace_compiled(void) {
#if CONFIG_NPC_TEXT_TRACE
  return true;
#else
  return false;
#endif
}
bool npc_mtrace_compiled(void) {
#if CONFIG_NPC_TEXT_TRACE
  return true;
#else
  return false;
#endif
}
bool npc_dtrace_compiled(void) {
#if CONFIG_NPC_TEXT_TRACE
  return true;
#else
  return false;
#endif
}

bool npc_text_trace_compiled(void) {
#if CONFIG_NPC_TEXT_TRACE
  return true;
#else
  return false;
#endif
}

void npc_init_trace(const NpcSimConfig *config) {
  g_trace.itrace = npc_itrace_compiled() ? config->itrace : false;
  g_trace.mtrace = npc_mtrace_compiled() ? config->mtrace : false;
  g_trace.dtrace = npc_dtrace_compiled() ? config->dtrace : false;
  if (config->itrace_cond[0] != '\0')
    strncpy(g_trace.itrace_cond, config->itrace_cond, NPC_EXPR_MAX - 1);
  else
    strncpy(g_trace.itrace_cond, "true", NPC_EXPR_MAX - 1);
  g_trace.itrace_cond[NPC_EXPR_MAX - 1] = '\0';

  if (npc_itrace_compiled() && !npc_init_disasm()) {
    printf("[npc] itrace disasm unavailable, commit logs fall back to raw inst.\n");
  }
  if (config->itrace && !npc_itrace_compiled())
    printf("[npc] itrace requested but not built. Enable NPC_TEXT_TRACE.\n");
  if (config->mtrace && !npc_mtrace_compiled())
    printf("[npc] mtrace requested but not built. Enable NPC_TEXT_TRACE.\n");
  if (config->dtrace && !npc_dtrace_compiled())
    printf("[npc] dtrace requested but not built. Enable NPC_TEXT_TRACE.\n");

  if (npc_itrace_compiled() && !validate_itrace_cond(g_trace.itrace_cond)) {
    printf("[npc] bad itrace condition '%s', fallback to true.\n", g_trace.itrace_cond);
    strncpy(g_trace.itrace_cond, "true", NPC_EXPR_MAX - 1);
  }
}

bool npc_itrace_configured(void) { return npc_itrace_compiled() && g_trace.itrace; }
bool npc_mtrace_configured(void) { return npc_mtrace_compiled() && g_trace.mtrace; }
bool npc_dtrace_configured(void) { return npc_dtrace_compiled() && g_trace.dtrace; }
bool npc_text_trace_configured(void) {
  return npc_itrace_configured() || npc_mtrace_configured() || npc_dtrace_configured();
}

bool npc_itrace_enabled(void) {
  if (!npc_itrace_configured()) return false;
  return evaluate_itrace_cond(g_trace.itrace_cond);
}
bool npc_mtrace_enabled(void) { return npc_mtrace_configured(); }
bool npc_dtrace_enabled(void) { return npc_dtrace_configured(); }

const char *npc_itrace_condition(void) { return g_trace.itrace_cond; }

void npc_trace_info_display(void) {
  printf("texttrace: %s (build=%s)\n", on_off(npc_text_trace_configured()), npc_text_trace_compiled() ? "y" : "n");
  printf("itrace   : %s (build=%s)\n", on_off(npc_itrace_configured()), npc_itrace_compiled() ? "y" : "n");
  printf("disasm   : %s\n", npc_disasm_ready() ? "y" : "n");
  printf("cond     : %s\n", npc_itrace_condition());
  printf("mtrace   : %s (build=%s)\n", on_off(npc_mtrace_configured()), npc_mtrace_compiled() ? "y" : "n");
  printf("dtrace   : %s (build=%s)\n", on_off(npc_dtrace_configured()), npc_dtrace_compiled() ? "y" : "n");
}

bool npc_trace_set_mode(const char *name, bool enabled, char *msg_buf, size_t bufsize) {
  bool *slot = NULL;
  bool compiled = false;

  if (strcmp(name, "itrace") == 0) { slot = &g_trace.itrace; compiled = npc_itrace_compiled(); }
  else if (strcmp(name, "mtrace") == 0) { slot = &g_trace.mtrace; compiled = npc_mtrace_compiled(); }
  else if (strcmp(name, "dtrace") == 0) { slot = &g_trace.dtrace; compiled = npc_dtrace_compiled(); }
  else {
    if (msg_buf) snprintf(msg_buf, bufsize, "unknown trace category: %s", name);
    return false;
  }
  if (!compiled) {
    if (msg_buf) snprintf(msg_buf, bufsize, "%s not built. Enable NPC_TEXT_TRACE in menuconfig.", name);
    return false;
  }
  *slot = enabled;
  if (msg_buf) snprintf(msg_buf, bufsize, "%s is now %s.", name, on_off(enabled));
  return true;
}

bool npc_trace_set_itrace_condition(const char *expression, char *msg_buf, size_t bufsize) {
  if (!npc_itrace_compiled()) {
    if (msg_buf) snprintf(msg_buf, bufsize, "itrace not built. Enable NPC_TEXT_TRACE in menuconfig.");
    return false;
  }
  if (!expression || expression[0] == '\0') {
    if (msg_buf) snprintf(msg_buf, bufsize, "trace cond expects non-empty expression.");
    return false;
  }
  if (!validate_itrace_cond(expression)) {
    if (msg_buf) snprintf(msg_buf, bufsize, "bad itrace condition expression.");
    return false;
  }
  strncpy(g_trace.itrace_cond, expression, NPC_EXPR_MAX - 1);
  g_trace.itrace_cond[NPC_EXPR_MAX - 1] = '\0';
  if (msg_buf) snprintf(msg_buf, bufsize, "itrace condition updated to: %s", g_trace.itrace_cond);
  return true;
}

/* NPC 简易调试器（SDB）— C 重构版
 * std::getline/std::istringstream 改为 fgets + strtok_r */
#include "monitor/sdb.h"

#include "cpu/cpu.h"
#include "memory/paddr.h"
#include "monitor/expr.h"
#include "monitor/log.h"
#include "monitor/trace.h"
#include "monitor/watchpoint.h"
#include "utils.h"

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if CONFIG_NPC_SDB

#define LINE_MAX_SDB 1024

/* 就地 trim 首尾空白 */
static char *trim(char *s) {
  if (!s) return s;
  while (isspace((unsigned char)*s)) ++s;
  char *end = s + strlen(s) - 1;
  while (end > s && isspace((unsigned char)*end)) *end-- = '\0';
  return s;
}

/* 以空格切出下一个子串，state 用于 strtok_r */
static char *next_token(char **state) {
  return strtok_r(NULL, " \t", state);
}

/* ---- 命令处理函数族 ---- */

static int cmd_continue(char *args) {
  (void)args;
  npc_cpu_exec(UINT64_MAX);
  NpcState *st = npc_state();
  if (st->state == NPC_WATCHPOINT_HIT) {
    printf("Watchpoint %d hit: %s\n  Old = 0x%016" NPC_PRIxWORD ", New = 0x%016" NPC_PRIxWORD "\n",
           st->watchpoint_id, st->watchpoint_expr,
           st->watchpoint_old_value, st->watchpoint_new_value);
  }
  return 0;
}

static int cmd_quit(char *args) {
  (void)args;
  npc_state()->state = NPC_QUIT;
  return -1;
}

static int cmd_si(char *args) {
  uint64_t n = 1;
  if (args) {
    char *end = NULL;
    unsigned long long val = strtoull(args, &end, 10);
    if (end && *end == '\0' && val > 0) n = (uint64_t)val;
  }
  npc_cpu_exec(n);
  NpcState *st = npc_state();
  if (st->state == NPC_WATCHPOINT_HIT) {
    printf("Watchpoint %d hit: %s\n  Old = 0x%016" NPC_PRIxWORD ", New = 0x%016" NPC_PRIxWORD "\n",
           st->watchpoint_id, st->watchpoint_expr,
           st->watchpoint_old_value, st->watchpoint_new_value);
  }
  return 0;
}

static int cmd_info(char *args) {
  if (!args || args[0] == '\0') { printf("info r|w|t|c\n"); return 0; }

  if (strcmp(args, "r") == 0 || strcmp(args, "reg") == 0) {
    npc_cpu_reg_display();
  } else if (strcmp(args, "w") == 0 || strcmp(args, "wp") == 0) {
    npc_watchpoint_display();
  } else if (strcmp(args, "t") == 0 || strcmp(args, "trace") == 0) {
    npc_trace_info_display();
  } else if (strcmp(args, "c") == 0 || strcmp(args, "cpu") == 0) {
    npc_cpu_info_display();
  } else {
    printf("Unknown info subcmd: %s\n", args);
  }
  return 0;
}

static int cmd_x(char *args) {
  if (!args) { printf("Usage: x N EXPR\n"); return 0; }

  char *state_ptr = NULL;
  char *first = strtok_r(args, " \t", &state_ptr);
  if (!first) { printf("Usage: x N EXPR\n"); return 0; }

  int count = (int)strtol(first, NULL, 10);
  if (count <= 0) { printf("Bad count: %s\n", first); return 0; }

  char *expr_part = strtok_r(NULL, "", &state_ptr);
  if (!expr_part) { printf("Usage: x N EXPR\n"); return 0; }
  expr_part = trim(expr_part);

  npc_word_t addr = 0;
  if (!npc_expr(expr_part, &addr)) { printf("Bad expression: %s\n", expr_part); return 0; }

  for (int i = 0; i < count; ++i) {
    npc_word_t w = 0;
    if (npc_paddr_read(addr, &w, NPC_BUS_LOAD)) {
      printf("0x%016" NPC_PRIxWORD ": 0x%016" NPC_PRIxWORD "\n", addr, w);
    } else {
      printf("0x%016" NPC_PRIxWORD ": <invalid>\n", addr);
    }
    addr += sizeof(npc_word_t);
  }
  return 0;
}

static int cmd_p(char *args) {
  if (!args || args[0] == '\0') { printf("Usage: p EXPR\n"); return 0; }
  npc_word_t val = 0;
  if (npc_expr(args, &val)) {
    printf("0x%016" NPC_PRIxWORD " (%" PRIu64 ")\n", val, (uint64_t)val);
  } else {
    printf("Failed to evaluate: %s\n", args);
  }
  return 0;
}

static int cmd_w(char *args) {
  if (!args || args[0] == '\0') { printf("Usage: w EXPR\n"); return 0; }
  npc_new_watchpoint(args);
  return 0;
}

static int cmd_d(char *args) {
  if (!args) { printf("Usage: d N\n"); return 0; }
  int no = (int)strtol(args, NULL, 10);
  npc_free_watchpoint(no);
  return 0;
}

static int cmd_trace(char *args) {
  if (!args || args[0] == '\0') { npc_trace_info_display(); return 0; }

  char *state_ptr = NULL;
  char *subcmd = strtok_r(args, " \t", &state_ptr);
  if (!subcmd) { npc_trace_info_display(); return 0; }

  if (strcmp(subcmd, "cond") == 0) {
    char *expr = strtok_r(NULL, "", &state_ptr);
    if (!expr || *trim(expr) == '\0') { printf("Usage: trace cond EXPR\n"); return 0; }
    char msg[256];
    npc_trace_set_itrace_condition(trim(expr), msg, sizeof(msg));
    printf("%s\n", msg);
    return 0;
  }

  /* trace <name> on|off */
  char *onoff = next_token(&state_ptr);
  if (!onoff) { printf("Usage: trace <name> on|off | trace cond EXPR\n"); return 0; }

  bool enabled = (strcmp(onoff, "on") == 0 || strcmp(onoff, "1") == 0);
  char msg[256];
  npc_trace_set_mode(subcmd, enabled, msg, sizeof(msg));
  printf("%s\n", msg);
  return 0;
}

static int cmd_help(char *args);

typedef struct {
  const char *name;
  const char *description;
  int (*handler)(char *args);
} SdbCmd;

static SdbCmd g_cmd_table[] = {
  {"help",  "Display this information",   cmd_help},
  {"c",     "Continue program execution", cmd_continue},
  {"q",     "Exit NPC",                   cmd_quit},
  {"si",    "Step N instructions",        cmd_si},
  {"info",  "Show various info (r/w/t/c)",cmd_info},
  {"x",     "Scan memory: x N EXPR",      cmd_x},
  {"p",     "Evaluate expression",        cmd_p},
  {"w",     "Set watchpoint: w EXPR",      cmd_w},
  {"d",     "Delete watchpoint: d N",      cmd_d},
  {"trace", "Trace control",              cmd_trace},
};

#define NR_CMD (int)(sizeof(g_cmd_table) / sizeof(g_cmd_table[0]))

static int cmd_help(char *args) {
  (void)args;
  for (int i = 0; i < NR_CMD; ++i) {
    printf("  %-8s %s\n", g_cmd_table[i].name, g_cmd_table[i].description);
  }
  return 0;
}

int npc_sdb_mainloop(void) {
  char line[LINE_MAX_SDB];

  for (;;) {
    printf("(npc) ");
    fflush(stdout);

    if (!fgets(line, sizeof(line), stdin)) {
      /* EOF: 用 ctrl-D 退出也走 QUIT */
      printf("\n");
      npc_state()->state = NPC_QUIT;
      return 0;
    }

    char *trimmed = trim(line);
    if (*trimmed == '\0') continue;

    /* 切出命令名 */
    char *state_ptr = NULL;
    char *cmd_name = strtok_r(trimmed, " \t", &state_ptr);
    char *args = strtok_r(NULL, "", &state_ptr);
    if (args) args = trim(args);

    bool found = false;
    for (int i = 0; i < NR_CMD; ++i) {
      if (strcmp(cmd_name, g_cmd_table[i].name) == 0) {
        int ret = g_cmd_table[i].handler(args);
        if (ret < 0) return 0;
        found = true;
        break;
      }
    }
    if (!found) {
      printf("Unknown command: %s\n", cmd_name);
    }

    /* 若执行完发现已终止，打印一下状态 */
    NpcState *st = npc_state();
    if (st->state == NPC_QUIT) return 0;
  }
}

#else /* !CONFIG_NPC_SDB */

int npc_sdb_mainloop(void) {
  npc_cpu_exec(UINT64_MAX);
  return (npc_state()->state == NPC_END) ? (int)npc_state()->halt_ret : 1;
}

#endif

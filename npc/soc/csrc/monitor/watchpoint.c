/* NPC 监视点子系统 — C 重构版
 * std::array + std::string 改为固定 C 数组 + char 缓冲区 */
#include "monitor/watchpoint.h"

#include "monitor/expr.h"
#include "utils.h"

#include <stdio.h>
#include <string.h>

#if CONFIG_NPC_WATCHPOINT

#define WP_POOL_SIZE 32

typedef struct {
  bool in_use;
  int  id;
  char expression[NPC_EXPR_MAX];
  uint32_t last_value;
} WatchpointSlot;

static WatchpointSlot g_pool[WP_POOL_SIZE];
static int g_next_id;

void npc_init_watchpoint_pool(void) {
  memset(g_pool, 0, sizeof(g_pool));
  g_next_id = 0;
}

bool npc_new_watchpoint(const char *expression) {
  if (!expression || expression[0] == '\0') {
    printf("watchpoint: empty expression.\n");
    return false;
  }

  /* 先试算一下确保表达式合法 */
  uint32_t val = 0;
  if (!npc_expr(expression, &val)) {
    printf("watchpoint: failed to evaluate '%s'.\n", expression);
    return false;
  }

  for (int i = 0; i < WP_POOL_SIZE; ++i) {
    if (!g_pool[i].in_use) {
      g_pool[i].in_use = true;
      g_pool[i].id = g_next_id++;
      strncpy(g_pool[i].expression, expression, NPC_EXPR_MAX - 1);
      g_pool[i].expression[NPC_EXPR_MAX - 1] = '\0';
      g_pool[i].last_value = val;
      printf("Watchpoint %d: %s = 0x%08x\n", g_pool[i].id, g_pool[i].expression, val);
      return true;
    }
  }

  printf("watchpoint: pool exhausted (%d slots).\n", WP_POOL_SIZE);
  return false;
}

bool npc_free_watchpoint(int no) {
  for (int i = 0; i < WP_POOL_SIZE; ++i) {
    if (g_pool[i].in_use && g_pool[i].id == no) {
      printf("Deleted watchpoint %d: %s\n", no, g_pool[i].expression);
      g_pool[i].in_use = false;
      g_pool[i].expression[0] = '\0';
      return true;
    }
  }
  printf("No watchpoint number %d.\n", no);
  return false;
}

void npc_watchpoint_display(void) {
  bool any = false;
  for (int i = 0; i < WP_POOL_SIZE; ++i) {
    if (g_pool[i].in_use) {
      printf("  #%-3d %s = 0x%08x\n", g_pool[i].id, g_pool[i].expression, g_pool[i].last_value);
      any = true;
    }
  }
  if (!any) printf("No watchpoints.\n");
}

bool npc_check_watchpoints(void) {
  for (int i = 0; i < WP_POOL_SIZE; ++i) {
    if (!g_pool[i].in_use) continue;

    uint32_t new_val = 0;
    if (!npc_expr(g_pool[i].expression, &new_val)) continue;

    if (new_val != g_pool[i].last_value) {
      NpcState *st = npc_state();
      st->state = NPC_WATCHPOINT_HIT;
      st->watchpoint_id = g_pool[i].id;
      st->watchpoint_old_value = g_pool[i].last_value;
      st->watchpoint_new_value = new_val;
      strncpy(st->watchpoint_expr, g_pool[i].expression, NPC_EXPR_MAX - 1);
      st->watchpoint_expr[NPC_EXPR_MAX - 1] = '\0';

      printf("Watchpoint %d: %s\n", g_pool[i].id, g_pool[i].expression);
      printf("  Old value = 0x%08x\n", g_pool[i].last_value);
      printf("  New value = 0x%08x\n", new_val);

      g_pool[i].last_value = new_val;
      return true;
    }
  }
  return false;
}

#else /* !CONFIG_NPC_WATCHPOINT */

void npc_init_watchpoint_pool(void) {}
bool npc_new_watchpoint(const char *expression) { (void)expression; printf("watchpoint not built.\n"); return false; }
bool npc_free_watchpoint(int no) { (void)no; printf("watchpoint not built.\n"); return false; }
void npc_watchpoint_display(void) { printf("watchpoint not built.\n"); }
bool npc_check_watchpoints(void) { return false; }

#endif

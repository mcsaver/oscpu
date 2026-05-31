#ifndef NPC_RV64_CSRC_MONITOR_EXPR_H_
#define NPC_RV64_CSRC_MONITOR_EXPR_H_

#include <stdbool.h>
#include <stdint.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_expr(void);
bool npc_expr(const char *text, npc_word_t *result);

#ifdef __cplusplus
}
#endif

#endif

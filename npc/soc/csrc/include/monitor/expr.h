#ifndef NPC_SINGLE_CSRC_MONITOR_EXPR_H_
#define NPC_SINGLE_CSRC_MONITOR_EXPR_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_expr(void);
bool npc_expr(const char *text, uint32_t *result);

#ifdef __cplusplus
}
#endif

#endif

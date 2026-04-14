#ifndef NPC_SINGLE_CSRC_MONITOR_EXPR_H_
#define NPC_SINGLE_CSRC_MONITOR_EXPR_H_

#include <cstdint>
#include <string>

namespace npc {

void init_expr();
bool expr(const std::string &text, uint32_t *result);

}  // namespace npc

#endif
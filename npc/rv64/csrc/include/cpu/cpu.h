#ifndef NPC_RV64_CSRC_CPU_CPU_H_
#define NPC_RV64_CSRC_CPU_CPU_H_

#include <stdbool.h>
#include <stdint.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

bool npc_init_cpu(int argc, char **argv, const NpcSimConfig *config);
int npc_cpu_exec(uint64_t max_instructions);
void npc_fini_cpu(void);
void npc_cpu_reg_display(void);
void npc_cpu_info_display(void);
bool npc_isa_reg_str2val(const char *name, npc_word_t *value);
bool npc_cpu_read_reg(int index, npc_word_t *value);
npc_word_t npc_cpu_pc(void);
uint32_t npc_cpu_state_bits(void);
bool npc_consume_sigint_request(void);

#ifdef __cplusplus
}
#endif

#endif

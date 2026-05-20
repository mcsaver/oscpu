#ifndef NPC_SINGLE_CSRC_CPU_DIFFTEST_H_
#define NPC_SINGLE_CSRC_CPU_DIFFTEST_H_

#include <stdbool.h>
#include <stdint.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

bool npc_init_difftest(const NpcSimConfig *config);
void npc_fini_difftest(void);
bool npc_difftest_enabled(void);
void npc_difftest_skip_ref(void);
bool npc_difftest_step(uint32_t pc, uint32_t inst, uint32_t next_pc,
                       const uint32_t gpr[32],
                       bool rd_en, uint32_t rd_addr, uint32_t rd_data);

#ifdef __cplusplus
}
#endif

#endif

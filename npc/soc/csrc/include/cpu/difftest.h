#ifndef NPC_SINGLE_CSRC_CPU_DIFFTEST_H_
#define NPC_SINGLE_CSRC_CPU_DIFFTEST_H_

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

#if CONFIG_NPC_DIFFTEST
bool npc_init_difftest(const NpcSimConfig *config);
void npc_fini_difftest(void);
bool npc_difftest_enabled(void);
void npc_difftest_skip_ref(void);
bool npc_difftest_step(uint32_t pc, uint32_t inst, uint32_t next_pc,
                       const uint32_t gpr[32],
                       bool rd_en, uint32_t rd_addr, uint32_t rd_data);
#else
static inline bool npc_init_difftest(const NpcSimConfig *config) {
  if (config && config->difftest) {
    fprintf(stderr, "[npc-diff] --diff requested, but this binary was built without CONFIG_NPC_DIFFTEST.\n"
                    "           Enable NPC_DIFFTEST in menuconfig or use default_defconfig, then rebuild.\n");
    return false;
  }
  return true;
}
static inline void npc_fini_difftest(void) {}
static inline bool npc_difftest_enabled(void) { return false; }
static inline void npc_difftest_skip_ref(void) {}
static inline bool npc_difftest_step(uint32_t pc, uint32_t inst, uint32_t next_pc,
                                     const uint32_t gpr[32],
                                     bool rd_en, uint32_t rd_addr, uint32_t rd_data) {
  (void)pc;
  (void)inst;
  (void)next_pc;
  (void)gpr;
  (void)rd_en;
  (void)rd_addr;
  (void)rd_data;
  return true;
}
#endif

#ifdef __cplusplus
}
#endif

#endif

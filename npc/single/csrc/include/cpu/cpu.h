#ifndef NPC_SINGLE_CSRC_CPU_CPU_H_
#define NPC_SINGLE_CSRC_CPU_CPU_H_

#include <cstdint>

#include "../utils.h"

namespace npc {

bool init_cpu(int argc, char **argv, const SimConfig &config);
int cpu_exec(uint64_t max_cycles);
void fini_cpu();
void cpu_reg_display();
void cpu_info_display();
bool isa_reg_str2val(const char *name, uint32_t *value);
bool cpu_read_reg(int index, uint32_t *value);
uint32_t cpu_pc();
uint32_t cpu_state_bits();
bool consume_sigint_request();

}  // namespace npc

#endif
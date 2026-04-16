#ifndef NPC_SINGLE_CSRC_MONITOR_DISASM_H_
#define NPC_SINGLE_CSRC_MONITOR_DISASM_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

bool npc_init_disasm(void);
void npc_fini_disasm(void);
bool npc_disasm_ready(void);
/* 反汇编一条指令到 buf，返回写入长度（不含 '\0'），失败返回 0 */
int npc_disassemble_inst(uint32_t pc, uint32_t inst, char *buf, size_t bufsize);

#ifdef __cplusplus
}
#endif

#endif

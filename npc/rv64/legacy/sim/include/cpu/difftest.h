#ifndef NPC_RV64_CSRC_CPU_DIFFTEST_H_
#define NPC_RV64_CSRC_CPU_DIFFTEST_H_

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

// 全状态 difftest: CSR + priv 扁平化槽位数(★索引约定与 NEMU dut.c 一致)。
// 0..16 阶段1比较(mstatus/mepc/mcause/mtvec/mtval/mscratch/sepc/scause/stvec/stval/
// sscratch/medeleg/mideleg/satp/mcounteren/scounteren/priv); 17+ 预留(mie/mip/mcycle/
// minstret/fflags/frm)先填不比。
#define NPC_DIFF_CSR_N 23
#define NPC_DIFF_FPR_N 32   // 全状态 difftest 阶段2: 32 个 FPR

#if CONFIG_NPC_DIFFTEST
bool npc_init_difftest(const NpcSimConfig *config);
void npc_fini_difftest(void);
bool npc_difftest_enabled(void);
void npc_difftest_skip_ref(void);
// 供 commit 处理在 step 前注入本条提交后的 DUT CSR 快照(旁路通道, 不改 step 签名)。
void npc_difftest_set_dut_csr(const npc_word_t csr[NPC_DIFF_CSR_N]);
void npc_difftest_set_dut_fpr(const uint64_t fpr[NPC_DIFF_FPR_N]);
// 阶段4: NPC 取异步中断时登记 pending(mcause 含 interrupt bit), difftest 在同步点让 NEMU raise。
void npc_difftest_set_pending_intr(uint64_t mcause);
bool npc_difftest_step(npc_word_t pc, uint32_t inst, npc_word_t next_pc,
                       const npc_word_t gpr[32],
                       bool rd_en, uint32_t rd_addr, npc_word_t rd_data);
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
static inline void npc_difftest_set_dut_csr(const npc_word_t csr[NPC_DIFF_CSR_N]) { (void)csr; }
static inline void npc_difftest_set_dut_fpr(const uint64_t fpr[NPC_DIFF_FPR_N]) { (void)fpr; }
static inline void npc_difftest_set_pending_intr(uint64_t mcause) { (void)mcause; }
static inline bool npc_difftest_step(npc_word_t pc, uint32_t inst, npc_word_t next_pc,
                                     const npc_word_t gpr[32],
                                     bool rd_en, uint32_t rd_addr, npc_word_t rd_data) {
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

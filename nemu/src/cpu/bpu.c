/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <cpu/bpu.h>
#include <stdio.h>

#ifdef CONFIG_BPU

#define BPU_BTB_NR CONFIG_BPU_BTB_ENTRIES
#define BPU_BHT_NR CONFIG_BPU_BHT_ENTRIES
#define BPU_RAS_NR CONFIG_BPU_RAS_ENTRIES
#define BPU_COUNTER_MAX ((1u << CONFIG_BPU_COUNTER_BITS) - 1u)
#define BPU_TAKEN_THRESHOLD (1u << (CONFIG_BPU_COUNTER_BITS - 1))
#define OPC_BRANCH 0x63
#define OPC_JALR   0x67
#define OPC_JAL    0x6f

typedef enum {
  RAS_NONE,
  RAS_PUSH,
  RAS_POP,
  RAS_POP_PUSH,
} RasAction;

typedef struct {
  bool valid;
  bool conditional;
  RasAction ras_action;
} ControlInfo;

typedef struct {
  bool valid;
  vaddr_t pc;
  vaddr_t target;
} BtbEntry;

static BtbEntry btb[BPU_BTB_NR];
static uint8_t bht[BPU_BHT_NR];
static vaddr_t ras[BPU_RAS_NR];
static uint32_t ras_size;
static uint32_t ghr;
static BpuStats bpu_stats;

static inline uint32_t opcode(uint32_t inst) {
  return BITS(inst, 6, 0);
}

static inline uint32_t funct3(uint32_t inst) {
  return BITS(inst, 14, 12);
}

static inline uint32_t rd(uint32_t inst) {
  return BITS(inst, 11, 7);
}

static inline uint32_t rs1(uint32_t inst) {
  return BITS(inst, 19, 15);
}

static inline bool is_link_reg(uint32_t reg) {
  return reg == 1 || reg == 5;
}

static inline bool is_valid_branch_funct3(uint32_t f3) {
  return f3 == 0x0 || f3 == 0x1 || (f3 >= 0x4 && f3 <= 0x7);
}

static RasAction jalr_ras_action(uint32_t rd_idx, uint32_t rs1_idx) {
  bool rd_link = is_link_reg(rd_idx);
  bool rs1_link = is_link_reg(rs1_idx);

  if (!rd_link && !rs1_link) return RAS_NONE;
  if (!rd_link && rs1_link) return RAS_POP;
  if (rd_link && !rs1_link) return RAS_PUSH;
  return rd_idx == rs1_idx ? RAS_PUSH : RAS_POP_PUSH;
}

static bool ras_action_uses_top(RasAction action) {
  return action == RAS_POP || action == RAS_POP_PUSH;
}

static bool ras_action_pushes(RasAction action) {
  return action == RAS_PUSH || action == RAS_POP_PUSH;
}

static bool ras_action_pops(RasAction action) {
  return action == RAS_POP || action == RAS_POP_PUSH;
}

static bool decode_rvc_control(uint16_t inst, ControlInfo *info) {
  uint32_t quadrant = BITS(inst, 1, 0);
  uint32_t f3 = BITS(inst, 15, 13);
  uint32_t crd = BITS(inst, 11, 7);
  uint32_t crs2 = BITS(inst, 6, 2);

  if (quadrant == 0x1) {
    switch (f3) {
      case 0x1: // c.jal
        info->valid = true;
        info->ras_action = RAS_PUSH;
        return true;
      case 0x5: // c.j
        info->valid = true;
        return true;
      case 0x6: // c.beqz
      case 0x7: // c.bnez
        info->valid = true;
        info->conditional = true;
        return true;
      default:
        return false;
    }
  }

  if (quadrant == 0x2 && f3 == 0x4 && crs2 == 0 && crd != 0) {
    info->valid = true;
    if (BITS(inst, 12, 12) == 0) {
      info->ras_action = is_link_reg(crd) ? RAS_POP : RAS_NONE; // c.jr
    } else {
      info->ras_action = jalr_ras_action(1, crd); // c.jalr 隐式写 ra
    }
    return true;
  }

  return false;
}

static bool decode_control(uint32_t inst, ControlInfo *info) {
  memset(info, 0, sizeof(*info));

  if ((inst & 0x3) != 0x3) {
    return decode_rvc_control(inst & 0xffffu, info);
  }

  switch (opcode(inst)) {
    case OPC_BRANCH:
      if (!is_valid_branch_funct3(funct3(inst))) return false;
      info->valid = true;
      info->conditional = true;
      return true;
    case OPC_JAL:
      info->valid = true;
      info->ras_action = is_link_reg(rd(inst)) ? RAS_PUSH : RAS_NONE;
      return true;
    case OPC_JALR:
      if (funct3(inst) != 0) return false;
      info->valid = true;
      info->ras_action = jalr_ras_action(rd(inst), rs1(inst));
      return true;
    default:
      return false;
  }
}

static inline uint32_t btb_index(vaddr_t pc) {
  return (pc >> 1) % BPU_BTB_NR;
}

static inline uint32_t ghr_mask(void) {
  return CONFIG_BPU_GHR_BITS == 0 ? 0 : ((1u << CONFIG_BPU_GHR_BITS) - 1u);
}

static inline uint32_t bht_index(vaddr_t pc) {
  return ((pc >> 1) ^ (ghr & ghr_mask())) % BPU_BHT_NR;
}

static bool btb_lookup(vaddr_t pc, vaddr_t *target) {
  uint32_t idx = btb_index(pc);
  BtbEntry *entry = &btb[idx];
  bpu_stats.btb_access++;
  if (entry->valid && entry->pc == pc) {
    bpu_stats.btb_hit++;
    *target = entry->target;
    return true;
  }
  bpu_stats.btb_miss++;
  return false;
}

static void btb_update(vaddr_t pc, vaddr_t target) {
  uint32_t idx = btb_index(pc);
  btb[idx] = (BtbEntry) {
    .valid = true,
    .pc = pc,
    .target = target,
  };
}

static bool bht_predict_taken(vaddr_t pc) {
  return bht[bht_index(pc)] >= BPU_TAKEN_THRESHOLD;
}

static void bht_update(vaddr_t pc, bool taken) {
  uint8_t *counter = &bht[bht_index(pc)];
  if (taken) {
    if (*counter < BPU_COUNTER_MAX) (*counter)++;
  } else if (*counter > 0) {
    (*counter)--;
  }
  ghr = ((ghr << 1) | (taken ? 1u : 0u)) & ghr_mask();
}

static void ras_push(vaddr_t ret_addr) {
  bpu_stats.ras_push++;
  if (ras_size == BPU_RAS_NR) {
    memmove(&ras[0], &ras[1], sizeof(ras[0]) * (BPU_RAS_NR - 1));
    ras[BPU_RAS_NR - 1] = ret_addr;
    bpu_stats.ras_overflow++;
    return;
  }
  ras[ras_size++] = ret_addr;
}

static void ras_pop(void) {
  if (ras_size == 0) {
    bpu_stats.ras_underflow++;
    return;
  }
  ras_size--;
  bpu_stats.ras_pop++;
}

static bool ras_peek(vaddr_t *target) {
  bpu_stats.ras_access++;
  if (ras_size == 0) {
    bpu_stats.ras_miss++;
    return false;
  }
  *target = ras[ras_size - 1];
  return true;
}

static uint64_t rate_x100(uint64_t hit, uint64_t access) {
  return access == 0 ? 0 : hit * 10000 / access;
}

static void print_rate_line(const char *name, uint64_t access, uint64_t hit, uint64_t miss) {
  uint64_t rate = rate_x100(hit, access);
  Log("%s access = %" PRIu64 ", hit = %" PRIu64 ", miss = %" PRIu64
      ", hit rate = %" PRIu64 ".%02" PRIu64 "%%",
      name, access, hit, miss, rate / 100, rate % 100);
}

static void reset_bpu_state(void) {
  memset(btb, 0, sizeof(btb));
  memset(ras, 0, sizeof(ras));
  memset(&bpu_stats, 0, sizeof(bpu_stats));
  ras_size = 0;
  ghr = 0;
  for (uint32_t i = 0; i < BPU_BHT_NR; i++) {
    bht[i] = CONFIG_BPU_COUNTER_INIT;
  }
}

void init_bpu(void) {
  assert(CONFIG_BPU_BTB_ENTRIES > 0);
  assert(CONFIG_BPU_BHT_ENTRIES > 0);
  assert(CONFIG_BPU_RAS_ENTRIES > 0);
  assert(CONFIG_BPU_COUNTER_BITS >= 1 && CONFIG_BPU_COUNTER_BITS <= 8);
  assert(CONFIG_BPU_COUNTER_INIT <= BPU_COUNTER_MAX);
  assert(CONFIG_BPU_GHR_BITS <= 16);
  reset_bpu_state();
}

void bpu_init_for_test(void) {
  init_bpu();
}

void bpu_commit(vaddr_t pc, uint32_t inst, vaddr_t snpc, vaddr_t dnpc) {
  ControlInfo info;
  if (!decode_control(inst, &info)) return;

  bool actual_taken = dnpc != snpc;
  vaddr_t actual_target = actual_taken ? dnpc : snpc;
  bool predicted_taken = info.conditional ? bht_predict_taken(pc) : true;
  bool predicted_target_valid = false;
  bool target_from_ras = false;
  vaddr_t predicted_target = 0;

  bpu_stats.control_access++;
  if (info.conditional) {
    bpu_stats.branch_access++;
    if (predicted_taken == actual_taken) bpu_stats.branch_hit++;
    else bpu_stats.branch_miss++;
  }

  if (predicted_taken) {
    bpu_stats.target_access++;
    if (ras_action_uses_top(info.ras_action)) {
      predicted_target_valid = ras_peek(&predicted_target);
      target_from_ras = predicted_target_valid;
    }
    if (!predicted_target_valid) {
      predicted_target_valid = btb_lookup(pc, &predicted_target);
    }

    if (predicted_target_valid && predicted_target == actual_target) {
      bpu_stats.target_hit++;
      if (target_from_ras) bpu_stats.ras_hit++;
    } else {
      bpu_stats.target_miss++;
      if (target_from_ras) bpu_stats.ras_miss++;
    }
  }

  if (info.conditional) {
    bht_update(pc, actual_taken);
  }
  if (actual_taken) {
    btb_update(pc, actual_target);
  }

  // RAS 更新放在预测对比之后，模拟“用旧栈预测当前返回，再按真实控制流提交”的时序。
  if (ras_action_pops(info.ras_action)) {
    ras_pop();
  }
  if (ras_action_pushes(info.ras_action)) {
    ras_push(snpc);
  }
}

void bpu_statistic(void) {
  print_rate_line("bpu branch", bpu_stats.branch_access,
      bpu_stats.branch_hit, bpu_stats.branch_miss);
  print_rate_line("bpu target", bpu_stats.target_access,
      bpu_stats.target_hit, bpu_stats.target_miss);
  print_rate_line("bpu btb", bpu_stats.btb_access,
      bpu_stats.btb_hit, bpu_stats.btb_miss);
  print_rate_line("bpu ras", bpu_stats.ras_access,
      bpu_stats.ras_hit, bpu_stats.ras_miss);
  Log("bpu control = %" PRIu64 ", ras push = %" PRIu64
      ", pop = %" PRIu64 ", overflow = %" PRIu64 ", underflow = %" PRIu64,
      bpu_stats.control_access, bpu_stats.ras_push, bpu_stats.ras_pop,
      bpu_stats.ras_overflow, bpu_stats.ras_underflow);
}

const BpuStats *bpu_get_stats(void) {
  return &bpu_stats;
}

#else

static BpuStats bpu_stats;

void init_bpu(void) {}

void bpu_commit(vaddr_t pc, uint32_t inst, vaddr_t snpc, vaddr_t dnpc) {
  (void)pc;
  (void)inst;
  (void)snpc;
  (void)dnpc;
}

void bpu_statistic(void) {}

const BpuStats *bpu_get_stats(void) {
  return &bpu_stats;
}

void bpu_init_for_test(void) {}

#endif

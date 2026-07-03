#include "cpu/difftest.h"

#include "memory/paddr.h"
#include "monitor/log.h"

#include <dlfcn.h>

#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cstdlib>

enum {
  DIFFTEST_TO_DUT = 0,
  DIFFTEST_TO_REF = 1,
};

struct DiffContext {
  npc_word_t gpr[32];
  npc_word_t pc;
};

using ref_init_t = void (*)(int);
using ref_memcpy_t = void (*)(uint32_t, void *, size_t, bool);
using ref_regcpy_t = void (*)(void *, bool);
using ref_exec_t = void (*)(uint64_t);

static bool g_enabled = false;
static bool g_skip_ref = false;
static void *g_ref_handle = nullptr;
static ref_init_t g_ref_init = nullptr;
static ref_memcpy_t g_ref_memcpy = nullptr;
static ref_regcpy_t g_ref_regcpy = nullptr;
static ref_exec_t g_ref_exec = nullptr;

static void *load_symbol(const char *name) {
  dlerror();
  void *sym = dlsym(g_ref_handle, name);
  const char *err = dlerror();
  if (err) {
    fprintf(stderr, "[npc-diff] dlsym(%s): %s\n", name, err);
    return nullptr;
  }
  return sym;
}

static bool load_reference_symbols(void) {
  g_ref_init = reinterpret_cast<ref_init_t>(load_symbol("difftest_init"));
  g_ref_memcpy = reinterpret_cast<ref_memcpy_t>(load_symbol("difftest_memcpy"));
  g_ref_regcpy = reinterpret_cast<ref_regcpy_t>(load_symbol("difftest_regcpy"));
  g_ref_exec = reinterpret_cast<ref_exec_t>(load_symbol("difftest_exec"));
  return g_ref_init && g_ref_memcpy && g_ref_regcpy && g_ref_exec;
}

static DiffContext make_dut_context(npc_word_t next_pc, const npc_word_t gpr[32],
                                    bool rd_en, uint32_t rd_addr, npc_word_t rd_data) {
  DiffContext ctx = {};
  if (gpr) memcpy(ctx.gpr, gpr, sizeof(ctx.gpr));
  ctx.gpr[0] = 0;
  if (rd_en && rd_addr > 0 && rd_addr < 32) ctx.gpr[rd_addr] = rd_data;
  ctx.pc = next_pc;
  return ctx;
}

static bool compare_context(const DiffContext *ref, const DiffContext *dut,
                            npc_word_t pc, uint32_t inst) {
  if (ref->pc != dut->pc) {
    LogBoth("[npc-diff] mismatch at dut commit pc=0x%016" NPC_PRIxWORD " inst=0x%08x", pc, inst);
    LogBoth("[npc-diff] pc ref=0x%016" NPC_PRIxWORD " dut=0x%016" NPC_PRIxWORD, ref->pc, dut->pc);
    return false;
  }

  for (int i = 0; i < 32; ++i) {
    if (ref->gpr[i] != dut->gpr[i]) {
      LogBoth("[npc-diff] mismatch at dut commit pc=0x%016" NPC_PRIxWORD " inst=0x%08x", pc, inst);
      LogBoth("[npc-diff] x%d ref=0x%016" NPC_PRIxWORD " dut=0x%016" NPC_PRIxWORD,
              i, ref->gpr[i], dut->gpr[i]);
      return false;
    }
  }
  return true;
}

bool npc_init_difftest(const NpcSimConfig *config) {
  g_enabled = false;
  g_skip_ref = false;

  if (!config || !config->difftest) return true;
  if (config->diff_so_path[0] == '\0') {
    fprintf(stderr, "[npc-diff] --diff enabled but no reference .so path was configured.\n");
    return false;
  }

  g_ref_handle = dlopen(config->diff_so_path, RTLD_LAZY | RTLD_LOCAL);
  if (!g_ref_handle) {
    fprintf(stderr, "[npc-diff] dlopen(%s): %s\n", config->diff_so_path, dlerror());
    return false;
  }
  if (!load_reference_symbols()) return false;

  g_ref_init(config->diff_port);

  size_t image_size = npc_loaded_img_size();
  if (image_size > 0) {
    g_ref_memcpy(NPC_RESET_PC, npc_guest_to_host(NPC_RESET_PC), image_size, DIFFTEST_TO_REF);
  }

  DiffContext reset_ctx = {};
  reset_ctx.pc = NPC_RESET_PC;
  g_ref_regcpy(&reset_ctx, DIFFTEST_TO_REF);

  g_enabled = true;
  LogBoth("[npc-diff] reference enabled: %s, image-size=%zu", config->diff_so_path, image_size);
  return true;
}

void npc_fini_difftest(void) {
  g_enabled = false;
  g_skip_ref = false;
  g_ref_init = nullptr;
  g_ref_memcpy = nullptr;
  g_ref_regcpy = nullptr;
  g_ref_exec = nullptr;
  if (g_ref_handle) {
    dlclose(g_ref_handle);
    g_ref_handle = nullptr;
  }
}

bool npc_difftest_enabled(void) {
  return g_enabled;
}

void npc_difftest_skip_ref(void) {
  if (g_enabled) g_skip_ref = true;
}

bool npc_difftest_step(npc_word_t pc, uint32_t inst, npc_word_t next_pc,
                       const npc_word_t gpr[32],
                       bool rd_en, uint32_t rd_addr, npc_word_t rd_data) {
  if (!g_enabled) return true;

  DiffContext dut = make_dut_context(next_pc, gpr, rd_en, rd_addr, rd_data);
  if (g_skip_ref) {
    g_ref_regcpy(&dut, DIFFTEST_TO_REF);
    g_skip_ref = false;
    return true;
  }

  // 比较模式：步进前比对"指令自身 PC"(committed pc),步进后比 GPR。
  // 不比对 commit 上报的 next_pc——OoO 的 ROB 存 dispatch 时的【预测】next_pc,误预测分支
  // 解析为 taken 后该字段不更新(核实际已取 target),直接比 next_pc 会误报;改用"committed pc
  // == ref 步进前 pc"校验控制流(下一条 committed pc 即上一条的真实 next_pc),等价且正确。
  // 【F2 difftest 基建】MMIO 访存的 skip 判定搬到 commit 拍、按指令解码 EA:
  // 旧机制(桥 rsp 拍/uart 总线拍置全局 skip 旗)有两个致命时序洞——
  //   (a) SQ 切换后 store 的总线访问在 commit 之后, UART store 自己吃不到 skip,
  //       ref 真执行 MMIO store → fault → ref.pc=0(既往 CoreMark 3.2M 条预存墙真身);
  //   (b) skip 旗与 commit 粗配对, MIQ/F2 时代 rsp→commit 距离拉大即错位毒 ref。
  // 此处按 dut commit 的 inst 解码(load/store/AMO)+dut GPR 算 EA, 非 pmem 即为
  // MMIO 访问: ref 不步进, 拷 dut GPR 进 ref、ref.pc=pc+4(mem 指令恒非控制流)。
  {
    uint32_t opc = inst & 0x7f;
    bool mem_is_load = (opc == 0x03) || (opc == 0x07);
    bool mem_is_store = (opc == 0x23) || (opc == 0x27);
    bool mem_is_amo = (opc == 0x2f);
    if (mem_is_load || mem_is_store || mem_is_amo) {
      uint32_t rs1 = (inst >> 15) & 0x1f;
      int64_t imm = 0;
      if (mem_is_load) imm = (int64_t)(int32_t)inst >> 20;
      else if (mem_is_store)
        imm = (int64_t)((int32_t)(inst & 0xfe000000) >> 20) | ((inst >> 7) & 0x1f);
      npc_word_t ea = gpr[rs1] + (npc_word_t)imm;
      if (ea < NPC_PMEM_BASE) {
        DiffContext ref_chk = {};
        g_ref_regcpy(&ref_chk, DIFFTEST_TO_DUT);
        if (ref_chk.pc != pc) {
          LogBoth("[npc-diff] control-flow mismatch (mmio skip): dut commit pc=0x%016" NPC_PRIxWORD
                  " inst=0x%08x, ref expects pc=0x%016" NPC_PRIxWORD, pc, inst, ref_chk.pc);
          return false;
        }
        DiffContext dut_ov = make_dut_context(pc + 4, gpr, rd_en, rd_addr, rd_data);
        g_ref_regcpy(&dut_ov, DIFFTEST_TO_REF);
        g_skip_ref = false;   // 旧机制若已挂旗, 一并吸收(本条即其归属)
        return true;
      }
    }
  }

  DiffContext ref_pre = {};
  g_ref_regcpy(&ref_pre, DIFFTEST_TO_DUT);
  if (ref_pre.pc != pc) {
    LogBoth("[npc-diff] control-flow mismatch: dut commit pc=0x%016" NPC_PRIxWORD
            " inst=0x%08x, ref expects pc=0x%016" NPC_PRIxWORD, pc, inst, ref_pre.pc);
    return false;
  }
  g_ref_exec(1);
  DiffContext ref = {};
  g_ref_regcpy(&ref, DIFFTEST_TO_DUT);
  for (int i = 0; i < 32; ++i) {
    if (ref.gpr[i] != dut.gpr[i]) {
      LogBoth("[npc-diff] mismatch at dut commit pc=0x%016" NPC_PRIxWORD " inst=0x%08x", pc, inst);
      LogBoth("[npc-diff] x%d ref=0x%016" NPC_PRIxWORD " dut=0x%016" NPC_PRIxWORD,
              i, ref.gpr[i], dut.gpr[i]);
      return false;
    }
  }
  return true;
}

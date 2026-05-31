#include "cpu/difftest.h"

#include "memory/paddr.h"
#include "monitor/log.h"

#include <dlfcn.h>

#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstring>

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

  DiffContext ref = {};
  g_ref_exec(1);
  g_ref_regcpy(&ref, DIFFTEST_TO_DUT);
  return compare_context(&ref, &dut, pc, inst);
}

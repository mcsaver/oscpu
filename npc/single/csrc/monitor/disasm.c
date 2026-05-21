/* NPC Capstone 反汇编 — C 重构版
 * std::filesystem/std::string/std::vector 改为 C 风格路径操作 */
#include "monitor/disasm.h"

#include <stdio.h>

#if CONFIG_NPC_ITRACE

#include <capstone/capstone.h>
#include <dlfcn.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void *g_capstone_handle = NULL;
static csh   g_disasm_handle = 0;
static bool  g_disasm_ready = false;
static char  g_capstone_path[PATH_MAX];

static size_t (*g_cs_disasm)(csh, const uint8_t *, size_t, uint64_t, size_t, cs_insn **) = NULL;
static void   (*g_cs_free)(cs_insn *, size_t) = NULL;
static cs_err (*g_cs_open)(cs_arch, cs_mode, csh *) = NULL;
static cs_err (*g_cs_close)(csh *) = NULL;

static void try_open_capstone(void) {
  /* 候选路径列表 */
  char paths[5][PATH_MAX];
  int count = 0;

  /* 从 /proc/self/exe 向上三级拼路径 */
  char exe[PATH_MAX] = {};
  ssize_t len = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
  if (len > 0) {
    exe[len] = '\0';
    /* 往上找三层父目录 */
    char *slash = strrchr(exe, '/'); if (slash) *slash = '\0';
    slash = strrchr(exe, '/'); if (slash) *slash = '\0';
    slash = strrchr(exe, '/'); if (slash) *slash = '\0';
    snprintf(paths[count++], PATH_MAX, "%s/nemu/tools/capstone/repo/libcapstone.so.5", exe);
  }

  const char *nemu_home = getenv("NEMU_HOME");
  if (nemu_home && nemu_home[0]) {
    snprintf(paths[count++], PATH_MAX, "%s/tools/capstone/repo/libcapstone.so.5", nemu_home);
  }

  strncpy(paths[count++], "../../nemu/tools/capstone/repo/libcapstone.so.5", PATH_MAX - 1);
  strncpy(paths[count++], "../nemu/tools/capstone/repo/libcapstone.so.5", PATH_MAX - 1);
  strncpy(paths[count++], "tools/capstone/repo/libcapstone.so.5", PATH_MAX - 1);

  for (int i = 0; i < count; ++i) {
    g_capstone_handle = dlopen(paths[i], RTLD_LAZY);
    if (g_capstone_handle) {
      strncpy(g_capstone_path, paths[i], PATH_MAX - 1);
      return;
    }
  }
}

bool npc_init_disasm(void) {
  if (g_disasm_ready) return true;

  try_open_capstone();
  if (!g_capstone_handle) {
    fprintf(stderr, "[npc] failed to locate libcapstone.so.5: %s\n", dlerror());
    return false;
  }

  g_cs_open   = (cs_err (*)(cs_arch, cs_mode, csh *))dlsym(g_capstone_handle, "cs_open");
  g_cs_disasm = (size_t (*)(csh, const uint8_t *, size_t, uint64_t, size_t, cs_insn **))dlsym(g_capstone_handle, "cs_disasm");
  g_cs_free   = (void (*)(cs_insn *, size_t))dlsym(g_capstone_handle, "cs_free");
  g_cs_close  = (cs_err (*)(csh *))dlsym(g_capstone_handle, "cs_close");

  if (!g_cs_open || !g_cs_disasm || !g_cs_free || !g_cs_close) {
    fprintf(stderr, "[npc] failed to resolve Capstone symbols from %s\n", g_capstone_path);
    dlclose(g_capstone_handle); g_capstone_handle = NULL;
    g_capstone_path[0] = '\0';
    return false;
  }

  if (g_cs_open(CS_ARCH_RISCV, (cs_mode)(CS_MODE_RISCV32 | CS_MODE_RISCVC), &g_disasm_handle) != CS_ERR_OK) {
    fprintf(stderr, "[npc] failed to init RISC-V disassembler\n");
    dlclose(g_capstone_handle); g_capstone_handle = NULL;
    g_disasm_handle = 0;
    return false;
  }

  g_disasm_ready = true;
  return true;
}

void npc_fini_disasm(void) {
  if (g_disasm_handle && g_cs_close) { g_cs_close(&g_disasm_handle); g_disasm_handle = 0; }
  if (g_capstone_handle) { dlclose(g_capstone_handle); g_capstone_handle = NULL; }
  g_capstone_path[0] = '\0';
  g_disasm_ready = false;
  g_cs_open = NULL;
  g_cs_disasm = NULL;
  g_cs_free = NULL;
  g_cs_close = NULL;
}

bool npc_disasm_ready(void) { return g_disasm_ready; }

int npc_disassemble_inst(uint32_t pc, uint32_t inst, char *buf, size_t bufsize) {
  if (!g_disasm_ready || !buf || bufsize == 0) return 0;

  uint8_t bytes[4] = {
    (uint8_t)(inst & 0xff),
    (uint8_t)((inst >> 8) & 0xff),
    (uint8_t)((inst >> 16) & 0xff),
    (uint8_t)((inst >> 24) & 0xff),
  };

  cs_insn *decoded = NULL;
  size_t count = g_cs_disasm(g_disasm_handle, bytes, 4, pc, 0, &decoded);
  if (count != 1 || !decoded) {
    if (decoded) g_cs_free(decoded, count);
    buf[0] = '\0';
    return 0;
  }

  int n;
  if (decoded->op_str[0] != '\0')
    n = snprintf(buf, bufsize, "%s %s", decoded->mnemonic, decoded->op_str);
  else
    n = snprintf(buf, bufsize, "%s", decoded->mnemonic);

  g_cs_free(decoded, count);
  return (n < 0) ? 0 : (n >= (int)bufsize ? (int)bufsize - 1 : n);
}

#else /* !CONFIG_NPC_ITRACE */

bool npc_init_disasm(void)  { return false; }
void npc_fini_disasm(void)  {}
bool npc_disasm_ready(void) { return false; }
int  npc_disassemble_inst(uint32_t pc, uint32_t inst, char *buf, size_t bufsize) {
  (void)pc; (void)inst;
  if (buf && bufsize > 0) buf[0] = '\0';
  return 0;
}

#endif

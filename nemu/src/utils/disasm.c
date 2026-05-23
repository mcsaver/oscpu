/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <dlfcn.h>
#include <capstone/capstone.h>
#include <common.h>

//定义了一个函数指针变量cs_disasm_dl，这个函数的功能是：反汇编机器码为汇编指令
static size_t (*cs_disasm_dl)(csh handle, const uint8_t *code,
    size_t code_size, uint64_t address, size_t count, cs_insn **insn);
static void (*cs_free_dl)(cs_insn *insn, size_t count);

static csh handle;
static bool disasm_ready = false;

static void format_raw_inst(char *str, int size, uint64_t pc, uint8_t *code, int nbyte) {
  uint64_t raw = 0;
  for (int i = 0; i < nbyte && i < (int)sizeof(raw); i++) {
    raw |= (uint64_t)code[i] << (i * 8);
  }
  // Capstone 不可用或遇到非法编码时，trace 仍输出原始指令，避免调试路径影响执行语义。
  snprintf(str, size, ".word\t0x%0*" PRIx64 " @ 0x%08" PRIx64, nbyte * 2, raw, pc);
}

static void *open_capstone(void) {
  const char *nemu_home = getenv("NEMU_HOME");
  if (nemu_home != NULL && nemu_home[0] != '\0') {
    char path[4096];
    snprintf(path, sizeof(path), "%s/tools/capstone/repo/libcapstone.so.5", nemu_home);
    void *dl_handle = dlopen(path, RTLD_LAZY);
    if (dl_handle != NULL) return dl_handle;
  }

  // 保留从 nemu/ 目录直接启动时的旧相对路径行为。
  return dlopen("tools/capstone/repo/libcapstone.so.5", RTLD_LAZY);
}

void init_disasm() {
  void *dl_handle = open_capstone();
  if (dl_handle == NULL) {
    Log("failed to load capstone: %s", dlerror());
    disasm_ready = false;
    return;
  }

  cs_err (*cs_open_dl)(cs_arch arch, cs_mode mode, csh *handle) = NULL;
  cs_open_dl = dlsym(dl_handle, "cs_open");

  cs_disasm_dl = dlsym(dl_handle, "cs_disasm");

  cs_free_dl = dlsym(dl_handle, "cs_free");
  if (cs_open_dl == NULL || cs_disasm_dl == NULL || cs_free_dl == NULL) {
    Log("failed to resolve capstone symbols: %s", dlerror());
    disasm_ready = false;
    return;
  }

  cs_arch arch = MUXDEF(CONFIG_ISA_x86,      CS_ARCH_X86,
                   MUXDEF(CONFIG_ISA_mips32, CS_ARCH_MIPS,
                   MUXDEF(CONFIG_ISA_riscv,  CS_ARCH_RISCV,
                   MUXDEF(CONFIG_ISA_loongarch32r,  CS_ARCH_LOONGARCH, -1))));
  cs_mode mode = MUXDEF(CONFIG_ISA_x86,      CS_MODE_32,
                   MUXDEF(CONFIG_ISA_mips32, CS_MODE_MIPS32,
                   MUXDEF(CONFIG_ISA_riscv,  MUXDEF(CONFIG_ISA64, CS_MODE_RISCV64, CS_MODE_RISCV32),
                   MUXDEF(CONFIG_ISA_loongarch32r,  CS_MODE_LOONGARCH32, -1))));
#if defined(CONFIG_ISA_riscv) && defined(CONFIG_RISCV_EXT_C)
  // 反汇编模式和真实取指配置保持一致；未开启 C 时不把 16 位编码误当成合法指令显示。
  mode |= CS_MODE_RISCVC;
#endif
	int ret = cs_open_dl(arch, mode, &handle);
  if (ret != CS_ERR_OK) {
    Log("failed to initialize capstone, ret=%d", ret);
    disasm_ready = false;
    return;
  }

#ifdef CONFIG_ISA_x86
  cs_err (*cs_option_dl)(csh handle, cs_opt_type type, size_t value) = NULL;
  cs_option_dl = dlsym(dl_handle, "cs_option");
  if (cs_option_dl == NULL) {
    Log("failed to resolve capstone option symbol: %s", dlerror());
    disasm_ready = false;
    return;
  }

  ret = cs_option_dl(handle, CS_OPT_SYNTAX, CS_OPT_SYNTAX_ATT);
  if (ret != CS_ERR_OK) {
    Log("failed to configure capstone syntax, ret=%d", ret);
    disasm_ready = false;
    return;
  }
#endif
  disasm_ready = true;
}

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte) {
  if (!disasm_ready || cs_disasm_dl == NULL || cs_free_dl == NULL) {
    format_raw_inst(str, size, pc, code, nbyte);
    return;
  }
	cs_insn *insn;
	size_t count = cs_disasm_dl(handle, code, nbyte, pc, 0, &insn);
  if (count == 0) {
    format_raw_inst(str, size, pc, code, nbyte);
    return;
  }
  assert(count == 1);
  int ret = snprintf(str, size, "%s", insn->mnemonic);
  if (insn->op_str[0] != '\0') {
    snprintf(str + ret, size - ret, "\t%s", insn->op_str);
  }
  cs_free_dl(insn, count);
}

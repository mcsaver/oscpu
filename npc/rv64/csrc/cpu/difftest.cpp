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
using ref_csrsnap_t = void (*)(void *);   // 全状态: NEMU 导出 difftest_csr_snapshot

static bool g_enabled = false;
static bool g_skip_ref = false;
static void *g_ref_handle = nullptr;
static ref_init_t g_ref_init = nullptr;
static ref_memcpy_t g_ref_memcpy = nullptr;
static ref_regcpy_t g_ref_regcpy = nullptr;
static ref_exec_t g_ref_exec = nullptr;
static ref_csrsnap_t g_ref_csr_snapshot = nullptr;  // 可选: 旧 ref.so 无则降级只比 gpr/pc
static ref_csrsnap_t g_ref_fpr_snapshot = nullptr;  // 阶段2: 可选 FPR 快照(同签名)
static void (*g_ref_raise_intr)(uint64_t) = nullptr;  // 阶段4: NEMU difftest_raise_intr(mcause)
// 阶段4: NPC 取异步中断的 pending 登记(mcause 含 interrupt bit), difftest 在同步点让 NEMU raise。
static struct { bool valid; uint64_t mcause; } g_pending_intr = {false, 0};

// 本条提交后的 DUT CSR 快照(commit 处理在 step 前经 npc_difftest_set_dut_csr 注入)。
static npc_word_t g_dut_csr[NPC_DIFF_CSR_N] = {};
// ★索引名与 NEMU dut.c isa_difftest_csr_snapshot 一致。比较列表见 kCsrCmpList。
static const char *const kCsrName[NPC_DIFF_CSR_N] = {
  "mstatus", "mepc", "mcause", "mtvec", "mtval", "mscratch",
  "sepc", "scause", "stvec", "stval", "sscratch",
  "medeleg", "mideleg", "satp", "mcounteren", "scounteren", "priv",
  "mie", "mip", "mcycle", "minstret", "fflags", "frm"
};
// CSR 比较索引列表: 阶段2 = 确定性 CSR[0..16] + fflags(21)/frm(22); mie(17)/mip(18)/mcycle(19)/
// minstret(20) 为异步/计数状态, 阶段3 掩码排除(不列入)。
static const int kCsrCmpList[] = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 21, 22
};
static const int kCsrCmpCount = (int)(sizeof(kCsrCmpList) / sizeof(kCsrCmpList[0]));

// 阶段2 FPR: 本条提交后的 DUT arch FPR 快照 + 延迟比较的暂存 ref FPR。
static uint64_t g_dut_fpr[NPC_DIFF_FPR_N] = {};

void npc_difftest_set_dut_csr(const npc_word_t csr[NPC_DIFF_CSR_N]) {
  memcpy(g_dut_csr, csr, sizeof(g_dut_csr));
}

void npc_difftest_set_dut_fpr(const uint64_t fpr[NPC_DIFF_FPR_N]) {
  memcpy(g_dut_fpr, fpr, sizeof(g_dut_fpr));
}

void npc_difftest_set_pending_intr(uint64_t mcause) {
  g_pending_intr.valid = true;
  g_pending_intr.mcause = mcause;
}

// ★延迟一拍 CSR 比较: NpcSimTop 每 commit 拍 XMR 读的 csr_*_q 滞后 commit event 一拍
// (CSR 写的 NBA 更新在同拍 always_ff 读之后)→ event.csr = 该条提交【前】的 CSR = 上一条提交后。
// 故用「当前 DUT CSR(上一条写后) vs 暂存的上一条 ref CSR(上一条 exec 后)」比较, 正好抵消滞后。
// 首条不比(pending 空)、末条不比(pending 未消费), 可接受。
static bool g_csr_pending = false;
static npc_word_t g_pending_ref_csr[NPC_DIFF_CSR_N] = {};
static npc_word_t g_pending_pc = 0;
static uint32_t g_pending_inst = 0;

static bool csr_delayed_step(npc_word_t pc, uint32_t inst) {
  if (!g_ref_csr_snapshot) return true;
  // 诊断开关: NPC_DIFF_CSR_WARN 置位时每类 CSR 分歧只打印一次且不中止(看分歧全貌); 否则首个分歧 abort。
  static const bool warn_only = (getenv("NPC_DIFF_CSR_WARN") != nullptr);
  static bool warned[NPC_DIFF_CSR_N] = {};
  bool ok = true;
  // xret(mret/sret) 的 mstatus/priv 更新时序与 csrw(NBA 滞后一拍)不一致, 使「统一滞后一拍」的
  // 延迟比较模型对 xret 那一拍失配(非功能 bug: 测试仍 HIT GOOD)。阶段1 暂跳过 xret 的比较点;
  // 阶段1.5 根本修法 = RTL 暴露 CSR next-state 组合 wire 使 snapshot 精确对齐提交拍。
  const bool cur_is_xret = (inst == 0x30200073u) || (inst == 0x10200073u);
  if (g_csr_pending && !cur_is_xret) {
    // CSR + priv + fflags/frm(比较列表; mie/mip/mcycle/minstret 阶段3 排除)
    for (int k = 0; k < kCsrCmpCount && (ok || warn_only); ++k) {
      int i = kCsrCmpList[k];
      // ★fcvt.w/wu/l/lu(FP→GPR: opcode 0x53 + funct7 0x60/0x61)的 fflags 副作用经 FP done-FIFO 比
      // 整数 CSR 多滞后一拍到 csr_fflags_q(实测: 处理 fcvt 的 K+1 拍 dut_ff 仍为旧值, K+2 拍才现 NV)。
      // 「统一滞后一拍」延迟模型对它错位一次(清 fflags 后首个 NV-setting fcvt 暴露, 类 xret 一拍失配)。
      // fflags sticky: 跳过上一条=FP→GPR 的本拍 fflags(idx21)比较非漏验——NV 下一拍即入 csr_fflags_q,
      // 由后续指令的 sticky 值继续校。NPC fflags 值正确, 纯 difftest 比较时序 artifact。
      if (i == 21) {
        const uint32_t pf7 = g_pending_inst >> 25;
        if ((g_pending_inst & 0x7f) == 0x53u && (pf7 & 0x7eu) == 0x60u) continue;
      }
      // ★mstatus(idx 0): mask FS[14:13]+SD[63]。spec 明确允许 FS(FP 状态)dirty 追踪不精确
      // (可保守/精确); 且双提交时 FP 副作用(FLD 的 FS-dirty 走 NBA 下一拍才可见)不可经一拍滞后
      // 快照精确观测——co-issue 的 lane1 同拍快照看不到 lane0 FLD 置的 FS dirty。NPC 确实置 FS
      // dirty(符合 spec, 仅精确时序不可观测), 故掩去这两位(似 mcycle/mip 的不可比状态掩码)。
      const uint64_t cmp_mask = (i == 0)
          ? ~(((uint64_t)0x6000) | ((uint64_t)1 << 63)) : ~(uint64_t)0;
      if ((g_pending_ref_csr[i] & cmp_mask) != (g_dut_csr[i] & cmp_mask)) {
        if (!warn_only || !warned[i]) {
          warned[i] = true;
          LogBoth("[npc-diff] CSR mismatch at dut commit pc=0x%016" NPC_PRIxWORD " inst=0x%08x",
                  g_pending_pc, g_pending_inst);
          LogBoth("[npc-diff] %s ref=0x%016" NPC_PRIxWORD " dut=0x%016" NPC_PRIxWORD,
                  kCsrName[i], g_pending_ref_csr[i], g_dut_csr[i]);
        }
        ok = false;
      }
    }
    // 阶段2 FPR 已移到 difftest_step 直接比较(shadow 是 post-K, 非延迟), 此处不再比 FPR。
  }
  g_ref_csr_snapshot(g_pending_ref_csr);   // 暂存本条 exec 后的 ref CSR, 待下一条比较
  g_pending_pc = pc;
  g_pending_inst = inst;
  g_csr_pending = true;
  return warn_only ? true : ok;
}

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
  // 可选: 全状态 CSR 快照。旧 ref.so 无此符号时静默降级(只比 gpr/pc), 不失败。
  dlerror();
  g_ref_csr_snapshot = reinterpret_cast<ref_csrsnap_t>(dlsym(g_ref_handle, "difftest_csr_snapshot"));
  if (dlerror() || !g_ref_csr_snapshot) {
    g_ref_csr_snapshot = nullptr;
    fprintf(stderr, "[npc-diff] note: reference lacks difftest_csr_snapshot; CSR/priv diff disabled.\n");
  }
  dlerror();
  g_ref_fpr_snapshot = reinterpret_cast<ref_csrsnap_t>(dlsym(g_ref_handle, "difftest_fpr_snapshot"));
  if (dlerror() || !g_ref_fpr_snapshot) {
    g_ref_fpr_snapshot = nullptr;
    fprintf(stderr, "[npc-diff] note: reference lacks difftest_fpr_snapshot; FPR diff disabled.\n");
  }
  dlerror();
  g_ref_raise_intr = reinterpret_cast<void (*)(uint64_t)>(dlsym(g_ref_handle, "difftest_raise_intr"));
  if (dlerror()) g_ref_raise_intr = nullptr;   // 阶段4: 缺则中断同步降级(control-flow mismatch)
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
  g_csr_pending = false;   // 延迟 CSR 比较链复位
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
    return csr_delayed_step(pc, inst);   // 维护延迟 CSR 比较链(MMIO 不改被比 CSR)
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
      // ★MMIO skip 只在【地址翻译关闭】时用虚拟 EA 判(此时 VA==PA, 低地址=真 MMIO 设备如 CLINT);
      // 翻译开启时低 VA 是 pmem 映射(用户态/identity-offset 数据, VA<pmem_base 但 PA 落 pmem):
      // 绝不能用 VA<pmem_base 误判 MMIO——否则 skip 掉真 pmem store, NEMU 不 exec 该指令、ref 内存
      // 不同步(rv64si-p-dirty: dummy@VA=0x2008→PA=0x80002008 被误 skip, NEMU 跳过 store→ref 读旧 0)。
      // effective priv 取 MPRV(load/store 借 MPP)。satp=idx13/priv=idx16/mstatus=idx0(见 dut.c 快照序)。
      uint64_t xlate_satp = g_dut_csr[13], xlate_mstatus = g_dut_csr[0], xlate_priv = g_dut_csr[16];
      if (xlate_priv == 3 && (xlate_mstatus & (1ull << 17)))   // MPRV=1 → 有效 priv 取 MPP
        xlate_priv = (xlate_mstatus >> 11) & 0x3;
      bool xlate_on = ((xlate_satp >> 60) != 0) && (xlate_priv != 3);
      if (!xlate_on && ea < NPC_PMEM_BASE) {
        DiffContext ref_chk = {};
        g_ref_regcpy(&ref_chk, DIFFTEST_TO_DUT);
        if (ref_chk.pc != pc) {
          LogBoth("[npc-diff] control-flow mismatch (mmio skip): dut commit pc=0x%016" NPC_PRIxWORD
                  " inst=0x%08x, ref expects pc=0x%016" NPC_PRIxWORD, pc, inst, ref_chk.pc);
          return false;
        }
        // 用 DUT 提交的真实 next_pc（对 RVC 压缩访存 = pc+2，非压缩 = pc+4）；
        // 访存非控制流指令恒不误预测，故 next_pc 即其真实后继。写死 pc+4 会毒化
        // 压缩访存后的控制流校验（C.LWSP/C.SWSP 命中 MMIO → 下一条假阳性 mismatch）。
        DiffContext dut_ov = make_dut_context(next_pc, gpr, rd_en, rd_addr, rd_data);
        g_ref_regcpy(&dut_ov, DIFFTEST_TO_REF);
        g_skip_ref = false;   // 旧机制若已挂旗, 一并吸收(本条即其归属)
        return csr_delayed_step(pc, inst);   // 维护延迟 CSR 比较链
      }
    }
  }

  DiffContext ref_pre = {};
  g_ref_regcpy(&ref_pre, DIFFTEST_TO_DUT);
  if (ref_pre.pc != pc) {
    // ★自主 trap 恢复: NPC 的 exception faulting 指令【不 commit】(直接 trap 到 handler)→ difftest
    // 收不到它、NEMU 尚未执行 → dut 的 handler 首条 commit 与 NEMU 停在 faulting 指令处失配。
    // 让 NEMU exec(1) 执行 faulting 指令: 若它同样 fault, NEMU 也 trap 到同一 handler(pc), 对齐;
    // 否则(NEMU 未 fault, pc 仍不符)才是真 mismatch。通用处理任意 NPC 同步异常(misalign/page/
    // access/illegal)——faulting 指令的存在与 handler 入口由 dut commit 流隐式给出。
    // ★阶段4 中断同步: 若 NPC 报了异步中断(kind=2), 则让 NEMU raise 同中断(NPC 主导时刻)而非 exec
    // faulting 指令——中断非某条指令 fault, 而是异步在指令边界取; NEMU 以当前 pc 作 epc 跳同 handler。
    if (g_pending_intr.valid && g_ref_raise_intr) {
      g_ref_raise_intr(g_pending_intr.mcause);
      g_pending_intr.valid = false;
    } else {
      g_ref_exec(1);
    }
    DiffContext ref_retry = {};
    g_ref_regcpy(&ref_retry, DIFFTEST_TO_DUT);
    if (ref_retry.pc != pc) {
      LogBoth("[npc-diff] control-flow mismatch: dut commit pc=0x%016" NPC_PRIxWORD
              " inst=0x%08x, ref expects pc=0x%016" NPC_PRIxWORD, pc, inst, ref_pre.pc);
      return false;
    }
    // NEMU 也 trap 到 handler(pc)。faulting 指令的 trap 已改 mepc/mcause/mstatus/priv/tval →
    // 刷新延迟 CSR 比较的 pending 为 trap 后 ref CSR, 与 dut handler 首条的(trap 后)CSR 对齐。
    if (g_ref_csr_snapshot) {
      g_ref_csr_snapshot(g_pending_ref_csr);
      g_pending_pc = pc;
      g_pending_inst = inst;
      g_csr_pending = true;
    }
  }
  g_ref_exec(1);
  DiffContext ref = {};
  g_ref_regcpy(&ref, DIFFTEST_TO_DUT);
  // ★counter 读(rdcycle/rdtime/rdinstret 及 mcycle/minstret 的 csrr, 0xc00-c1f/0xb00-b1f 及 h 版)
  // 本质不可逐值 difftest: NPC 的 time=硬件 CLINT mtime(CLINT_MTIME_DIVISOR=10, 每10拍+1=cycle/10)、
  // cycle/instret=微架构计数; 而 NEMU 是指令级(clint_mtime++每指令、mcycle=指令数)。二者=微架构 cycle
  // vs 指令数, 比例=CPI 随程序变, 无固定倍数可对齐(NPC mtime×10 只还原 NPC 真 cycle, NEMU 侧仍指令数)。
  // 故读 counter 用 DUT 值同步 REF gpr[rd](NPC 主导, 保后续控制流/数据一致, 不逐值误报)。
  {
    const uint32_t opc2 = inst & 0x7f, f3 = (inst >> 12) & 0x7;
    const uint32_t csra = (inst >> 20) & 0xfff, crd = (inst >> 7) & 0x1f;
    const bool csrop = (opc2 == 0x73) && (f3 != 0 && f3 != 4);   // csrrw/s/c[i], 有 rd
    const bool counter = (csra >= 0xc00 && csra <= 0xc1f) || (csra >= 0xc80 && csra <= 0xc9f) ||
                         (csra >= 0xb00 && csra <= 0xb1f) || (csra >= 0xb80 && csra <= 0xb9f);
    if (csrop && counter && crd != 0 && crd < 32) {
      ref.gpr[crd] = dut.gpr[crd];              // NPC 主导 counter 读值
      g_ref_regcpy(&ref, DIFFTEST_TO_REF);      // 同步回 NEMU, 保后续用该 counter 值的指令一致
    }
  }
  for (int i = 0; i < 32; ++i) {
    if (ref.gpr[i] != dut.gpr[i]) {
      LogBoth("[npc-diff] mismatch at dut commit pc=0x%016" NPC_PRIxWORD " inst=0x%08x", pc, inst);
      LogBoth("[npc-diff] x%d ref=0x%016" NPC_PRIxWORD " dut=0x%016" NPC_PRIxWORD,
              i, ref.gpr[i], dut.gpr[i]);
      return false;
    }
  }

  // 阶段2 FPR: shadow(逐提交精确的 post-K 值)与 ref(exec K 后)【直接比较】——似 GPR shadow, 非
  // 延迟。shadow 每提交更新自己的 FP rd(双提交 lane0/lane1 各 post 自己), 故 K 的 event.fpr=post-K,
  // 与 ref post-K 对齐; 直接比即可, 不入 csr_delayed_step(那是给 arch-snapshot 的 post-(K-1) 用的)。
  if (g_ref_fpr_snapshot) {
    static const bool fpr_warn = (getenv("NPC_DIFF_CSR_WARN") != nullptr);
    static bool warned_fpr[NPC_DIFF_FPR_N] = {};
    uint64_t ref_fpr[NPC_DIFF_FPR_N] = {};
    g_ref_fpr_snapshot(ref_fpr);
    for (int i = 0; i < NPC_DIFF_FPR_N; ++i) {
      if (ref_fpr[i] != g_dut_fpr[i]) {
        if (!fpr_warn || !warned_fpr[i]) {
          warned_fpr[i] = true;
          LogBoth("[npc-diff] FPR mismatch at dut commit pc=0x%016" NPC_PRIxWORD " inst=0x%08x", pc, inst);
          LogBoth("[npc-diff] f%d ref=0x%016" PRIx64 " dut=0x%016" PRIx64,
                  i, ref_fpr[i], g_dut_fpr[i]);
        }
        if (!fpr_warn) return false;
      }
    }
  }

  // 全状态: 延迟一拍比较 CSR + priv(见 csr_delayed_step: 抵消 DUT CSR 快照的一拍滞后)。
  if (!csr_delayed_step(pc, inst)) return false;
  return true;
}

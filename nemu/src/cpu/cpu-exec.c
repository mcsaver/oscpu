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

#include <cpu/cpu.h>
#include <cpu/bpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <memory/cache.h>
#include <memory/paddr.h>
#include <memory/vaddr.h>
#include <isa.h>
#include <utils/profile.h>
#include <errno.h>
#include <locale.h>
#include <stdlib.h>
#include <string.h>
#if defined(CONFIG_WATCHPOINT) && !defined(CONFIG_TARGET_AM)
// AM 目标不会编译 sdb/watchpoint 模块，这里同步收紧编译条件，
// 这样即使配置或旧对象文件残留异常，也不会再把监视点符号带进 AM 链接。
#include "../monitor/sdb/watchpoint.h"
#endif
#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
#include "../monitor/gdbstub.h"
#include "../monitor/qmp.h"
#endif

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
//打印指令的最大数
#define MAX_INST_TO_PRINT 10

// 这里把 g_print_step 提前定义到 ITRACE 辅助函数之前。
// 这样改完后，无论是否打开 ITRACE，need_itrace_logbuf() 都能在同一份源码下稳定看到它。
static bool g_print_step = false;

static bool cpu_runtime_env_enabled_default_true(const char *name) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  return !(env != NULL && env[0] != '\0' && strcmp(env, "0") == 0);
#else
  (void)name;
  return true;
#endif
}

#if defined(CONFIG_ISA_riscv) && !defined(CONFIG_TARGET_AM)
static bool cpu_runtime_env_u64(const char *name, uint64_t *value) {
  const char *env = getenv(name);
  if (env == NULL || env[0] == '\0') {
    return false;
  }
  errno = 0;
  char *end = NULL;
  uint64_t parsed = strtoull(env, &end, 0);
  Assert(errno == 0 && end != env && *end == '\0',
      "invalid %s=%s, expect an integer", name, env);
  *value = parsed;
  return true;
}
#endif

#if defined(CONFIG_ISA_riscv)
static bool pc_gpr_trace_is_enabled = false;
static word_t pc_gpr_trace_start = 0;
static word_t pc_gpr_trace_end = 0;
static uint64_t pc_gpr_trace_max = 4096;
static uint64_t pc_gpr_trace_count = 0;
static bool pc_gpr_trace_user_only = true;

__attribute__((constructor))
static void cpu_pc_gpr_trace_config_init(void) {
#ifndef CONFIG_TARGET_AM
  uint64_t start = 0;
  uint64_t end = 0;
  bool has_start = cpu_runtime_env_u64("NEMU_PC_GPR_TRACE_START", &start);
  bool has_end = cpu_runtime_env_u64("NEMU_PC_GPR_TRACE_END", &end);
  const char *trace_env = getenv("NEMU_PC_GPR_TRACE");
  bool requested = trace_env != NULL && trace_env[0] != '\0' &&
    strcmp(trace_env, "0") != 0;
  if (requested || has_start || has_end) {
    Assert(has_start && has_end,
        "NEMU_PC_GPR_TRACE requires START and END");
    Assert(end >= start,
        "NEMU_PC_GPR_TRACE range end must be >= start");
    cpu_runtime_env_u64("NEMU_PC_GPR_TRACE_MAX", &pc_gpr_trace_max);
    pc_gpr_trace_user_only =
      cpu_runtime_env_enabled_default_true("NEMU_PC_GPR_TRACE_USER_ONLY");
    pc_gpr_trace_start = (word_t)start;
    pc_gpr_trace_end = (word_t)end;
    pc_gpr_trace_count = 0;
    pc_gpr_trace_is_enabled = true;
    Log("pc-gpr-trace armed start=" FMT_WORD " end=" FMT_WORD
        " max=%" PRIu64 " user_only=%d",
        pc_gpr_trace_start, pc_gpr_trace_end, pc_gpr_trace_max,
        pc_gpr_trace_user_only ? 1 : 0);
  }
#endif
}

static inline void pc_gpr_trace_after_exec(const Decode *s) {
  if (likely(!pc_gpr_trace_is_enabled)) return;
  if (pc_gpr_trace_max != 0 && pc_gpr_trace_count >= pc_gpr_trace_max) {
    return;
  }
  if (pc_gpr_trace_user_only && cpu.priv != PRIV_U) {
    return;
  }
  if (s->pc < pc_gpr_trace_start || s->pc > pc_gpr_trace_end) {
    return;
  }
  pc_gpr_trace_count++;
  Log("pc-gpr-trace count=%" PRIu64 " pc=" FMT_WORD
      " inst=0x%08x snpc=" FMT_WORD " dnpc=" FMT_WORD
      " priv=%u satp=" FMT_WORD
      " ra=" FMT_WORD " sp=" FMT_WORD " t0=" FMT_WORD
      " a0=" FMT_WORD " a1=" FMT_WORD " a3=" FMT_WORD
      " a5=" FMT_WORD " s2=" FMT_WORD " s3=" FMT_WORD
      " s7=" FMT_WORD " s10=" FMT_WORD
#if defined(CONFIG_RISCV_EXT_D)
      " ft0_raw=0x%016" PRIx64 " ft0=%a"
      " ft1_raw=0x%016" PRIx64 " ft1=%a"
      " ft2_raw=0x%016" PRIx64 " ft2=%a"
      " ft3_raw=0x%016" PRIx64 " ft3=%a"
      " ft4_raw=0x%016" PRIx64 " ft4=%a"
      " ft5_raw=0x%016" PRIx64 " ft5=%a"
      " fa0_raw=0x%016" PRIx64 " fa0=%a"
      " fa2_raw=0x%016" PRIx64 " fa2=%a"
      " fa3_raw=0x%016" PRIx64 " fa3=%a"
      " fa4_raw=0x%016" PRIx64 " fa4=%a"
      " fa5_raw=0x%016" PRIx64 " fa5=%a"
#endif
      ,
      pc_gpr_trace_count, s->pc, s->isa.inst, s->snpc, s->dnpc,
      cpu.priv, cpu.csr.satp,
      cpu.gpr[1], cpu.gpr[2], cpu.gpr[5],
      cpu.gpr[10], cpu.gpr[11], cpu.gpr[13],
      cpu.gpr[15], cpu.gpr[18], cpu.gpr[19],
      cpu.gpr[23], cpu.gpr[26]
#if defined(CONFIG_RISCV_EXT_D)
      , cpu.fpr[0], (union { uint64_t u; double d; }){ .u = cpu.fpr[0] }.d
      , cpu.fpr[1], (union { uint64_t u; double d; }){ .u = cpu.fpr[1] }.d
      , cpu.fpr[2], (union { uint64_t u; double d; }){ .u = cpu.fpr[2] }.d
      , cpu.fpr[3], (union { uint64_t u; double d; }){ .u = cpu.fpr[3] }.d
      , cpu.fpr[4], (union { uint64_t u; double d; }){ .u = cpu.fpr[4] }.d
      , cpu.fpr[5], (union { uint64_t u; double d; }){ .u = cpu.fpr[5] }.d
      , cpu.fpr[10], (union { uint64_t u; double d; }){ .u = cpu.fpr[10] }.d
      , cpu.fpr[12], (union { uint64_t u; double d; }){ .u = cpu.fpr[12] }.d
      , cpu.fpr[13], (union { uint64_t u; double d; }){ .u = cpu.fpr[13] }.d
      , cpu.fpr[14], (union { uint64_t u; double d; }){ .u = cpu.fpr[14] }.d
      , cpu.fpr[15], (union { uint64_t u; double d; }){ .u = cpu.fpr[15] }.d
#endif
      );
}
#else
static inline void pc_gpr_trace_after_exec(const Decode *s) {
  (void)s;
}
#endif

bool cpu_interpreter_basic_block_runtime_enabled(void) {
  static int enabled = -1;
  if (enabled < 0) {
    enabled = cpu_runtime_env_enabled_default_true("NEMU_INTERPRETER_BASIC_BLOCK") ? 1 : 0;
  }
  return enabled != 0;
}

uint64_t cpu_interpreter_tb_max_inst_runtime(void) {
#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
  enum { runtime_cap = 4096 };
  static int initialized = 0;
  static uint64_t max_inst = CONFIG_INTERPRETER_TB_MAX_INST;

  if (!initialized) {
#ifndef CONFIG_TARGET_AM
    const char *env = getenv("NEMU_INTERPRETER_TB_MAX_INST");
    if (env != NULL && env[0] != '\0') {
      char *end = NULL;
      unsigned long long parsed = strtoull(env, &end, 0);
      if (end != env && *end == '\0' && parsed > 0) {
        max_inst = parsed > runtime_cap ? runtime_cap : parsed;
      }
    }
#endif
    initialized = 1;
  }
  return max_inst;
#else
  return 0;
#endif
}

bool cpu_interpreter_tb_amo_continue_runtime_enabled(void) {
#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
  static int enabled = -1;
  if (enabled < 0) {
    enabled = cpu_runtime_env_enabled_default_true("NEMU_INTERPRETER_TB_AMO_CONTINUE") ? 1 : 0;
  }
  return enabled != 0;
#else
  return false;
#endif
}

#ifdef CONFIG_ITRACE
#define IRINGBUF_MAX 16

static char iringbuf[IRINGBUF_MAX][128];
static int ir_head = 0;//写入下一个的位置
static int ir_count = 0;//当前记录的条数

void iringbuf_record(const char *logbuf) {
  strncpy(iringbuf[ir_head], logbuf, 127);
  iringbuf[ir_head][127] = '\0';
  ir_head = (ir_head + 1) % IRINGBUF_MAX;
  if (ir_count < IRINGBUF_MAX) ir_count++;
}

void iringbuf_dump() {
  int n     = ir_count;
  int start = (ir_head - n + IRINGBUF_MAX) % IRINGBUF_MAX;
  printf("Recent instructions (iringbuf, last %d):\n", n);
  for (int i = 0; i < n; i++) {
    int idx = (start + i) % IRINGBUF_MAX;
    // 最后一条（即出错指令）用 --> 标记
    if (i == n - 1)
      printf("--> %s\n", iringbuf[idx]);
    else
      printf("    %s\n", iringbuf[idx]);
  }
}

#ifndef CONFIG_TARGET_AM
// 这里先判断“这条指令的 logbuf 会不会真的被用到”，避免普通长跑时白做反汇编。
// 这样改完后，保留 ITRACE 编译开关也不会默认在每条指令上都支付日志构造成本。
static inline bool need_itrace_logbuf() {
  extern bool log_enable();
  return g_print_step || (log_enable() && NEMU_ITRACE_COND);
}
#else
static inline bool need_itrace_logbuf() {
  return g_print_step;
}
#endif

// 真正需要 trace 时再组装 logbuf，把“是否追踪”和“如何生成追踪文本”分离开。
// 这样既保留出错时可读的指令日志，又把无效的预取指和反汇编开销移出热路径。
static void build_itrace_logbuf(Decode *s) {
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst;
#ifdef CONFIG_ISA_x86
  for (i = 0; i < ilen; i ++) {
#else
  for (i = ilen - 1; i >= 0; i --) {
#endif
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst, ilen);
  iringbuf_record(s->logbuf);
}

#endif

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us

void device_update();
void device_update_after_inst(uint64_t retired);
void virtio_blk_statistic();
void virtio_net_statistic();

#if defined(CONFIG_RISCV_PROGRESS_DEBUG_LOG) && defined(CONFIG_ISA_riscv)
static inline void riscv_progress_debug_log(void) {
  if (CONFIG_RISCV_PROGRESS_DEBUG_INTERVAL <= 0) return;
  if (g_nr_guest_inst % CONFIG_RISCV_PROGRESS_DEBUG_INTERVAL != 0) return;
  Log("[Progress] inst=%" PRIu64 " pc=" FMT_WORD " priv=%u"
      " satp=" FMT_WORD " mstatus=" FMT_WORD
      " sepc=" FMT_WORD " scause=" FMT_WORD " stval=" FMT_WORD
      " mepc=" FMT_WORD " mcause=" FMT_WORD " mtval=" FMT_WORD
      " mie=" FMT_WORD " mip=" FMT_WORD,
      g_nr_guest_inst, cpu.pc, cpu.priv,
      cpu.csr.satp, cpu.csr.mstatus,
      cpu.csr.sepc, cpu.csr.scause, cpu.csr.stval,
      cpu.csr.mepc, cpu.csr.mcause, cpu.csr.mtval,
      cpu.csr.mie, cpu.csr.mip);
}
#else
static inline void riscv_progress_debug_log(void) {}
#endif

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {

//条件日志记录
//Itrace是Instruction Trace指令追踪的缩写。
//内部 trace 条件来自 nemu-config.h；日志范围统一交给 TRACE_START/TRACE_END 控制。
//数据：_this->logbuf存储了刚才执行的那条指令的反汇编字符串，也就是译码并且打印
#ifdef CONFIG_ITRACE
  if (NEMU_ITRACE_COND) { log_write("%s\n", _this->logbuf); }
#endif
//屏幕输出
//功能：在屏幕上打印当前执行的指令
//触发场景：如果执行步数n小于MAX_INST_TO_PRINT,也就是si 的时候打印
//确保只有开启了ITrace功能的时候才打印
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(_this->logbuf)); }
//差分测试
//调用difftest_step函数，将NEMU的cpu状态进行比对，如果两者状态(寄存器值、内存写入等)不一致，NUMU会报错
//_this->pc当前指令的地址
//dnpc:下一条指令的地址(Dynamic NEXT PC)，用于同步REF的执行流
#if defined(CONFIG_DIFFTEST) && !defined(CONFIG_TARGET_SHARE)
  difftest_step(_this->pc, dnpc);
#endif
  #if defined(CONFIG_WATCHPOINT) && !defined(CONFIG_TARGET_AM)
  int state = 0;
  // 没有监视点时直接跳过表达式求值，避免每条指令都白跑一层 compare_assert。
  if (watchpoint_enabled) {
    state = compare_assert();
  }
  //state_stop = 1;
  //state_run = 2;
  
  //执行到ebreak的时候，指令会通过set_nemu_state把nemu_state.state设为NEMU_END
  //但是trace_and_difftest在exec_once后仍会执行，若此时监视点有效
  //会用nemu_state.state = NEMU_STOP覆盖掉NEMU_END，此时可以继续向下执行，就会发生错误
  if (nemu_state.state == NEMU_RUNNING && state)
  {
    nemu_state.state = NEMU_STOP;
  }

  #endif
}

//Struct Decode
//pc
//snpc static next pc: 静态下一条PC通常是PC+4
//dnpc dynamic next pc：动态下一条PC通常是考虑跳转，分支，异常后的下一条
//isa
//IFDEF(CONFIG_ITRACE, char logbuf[128])
static void exec_once(Decode *s, vaddr_t pc) {//此处s是传入是指针,decode s是空的
  s->pc = pc;
  s->snpc = pc;

  isa_exec_once(s);
  // BPU 是透明性能模型，只用真实 dnpc 校验预测结果，不改变解释器提交的 PC。
  IFDEF(CONFIG_BPU, bpu_commit(s->pc, s->isa.inst, s->snpc, s->dnpc));
  cpu.pc = s->dnpc;
}

static inline void profile_opcode_mix_inst(uint32_t inst) {
#ifdef CONFIG_ISA_riscv
#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3u) != 0x3u) {
    nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_RVC, 1);
    return;
  }
#endif
  switch (inst & 0x7fu) {
    case 0x03: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_LOAD, 1); break;
    case 0x07: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_LOAD_FP, 1); break;
    case 0x0f: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_MISC_MEM, 1); break;
    case 0x13: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_OP_IMM, 1); break;
    case 0x1b: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_OP_IMM_32, 1); break;
    case 0x17: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_AUIPC, 1); break;
    case 0x23: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_STORE, 1); break;
    case 0x27: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_STORE_FP, 1); break;
    case 0x2f: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_AMO, 1); break;
    case 0x33: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_OP, 1); break;
    case 0x3b: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_OP_32, 1); break;
    case 0x53: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_FP, 1); break;
    case 0x63: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_BRANCH, 1); break;
    case 0x67: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_JALR, 1); break;
    case 0x6f: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_JAL, 1); break;
    case 0x37: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_LUI, 1); break;
    case 0x73: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_SYSTEM, 1); break;
    default: nemu_profile_count(NEMU_PROFILE_CPU_OPCODE_OTHER, 1); break;
  }
#else
  (void)inst;
#endif
}

static void execute_one(Decode *s) {
  exec_once(s, cpu.pc);//单步执行
  // 可选 opcode mix profile 用来定位真实 Ubuntu 用户态热点；默认关闭，避免扰动常规 profile。
  if (unlikely(nemu_profile_opcode_mix_enabled())) {
    profile_opcode_mix_inst(s->isa.inst);
  }
  g_nr_guest_inst ++;//记录客户指令的计数器
  IFDEF(CONFIG_ISA_riscv, isa_riscv_post_exec());
  pc_gpr_trace_after_exec(s);
  riscv_progress_debug_log();
#ifdef CONFIG_ITRACE
  // 把日志构造延后到执行后，并且仅在真正需要输出时触发，减少常规运行时的额外工作。
  if (need_itrace_logbuf()) {
    build_itrace_logbuf(s);
  }
#endif
  trace_and_difftest(s, cpu.pc);//调用trace_and_difftest进行ltrace(指令追踪)和Difftest(与标准模型如QEMU对比状态)
}

static inline bool debug_breakpoint_stop(void) {
#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
  // GDB Z0/Z1 执行断点按 PC 精确停在待执行指令前，basic-block 也不能越过块内断点。
  if (!gdbstub_fast_enabled()) return false;
  if (gdbstub_breakpoint_hit(cpu.pc)) {
    Log("GDB stub breakpoint hit at pc = " FMT_WORD, cpu.pc);
    nemu_state.state = NEMU_STOP;
    return true;
  }
#endif
  return false;
}

static inline bool debug_async_stop(void) {
#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
  // 运行中的 GDB Ctrl-C 只在 TB 边界轮询，保证 Ubuntu 长跑能被调试器打断，
  // 同时避免每条指令都做阻塞 socket 操作。
  if (!gdbstub_fast_enabled()) return false;
  if (gdbstub_async_stop_requested()) {
    Log("GDB stub async halt at pc = " FMT_WORD, cpu.pc);
    nemu_state.state = NEMU_STOP;
    return true;
  }
#endif
  return false;
}

#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
#define INTERPRETER_TB_MAX_INST CONFIG_INTERPRETER_TB_MAX_INST

#if INTERPRETER_TB_MAX_INST <= 0
#error "CONFIG_INTERPRETER_TB_MAX_INST must be positive"
#endif

typedef enum {
  INTERPRETER_TB_STOP_NONE = 0,
  INTERPRETER_TB_STOP_STATE,
  INTERPRETER_TB_STOP_CONTROL,
  INTERPRETER_TB_STOP_SYSTEM,
  INTERPRETER_TB_STOP_MEMORY_ORDER,
  INTERPRETER_TB_STOP_IO_WRITE,
  INTERPRETER_TB_STOP_STORE_CONSERVATIVE,
  INTERPRETER_TB_STOP_LIMIT,
} InterpreterTbStopReason;

static inline void interpreter_tb_profile_stop(InterpreterTbStopReason reason) {
  switch (reason) {
    case INTERPRETER_TB_STOP_STATE:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_STATE, 1);
      break;
    case INTERPRETER_TB_STOP_CONTROL:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_CONTROL, 1);
      break;
    case INTERPRETER_TB_STOP_SYSTEM:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM, 1);
      break;
    case INTERPRETER_TB_STOP_MEMORY_ORDER:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_MEMORY_ORDER, 1);
      break;
    case INTERPRETER_TB_STOP_IO_WRITE:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_IO_WRITE, 1);
      break;
    case INTERPRETER_TB_STOP_STORE_CONSERVATIVE:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_STORE_CONSERVATIVE, 1);
      break;
    case INTERPRETER_TB_STOP_LIMIT:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_LIMIT, 1);
      break;
    case INTERPRETER_TB_STOP_NONE:
    default:
      break;
  }
}

static inline InterpreterTbStopReason interpreter_tb_compressed_stop_reason(uint32_t inst) {
#ifdef CONFIG_RISCV_EXT_C
  uint32_t op = inst & 0x3u;
  uint32_t funct3 = BITS(inst, 15, 13);

  if (op == 0x0) {
    if (funct3 == 0x5 || funct3 == 0x6 || funct3 == 0x7) {
#ifdef CONFIG_CACHE
      return INTERPRETER_TB_STOP_STORE_CONSERVATIVE;
#else
      return INTERPRETER_TB_STOP_NONE;
#endif
    }
  }
  if (op == 0x1) {
    if (funct3 == 0x5) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JUMP_DIRECT, 1);
      return INTERPRETER_TB_STOP_NONE; // c.j 的目标已写入 dnpc，解释器可继续从目标取指。
    }
    if (funct3 == 0x6 || funct3 == 0x7) {
      return INTERPRETER_TB_STOP_NONE; // c.beqz/c.bnez 在动态 helper 中按 taken/not-taken 计数。
    }
#ifndef CONFIG_ISA64
    if (funct3 == 0x1) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JUMP_DIRECT, 1);
      return INTERPRETER_TB_STOP_NONE; // RV32 c.jal。
    }
#endif
  }
  if (op == 0x2) {
    if (funct3 == 0x4) {
      return INTERPRETER_TB_STOP_NONE; // c.mv/c.add/c.jr/c.jalr 由动态 helper 细分；c.ebreak 仍会停块。
    }
    if (funct3 == 0x5 || funct3 == 0x6 || funct3 == 0x7) {
#ifdef CONFIG_CACHE
      return INTERPRETER_TB_STOP_STORE_CONSERVATIVE;
#else
      return INTERPRETER_TB_STOP_NONE;
#endif
    }
  }
#endif
  return INTERPRETER_TB_STOP_NONE;
}

static inline bool interpreter_tb_compressed_dynamic_stop_reason(
    const Decode *s, uint32_t inst, InterpreterTbStopReason *reason) {
#ifdef CONFIG_RISCV_EXT_C
  uint32_t op = inst & 0x3u;
  uint32_t funct3 = BITS(inst, 15, 13);

  if (op == 0x1) {
    if (funct3 == 0x5) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JUMP_DIRECT, 1);
      *reason = INTERPRETER_TB_STOP_NONE;
      return true;
    }
    if (funct3 == 0x6 || funct3 == 0x7) {
      nemu_profile_count_if(s->dnpc != s->snpc ?
          NEMU_PROFILE_CPU_TB_CONTINUE_BRANCH_TAKEN :
          NEMU_PROFILE_CPU_TB_CONTINUE_BRANCH_NOT_TAKEN, 1);
      *reason = INTERPRETER_TB_STOP_NONE;
      return true;
    }
#ifndef CONFIG_ISA64
    if (funct3 == 0x1) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JUMP_DIRECT, 1);
      *reason = INTERPRETER_TB_STOP_NONE;
      return true;
    }
#endif
  }

  if (op == 0x2 && funct3 == 0x4) {
    uint32_t rd = BITS(inst, 11, 7);
    uint32_t rs2 = BITS(inst, 6, 2);
    bool bit12 = BITS(inst, 12, 12) != 0;
    if (bit12 && rd == 0 && rs2 == 0) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_CONTROL_FALLBACK, 1);
      *reason = INTERPRETER_TB_STOP_CONTROL; // c.ebreak/trap 不是普通可串接控制流。
      return true;
    }
    if (s->dnpc != s->snpc) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JALR, 1);
    } else {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_COMPRESSED_MISC, 1);
    }
    *reason = INTERPRETER_TB_STOP_NONE;
    return true;
  }
#else
  (void)s;
  (void)inst;
#endif
  (void)reason;
  return false;
}

static inline bool interpreter_tb_csr_readonly(uint32_t inst) {
  uint32_t funct3 = BITS(inst, 14, 12);
  uint32_t rs1_or_uimm = BITS(inst, 19, 15);

  switch (funct3) {
    case 0x2: // csrrs rd, csr, x0
    case 0x3: // csrrc rd, csr, x0
    case 0x6: // csrrsi rd, csr, 0
    case 0x7: // csrrci rd, csr, 0
      return rs1_or_uimm == 0;
    default:
      return false;
  }
}

static inline bool interpreter_tb_csr_sstatus_imm_clear_can_continue(const Decode *s, uint32_t inst) {
  enum { csr_sstatus = 0x100u, sstatus_imm_sie = 0x2u };
  uint32_t funct3 = BITS(inst, 14, 12);
  uint32_t csr = BITS(inst, 31, 20);
  uint32_t uimm = BITS(inst, 19, 15);

  // csrrci 的 5-bit 立即数在 sstatus 可写位中只能清 SIE；清位不会暴露新的异步中断。
  if (funct3 != 0x7 || csr != csr_sstatus || uimm == 0) {
    return false;
  }
  if (s->dnpc != s->snpc) {
    return false;
  }
  if ((uimm & sstatus_imm_sie) == 0) {
    return false;
  }

  nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_CSR_SSTATUS_IMM_CLEAR, 1);
  return true;
}

static inline bool interpreter_tb_csr_trap_metadata_can_continue(const Decode *s, uint32_t inst) {
  uint32_t csr = BITS(inst, 31, 20);

  if (s->dnpc != s->snpc) {
    return false;
  }
  // 这些 CSR 只是 trap 元数据寄存器；不改变当前 TB 内的取指、翻译、权限或中断使能。
  switch (csr) {
    case 0x140u: // sscratch
    case 0x141u: // sepc
    case 0x142u: // scause
    case 0x143u: // stval
    case 0x340u: // mscratch
    case 0x341u: // mepc
    case 0x342u: // mcause
    case 0x343u: // mtval
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_CSR_TRAP_METADATA, 1);
      return true;
    default:
      return false;
  }
}

static inline bool interpreter_tb_csr_sstatus_unchanged_can_continue(const Decode *s, uint32_t inst) {
  uint32_t csr = BITS(inst, 31, 20);

  if (csr != 0x100u || s->dnpc != s->snpc) {
    return false;
  }
  if (!isa_riscv_last_sstatus_write_was_unchanged()) {
    return false;
  }

  nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_CSR_SSTATUS_UNCHANGED, 1);
  return true;
}

static inline bool interpreter_tb_csr_sstatus_sie_clear_can_continue(const Decode *s, uint32_t inst) {
  uint32_t csr = BITS(inst, 31, 20);

  if (csr != 0x100u || s->dnpc != s->snpc) {
    return false;
  }
  // 真实写后只把 SIE 从 1 清到 0 才继续；设置 SIE 或改 SUM/FS/MXR/SPP 仍作为 TB 边界。
  if (!isa_riscv_last_sstatus_write_only_cleared_sie()) {
    return false;
  }

  nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_CSR_SSTATUS_SIE_CLEAR, 1);
  return true;
}

static inline void interpreter_tb_profile_amo_detail(uint32_t inst) {
  uint32_t funct5 = BITS(inst, 31, 27);
  switch (funct5) {
    case 0x02: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_AMO_LR, 1); break;
    case 0x03: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_AMO_SC, 1); break;
    case 0x01: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_AMO_SWAP, 1); break;
    case 0x00: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_AMO_ADD, 1); break;
    default: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_AMO_OTHER, 1); break;
  }
}

static inline void interpreter_tb_profile_continue_amo_detail(uint32_t inst) {
  uint32_t funct5 = BITS(inst, 31, 27);
  switch (funct5) {
    case 0x02: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_AMO_LR, 1); break;
    case 0x03: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_AMO_SC, 1); break;
    case 0x01: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_AMO_SWAP, 1); break;
    case 0x00: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_AMO_ADD, 1); break;
    default: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_AMO_OTHER, 1); break;
  }
}

static inline bool interpreter_tb_amo_can_continue(const Decode *s, uint32_t inst) {
  if (!cpu_interpreter_tb_amo_continue_runtime_enabled()) {
    return false;
  }
  if (s->dnpc != s->snpc) {
    return false;
  }
  if (unlikely(paddr_has_device_write())) {
    return false;
  }

  // AMO/LR/SC 已按顺序解释执行；只有真实落在 PMEM 且没有触发设备写时才合并进当前 TB。
  nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_AMO, 1);
  if (unlikely(nemu_profile_stop_detail_enabled())) {
    interpreter_tb_profile_continue_amo_detail(inst);
  }
  return true;
}

static inline void interpreter_tb_profile_sstatus_stop_delta(void) {
  word_t old_status = 0;
  word_t new_status = 0;
  word_t delta = 0;
  if (!isa_riscv_last_sstatus_write_delta(&old_status, &new_status, &delta)) {
    return;
  }

  if (delta & MSTATUS_SIE) {
    nemu_profile_count_if((new_status & MSTATUS_SIE) ?
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_SIE_SET :
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_SIE_CLEAR, 1);
  }
  if (delta & MSTATUS_SUM) {
    nemu_profile_count_if((new_status & MSTATUS_SUM) ?
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_SUM_SET :
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_SUM_CLEAR, 1);
  }
  if (delta & MSTATUS_FS_MASK) {
    switch (new_status & MSTATUS_FS_MASK) {
      case 0:
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_FS_TO_OFF, 1);
        break;
      case (word_t)1 << 13:
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_FS_TO_INITIAL, 1);
        break;
      case (word_t)2 << 13:
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_FS_TO_CLEAN, 1);
        break;
      case MSTATUS_FS_DIRTY:
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_FS_TO_DIRTY, 1);
        break;
    }
  }

  // 这里专门统计“剩余停块”里的单字段形态，用于判断下一轮是否还有安全 CSR 子类可放行。
  if (delta == MSTATUS_SIE) {
    nemu_profile_count_if((new_status & MSTATUS_SIE) ?
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_ONLY_SIE_SET :
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_ONLY_SIE_CLEAR, 1);
  } else if (delta == MSTATUS_SUM) {
    nemu_profile_count_if((new_status & MSTATUS_SUM) ?
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_ONLY_SUM_SET :
        NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_ONLY_SUM_CLEAR, 1);
  } else if ((delta & MSTATUS_FS_MASK) != 0 &&
             (delta & ~MSTATUS_FS_MASK) == 0) {
    nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_ONLY_FS, 1);
  } else if (delta != 0) {
    nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS_DELTA_OTHER_OR_MULTI, 1);
  }
}

static inline void interpreter_tb_profile_system_csr_detail(uint32_t inst) {
  switch (BITS(inst, 14, 12)) {
    case 0x1: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_CSRRW, 1); break;
    case 0x2: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_CSRRS, 1); break;
    case 0x3: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_CSRRC, 1); break;
    case 0x5: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_CSRRWI, 1); break;
    case 0x6: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_CSRRSI, 1); break;
    case 0x7: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_CSRRCI, 1); break;
    default: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OP_OTHER, 1); break;
  }
  uint32_t csr = BITS(inst, 31, 20);
  switch (csr) {
    case 0x100:
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS, 1);
      interpreter_tb_profile_sstatus_stop_delta();
      break;
    case 0x104: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SIE, 1); break;
    case 0x105: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_STVEC, 1); break;
    case 0x140: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSCRATCH, 1); break;
    case 0x141: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SEPC, 1); break;
    case 0x142: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SCAUSE, 1); break;
    case 0x143: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_STVAL, 1); break;
    case 0x144: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SIP, 1); break;
    case 0x180: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SATP, 1); break;
    case 0x300: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MSTATUS, 1); break;
    case 0x302: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MEDELEG, 1); break;
    case 0x303: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MIDELEG, 1); break;
    case 0x304: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MIE, 1); break;
    case 0x305: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MTVEC, 1); break;
    case 0x306: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MCOUNTEREN, 1); break;
    case 0x340: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MSCRATCH, 1); break;
    case 0x341: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MEPC, 1); break;
    case 0x342: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MCAUSE, 1); break;
    case 0x343: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MTVAL, 1); break;
    case 0x344: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MIP, 1); break;
    default: nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OTHER, 1); break;
  }
}

static inline InterpreterTbStopReason interpreter_tb_static_stop_reason(const Decode *s) {
  if (nemu_state.state != NEMU_RUNNING) return INTERPRETER_TB_STOP_STATE;

  uint32_t inst = s->isa.inst;
#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3u) != 0x3u) {
    InterpreterTbStopReason dynamic_reason = INTERPRETER_TB_STOP_NONE;
    if (interpreter_tb_compressed_dynamic_stop_reason(s, inst, &dynamic_reason)) {
      return dynamic_reason;
    }
    if (s->dnpc != s->snpc) {
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_CONTROL_FALLBACK, 1);
      return INTERPRETER_TB_STOP_CONTROL;
    }
    return interpreter_tb_compressed_stop_reason(inst);
  }
#endif

  switch (inst & 0x7fu) {
    case 0x0f: { // fence/fence.i。
      uint32_t funct3 = BITS(inst, 14, 12);
      if (funct3 == 0x0) {
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_FENCE, 1);
        return INTERPRETER_TB_STOP_NONE; // 普通 fence 在顺序解释器中不需要截断 TB。
      }
      if (funct3 == 0x1) {
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_FENCE_I, 1);
      }
      return INTERPRETER_TB_STOP_MEMORY_ORDER;
    }
    case 0x2f: // AMO/LR/SC：PMEM 顺序路径可继续，trap/设备写仍形成 TB 边界。
      if (interpreter_tb_amo_can_continue(s, inst)) {
        return INTERPRETER_TB_STOP_NONE;
      }
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_AMO, 1);
      if (unlikely(nemu_profile_stop_detail_enabled())) {
        interpreter_tb_profile_amo_detail(inst);
      }
      return INTERPRETER_TB_STOP_MEMORY_ORDER;
#ifdef CONFIG_CACHE
    case 0x23: // cache 模型下 store 可延迟写回，先保留旧式保守边界。
    case 0x27: // floating-point store。
      return INTERPRETER_TB_STOP_STORE_CONSERVATIVE;
#endif
    case 0x67: // jalr。
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JALR, 1);
      return INTERPRETER_TB_STOP_NONE;
    case 0x6f: // jal。
      nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_JUMP_DIRECT, 1);
      return INTERPRETER_TB_STOP_NONE;
    case 0x63: // conditional branch。
      nemu_profile_count_if(s->dnpc != s->snpc ?
          NEMU_PROFILE_CPU_TB_CONTINUE_BRANCH_TAKEN :
          NEMU_PROFILE_CPU_TB_CONTINUE_BRANCH_NOT_TAKEN, 1);
      return INTERPRETER_TB_STOP_NONE;
    case 0x73: { // SYSTEM/CSR/WFI/sret/mret/sfence.vma。
      uint32_t funct3 = BITS(inst, 14, 12);
      if (funct3 != 0) {
        if (interpreter_tb_csr_readonly(inst)) {
          nemu_profile_count_if(NEMU_PROFILE_CPU_TB_CONTINUE_CSR_READONLY, 1);
          return INTERPRETER_TB_STOP_NONE;
        }
        if (interpreter_tb_csr_sstatus_imm_clear_can_continue(s, inst)) {
          return INTERPRETER_TB_STOP_NONE;
        }
        if (interpreter_tb_csr_trap_metadata_can_continue(s, inst)) {
          return INTERPRETER_TB_STOP_NONE;
        }
        if (interpreter_tb_csr_sstatus_unchanged_can_continue(s, inst)) {
          return INTERPRETER_TB_STOP_NONE;
        }
        if (interpreter_tb_csr_sstatus_sie_clear_can_continue(s, inst)) {
          return INTERPRETER_TB_STOP_NONE;
        }
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR, 1);
        if (unlikely(nemu_profile_stop_detail_enabled())) {
          interpreter_tb_profile_system_csr_detail(inst);
        }
      } else if (inst == 0x10500073u) {
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_WFI, 1);
      } else if ((inst & 0xfe007fffu) == 0x12000073u) {
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_SFENCE_VMA, 1);
      } else {
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_SYSTEM_OTHER, 1);
      }
      return INTERPRETER_TB_STOP_SYSTEM;
    }
    default:
      if (s->dnpc != s->snpc) {
        nemu_profile_count_if(NEMU_PROFILE_CPU_TB_STOP_CONTROL_FALLBACK, 1);
        return INTERPRETER_TB_STOP_CONTROL;
      }
      return INTERPRETER_TB_STOP_NONE;
  }
}

static uint64_t execute_basic_block(uint64_t n) {
  Decode s;
  uint64_t retired = 0;
  uint64_t tb_max_inst = cpu_interpreter_tb_max_inst_runtime();
  uint64_t limit = n < tb_max_inst ? n : tb_max_inst;
  bool stopped_by_reason = false;

  // 这是 basic block interpreter 的保守第一阶段：仍逐条译码执行，
  // 但把中断查询和设备轮询移到块边界，减少 Ubuntu 长跑主循环开销。
  if (unlikely(paddr_has_device_write())) {
    paddr_take_device_write();
  }
  while (retired < limit) {
    if (debug_breakpoint_stop()) break;
    execute_one(&s);
    retired++;
    // 块内指令(tohost store/ebreak 等)可能 set_nemu_state(NEMU_END) 结束运行:
    // 必须在此立即停,不能等到 TB 静态边界,否则退出后仍会继续执行整块指令。
    if (unlikely(nemu_state.state != NEMU_RUNNING)) break;
    InterpreterTbStopReason reason = interpreter_tb_static_stop_reason(&s);
    if (reason == INTERPRETER_TB_STOP_NONE &&
        unlikely(paddr_has_device_write()) && paddr_take_device_write()) {
      reason = INTERPRETER_TB_STOP_IO_WRITE;
    }
    if (reason != INTERPRETER_TB_STOP_NONE) {
      interpreter_tb_profile_stop(reason);
      stopped_by_reason = true;
      break;
    }
  }
  if (retired == limit && nemu_state.state == NEMU_RUNNING && !stopped_by_reason) {
    interpreter_tb_profile_stop(INTERPRETER_TB_STOP_LIMIT);
  }

  return retired;
}
#endif

static uint64_t execute_one_or_block(uint64_t n) {
#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
  if (!g_print_step && cpu_interpreter_basic_block_runtime_enabled()) {
    uint64_t retired = execute_basic_block(n);
    if (unlikely(nemu_profile_enabled()) && retired > 0) {
      nemu_profile_count(NEMU_PROFILE_CPU_BASIC_BLOCKS, 1);
      nemu_profile_count(NEMU_PROFILE_CPU_BASIC_BLOCK_INST, retired);
    }
    return retired;
  }
#endif

  Decode s;
  if (debug_breakpoint_stop()) return 0;
  execute_one(&s);
  nemu_profile_count_if(NEMU_PROFILE_CPU_SINGLE_STEPS, 1);
  return 1;
}

static void execute(uint64_t n) {
  while (n > 0 && nemu_state.state == NEMU_RUNNING) {
#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
    if (qmp_fast_enabled()) {
      qmp_cpu_pause_point();
      if (nemu_state.state != NEMU_RUNNING) break;
    }
    if (debug_async_stop()) break;
#endif
    if (debug_breakpoint_stop()) break;

    word_t intr = INTR_EMPTY;
#ifdef CONFIG_INTERPRETER_INTR_FAST_FLAG
    if (isa_riscv_intr_pending_fast()) {
      intr = isa_query_intr();
    }
#else
    intr = isa_query_intr();
#endif
    if (intr != INTR_EMPTY) {
      // 异步中断在 TB 边界进入；先重定向到 trap handler，再执行本轮要退休的 handler 指令。
      cpu.pc = isa_raise_intr(intr, cpu.pc);
    }

    uint64_t retired = execute_one_or_block(n);
    if (retired == 0) break;
    n -= retired;

    if (nemu_state.state != NEMU_RUNNING) break;//如果执行过程中状态不再是NEMU_RUNNING(例如遇到了ebreak或断点，跳出循环)
#if defined(CONFIG_DEVICE) && !defined(CONFIG_TARGET_SHARE)
    device_update_after_inst(retired);//如果有设备模拟配置，通过device_update()刷新状态
#endif
  }
}

static void statistic() {
  nemu_profile_dump(g_nr_guest_inst, g_timer);
#ifdef CONFIG_STATISTIC
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
  // 程序结束时统一输出 cache counter，并顺带写回 DCache 脏行，方便结束后检查 PMEM。
  IFDEF(CONFIG_ISA_riscv, isa_riscv_plic_statistic());
  IFDEF(CONFIG_HAS_DISK, virtio_blk_statistic());
  IFDEF(CONFIG_HAS_VIRTIO_NET, virtio_net_statistic());
  IFDEF(CONFIG_CACHE, cache_statistic());
  IFDEF(CONFIG_BPU, bpu_statistic());
#else
  // 性能模式关闭统计输出，但 cache 模型若开启仍必须 flush 脏线，避免功能语义变化。
  IFDEF(CONFIG_HAS_DISK, virtio_blk_statistic());
  IFDEF(CONFIG_HAS_VIRTIO_NET, virtio_net_statistic());
  IFDEF(CONFIG_CACHE, cache_flush_all());
#endif
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n) {
  //判断n是否小于MAX_INST_TO_PRINT，如果是开启g_print_step，这会让后续执行的时候打印每条指令的汇编消息
  //用于si单步调试
  g_print_step = (n < MAX_INST_TO_PRINT);
  //检查运行状态，如果状态时是END,ABORT,QUIT说明程序已经结束，打印信息并且返回
  switch (nemu_state.state) {
    case NEMU_END: case NEMU_ABORT: case NEMU_QUIT:
      printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
      return;
    default: nemu_state.state = NEMU_RUNNING;
  }
  //启动记时，记录当前宿主机时间
  uint64_t timer_start = get_time();

  execute(n);

  uint64_t timer_end = get_time();
  uint64_t elapsed = timer_end - timer_start;
  g_timer += elapsed;
  if (unlikely(nemu_profile_enabled())) {
    nemu_profile_count(NEMU_PROFILE_CPU_EXEC_WINDOWS, 1);
    nemu_profile_count(NEMU_PROFILE_CPU_EXEC_US, elapsed);
  }

#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
  if (nemu_state.state == NEMU_END) {
    qmp_notify_shutdown_event();
  }
#endif

  switch (nemu_state.state) {
    case NEMU_RUNNING:
      nemu_state.state = NEMU_STOP;
      if (n >= MAX_INST_TO_PRINT) {
        Log("nemu: STOP after requested budget at pc = " FMT_WORD, cpu.pc);
        statistic();
      }
      break;

    case NEMU_END: case NEMU_ABORT:
      Log("nemu: %s at pc = " FMT_WORD,
          (nemu_state.state == NEMU_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (nemu_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          nemu_state.halt_pc);
      // fall through
    case NEMU_QUIT: statistic();
  }
}

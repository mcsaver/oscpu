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
#include <memory/vaddr.h>
#include <locale.h>
#if defined(CONFIG_WATCHPOINT) && !defined(CONFIG_TARGET_AM)
// AM 目标不会编译 sdb/watchpoint 模块，这里同步收紧编译条件，
// 这样即使配置或旧对象文件残留异常，也不会再把监视点符号带进 AM 链接。
#include "../monitor/sdb/watchpoint.h"
#endif

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
//打印指令的最大数
#define MAX_INST_TO_PRINT 10

// 这里把 g_print_step 提前定义到 ITRACE 辅助函数之前。
// 这样改完后，无论是否打开 ITRACE/ITRACE_COND，need_itrace_logbuf() 都能在同一份源码下稳定看到它。
static bool g_print_step = false;

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

#if !defined(CONFIG_TARGET_AM) && defined(CONFIG_ITRACE_COND)
// 这里先判断“这条指令的 logbuf 会不会真的被用到”，避免普通长跑时白做反汇编。
// 这样改完后，保留 ITRACE 编译开关也不会默认在每条指令上都支付日志构造成本。
static inline bool need_itrace_logbuf() {
  extern bool log_enable();
  return g_print_step || (log_enable() && ITRACE_COND);
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
//ITRACE_COND 保留为内部条件宏，当前默认 true；日志范围统一交给 TRACE_START/TRACE_END 控制，避免菜单里重复配置。
//数据：_this->logbuf存储了刚才执行的那条指令的反汇编字符串，也就是译码并且打印
  #ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) { log_write("%s\n", _this->logbuf); }
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

static void execute_one(Decode *s) {
  exec_once(s, cpu.pc);//单步执行
  g_nr_guest_inst ++;//记录客户指令的计数器
  IFDEF(CONFIG_ISA_riscv, isa_riscv32_post_exec());
  riscv_progress_debug_log();
#ifdef CONFIG_ITRACE
  // 把日志构造延后到执行后，并且仅在真正需要输出时触发，减少常规运行时的额外工作。
  if (need_itrace_logbuf()) {
    build_itrace_logbuf(s);
  }
#endif
  trace_and_difftest(s, cpu.pc);//调用trace_and_difftest进行ltrace(指令追踪)和Difftest(与标准模型如QEMU对比状态)
}

#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
#define INTERPRETER_TB_MAX_INST 16

static inline bool interpreter_tb_compressed_barrier(uint32_t inst) {
#ifdef CONFIG_RISCV_EXT_C
  uint32_t op = inst & 0x3u;
  uint32_t funct3 = BITS(inst, 15, 13);

  if (op == 0x0) {
    return funct3 == 0x6 || funct3 == 0x7; // c.sw/c.sd 一类压缩 store。
  }
  if (op == 0x1) {
    return funct3 == 0x1 || funct3 == 0x4 || funct3 == 0x5 ||
           funct3 == 0x6 || funct3 == 0x7; // c.j/c.beqz/c.bnez/c.jr/csr-like。
  }
  if (op == 0x2) {
    return funct3 == 0x4 || funct3 == 0x6 || funct3 == 0x7; // c.jr/c.jalr/c.ebreak 与 sp store。
  }
#endif
  return false;
}

static inline bool interpreter_tb_should_stop(const Decode *s) {
  if (nemu_state.state != NEMU_RUNNING) return true;
  if (s->dnpc != s->snpc) return true;

  uint32_t inst = s->isa.inst;
#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3u) != 0x3u) {
    return interpreter_tb_compressed_barrier(inst);
  }
#endif

  switch (inst & 0x7fu) {
    case 0x0f: // fence/fence.i：让自修改代码和外部可见顺序自然形成 TB 边界。
    case 0x23: // store 可能写 CLINT/PLIC/virtio/UART，下一条前应重新观察中断。
    case 0x27: // floating-point store。
    case 0x2f: // AMO/LR/SC 保守收束，避免把同步原语跨块重排。
    case 0x63: // branch，即使未跳转也结束当前 basic block。
    case 0x67: // jalr。
    case 0x6f: // jal。
    case 0x73: // SYSTEM/CSR/WFI/sret/mret/sfence.vma。
      return true;
    default:
      return false;
  }
}

static uint64_t execute_basic_block(uint64_t n) {
  Decode s;
  uint64_t retired = 0;
  uint64_t limit = n < INTERPRETER_TB_MAX_INST ? n : INTERPRETER_TB_MAX_INST;

  // 这是 basic block interpreter 的保守第一阶段：仍逐条译码执行，
  // 但把中断查询和设备轮询移到块边界，减少 Ubuntu 长跑主循环开销。
  while (retired < limit) {
    execute_one(&s);
    retired++;
    if (interpreter_tb_should_stop(&s)) break;
  }

  return retired;
}
#endif

static uint64_t execute_one_or_block(uint64_t n) {
#ifdef CONFIG_INTERPRETER_BASIC_BLOCK
  if (!g_print_step) {
    return execute_basic_block(n);
  }
#endif

  Decode s;
  execute_one(&s);
  return 1;
}

static void execute(uint64_t n) {
  while (n > 0 && nemu_state.state == NEMU_RUNNING) {
    word_t intr = INTR_EMPTY;
#ifdef CONFIG_INTERPRETER_INTR_FAST_FLAG
    if (isa_riscv32_intr_pending_fast()) {
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
#ifdef CONFIG_STATISTIC
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
  // 程序结束时统一输出 cache counter，并顺带写回 DCache 脏行，方便结束后检查 PMEM。
  IFDEF(CONFIG_ISA_riscv, isa_riscv32_plic_statistic());
  IFDEF(CONFIG_CACHE, cache_statistic());
  IFDEF(CONFIG_BPU, bpu_statistic());
#else
  // 性能模式关闭统计输出，但 cache 模型若开启仍必须 flush 脏线，避免功能语义变化。
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
  g_timer += timer_end - timer_start;

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

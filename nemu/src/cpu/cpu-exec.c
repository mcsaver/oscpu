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
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <memory/vaddr.h>
#include <locale.h>

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
//打印指令的最大数
#define MAX_INST_TO_PRINT 10

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

// 用完整反汇编字符串覆盖最近写入的那个槽位（执行成功后调用）
void iringbuf_update_last(const char *logbuf) {
  int last = (ir_head - 1 + IRINGBUF_MAX) % IRINGBUF_MAX;
  strncpy(iringbuf[last], logbuf, 127);
  iringbuf[last][127] = '\0';
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

#endif

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;

void device_update();
int compare_assert();

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {

//条件日志记录
//需要在menuconfig中开启CONFIG_ITRACE_COND
//Itrace是是Instruction Trace指令追踪的缩写
//ITRACE_COND是一个宏，可以定义在何时记录(例如只记录待定地址范围内的指令)，避免日志文件过大
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
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));
  #ifdef CONFIG_WATCHPOINT
  int state = 0;
  state = compare_assert();
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

#ifdef CONFIG_ITRACE
  // 【关键】在执行之前先预读指令字节并记录进 iringbuf。
  // 这样即使 isa_exec_once 遇到非法指令触发 abort()，该指令也已被捕获。
  {
    uint32_t raw = (uint32_t)vaddr_ifetch(pc, 4);
    uint8_t *rb = (uint8_t *)&raw;
    char pre_buf[128];
    char *pp = pre_buf;
    pp += snprintf(pp, sizeof(pre_buf), FMT_WORD ":", pc);
    // RISC-V 按大端序打印（与后续完整 logbuf 格式一致）
    for (int i = 3; i >= 0; i--)
      pp += snprintf(pp, 4, " %02x", rb[i]);
    snprintf(pp, sizeof(pre_buf) - (pp - pre_buf), "  ???");
    iringbuf_record(pre_buf);
  }
#endif

  isa_exec_once(s);
  cpu.pc = s->dnpc;

#ifdef CONFIG_ITRACE
  // isa_exec_once 成功返回后，用带完整反汇编的 logbuf 覆盖刚才的预记录槽位
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
  // 覆盖预记录槽位，将 ??? 替换为真正的反汇编结果
  iringbuf_update_last(s->logbuf);
#endif
}

static void execute(uint64_t n) {
  Decode s;
  for (;n > 0; n --) {
    exec_once(&s, cpu.pc);//单步执行
    g_nr_guest_inst ++;//记录客户指令的计数器
    trace_and_difftest(&s, cpu.pc);//调用trace_and_difftest进行ltrace(指令追踪)和Difftest(与标准模型如QEMU对比状态)
    if (nemu_state.state != NEMU_RUNNING) break;//如果执行过程中状态不再是NEMU_RUNNING(例如遇到了ebreak或断点，跳出循环)
    IFDEF(CONFIG_DEVICE, device_update());//如果有设备模拟配置，通过device_update()刷新状态
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
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
    case NEMU_RUNNING: nemu_state.state = NEMU_STOP; break;

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

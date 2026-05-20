#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
#include <klib-macros.h>

//RISCV中mcause的编码规则：最高位：1表示中断，0表示异常，其余低位表示具体原因号
//mcasuse = 是否中断表示位 | 异常号
#define IRQ_MASK      ((uintptr_t)1 << (__riscv_xlen - 1))
//在Machine mode下的ecall异常号是11
#define CAUSE_ECALL_M 11
//Machine Timer Interrupt，原因号是7
#define CAUSE_MTI     (IRQ_MASK | 7)
//Machine External Interrupt，原因号是11
#define CAUSE_MEI     (IRQ_MASK | 11)

//当底层trap发生的时，先保存成Context，然后调用Context
static Context* (*user_handler)(Event, Context*) = NULL;


//struct Context {
//  uintptr_t gpr[NR_REGS], mcause, mstatus, mepc;
//  void *pdir;//地址空间信息
//};

//typedef struct {
// enum {
//    EVENT_NULL = 0,
//    EVENT_YIELD, EVENT_SYSCALL, EVENT_PAGEFAULT, EVENT_ERROR,
//    EVENT_IRQ_TIMER, EVENT_IRQ_IODEV,
//  } event;
//  uintptr_t cause, ref;
//  //uintptr_t是“能装下指针/地址的无符号整数类型”，常用于保存异常原因码、地址、寄存器值之类和机器位宽相关的数据
  //cause：事件原因/错误码
  //ref：与事件相关的引用值，常常是故障地址、相关对象地址等
//  const char *msg;
  //这是可选的文字说明，主要方便调试或打印日志
//} Event;

//输入：底层现场Context
//输出：语义化事件Event
//调度：把事件交给上层handler
Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    //先构造一个Event ev
    Event ev = {0};
    switch (c->mcause) {
      case CAUSE_ECALL_M:
        ev.event = (c->GPR1 == (uintptr_t) - 1) ? EVENT_YIELD : EVENT_SYSCALL;
        c->mepc += 4; //RISC-V ecall返回必须跳过当前指令
        break;
      case CAUSE_MTI:
        ev.event = EVENT_IRQ_TIMER;//时钟中断
        break;
      case CAUSE_MEI:
        ev.event = EVENT_IRQ_IODEV;//外部设备中断
        break;
      default: 
        ev.event = EVENT_ERROR;//不在处理范围内，就是错误事件
        ev.cause = c->mcause;
        break;
    }

    c = user_handler(ev, c);//把当前现场交给调度器，让调度器决定“下一秒该恢复谁的现场”
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

static void __am_kcontext_on_return() {
  panic("kernel context returns");
}

//cte_init主要做两件事，第一件事就是设置异常入口地址
//第二件事就是注册一个事件处理回调函数，这个回调函数由yield test提供
bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  uintptr_t stack_top = (uintptr_t)kstack.end & ~(uintptr_t)0xf;
  Context *c = (Context *)stack_top - 1;
  memset(c, 0, sizeof(Context));

  // 新建任务第一次被调度时不是从 trap 返回点继续，而是让 mret 直接进入 entry(arg)。
  c->mepc = (uintptr_t)entry;
  // PA 讲义要求 riscv32 初始内核线程上下文的 mstatus 为 0x1800，即 MPP=M。
  c->mstatus = MSTATUS_MPP_M;
  c->gpr[1] = (uintptr_t)__am_kcontext_on_return;
  c->GPR2 = (uintptr_t)arg;
  c->pdir = NULL;
  return c;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

//当前中断是否打开
bool ienabled() {
  uintptr_t mstatus;
  asm volatile("csrr %0, mstatus" : "=r"(mstatus));
  return (mstatus & MSTATUS_MIE) != 0;
}

//设置当前是否允许中断
void iset(bool enable) {
  uintptr_t mask = MSTATUS_MIE;
  if (enable) asm volatile("csrs mstatus, %0" : : "r"(mask));
  else        asm volatile("csrc mstatus, %0" : : "r"(mask));
}

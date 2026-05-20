#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
#include <klib-macros.h>

#define IRQ_MASK      ((uintptr_t)1 << (__riscv_xlen - 1))
#define CAUSE_ECALL_M 11
#define CAUSE_MTI     (IRQ_MASK | 7)
#define CAUSE_MEI     (IRQ_MASK | 11)

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      case CAUSE_ECALL_M:
        ev.event = (c->GPR1 == (uintptr_t)-1) ? EVENT_YIELD : EVENT_SYSCALL;
        c->mepc += 4;
        break;
      case CAUSE_MTI:
        ev.event = EVENT_IRQ_TIMER;
        break;
      case CAUSE_MEI:
        ev.event = EVENT_IRQ_IODEV;
        break;
      default:
        ev.event = EVENT_ERROR;
        ev.cause = c->mcause;
        break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

static void __am_kcontext_on_return() {
  panic("kernel context returns");
}

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

  // 新任务第一次恢复时直接经 mret 跳到 entry(arg)，与 NEMU 平台的 CTE 语义保持一致。
  c->mepc = (uintptr_t)entry;
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

bool ienabled() {
  uintptr_t mstatus;
  asm volatile("csrr %0, mstatus" : "=r"(mstatus));
  return (mstatus & MSTATUS_MIE) != 0;
}

void iset(bool enable) {
  uintptr_t mask = MSTATUS_MIE;
  if (enable) asm volatile("csrs mstatus, %0" : : "r"(mask));
  else        asm volatile("csrc mstatus, %0" : : "r"(mask));
}

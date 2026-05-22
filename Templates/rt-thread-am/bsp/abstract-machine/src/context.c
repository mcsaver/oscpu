#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <rthw.h>
#include <rtthread.h>

#define RT_AM_CONTEXT_STACK_ALIGN 16U

typedef struct {
  void (*entry)(void *);
  void *parameter;
  void (*exit)(void);
} RtAmThreadStart;

static Context **rt_am_switch_from = NULL;
static Context **rt_am_switch_to = NULL;
static bool rt_am_switch_pending = false;

static uintptr_t rt_am_align_down(uintptr_t addr, uintptr_t align) {
  assert((align & (align - 1U)) == 0);
  return addr & ~(align - 1U);
}

static Context *rt_am_dispatch_context(Context *current) {
  if (!rt_am_switch_pending) {
    return current;
  }

  Context **from = rt_am_switch_from;
  Context **to = rt_am_switch_to;

  rt_am_switch_from = NULL;
  rt_am_switch_to = NULL;
  rt_am_switch_pending = false;

  if (from != NULL) {
    *from = current;
  }
  assert(to != NULL && *to != NULL);
  return *to;
}

static void rt_am_request_switch(rt_ubase_t from, rt_ubase_t to, bool in_interrupt) {
  Context **from_sp = (Context **)from;
  Context **to_sp = (Context **)to;

  assert(to_sp != NULL && *to_sp != NULL);

  /*
   * RT-Thread 只保存线程对象里的 sp；在 AM 上这个 sp 就是 Context *。
   * 普通线程切换用 yield 进入 CTE，时钟中断里的切换则延后到当前事件处理尾部统一完成。
   */
  if (!rt_am_switch_pending) {
    rt_am_switch_from = from_sp;
  }
  rt_am_switch_to = to_sp;
  rt_am_switch_pending = true;

  if (!in_interrupt) {
    yield();
  }
}

static void rt_am_thread_trampoline(void *arg) {
  RtAmThreadStart start = *(RtAmThreadStart *)arg;

  start.entry(start.parameter);
  if (start.exit != NULL) {
    start.exit();
  }

  assert(0);
}

static Context* ev_handler(Event e, Context *c) {
  switch (e.event) {
    case EVENT_YIELD:
      break;
    case EVENT_IRQ_TIMER:
      rt_interrupt_enter();
      rt_tick_increase();
      rt_interrupt_leave();
      break;
    case EVENT_IRQ_IODEV:
      rt_interrupt_enter();
      rt_interrupt_leave();
      break;
    default: printf("Unhandled event ID = %d\n", e.event); assert(0);
  }
  return rt_am_dispatch_context(c);
}

void __am_cte_init() {
  bool ok = cte_init(ev_handler);
  assert(ok);
}

#ifdef RT_USING_SMP
void rt_hw_context_switch_to(rt_ubase_t to, struct rt_thread *to_thread) {
  (void)to_thread;
  rt_am_request_switch(0, to, false);
}

void rt_hw_context_switch(rt_ubase_t from, rt_ubase_t to, struct rt_thread *to_thread) {
  (void)to_thread;
  rt_am_request_switch(from, to, false);
}

void rt_hw_context_switch_interrupt(void *context, rt_ubase_t from, rt_ubase_t to, struct rt_thread *to_thread) {
  (void)context;
  (void)to_thread;
  rt_am_request_switch(from, to, true);
}
#else
void rt_hw_context_switch_to(rt_ubase_t to) {
  rt_am_request_switch(0, to, false);
}

void rt_hw_context_switch(rt_ubase_t from, rt_ubase_t to) {
  rt_am_request_switch(from, to, false);
}

void rt_hw_context_switch_interrupt(rt_ubase_t from, rt_ubase_t to, rt_thread_t from_thread, rt_thread_t to_thread) {
  (void)from_thread;
  (void)to_thread;
  rt_am_request_switch(from, to, true);
}
#endif

rt_uint8_t *rt_hw_stack_init(void *tentry, void *parameter, rt_uint8_t *stack_addr, void *texit) {
#ifdef ARCH_CPU_STACK_GROWS_UPWARD
  assert(0);
#else
  /*
   * AM/riscv32 kcontext() 会先把 kstack.end 向下对齐到 16 字节再放置
   * Context。BSP 侧必须按同一边界预留 Context，否则 8 字节对齐的
   * RT-Thread 栈顶会让 kcontext() 再下移 8 字节，覆盖 RtAmThreadStart.exit。
   */
  uintptr_t stack_end =
      rt_am_align_down((uintptr_t)stack_addr + sizeof(rt_ubase_t),
                       RT_AM_CONTEXT_STACK_ALIGN);
  uintptr_t context_base = stack_end - sizeof(Context);
  uintptr_t start_base =
      rt_am_align_down(context_base - sizeof(RtAmThreadStart), RT_ALIGN_SIZE);
  RtAmThreadStart *start = (RtAmThreadStart *)start_base;

  /*
   * 线程入口需要在返回时走 RT-Thread 的 texit，而 AM kcontext 只接受 entry(arg)。
   * 因此在新线程栈上放一个启动描述符，再由 trampoline 衔接两套 ABI。
   */
  start->entry = (void (*)(void *))tentry;
  start->parameter = parameter;
  start->exit = (void (*)(void))texit;

  Area kstack = RANGE((void *)start_base, (void *)stack_end);
  return (rt_uint8_t *)kcontext(kstack, rt_am_thread_trampoline, start);
#endif
}

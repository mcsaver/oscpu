// ace-sim: 内核单元测试 —— 严格覆盖 cur/next(目标1)、event wheel(目标2)、active set(目标3)。
#include <cstdio>
#include "hw/reg.hh"
#include "hw/resource.hh"
#include "sim/active_scheduler.hh"
#include "sim/event_wheel.hh"

using namespace ace;

static int g_fail = 0;
#define CHECK(cond)                                                        \
  do {                                                                     \
    if (!(cond)) { std::printf("  FAIL %s:%d  %s\n", __FILE__, __LINE__, #cond); ++g_fail; } \
  } while (0)

// ---- 目标1:Reg cur/next 分离 ----
static void test_reg() {
  Reg<int> r(10);
  CHECK(r.cur() == 10);
  CHECK(!r.dirty());
  r.write(42);
  CHECK(r.cur() == 10);   // eval 期间 cur 不变
  CHECK(r.dirty());
  r.commit();             // EdgeCommit
  CHECK(r.cur() == 42);
  CHECK(!r.dirty());
  r.commit();             // 幂等
  CHECK(r.cur() == 42);
  // 未写则 commit 不改变
  Reg<int> s(7);
  s.commit();
  CHECK(s.cur() == 7);
}

// ---- 目标2:EventWheel 近/远未来、到期取出、next_event_cycle ----
static void test_wheel() {
  EventWheel w;
  auto mk = [](Cycle when, uint64_t p0) { Event e; e.when = when; e.payload0 = p0; return e; };

  w.schedule(mk(5, 100), 0);
  w.schedule(mk(5, 101), 0);   // 同周期两个事件
  w.schedule(mk(3, 200), 0);
  CHECK(w.size() == 3);
  CHECK(w.next_event_cycle(0) == 3);

  // 周期 3 无到期(在 0 桶?)——从 now=0 取 due(0) 应为空
  CHECK(w.take_due(0).empty());
  auto d3 = w.take_due(3);
  CHECK(d3.size() == 1 && d3[0].payload0 == 200);
  CHECK(w.next_event_cycle(3) == 5);

  auto d5 = w.take_due(5);
  CHECK(d5.size() == 2);
  CHECK(w.empty());
  CHECK(w.next_event_cycle(5) == kInvalidCycle);

  // 远未来:超出窗口 -> 进 far 堆,仍能被 next_event_cycle 报告,并在临近时迁移进桶。
  EventWheel w2;
  Cycle far = EventWheel::kWindow + 100;  // > 窗口
  w2.schedule(mk(far, 999), 0);
  w2.schedule(mk(10, 1), 0);
  CHECK(w2.next_event_cycle(0) == 10);
  CHECK(w2.take_due(10).size() == 1);
  CHECK(w2.next_event_cycle(10) == far);  // 远事件仍可见
  // 迁移:推进到 far 附近,take_due 应能取到它
  auto df = w2.take_due(far);
  CHECK(df.size() == 1 && df[0].payload0 == 999);
  CHECK(w2.empty());
}

// ---- 目标3:ActiveScheduler 去重、drain 清空、eval 内再激活落到下一轮 ----
static void test_scheduler() {
  ActiveScheduler s;
  s.resize(4);
  s.activate(1, Phase::Eval);
  s.activate(1, Phase::Eval);   // 去重
  s.activate(2, Phase::Eval);
  s.activate(3, Phase::Retire);
  CHECK(s.has_activity());

  auto eval_list = s.drain(Phase::Eval);
  CHECK(eval_list.size() == 2);  // 1 和 2(去重后)
  // drain 后 Eval 集空,但 Retire 仍有 -> 仍有 activity
  CHECK(s.has_activity());

  // 模拟"drain 期间再次 activate 同 phase":应进入新集合(下一轮才处理)
  s.activate(2, Phase::Eval);
  auto again = s.drain(Phase::Eval);
  CHECK(again.size() == 1 && again[0] == 2);

  auto ret = s.drain(Phase::Retire);
  CHECK(ret.size() == 1 && ret[0] == 3);
  CHECK(!s.has_activity());

  // 越界 id 被忽略,不崩溃
  s.activate(999, Phase::Eval);
  CHECK(!s.has_activity());
}

// ---- 资源模型:width(同周期)与 II(跨周期)正交,width 在 II>=1 时不得失效(缺陷 #7)----
static void test_fu() {
  FunctionalUnit p(FuDesc{/*lat*/3, /*ii*/1, /*width*/2});
  CHECK(p.can_issue(0)); p.reserve(0);
  CHECK(p.can_issue(0)); p.reserve(0);   // 同周期第 2 槽:width=2 应放行(旧实现会被 II 误杀)
  CHECK(!p.can_issue(0));                // width 用尽
  CHECK(p.can_issue(1)); p.reserve(1);   // 下周期 II=1 放行

  FunctionalUnit d(FuDesc{/*lat*/20, /*ii*/20, /*width*/1});  // 非流水除法器
  CHECK(d.can_issue(5)); d.reserve(5);
  CHECK(!d.can_issue(6));                 // II 未到
  CHECK(!d.can_issue(24));
  CHECK(d.can_issue(25));                 // 5 + 20
  CHECK(d.next_free() == 25);            // 供 CPU 自唤醒的释放周期
}

int main() {
  std::printf("=== ace-sim kernel unit tests ===\n");
  test_reg();
  test_wheel();
  test_scheduler();
  test_fu();
  if (g_fail == 0) std::printf("ALL KERNEL TESTS PASS\n");
  else             std::printf("%d KERNEL CHECKS FAILED\n", g_fail);
  return g_fail == 0 ? 0 : 1;
}

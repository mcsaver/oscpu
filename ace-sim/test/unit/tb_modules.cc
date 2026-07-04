// ace-sim 模块单元测试(镜像 npc testbench/tests/tb_ooo_*)。
// 每个抽出的核心模块喂激励、查端口/状态,独立于整核 fuzz 定位模块级回归。
#include <cstdio>
#include "core/dispatch/Rob.hh"
#include "core/execute/Alu.hh"
#include "core/execute/BranchResolve.hh"
#include "core/execute/MulDiv.hh"
#include "core/frontend/Bpu.hh"
#include "core/issue/IssueQueue.hh"
#include "core/memory/StoreQueue.hh"
#include "core/regfile/PhysRegFile.hh"
#include "core/rename/FreeList.hh"
#include "core/rename/RenameMap.hh"

using namespace ace;

static int g_fail = 0;
#define CHECK(c) do { if(!(c)){ std::printf("  FAIL %s:%d  %s\n",__FILE__,__LINE__,#c); ++g_fail; } } while(0)

// 前递用的极简 MemPort(记录落存)
struct MockMem : MemPort {
  uint64_t last_addr = 0, last_data = 0; int writes = 0;
  bool can_send() const override { return true; }
  void send(const MemReq&) override {}
  void write(uint64_t a, uint64_t d) override { last_addr = a; last_data = d; ++writes; }
};

static void test_Bpu() {
  Bpu b(256);
  CHECK(!b.predict(0));            // 起步弱不跳转(计数器 1 < 2)
  b.update(0, true);              // -> 2
  CHECK(b.predict(0));            // 跳转
  b.update(0, true);             // -> 3(饱和)
  b.update(0, true);
  CHECK(b.predict(0));
  b.update(0, false);            // -> 2
  CHECK(b.predict(0));
  b.update(0, false);            // -> 1
  CHECK(!b.predict(0));
}

static void test_execute() {
  Alu a(FuDesc{1, 1, 2});
  CHECK(a.compute(3, 4, 5) == 12);
  CHECK(a.taken(0, 7, 7) && !a.taken(0, 7, 8));   // EQ
  CHECK(!a.taken(1, 7, 7) && a.taken(1, 7, 8));   // NE
  MulDiv m(FuDesc{3, 1, 2}, FuDesc{20, 20, 1});
  CHECK(m.compute(false, 6, 7) == 42);            // mul
  CHECK(m.compute(true, 20, 4) == 5);             // div
  CHECK(m.compute(true, 9, 0) == 0);              // div-by-0 -> 0
  CHECK(m.latency(true) == 20 && m.latency(false) == 3);
  BranchResolve br;
  auto r1 = br.resolve(10, 99, 11, false);        // 预测 not-taken(next=11),实际 not-taken
  CHECK(!r1.mispredict && r1.redirect_pc == 11);
  auto r2 = br.resolve(10, 99, 11, true);         // 实际 taken(next=99) != 预测 11
  CHECK(r2.mispredict && r2.redirect_pc == 99);
}

static void test_rename_freelist() {
  RenameMap rat(32);
  CHECK(rat.phys(5) == 5);                        // 恒等
  CHECK(rat.remap(5, 40) == 5 && rat.phys(5) == 40);
  auto snap = rat.snapshot();
  rat.remap(5, 41);
  CHECK(rat.phys(5) == 41);
  rat.restore(snap);
  CHECK(rat.phys(5) == 40);                       // 回滚

  FreeList fl(64, 32);
  CHECK(!fl.empty());
  int p = fl.alloc();
  CHECK(p >= 32 && p < 64);
  fl.free(p);
  CHECK(fl.alloc() == p);                         // LIFO
}

static void test_physregfile() {
  PhysRegFile prf(64, 32);
  CHECK(prf.ready(0) && prf.ready(31));           // 初始架构就绪
  prf.set_unready(40);
  CHECK(!prf.ready(40));
  prf.write(40, 0xbeef);
  CHECK(prf.ready(40) && prf.value(40) == 0xbeef);
}

static void test_rob() {
  Rob rob(8);
  FreeList fl(64, 32);
  CHECK(rob.empty());
  int i0 = rob.alloc(); rob.at(i0).dyn_id = 1; rob.at(i0).valid = true; rob.at(i0).done = true;
  int i1 = rob.alloc(); rob.at(i1).dyn_id = 2; rob.at(i1).valid = true; rob.at(i1).phys_dst = 50;
  int i2 = rob.alloc(); rob.at(i2).dyn_id = 3; rob.at(i2).valid = true; rob.at(i2).phys_dst = 51;
  CHECK(rob.count() == 3);
  // squash after i0(dyn 1):回收 i1/i2,归还 phys 50/51
  rob.squash(i0, fl);
  CHECK(rob.count() == 1 && !rob.at(i1).valid && !rob.at(i2).valid);
  CHECK(fl.alloc() == 51 && fl.alloc() == 50);    // 后进先出归还
  // 提交队头
  CHECK(rob.head().dyn_id == 1);
  rob.pop_head();
  CHECK(rob.empty());
}

static void test_issue_queue() {
  PhysRegFile prf(64, 32);
  IssueQueue iq(16, 64);
  prf.set_unready(40);                            // p40 未就绪
  // 依赖 p40 的 ALU:进等待表,不在就绪列表
  iq.insert(/*dyn*/1, FuType::ALU, /*s0*/40, /*s1*/-1, /*s0r*/false, /*s1r*/true,
            /*dst*/41, /*rob*/0, /*imm*/0, /*cond*/0);
  CHECK(iq.ready_list(0).empty());
  prf.write(40, 7);
  iq.wakeup(40);                                  // p40 就绪 -> 唤醒
  CHECK(iq.ready_list(0).size() == 1);
  int slot = iq.ready_list(0).front();
  CHECK(iq.at(slot).dyn_id == 1);
  iq.free_slot(slot);                             // 发射回收
  // 两源皆就绪 -> 直接进就绪列表(LOAD 类=4)
  iq.insert(2, FuType::LOAD, -1, -1, true, true, 42, 1, 0, 0);
  CHECK(iq.ready_list(4).size() == 1);
  // squash 更年轻(dyn>1):dyn 2 被回收
  iq.squash(/*branch_dyn*/1, prf);
  CHECK(iq.ready_list(4).empty());
}

static void test_store_queue() {
  MockMem mem;
  StoreQueue sq(8);
  // 两条同址 store(dyn 1、2),再一个 load(dyn 3):前递最年轻的更老(dyn 2)。STA/STD 分开回填(⑥)。
  sq.alloc(1, 0); sq.alloc(2, 1);
  sq.execute_addr(1, 0x1000); sq.execute_data(1, 111);
  sq.execute_addr(2, 0x1000); sq.execute_data(2, 222);
  bool wait, fwd; uint64_t data;
  sq.disambiguate(3, 0x1000, wait, fwd, data);
  CHECK(!wait && fwd && data == 222);
  // 不同址 -> 走内存(no match)
  sq.disambiguate(3, 0x2000, wait, fwd, data);
  CHECK(!wait && !fwd);
  // 更老 store 地址未知(STA 未执行)-> 等待
  sq.alloc(4, 2);                                  // dyn4 未 execute_addr
  sq.disambiguate(5, 0x9999, wait, fwd, data);
  CHECK(wait);
  // STA/STD 分离(⑥):地址已知但**不同址** -> 不阻塞异址 load(旧模型要等整条 store)
  sq.execute_addr(4, 0x7777);                      // 地址已知,数据(STD)仍未就绪
  sq.disambiguate(5, 0x9999, wait, fwd, data);
  CHECK(!wait && !fwd);                            // 异址:越过 dyn4,走内存
  // 同址但数据未就绪 -> 等 STD
  sq.disambiguate(5, 0x7777, wait, fwd, data);
  CHECK(wait && !fwd);
  sq.execute_data(4, 444);                         // STD 到位 -> 同址可前递
  sq.disambiguate(5, 0x7777, wait, fwd, data);
  CHECK(!wait && fwd && data == 444);
  // 提交 + drain 落存(程序序:dyn1 先)
  sq.commit(1);
  CHECK(sq.drain_one(&mem) && mem.last_addr == 0x1000 && mem.last_data == 111);
  // squash 更年轻(dyn>2):dyn4 被丢弃
  sq.squash(2);
  sq.disambiguate(5, 0x7777, wait, fwd, data);
  CHECK(!wait && !fwd);                            // dyn4 已丢,不再前递/等待
}

int main() {
  std::printf("=== ace-sim module unit tests ===\n");
  test_Bpu();
  test_execute();
  test_rename_freelist();
  test_physregfile();
  test_rob();
  test_issue_queue();
  test_store_queue();
  if (g_fail == 0) std::printf("ALL MODULE TESTS PASS\n");
  else             std::printf("%d MODULE CHECKS FAILED\n", g_fail);
  return g_fail == 0 ? 0 : 1;
}

# 规范：分支方向预测器 OooBranchDirectionPredictor

> 模块：`vsrc/frontend/OooBranchDirectionPredictor.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
预测条件分支方向(taken/not-taken),双发射(2 lookup 口)。gshare(全局历史)+ local(局部历史)混合,
2-bit 饱和计数器。只管方向;目标地址由 BTB/RAS/BTC,跳转由 jump sequencer。

## 2. 结构
```
 gshare:  index = fn(PC, GHR)        → bht_q[idx] (2-bit 饱和)  [BPU_BHT_ENTRIES≈4096]
 local :  lh = local_hist_q[PC_idx]  → local_pht_q[lh] (2-bit) [BPU_LOCAL_*≈4096]
 GHR(ghr_q): 全局分支历史移位寄存器(BHT_INDEX_W 位)
 lookup → pred_taken / predict_strong / bht_idx(供 update 回写)
 update(resolve): 按实际 taken 更新计数器(±1 饱和)、移入 GHR、更新 local history
```
- 每项带 valid 位:未训练(valid=0)时回退**静态预测**(如 backward-taken/forward-not-taken)。
- 2-bit 计数器:`taken = valid ? (counter>=2) : static`;strong = 计数器在两端(00/11)。

## 3. 不变量
- **BP-I1 索引一致**:lookup 产出的 bht_idx 必须随 uop 传到 resolve,update 用同一 idx 回写(否则训错条目)。
- **BP-I2 更新顺序**:GHR/计数器在 resolve(真实方向已知)时更新;投机期不污染(误预测恢复见 BranchSpecTracker)。
- **BP-I3 双发射**:lookup0/lookup1 同拍读同一表,需保证两口读不互相干扰(纯读)。
- 预测错不影响正确性(只影响性能):误预测由后端 resolve→精确 redirect 纠正。

## 4. 关键路径
Vivado OOC:13 逻辑级/logic ~3.4ns(local_hist→local_pht 索引+计数器),非 Fmax 瓶颈
(<DispatchBackend 39 级)。BHT/PHT 4096×2-bit 综合为分布式 RAM/BRAM。

## 5. 验证
- riscv-tests 分支测试(beq/bne/blt/...)、AM branch-resolve-loop(回边循环高可预测);
  方向错只降性能不破坏正确性。BPU 统计需 `CONFIG_NPC_BRANCH_STATS` 构建(默认 perf 关)。

## 6. 变更记录
- 2026-06-28：逆向文档化(gshare+local 混合/2-bit 饱和/双 lookup/静态回退/resolve 更新)。

---
name: b4-dead-silicon-removal
description: rv64核B4死硅物理删除基本完成;9批~5900行已删各cycle-exact中性;3融合活死门证据化保留;方法学+踩坑
metadata: 
  node_type: memory
  type: project
  originSessionId: 0f469065-9395-43a3-bc78-2c6ef32f80ca
---

rv64 OoO 核 **B4：物理删除真相基线 §4 死硅普查表登记的死硅**（编译常量门死、Verilator 已常量折叠 →
删除=源码可维护性重构 + 还宪法"只加不减"债，行为证明不变）。用户 2026-07-04 纠正框定：纯 CPI 优化红利
已收割(-58%,CPI 1.229)，真正未竟的是宪法 north-star 的**架构收尾**（功能拆除已做完，死壳物理未删）。
用户指令"自主连续推进直到完成所有宪法要求"。

**历史执行方法（不可作为当前默认流程）**：当时按死硅族分批证明常量折叠与 cycle 中性，并对触碰 F2
kill/redirect 的批次增加逐指令 DiffTest 和 CoreMark workload；跨模块死信号用**恒等常量 0 tie-off**，
不递归删除仍由活路径消费的 KEEP 端口。

上述串行、patch 搬运、逐族 commit 和全量命令是当时多个改动竞争同一控制面与 build 资源时的 campaign
选择，不是后续任务授权或固定门禁。当前只在真实共享可变资源冲突时串行，按本轮 claim 选择最小充分
验证；cycle-neutral、F2 kill/redirect 与可综合边界等技术不变量仍须如实保留。

**已物理删除 9 批 ~5900 行(各 cycle-exact 中性)**：csrc cache.c/serial.c(15497d2bd) → PRF read4-9全
(e72948c90+3edd53210,真5R2W) → SyntheticLane1Ret(21c7fbe14) → checkpoint影子×5(a7d5c5661) →
前端prefetch/BTC网13模块-2881行(bac43bc8f) → WBU-LOAD+IQ-load-branch-fast(ca18af091) →
dispatch快解析族(3edd53210) → pending_mem链(b2918073a,从未可达) → pending-branch/jump链+BPU旧臂+
fetch-bypass -1873行(10d7729c0,宪法"隐藏串行主干";KEEP stop_pending/system-trap 完整保留)。

**剩余 3 项=「融合活+死」门，穷举证明不可安全物理删除，保留为行为中性死码**（wave6a/6b）：
①DirectBranchResolveGate（resolve六臂恒0中性，但同壳独家产 pred_npc单源/BPU issue-resolve/fetch-fire
活 F2 select 输出→删壳=改写红线）；②SpecTracker（checkpoint_pending 由活分支fire置位、经
ras_direct_update_safe 调制活RAS push/pop→删除改分支预测非中性）；③RecoveryGate pending/spec臂（混活F2
untracked-redirect，已 pending_branch_i=0 tie-off塌缩）。物理清理需 F2/RAS 风险的架构重构（拆 select/resolve），
属独立架构项非"保守删除"。

**坑**：①build/link 抓死硅的跨语言 DPI 消费者(cache.c 经 NpcSimTop DPI，lint过link不过);
②checkpoint 删端口后 6 模块 TB 的 mode=0 场景须同步退休(状态等价:场景=restore还原快照=净no-op);
③当时 worktree base 问题见 [[worktree-agent-base-fresh-gotcha]]（历史工具记录）;④pending 链删除必须区分死 pending owner(删) vs
system/trap+stop_pending(KEEP,验证 0 arbiter 输入被孤立)。真相入口 [[rv64core-audit-baseline]];宪法 §8.3/§9。

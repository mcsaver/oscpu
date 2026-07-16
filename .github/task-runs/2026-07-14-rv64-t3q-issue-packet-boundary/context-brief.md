# T3Q bounded context brief

- 日期：2026-07-14（Asia/Shanghai）
- profile：`npc-dev`
- 生成命令：`python3 scripts/github_index_db.py brief OooIntBackend OooFpBackend OooIntIssueQueue OooFpIssueQueue PipeStageReg 200MHz --profile npc-dev --max-tokens 5000`
- 召回规模：`1209 / 5000` tokens
- 建议验证入口：`scripts/agent-e2e.sh --profile npc-dev`

## 召回约束

1. 遵循根 `AGENTS.md` 与 `.github/AGENTS.md`：跨模块修改先画清调用链，修改后提供功能和 fresh STA 证据。
2. 任务结束更新 project/module memory 与 task-run；收尾运行 strict guard。
3. `npc-dev` profile 覆盖 NPC sim/single/soc/rv64 合同，但不能替代 RV64 全核回归和精确 5ns OpenSTA。

## T3P fresh STA 触发事实

- 网表 SHA-256：`4993c222c5d21e1f2ed82449284fa62ff8b214ebfd703ff3c08d5daa3b160dd6`
- 5ns：WNS `-4.060ns`，TNS `-34537.41ns`，组合环 `0`
- top40 分为两个独立路径族：
  - integer IQ flop → PRF/ALU/backend mux → `OooMulDivUnit` request/state flop，最差约 `-4.065ns`；
  - ROB flop → FP IQ select → FP PRF → `OooFpConvertGate` → `u_exec1_stage`，最差约 `-3.898ns`。

## Root cause 与候选边界

发射选择、物理寄存器堆读取和执行计算仍在同一拍。T3Q 候选是在整数/浮点 IQ 输出和 PRF 读取之间加入 non-fall-through、valid/ready、flush/ROB-age-kill 完整的 issue-packet 寄存边界；IQ 只在边界接收 packet 时出队，下游只消费寄存后的 packet。该边界必须接受 stall、同拍 consume/refill、flush 和 younger-than-kill 的定向测试，不能用透明 ready mux 冒充时序切分。

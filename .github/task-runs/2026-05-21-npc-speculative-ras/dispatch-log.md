# NPC Speculative RAS Dispatch Log

## 节点记录

| node_id | owner_agent | depends_on | inputs | outputs | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- |
| recall | Codex | none | `.github/AGENTS.md`、memory、NPC study、BPU/IF/PipelineControl 源码 | 现有 BPU 更新/flush 边界 | 明确 RAS 仅 EX update 的滞后点 | 回退到只解释方案 |
| design | Codex | recall | `BranchPredictor`、`IfStage.flush_i`、`bpu_update_valid` | 双 RAS + rollback 设计 | 投机更新可被 flush 恢复；EX update 不双改 spec RAS | 若接口复杂化，改为非投机 RAS 保持现状 |
| implement | Codex | design | RTL 源码 | `BranchPredictor.rollback_i`、`ras_arch/spec`、IfStage 连接 | lint 通过，无未接端口 | 回退单文件改动 |
| test | Codex | implement | 单测和 AM cpu-tests | BPU 单测扩展、lint/build/cpu-tests 结果 | 模块 testbench 21/21 与控制流样本 PASS | 缩小到 BPU 单测定位 |
| record | Codex | test | 验证结果与改动摘要 | project-status、npc memory、task report | 长期结论可被后续会话恢复 | 若记录冲突，仅追加不删除历史 |

## 执行摘要

1. 读取 BPU/IF/EX 控制边界，确认当前 `RAS` 只在 `update_valid_i` 下 EX 阶段修改。
2. 将 RAS 拆成 `arch` 与 `spec` 两份：预测读写 `spec`，EX update 写 `arch`。
3. 将 `IfStage.flush_i` 作为 rollback 信号接入 BPU。
4. 补充 `tb_branch_predictor` 的投机 push/pop 和 rollback 用例。
5. 完成 lint、模块 testbench、Verilator build 与控制流/递归/压缩跳转 cpu-tests 验证。

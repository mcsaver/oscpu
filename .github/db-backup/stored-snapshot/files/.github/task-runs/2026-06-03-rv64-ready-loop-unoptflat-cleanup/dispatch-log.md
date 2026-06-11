# Dispatch Log

## 节点图

| node_id | owner_agent | depends_on | 输入 | 输出 | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- |
| recall | Codex | - | 项目规则、memory、RV64 README/study | 约束摘要 | 明确 RTL 四段式与验证要求 | 补读缺失文件 |
| trace-ready-loop | Codex | recall | `OooAluDecodeBackend/OooDispatchBackend/OooIntBackend/OooAluFetchCore` | ready/resolve 组合链 | 找到 `UNOPTFLAT` root cause | 用 Verilator lint path 继续缩小 |
| rtl-fix | Codex | trace-ready-loop | 组合环路径 | RTL 补丁 | parent ready 单向化、未打拍 fast path 退出组合锥 | 恢复局部改动并保留记录 |
| verify | Codex | rtl-fix | 修改后工作区 | lint/build/test/smoke 证据 | 所有门禁 PASS，活动 RTL waiver 清零 | 定位失败日志并回到 trace |
| record | Codex | verify | 验证结果与 diff | memory/task-run 更新 | 长期结论落盘 | 若验证不完整，记录缺口 |

## 执行记录

1. RECALL
   - 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、RTL workflow、RV64 README/study。
   - 结论：本轮必须先推导协议/不变量，再删除 waiver。

2. TRACE
   - 初始目标是 `OooAluDecodeBackend` 的 `backend_dispatch*_valid/ready` waiver。
   - Verilator lint path 显示真正环路跨越前端 direct branch/return、backend dispatch branch resolve、issue bypass 和 optional lane1。

3. RTL
   - `OooDispatchBackend` ready 改为由本模块容量计数直接生成。
   - `OooAluFetchCore` 关闭未打拍同拍 lane1 synthetic append fast path，branch target cache lookup 使用 head0 target。
   - `OooIntBackend` 关闭 lane1 dispatch fast branch resolve。
   - 删除 `OooAluDecodeBackend` 与 `OooAluFetchCore` 活动 `UNOPTFLAT` waiver。

4. VERIFY
   - focused decode/backend：3/3 PASS。
   - frontend neighbor：3/3 PASS。
   - `make -C npc/rv64 lint`：PASS。
   - `make -C npc/rv64 -j2`：PASS。
   - Linux/tools 6 个 smoke：全部 GOOD TRAP。
   - 活动 RTL waiver scan：无命中。
   - `git diff --check`：PASS。

5. RECORD
   - 更新 `.github/memory/project-status.md`。
   - 更新 `.github/memory/modules/npc.md`。
   - 当前 task-run 目录保存本报告和调度日志。

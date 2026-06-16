# Dispatch Log

## 2026-05-29

- 任务：为 ALU-only OoO 实验核补最小 load/store 通路。
- 设计选择：先做 lane0 memory precise barrier，让 memory uop 真实进入后端并提交；不做前端 synthetic load 写回，避免破坏 rename/PRF 状态。
- 范围边界：不实现 LSQ speculation、store forwarding、lane1 memory、cache miss 多 outstanding；这些作为后续从“精确但慢”过渡到“乱序访存”的升级点。
- 实现结果：`OooIntBackend` 新增 LSU-backed 单 outstanding memory uop，`OooAluFetchCore` 新增 lane0 memory drain/dispatch/refetch 协议，`NpcSimTop` 实验路径接 DPI memory response。
- 验证结果：OoO 定向与全量模块回归 PASS；实验 lint/build PASS；raw memory GOOD TRAP `cycles=28/commits=8/CPI=3.500`；4096 ALU 仍 `CPI=0.502`；默认主线 lint/build 与 `cpu-tests add` PASS。
- 后续入口：下一阶段优先把 drain barrier 替换为真正 LSQ/store buffer + commit-store，并设计 load/store 与 branch checkpoint 的 flush/rollback 协议。

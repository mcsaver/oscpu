# Dispatch Log

- 接受用户对 WSL 崩溃的分析：WSL `E_UNEXPECTED` 更像环境症状，代码侧触发压力来自 CoreMark no-progress。
- 复核现象：fault-trap 前历史 CoreMark1000 `CPI=0.779`；fault-trap 后 CoreMark 不是 BAD TRAP，而是长时间无退休并叠加 WSL 服务错误。
- 串行复验当前工作树，避免并发 WSL/vsock 不稳定。
- 确认当前 CoreMark10 已不再卡死，memory request/response 平衡。
- 建立最终 focused 基线：`branch-resolve-loop ooo-mem-order linux-mini-boot` 全部 PASS。
- 建立最终 CoreMark10 基线：PASS，`cycles=2661725/commits=3216115/CPI=0.828`。
- 记录当前主要瓶颈：top branch wait `0x80000b2c`，对应 CoreMark list merge/sort 路径的 load-dependent branch。
- 撤回 ROB64/IQ32 窗口实验，因无 CoreMark收益。
- 撤回 issue1 过度门控，因 CoreMark退化到 `CPI=0.831`。
- 保持 branch prefetch same-cycle dispatch 关闭，因 focused PASS 但 CoreMark无收益。
- 保持 direct branch speculation 关闭，早前实验会破坏 focused 或退化。
- 保持 load-branch fast resolve 关闭；启用后 focused PASS 但 CoreMark退化到 `CPI=0.907`。
- 撤回 ROB same-cycle slot borrow 两个版本，因 Verilator `UNOPTFLAT` 组合环。
- 撤回 BPU local strong-only override，因 miss 增加且周期无收益。
- 更新 `.github/memory/project-status.md`、NPC 模块笔记、AM-Kernels 模块笔记和 known-issues。

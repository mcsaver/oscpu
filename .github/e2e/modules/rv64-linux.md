# RV64 Linux E2E Contract

本模块只描述显式选择的 RV64 Linux/OpenSBI/rootfs/QEMU/NPC 系统 profile；普通局部 Linux、脚本或 RTL
修改不自动运行它，也不需要先生成 preflight、marker、SHA 或 task-run。

## Claim boundaries

- 分层区分 image、OpenSBI、kernel、PID1、设备事务、rootfs/Ubuntu userland、交互 shell 与自然 poweroff；
  低层 smoke 只能支持对应层。
- QEMU 是 reference，不能替代 NPC target 日志；同理 NEMU/NPC/Verilator 的证据不能混写。
- 完整 Ubuntu 或严格 systemd transaction 只有在 acceptance criteria 明确要求该 workload 时执行。选择
  `--user-authorized-full-ubuntu` 表示接受高成本 workload，不是安全本地工程动作的第二次授权。
- 显式 persistent/published 长跑若中断、terminal evidence 缺失或 cleanup 失败，必须报告 FAIL/GAP；一次性
  交互运行直接报告返回码、命中的层级和未完成范围。

## Integrity exceptions

可写 block image 必须从只读模板派生，运行不能污染模板。只有这里的 template/copy byte identity、正式
release/reproducibility 或已发布 transaction evidence 才使用 pre/post SHA-256；普通 build/log/task identity
不使用 hash。严格 transaction JSON/整行 marker 只服务其明确系统验收，不反向成为 probe、compile 或局部
修复的前置条件。

工程 PASS 由对应 workload 的真实 boot/device/guest/poweroff 结果判断；profile 合同存在性或外层脚本返回
不能替代这些结果。

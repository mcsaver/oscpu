# RV64 T3E：ROB-walk checkpoint-capture 配置隔离

## 基本信息

- `task_id`: 2026-07-13-rv64-t3e-checkpoint-capture-isolation
- `status`: completed (structural slice); parent timing goal remains active
- `profile`: npc-dev
- `base_commit`: eb9bd3b28（叠加 T3B/T3C/T3D 工作树）
- `trigger`: T3B/C/D fresh 5 ns OpenSTA 仍报告 16 条组合环
- `parent_goal`: active；完整功能与 200 MHz 尚未闭合

## 根因与目标

16 条环共享 legacy `branch_spec_checkpoint_capture` 反馈。该输出在当前
`OOO_ROB_WALK_MODE=1` 架构下应恒 0，但 RTL 只依赖父层 `pending_branch=0` 的跨层级
不可达证明；保层级综合没有传播该常量，于是形成
`long-op response -> execute quiet -> checkpoint capture -> issue block -> branch kill`
的伪 SCC。

T3E 在 `OooBranchResolveRecoveryGate` 生产端编码配置真相：mode 1 恒 0，mode 0 原谓词
逐位保留。禁止打拍 kill、修改 issue/ready 或用 false-path/UNOPTFLAT 掩盖。

## 接受门禁

- RED：默认 mode 1 下，单测强行驱动全部 legacy capture 前件为 1，旧 RTL 必须错误输出 1。
- GREEN：focused 与 93 项 module suite 通过；full Verilator 不新增环形 waiver。
- fresh OpenSTA：combinational loops 必须从 16 降为 0。
- CoreMark 与完整 ISA/privileged/FP 回归不得产生新功能或周期回退。

## 实现者交付证据

- RED：旧 RTL 在 mode 1 强驱全部 legacy capture 前件时唯一失败，`got=1 exp=0`。
- GREEN：mode 1 与命令行 mode 0 双配置 focused 均 PASS；module suite `93/93`。
- full Verilator 5.051、lint、RTL style、contract (`77 >= 59`) 均 PASS。
- CoreMark10 与 T3B/C/D 候选逐周期一致：`2,937,909 cycles / 3,218,573 commits`，
  CRC `fcaf`，GOOD TRAP，CoreMark/MHz `3.474`。
- fresh Yosys `105/105`、synth check `0`；fresh OpenSTA loops `16 -> 0`。

## 审查者反例与裁决

- 审查发现原 testbench 用 `ifdef` 判断宏存在性，不能动态覆盖 mode 0；已改为按宏值
  分支，并实际用 `OOO_ROB_WALK_MODE=0` 重编译通过。
- mode 1 前缀为常量 0，4-state 下即使 legacy 前件为 X，capture 仍为 0；mode 0
  前缀为 1，旧谓词逐项不变。
- fresh STA 的 loops=0 关闭了 T3E 结构目标；但 WNS/TNS 为
  `-17.23 ns / -291670.31 ns`，因此 200 MHz 目标仍不成立，转入 T3F。

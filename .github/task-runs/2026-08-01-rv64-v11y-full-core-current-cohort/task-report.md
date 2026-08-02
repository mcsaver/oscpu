# RV64 V11Y 任务报告

## 结论

- `status`: completed for current functional scope
- `design_id`: `sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`
- `classification`: production RTL fix + verification + checker replay
- `promotion`: not eligible; architecture/system/PPA gates remain open

## 实现者结论

本轮关闭了四类已确认的 RV64 可见语义缺陷：SSTATUS writable mask、RVC
`C.LUI rd=x0` hint、FP CSR 在 `mstatus.FS=Off` 时的非法访问与 FS dirty、
以及 MPP/delegation/SIE/SIP WARL/view 合同。`rv64-inst-audit` 的 `mcycle`
失败被定位为真实 OoO 周期与旧 exact-read oracle 冲突，改为使用
`mcountinhibit` 的可判别检查，没有冻结或削弱硬件计数器。

当前 RTL 通过 113/113 module；同一设计的 functional 执行完成
official 177/177、AM 61/61、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`
和 Dhrystone 10000。原 attempt-3 只因旧输入 oracle 把 177 个官方构建目标
误列为源码而保持 FAIL。最终 versioned replay 精确排除 354 个允许的官方
构建产物，真实输入变化为 0，11/11 证据 mutation 被拒绝，并发布 canonical
aggregate/result/log。

未运行 Linux 或完整系统重认证；production semantics 已变化，因此系统
资格仍为 RED，完整系统运行仅在 architecture/fast gates 关闭并取得适用授权
后启动。本轮没有时序、功耗或 physical promotion 声明。

## 独立审查者结论

`REPLAY_APPROVED`。审查者复算 replay-3 的全部 artifact hash，核对 113、
177、61 三组唯一 inventory、official/AM terminal、7 个 phase 返回码、
11/11 mutation、symlink/特殊文件边界和原始 FAIL 哈希。允许对相同输入执行
一次 `--publish-current`；发布后三个 canonical 文件已逐字节与最终 replay
一致。

未证明范围为历史 `.config` 逐字节值、重新执行 RTL、Linux/system 结果、
以及 PPA/promotion。配置只声明为由 recorded `default_defconfig`、`auto.conf`
和 `autoconf.h` 重构。

## 空间收口

task-run 从 264 MB 降至 25 MB。保留原始 FAIL、最终 PASS、模块结果、raw
日志、输入 manifest、canonical 结果与 compact history；删除 219 MB 意外
`obj_dir`、三份 superseded replay wrapper、14 个 `/tmp` 编译目录和两个失败
functional attempt 中不可重放的 images/frozen 二级产物。当前 task-run 中
`.vvp/.o/.a/obj_dir/build` 数量均为 0。

## Strict guard scoped exemption

首次 strict guard 因轻量模式禁止隐式 Git 全树枚举而拒绝；使用 22 个明确
V11Y 路径后，只报告缺少 `abstract-machine`、`am-kernels`、`npc-dev` 三个
通用 profile 包。未发现 RTL、TB、AM 或 checker FAIL。本轮不重复运行这些
通用 profile：113/113 module、61/61 AM DiffTest、177/177 official、13 项
checker 单测与 11/11 mutation 已提供更直接的路径级证据。该豁免只适用于
V11Y 确定性交付，不豁免未来 architecture/system/PPA gate。

## 下一动作

回到 architecture debt 主线，先用当前 `882111...` design-id 运行轻量
full-core debt audit，选择首个真实 P0/P1，而不是继续扩展 V11Y 流程。

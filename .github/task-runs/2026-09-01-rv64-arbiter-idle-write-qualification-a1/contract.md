# RV64 dual-memory arbiter IDLE write admission 资格化契约

## 目标与冻结身份

本任务在 retained `axi-crossbar-held-grant-target-offer-v1` production RTL 上，只测量
`OooDualMemAxiArbiter` 的 registered IDLE write owner-select 空拍。冻结 production design ID 为
`sha256:24849eb786b11715023bb3d512519a0e3bda4c61765686d3c180890e2977572a`（155 个 RTL
文件）。诊断 probe 只能通过 build extension/bind 注入，不修改 production RTL或功能接口。

## 机会定义

只在以下谓词精确成立时记录一次 IDLE write event：

```text
state == S_IDLE && capture_valid && capture_write
```

对既有 `capture_owner` 选中的 lane 分别统计 source AW/W VALID `11/10/01/00`、arbiter downstream
AW/W READY `11/10/01/00`、lane winner和双 lane contention。严格机会定义为 selected source=`11`
且 downstream READY=`11`。read、illegal dual-type、reset、非 owner lane和 unknown state/owner/VALID/
READY 都不得成为机会。

本任务不把 probe 的 `xbar_head*_wr_rsp` 解释为 arbiter capture 的 head-critical 计数；这些字段只在
后级 xbar grant 拍采样 AXI write-response reason。IDLE write admission 的最终 criticality oracle 是
功能候选 exact-predecessor A/B，而不是不同拍计数相等。

## Workload acceptance

使用 retained predecessor 完全相同的 CoreMark/Dhrystone 镜像、DiffTest reference、ROI PC与运行
参数。diagnostic build 必须保持：

- CoreMark ROI `cycles=4,667,639`、`retired=3,183,617`；
- Dhrystone ROI `cycles=7,891,545`、`retired=4,250,000`；
- GOOD TRAP、DiffTest ON、exit code 0、功能输出/CRC与 SQ receipt不变量；
- marker 恰好一次，complete/available/conservation=1、overflow/invalid=0；
- arbiter event必须分别等于 source matrix、READY matrix与 lane winner总和。

## 裁决边界

若两项都有非零 strict event，且独立架构审查确认不存在 READY 环、owner/B授权可以保持，则允许以
新版本合同实验 `dual-mem-arbiter-idle-write-admission-v1`。这会重签旧 F0 的 IDLE-quiet边界；只允许
write admission，read仍保持 registered selection。资格化本身不授权 store early completion、B
fall-through、owner提前释放或 PPA 声明。


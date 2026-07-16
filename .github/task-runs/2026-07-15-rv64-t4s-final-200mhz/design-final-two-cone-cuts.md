# T4S：final two-cone timing cuts

## 输入红线

T4R 已关闭 xbar fall-through 族，但 exact 5.0 ns 仍为 WNS
`-0.050334848 ns`、TNS `-0.197783574 ns`，13 条 violation。不得依靠映射波动、
false path 或 multicycle 例外收口。

## Cut A：FP resource intent / actual accept 解耦

剩余 IQ/PC 族共同经过：

```text
packet valid -> OooIntBackend FP raw-valid gate
             -> OooFpBackend registered-count credit/ready
             -> DBE accept/fire -> IQ/redirect state
```

`dispatchN_accept` 已蕴含 packet valid，FP map/free-list/IQ 的所有状态更新也已由
accept 资格化。因此 resource-need 只读取 raw class intent；valid=0 时 class payload
为 don't-care，不能再把 packet valid 接入 capacity ready。活动事务满足：

```text
(packet_valid && class) && accept == class && accept
```

四个 arithmetic/load intent 口一起切换，避免关键路径改走 sibling lane/class。

## Cut B：Dcache fill address owner

`fill_we = fill_valid && cacheable(fill_addr)` 必须继续保护 SRAM en/we/wmask 与 valid。
SRAM addr 在 en=0 时是 don't-care，因此地址 owner 可直接使用 `fill_valid`：合法 fill
与旧实现逐位等价，非法 fill 仍不写且不置 valid。此切法不增加 delayed fill，因而
不改变 `reset > DMA invalidate > fill/store` 的 valid 优先级。

## 验证

- FP/int dispatch、FP IQ、Dcache、mem bridge 定向 TB；完整 module suite。
- lint、默认仿真构建、AM/official ISA、CoreMark/Dhrystone、virtio preload smoke。
- frozen-input fresh synthesis + no-exception exact 5.0 ns global STA；仅当 WNS/TNS
  非负、所有报告路径 MET、输入/网表绑定与 freeze attestation 全通过，才声明 200 MHz。


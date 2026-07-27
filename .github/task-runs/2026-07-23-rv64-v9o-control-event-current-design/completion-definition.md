# V9O completion definition

本切片只有同时满足以下条件才可称为完成：

1. 独立只读 reviewer 从 E1/E2/E3 request 到 fetch、ROB、rename、IQ、执行完成、FP、
   MIQ/SQ 与全后端清空逐项追踪，给出阶段图、行为保持切点和可构造反例。
2. spec 在 RTL 前冻结 request/apply 两阶段、事件原因、年龄边界、前端/后端 consumer set
   以及 `mmu_flush`/AXI drain 正交边界。
3. 前端类型化赢家不再是 unused sink，并作为规范参考视图；生产后端采用 ROB edge-old
   `head0_control_event_pregrant` 的无组合环投影，双向断言证明 branch/full 投影与最终
   `SELECTIVE_NOW/FULL_NEXT` 赢家一致。
4. 精确陷阱与 queue-head CSR 的全后端清空保持 C0 提交、C1 apply；同拍 branch+commit
   由稳定年龄投影选择 older commit，且严格年轻 completion 不越过 full boundary。
   `OooCoreTopGlue` 的 C1 request 只能直接来自 ROB full pregrant；trap/CSR 架构提交脉冲
   与相应 typed pregrant 必须有双向立即断言和真实程序覆盖。
5. pending-system CSR 必须用 exact `{type, ProducerId}` 匹配队头 owner；其
   `CSR_COMMIT/NONE` 路径关闭同拍 dispatch/branch，但不误发 full barrier 或 C1 apply。
6. focused testbench 覆盖 branch、trap、queue-head CSR、pending FP CSR、CSR 与 older
   store/younger load 次序、direct、同拍多源、环形 ROB 年龄、真实 full-C0 × 8 completion
   class，以及两个 lane 同时持有 registered AR owner 时的多拍 C0 barrier 和两个精确
   terminal。
7. 至少 11 个 compile-success RTL 变异分别改变 strict-younger 边界、C1 valid、reason、
   single C0 request source、pending owner 匹配、branch 优先级、宏配置 memory 准入和
   registered AXI VALID；每个
   变异都必须编译成功并被指定仿真或 full-cone lint oracle 拒绝；其中 current
   completion-ready 回接 pregrant 的变异必须重现组合 SCC，而基线必须
   `UNOPTFLAT=0`，且生产 RTL 哈希前后不变。
8. default module aggregate、`OOO_CSR_QUEUE_HEAD=1` generic aggregate、相关 canonical
   architecture targets、arch-stable audit 与 strict guard 重新运行；focused、宏配置和
   每个模块日志都带运行时 current design-id，runner 在执行前后复算完整 RTL source set；
   总索引绑定 live source SHA、artifact SHA 与 provenance SHA。
9. 独立终审检查反例覆盖、证据 freshness 与结论边界；full-core `GAP`、PPA
   `UNQUALIFIED`、promotion=false 在其它 blocker 未闭合时保持不变。

# RV64 OoO T0：5 ns 目标驱动重映射基线

## 结论

修复 ABC 目标传播合约后，当前 RTL 在 `STA_CLK_FREQ_MHZ=200` 下完成了目标驱动的 Yosys/ABC 重映射和 OpenSTA 5 ns 分析。结果仍远未达到 200 MHz：WNS 为 `-15.74 ns`，TNS 为 `-196567.73 ns`。最差 40 条路径以整数后端内部的以下组合闭环为主：

`Store Queue state -> issue/execute/ready/kill control -> IQ/PRF/ALU -> MIQ D`

最差路径不从 DCache 或前端开始，而是从 `OooStoreQueue` 状态寄存器到 `OooMemInflightQueue` 寄存器。T1 因而应优先在 IQ issue 输出与执行/内存入队之间建立明确寄存边界，并删除只会延长静态组合锥的死旁路；具体改法必须先由 focused test 锁定独立反压、flush/kill 和依赖唤醒语义。

## 旧结论勘误

本目录最初记录的 `WNS -12.63 ns / TNS -153907.62 ns` 与 `DCache SRAM -> MIQ` 路径来自现已重命名为 `*.pre-target-contract.*` 的产物。那次综合虽然设置了 `STA_CLK_FREQ_MHZ=200`，但自定义 ABC `DELAY-4` 脚本没有 `{D}` 占位符，因此 `abc -D 5000` 没有进入实际的 `&nf/upsize/dnsize` 映射命令。

该旧结果仍可作为“当时脚本的无目标映射诊断”，但不能称为 5 ns 目标驱动重映射，也不能决定当前优化优先级。流程修复提交为 `ee422740d75bd8ff042575cf515d8dd04d926749`；修复后 105 个最终 ABC cone 均出现 `ABC: + &nf -D 5000.0`，不存在以 SDC 改写冒充目标驱动映射的问题。

## 运行范围与输入身份

- 时间：`2026-07-12 02:08–02:46 +08:00`（目标驱动综合至 OpenSTA 报告完成）
- 分支：`ai`
- HEAD：`ee422740d75bd8ff042575cf515d8dd04d926749`
- `.config` SHA-256：`cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
- 三个用户未提交 RTL 文件的合并 diff SHA-256：`ba53023545091ab611f5d05d2a1afe2ed709ba797811c06baa6a4f0b8740a391`
- 工具：Yosys `0.66+197 (aa18c921a)`；OpenSTA `3.1.0`
- 标准单元角：`icsprout55` typical/TT、1.2 V、25 C

综合输入包含用户工作树中的 `OooAdUpdateChecker.sv`、`OooFrontend.v` 和 `NpcSimTop.sv` 修改，但本任务没有暂存或改写这些文件。后续对比必须同时核对 HEAD、上述 dirty diff 和 `.config` 身份。

## 运行命令

目标驱动重映射使用：

```sh
timeout --foreground 7200s make -C npc/rv64 syn \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

OpenSTA 使用同一映射网表、5.000 ns core clock 和 40 条 max path 报告。iEDA 同网表运行被限制在 600 s，并在 data backward propagation 阶段终止；它没有产生可用的 `.rpt/.pwr`，因此本基线的数值真源只有 OpenSTA。

## 目标驱动结果

| 项目 | 修复前无目标映射诊断 | 修复后 5 ns 目标驱动映射 |
|---|---:|---:|
| ABC `&nf -D 5000.0` cone 数 | `0` | `105` |
| WNS | `-12.63 ns` | `-15.74 ns` |
| TNS | `-153907.62 ns` | `-196567.73 ns` |
| 最差起点族 | DCache SRAM | Store Queue 状态寄存器 |
| 最差终点族 | MIQ | MIQ |
| 可决定当前优化优先级 | 否 | 是，作为 non-signoff T0 |

Yosys 在 `1404.66 s` 完成，峰值内存 `3650.20 MB`，最终 `check` 报告 0 个问题。映射顶层面积为 `1,571,023.44`，其中不包含四个黑盒宏的未知面积。

最差路径：

- 起点：`u_core/.../u_int_backend/u_store_queue/_6266_`
- 终点：`u_core/.../u_int_backend/u_mem_inflight_queue/_7490_`
- 数据到达：`20.709 ns`
- 数据要求：`4.971 ns`
- slack：`-15.739 ns`

报告中的静态弧依次穿过 Store Queue 派生控制、整数后端 glue、PRF、ALU0、ALU1、MulDiv 控制、IQ、再次经过 PRF/ALU0/ALU1，最终进入 MIQ。它说明这些单元之间缺少足够的寄存边界；它不证明软件会在一拍内按该名称顺序执行多条指令，也不应被解释成某个单独模块的功能错误。

## 流程边界

本结果是可重复的逻辑综合/理想时钟 STA 基线，不是 signoff：

- 无 SPEF、CTS、OCV、时钟不确定度和时钟延迟；
- 无完整 input/output delay、generated clock、false path、multicycle 和 clock group 约束；
- SRAM、BPU 和 FP 边界使用占位 Liberty，宏时序仅为近似；
- power 文件只有诊断性输出，不能支撑功耗结论；
- iEDA 未在 600 s 界限内生成时序报告；
- 真实布线后 200 MHz 需要逻辑侧留出裕量，不能以逻辑 WNS 刚好非负宣称物理收敛。

## T1 设计约束

T1 的根因目标是切断后端同拍反馈闭环，而不是只优化一个门级局部。候选实现需同时满足：

1. 两条 issue lane 可独立反压、保持和消费，不能因单 lane 阻塞造成不必要的原子捆绑；
2. flush、checkpoint restore 和 branch mispredict 不得让已杀 payload 进入执行或 MIQ；
3. IQ 同拍 wakeup 可以保留，但其组合锥必须终止在新 stage 的 D 端；
4. 已删除 dispatch-to-issue bypass 后，issue0 到 issue1 的当拍结果前递若确属不可达，应以结构检查和依赖回归共同证明后删除；
5. PRF 当拍写穿透能否删除取决于新 stage 的读时序，必须由 WB/依赖相邻拍测试证明。

实现后必须运行 focused test、完整架构回归和同设置 200 MHz 目标驱动重映射；局部综合 delay、旧网表重约束或单个静态路径消失都不能单独证明 T1 成功。

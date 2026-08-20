# BPU inline physical-boundary architecture review v1

RV64 RTL 结论｜对象=`OooBranchDirectionPredictor`、`architecture_registry.py`、A2 `summary.json`｜周期/配置=5.000 ns；`mapped-5ns-four-placeholder-v1` → `mapped-5ns-bpu-inline-v1`｜TB/EDA 观测=A2 flow PASS，WNS=-11.550187111 ns；本节点未运行综合/STA｜范围=GAP

裁决：A2 四宏基线 **RETAIN**；registry-authorized physical configuration **FIX，唯一推荐**；直接翻转 canonical `blackbox_in_mapped_flow` 与另建非绑定 runner 均 **BLOCK**。

推荐配置：

- `mapped-5ns-four-placeholder-v1`：两个 SRAM、`OooFpArithGate`、`OooBranchDirectionPredictor` 均为 `placeholder_blackbox`。
- `mapped-5ns-bpu-inline-v1`：只把 `OooBranchDirectionPredictor` 改为 `inline_rtl`；其余三个 boundary 不变；comparison parent 为四宏基线。
- 两者共享 `NpcTop`、5.0 ns、`clk`、空 define、现有 synth/STA flag 与七个 keep-hierarchy module。
- RTL design-id 仍为 `sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`，但 physical configuration/projection 必须有独立身份。

最小实现边界：

1. catalog/schema 增加 `physical_configurations`，要求 boundary key set 精确等于 `physical_boundaries`，inline child 相对 parent 的唯一 delta 为 BPU predictor。
2. `mapped_projection()` 接收显式 configuration id，返回 `boundary_modes`、3 个 blackbox、BPU inline module 和对应 3 个 Liberty；未知/空配置 fail-closed。
3. 同一 runner 要求 `--physical-configuration` 与 expected RTL design-id；projection 只能来自 registry；summary binding 同时记录 RTL identity、physical configuration、projection 和 run-parameter artifact identity。
4. A2 summary 字节保持不变，继续称 frozen legacy evidence baseline；WNS<0 的 timing GAP 不变。新的 v2 policy hash 不应因更新 current evidence pointer 自指失效。
5. 单测拒绝：未知 variant、BPU 被重新 blackbox、BPU Liberty 残留、误删 SRAM/FP、周期/define/synth flag/keep-hierarchy 漂移、错误 RTL design-id、stale manifest 与伪 projection/parameter hash。

未知项：BPU 17674-bit predictor 状态的 Yosys/ABC 时间、网表膨胀、真实 WNS/area/power 未测；若超时或灾难性展开，回滚到 production child split。Top40 的 BPU 命中为 0 不能证明 inline 或 timing 合格。合同内只读命令已结束，WSL shell ownership 已归还。

# BPU inline physical configuration implementation v1

RV64 RTL 结论｜对象=`NpcTop` / `OooBranchDirectionPredictor` 与 registry/schema/runner/tests｜周期/配置=5.000 ns；`mapped-5ns-four-placeholder-v1` → `mapped-5ns-bpu-inline-v1`；RTL design-id=d3f3｜TB/EDA 观测=`bash -n` rc=0；`test_architecture_registry` 18/18 PASS；未运行综合/STA/RTL 仿真｜范围=配置与 fail-closed binding PASS；timing/PPA GAP

仅修改：

- `npc/rv64/design/arch/rv64-architecture-registry-v1.json`
- `npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json`
- `npc/rv64/eval/ppa/tools/architecture_registry.py`
- `npc/rv64/eval/ppa/tests/test_architecture_registry.py`
- `npc/rv64/eval/ppa/run-traceable-mapped-current.sh`

实现结果：

- 四宏配置保持两个 SRAM、`OooFpArithGate`、`OooBranchDirectionPredictor` 为 placeholder；BPU-inline 配置只将 predictor 设为 `inline_rtl`，对应 BPU Liberty 不进入投影。
- runner 强制显式 physical configuration 与 expected RTL design-id，并在 EDA 前计算 live design-id；错误/未知配置或非 d3f3 输入立即 rc=2。
- v2 binding 分离 RTL design-id、architecture policy、physical configuration、projection、run-parameter contract、parameters、STA input manifest 与 evidence artifacts。
- `architecture_policy_sha256` 排除可变 `evidence` pointer；parameters 在 run-start 冻结 policy/configuration/projection 三个摘要，防止长跑中 catalog 策略漂移后伪绑定。
- stamp 同时校验 summary unknown-macro census 与 raw `synth_stat.txt` 最终 design-hierarchy census；OpenSTA 与 synthesis receipts 均逐项重算。
- A2 frozen summary 未修改，WNS `-11.550187111 ns` 继续是 timing GAP。

验证：WORKER 初版 `bash -n` rc=0、registry 17/17；主节点审阅补齐 run-start hash 与 raw census 后，`bash -n` rc=0、registry 18/18。没有重复运行综合/STA/RTL 仿真。unknown 仍为 BPU inline 后的 Yosys/ABC 容量、面积、功耗、WNS 与 Top40；这些由下一次唯一长跑测量。

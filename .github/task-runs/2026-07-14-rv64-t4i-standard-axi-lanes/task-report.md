# RV64 T4I：标准 AXI lane、完整回归与 200MHz 代理时序闭合

## 基本信息

- `task_id`: 2026-07-14-rv64-t4i-standard-axi-lanes
- `task_slug`: rv64-t4i-standard-axi-lanes
- `graph_template`: custom
- `graph_mode`: static+dynamic
- `status`: completed
- `owner`: /root
- `started_at`: 2026-07-14T00:00:00+08:00
- `updated_at`: 2026-07-14T20:36:32+08:00

## 任务目标

- `source_request`: 持续优化 RV64 架构，补齐完整功能并达到 200MHz；把 OS `/tmp` 相关内容归档进工作区。
- `goal`: 闭合标准 AXI byte-lane/size/response 合同，完成全量功能回归，并用当前冻结 RTL 的 fresh 5ns gate-level proxy STA 验证 200MHz。
- `scope`: NPC RV64 RTL、testbench、评测脚本、CoreMark/Dhrystone、Yosys/OpenSTA 证据与任务/memory 留档。

## 选图说明

- `selected_template`: custom（RTL correctness → 全量回归 → fresh synthesis → exact-5ns STA → evidence hardening → reviewer）
- `why_this_graph`: 改动跨 LSU、AXI xbar、设备 slave、DPI、frontend/backend 与评测脚本，单一模块 gate 不足以闭合数据流和 200MHz 证据。
- `dynamic_nodes_added`: PMA/PMP 精确异常、标准 lane adapter、AW/W 独立握手、设备 lane 归一化、Dhrystone 可缩短 smoke、证据 mutation 与 binding audit。
- `why_dynamic_nodes_were_needed`: 旧实现存在 exact-address/low-window 私有 ABI、store 提前完成和汇总脚本误计数，必须按 root cause 分别闭合。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| contract-and-root-cause | /root | completed | AXI/LSU/xbar/device 调用链 | 标准 lane、size、owner、response 合同 | 设计 spec、定向 TB |
| implementation | /root | completed | RTL/C++/C/eval harness | lane adapter、AWSIZE 贯通、B owner、标准设备/DPI | source diff、lint |
| functional-regression | /root | completed | 当前 137 个 RTL/C++ 源与仿真 binary | module、official/privileged、AM、benchmark、DPI | `evidence/functional-*`、`evidence/axi-dpi-sized.log` |
| fresh-synthesis | /root | completed | 冻结 source manifest | 116 modules、ABC 220、check/freeze PASS | `evidence/synthesis/`、`evidence/synth-top-stat-corrected.json` |
| exact-5ns-sta | /root | completed | fresh netlist + H7CL liberty/placeholder macros | top40 40/40 MET、worst `+0.017907454ns` | `evidence/opensta-fresh-t4i-final/` |
| independent-review | reviewer-agent | completed | raw evidence、checker、限制条件 | 无 P0；确认 proxy closure，拒绝物理签核越级 | 本报告“审查边界”与 evidence manifest |
| archive-and-handoff | /root | completed | OS `/tmp` 相关顶层对象、任务产物 | workspace `tmp/os-tmp-archive/...` 与 task-run | archive manifest/SHA、task report |

## 关键实现

- `OooLsuAxiLaneAdapter` 将 LSU 请求转换为标准 AXI lane；仅对已授权 PMEM misaligned footprint 做逐字节 split，非法请求 fail closed 且无总线副作用。
- `OooMemAxiBridge` 的 store 直到聚合物理 B response 后才完成；cache RMW 仅在 B 成功后提交；AW/W 独立握手与 owner 保持到 B。
- `AWSIZE` 从 xbar/bus/top/sim 全链贯通；UART、CLINT、PLIC、DPI、virtio 均按标准 lane 解码，DPI wrapper 在边界内归一化 host exact-address ABI。
- PMA/PMP、取指 fault owner/tval、frontend owner/credit、issue/wakeup/PRF/ROB 等前序切片一并纳入当前冻结源和回归。
- `npc-eval.sh` 以进程返回值、GOOD TRAP、timeout 三重判定 benchmark；修复 official PASS 误计数；Dhrystone 支持运行次数参数但默认仍保持 500000。

## 验证证据

- module testbench：`100/100 PASS`，100 份原始日志由 `evidence/functional-raw/module-logs.sha256` 锁定。
- official/privileged：实际执行/构建 `177/177 PASS`；AM `59/59 PASS`，`413008 cycles / 152883 commits / weighted CPI 2.7014645`。
- CoreMark：GOOD TRAP，`6563047 cycles / 3218532 commits / CPI 2.039`。
- Dhrystone：10000-run 功能 smoke GOOD TRAP，`10802900 cycles / 4260665 commits / CPI 2.535`；默认 500000-run 在 20 分钟预算内 timeout，未宣称通过或性能完成。
- sized DPI：`AXI_DPI_SIZED_SUITE_PASS`；标准 lane/size 与 host ABI guard 均通过。
- functional binding audit：当前 binary SHA256 `8d6cf96dda99c39a9121b0e17a36acd8806fbca3eb6203fb8711ecdb8c230a9b`，137 个 vsrc/csrc 均不晚于 binary，审计 PASS。
- fresh Yosys：116 modules、ABC 220、顶层 area `1622701.08`、sequential `445478.88 (27.45%)`；netlist SHA256 `d7e5263f91876ab2e630c15cca7a56daddaae1459620676ae092d12af4e93eac`。
- exact-5ns OpenSTA：40/40 top paths MET，实际最差正 slack `+0.017907454ns`，WNS/TNS 报告值 `0/0`，setup member 集合精确匹配 `303/1873/1875`。
- checker hardening：负 slack 文本伪装为 `-0.0` 与 equal-count member substitution 两类 mutation 均被拒绝。

## 审查边界与风险

- `final_result`: 当前冻结 RTL 在 Yosys + OpenSTA、典型 standard-cell liberty、ideal clock、placeholder macro、内部受约束路径的 exact-5ns gate-level proxy STA 中达到 200MHz；功能回归在上述证据范围闭合。
- 这不是 tapeout/板级/物理 signoff：仍有 303 input missing delay、1873 output missing delay、1875 unconstrained endpoints，且没有 SPEF、CTS、OCV 或 clock uncertainty；macro liberty 明示为非签核 placeholder。
- 正 slack 仅 17.907ps（约 5ns 的 0.36%），物理实现阶段必须重新约束、布局布线并做多角签核。
- 全量评测曾覆盖工作树中原有 dirty `build/linux-logs/npc-linux.log`；原始 dirty 字节未找到可恢复副本。该文件保持 unstaged，不能把当前内容当成本任务产物提交。

## 关键产物

- `artifacts`: fresh netlist、STA reports、functional raw excerpts、checker/audit scripts、`final-evidence-manifest.sha256`。
- `logs_or_traces`: `.github/task-runs/2026-07-14-rv64-t4i-standard-axi-lanes/evidence/`。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md`（DB stored documents）。

## 当前阻塞点

- `blockers`: 本任务定义的 RTL 功能与 proxy 200MHz 无阻塞；物理 signoff 不在当前工具/模型覆盖范围。
- `missing_dependencies`: 签核 macro liberty、真实 IO delay、floorplan/CTS/SPEF/OCV；默认 500000-run Dhrystone 更长运行预算。
- `risk_assessment`: proxy margin 极小；需把 17.907ps 视为架构时序门槛证据，而不是量产裕量。

## 下一步建议

1. 进入物理实现时补齐 IO/clock uncertainty 与 macro signoff model，完成 P&R 后多角 STA。
2. 若需要默认 Dhrystone 性能数字，使用显式更长 timeout 单独运行，不降低 harness 的 timeout/GOOD TRAP 门禁。

## 模板升级候选

- `repeated_dynamic_subgraph`: source freeze → synthesis binding → exact setup-member STA → mutation-negative → final attestation。
- `should_promote_to_static_template`: 是，适合作为后续 RV64 频率闭合的 evidence-hardening 子图。
- `reason`: 能系统拒绝旧网表、输入漂移、负 slack `-0.0` 与 setup count-only 假绿。

## 收尾结论

- `evidence_summary`: 功能 `100/100 + 177/177 + 59/59 + benchmark/DPI`，fresh exact-5ns proxy STA worst `+0.017907454ns`，证据具备 source/netlist/setup/member binding。
- `notes`: 交付表述必须保留非物理签核边界；OS `/tmp` 归档位于 workspace `tmp/os-tmp-archive/2026-07-14-rv64-200mhz/`，不纳入 Git。

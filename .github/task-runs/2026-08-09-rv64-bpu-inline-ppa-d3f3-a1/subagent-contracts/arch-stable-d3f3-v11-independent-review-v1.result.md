RV64 RTL 结论｜对象=NpcTop/BPU/FP/arch-stable-current-d3f3-v11/candidate.json｜周期/配置=5 ns、seed=0、threads=1、design_id=sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af｜TB/EDA 观测=L0 114/114、L1 official 177/177+AM 61/61、ACT4 100/100、L2/L3 PASS、PPA UNQUALIFIED｜范围=PASS

裁决：`APPROVE_ARCH_STABLE`。

- 身份绑定：合同 SHA-256 为 `3933510e15ec24bf2d17e88c3520e3e7ee89d2f0262479a47165b193f1810bb1`；[candidate.json](/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/arch-stable-current-d3f3-v11/candidate.json) SHA-256 精确为 `8322170c192f133f2e93f55e69635c13ce6eb84398e74825cbe37769f4a29e2b`。[pre-review-audit.json](/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/arch-stable-current-d3f3-v11/pre-review-audit.json) 除 `independent_review.exact_binding` 外全部 PASS，未发现陈旧 design-id 或证据哈希。

- 147/128 口径：147 是 `architecture_hard_gates.rtl_binding()` 对 `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk` 的 147-file production identity envelope，不是“147 个可达 module”。独立 [elaboration receipt](/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-registry-elaboration-current.json) 为 `source_count=128`、`reachable_instance_count=196`、`status=PASS`。因此 147-file 冻结身份与 128-source elaborated cone 不冲突。

- BPU/FP reachability：NpcTop elaboration 明确包含 `OooBranchDirectionPredictor`、`OooBranchBpuUpdateGate`、`OooBranchSpecTracker`、`OooRasStack`、`OooRasUpdateGate`；FP 路径包含 `OooFpDecode`、`OooFpBackend`、`OooFpArithGate`、FP issue/register/classify/compare/convert/long-op/div-sqrt/sgnj 子实例。BPU 位于 `NpcTop.u_core.u_ooo_core.u_frontend`，FP 位于 frontend decode 及 execute backend 的 `u_fp_backend` 路径；不存在从功能综合身份遗漏 BPU/FP 的证据。

- TB/系统证据：[testbench Makefile](/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/Makefile) 哈希为 `317c3b7e08ff9d31d5e052f6cbf0009c95d5ff0d56cae7432fffa1484c557120`，当前 `TESTS` 赋值精确 114 项，114/114 均有绑定编译/仿真日志。L1 为 official 177/177、AM 61/61、DiffTest mismatch=0；ACT4 为 attempted/passed 100/100、failed/skipped/assertions=0。L2 为 9,897,206 cycles、6,095,067 commits，L3 为 57,143,074 cycles、24,432,533 commits，均 PASS 且零报告 RTL assertion。live receipt 哈希分别为 layered `d4b3f5c7…ff84`、system `360ae1e8…d2b5`、ACT4 `a4d8bf68…c892`，与候选链一致。

- 架构债务：[architecture-debt-current.json](/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-debt-current.json) 精确关闭 16 项：`CONTROL-EVENT-G1`、`F0-G1`、`FDG-G1`、`FENCE-G1`、`IFU-ACCESS-G1`、`IFU-AXI-G1`、`IFU-FETCH-G2`、`IFU-TVAL-G1`、`INSTRET-G1`、`MEM-ISSUE-G1`、`MIQ-FLUSH-G1`、`PTW-PMP-G1`、`SERIALIZE-G1`、`STORE-BRESP-G1`、`VECTORED-TRAP-G1`、`XRET-G1`。四项精确 cohort exclusion 为 `A-COHERENCE-G1`、`DEBUG-TRIGGER-G1`、`SFENCE-SINVAL-G1`、`WFI-G1`，分别受单 hart 无 coherent peer、无 advertised debug transport、保守全局失效承诺、WFI immediate-resume hint 产品边界约束；候选与 ledger 对称差为空。

- V9P：[path projection](/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/v9p-current-full-core-path-projection-v1.json) 哈希 `934cf70f…cedf`、状态 PASS。adapter/collector 日志分别以 `99034f37…6072`、`4cb905ab…e3d1` 字节相同；差异仅为 `J2→J4` 并行度。投影明确记录 `dut_rerun_performed=false`、未启动 simulation/synthesis/STA、未重标 direct review、无 ARCH_STABLE/PPA claim。历史反例仍原样保留：C0 retry capture 与 bridge owner retention，C1 对同一 tuple 发出 duplicate terminal，marker 为 `[S2-G1-TCOLL-INGRESS-DUP]`；当前 2/2 baseline、3/3 gate-open mutation 及 1/1 adapter mutation 均支持当前修复。

- Checker-only：L1 execution-equivalence 投影只删除两个命名审计器：`arch_stable_freeze.py` 与 `full_core_functional_evidence.py`；其余 RTL、TB、runner、toolchain、config、workload 均保持 byte-exact、fail-closed。两者由当前审计重新执行。ACT4 checker rebind 另行重放 retained ELF/log，原始 marker 为 `[ACT4-CHECKER-REBIND-D3F3-V1][PASS] cases=100 guest_rerun=0 assertions=0`，没有伪造第二次 DUT 执行。

- PPA 边界：候选保持 `ppa=UNQUALIFIED`、`promotion_eligible=false`、canonical/architecture-feasible seed 为 null。BPU predictor 与 FP arith physical boundary 仍是 non-signoff placeholder，内部 STA、面积和功耗未知；这些属于显式 PPA non-claim，未被提升为 ARCH_STABLE 的 PPA 结论。

`unknowns=[]`、`open_blockers=[]`。保留但不构成当前架构开放项的边界为：不可恢复的历史 V9P bank/owner tuple、未额外运行 collector fatal-removal mutation、BPU/FP 内部活动计数及 mapped PPA 未测。ledger 的 reopen 条件只要求历史源/失败绑定、当前 gate/mutation、当前 L0-L3 身份不漂移；这些条件均满足。

替代解释已排除：147 不能解释为 147 个 elaborated module；V9P 的 `UNKNOWN` 是历史 provenance non-claim，而非当前修复未知；system receipt 的 `whole_architecture=RED` 是 PPA/正式 promotion 状态，不否定 architecture-only freeze。

`scope_extension_request=null`。置信度：高；依据为声明工作区内 live 文件、哈希、canonical receipt 与 checker 语义的独立只读复核。本节点未运行新的 DUT 仿真、综合、STA 或 Python 定向单测，因此没有非预期 schema 字段返回码。所有工程命令已退出，WSL shell ownership 已归还。

[ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] design_id=sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af candidate_sha256=8322170c192f133f2e93f55e69635c13ce6eb84398e74825cbe37769f4a29e2b

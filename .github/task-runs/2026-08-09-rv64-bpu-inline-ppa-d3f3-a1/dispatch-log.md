# Dispatch log

## v9p-current-rebind-independent-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/v9p-current-rebind-independent-review-v1.json`
- contract_sha256: `bd3c1bf2d1745b11bb3961c558d6820407ef88f0ae335d9e2eb3b73371da3b22`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 evidence 文件。
- task_kind: `read-only-review`
- shell_ownership: 由主节点在派发前显式交付；reviewer 完成允许的 `rg`、`sed`、`sha256sum` 批次后归还。

## v9p-current-full-core-path-rebind-review-v2

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/v9p-current-full-core-path-rebind-review-v2.json`
- contract_sha256: `6044f8afe79440af602b8a6f65587d8f4e2d20005aba3e876dcbc44a957beb52`
- state: `candidate-only`
- reason: Windows→WSL 命令层错误展开了 goal 中两个反引号 module 标识符；该 JSON 未派发、不得作为下游证据。

## v9p-current-full-core-path-rebind-review-v3

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/v9p-current-full-core-path-rebind-review-v3.json`
- contract_sha256: `71b0d1619d4af6349eeb195d71a9e494ca03c434bfd700f5bf343c0394f54c89`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 evidence 文件。
- task_kind: `read-only-review`
- shell_ownership: 由主节点在派发前显式交付；reviewer 完成允许的 `rg`、`sed`、`sha256sum` 批次后归还。
- state: `PASS_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/v9p-current-full-core-path-rebind-review-v3.result.md`
- result_sha256: `35aac097b5332bef9d0a335aa70c5e42ca1e24e8b1db7e3ccec0ed90cc602903`
- projection_receipt: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/v9p-current-full-core-path-projection-v1.json`
- projection_receipt_sha256: `7e77424bc8b0e65343b5142b224986d66f37041d7e914e0c0cb80b45bbc8e8d7`
- conclusion: `PASS_PROJECTED_AGGREGATE`; old/new module receipts 不同，114/114 inventory 及 adapter/collector 日志字节相同；未启动仿真/综合/STA。
- shell_ownership_returned: `true`

## d3f3-bpu-inline-mapped-a1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-bpu-inline-mapped-a1.json`
- contract_sha256: `ff7f8ddd921f5cf69a79829a2cd8e229edfdac7831526802d89429be91a6cf6d`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 PPA evidence 文件。
- classifier: `PPA runner`; architecture configuration 与 tooling 已闭合，本节点只运行一次 BPU-inline synthesis/OpenSTA 并比较 A2。
- task_kind: `ppa-analysis`
- output_run: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-inline-a1`
- command: `npc/rv64/eval/ppa/run-traceable-mapped-current.sh --run-dir .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-inline-a1 --evidence-id traceable-d3f3-bpu-inline-a1 --physical-configuration mapped-5ns-bpu-inline-v1 --expected-rtl-design-id sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`
- shell_ownership: 由主节点派发后显式交付；正确命令只执行一次，任何 PASS/GAP/timeout/signal 均不得重试，cleanup 后归还。
- state: `SYNTH_SLICE_PASS_STA_FLOW_GAP_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-bpu-inline-mapped-a1.result.md`
- result_sha256: `1fc17b3d8dcf70eacb8c8c4c3b86eba7c29b3d981298efab84aeff2aa65d7225`
- conclusion: Yosys mapped synthesis PASS；BPU 从 unknown census 移除并映射为 87,601 cells、logic area +283,823.40、sequential area +109,068.96。历史 OpenSTA Tcl 固定要求四宏而拒绝合法三宏投影，故 WNS/TNS/Top40/PPA 保持 GAP。
- cleanup: runtime/netlist 已删除；outer exit=1、wall=2037s、无 signal、未重跑。
- shell_ownership_returned: `true`

## bpu-inline-configurable-sta-tool-fix-v1

- classifier: `WORKER/root-cause tool fix`; 不启动架构师 Agent，原因是 physical configuration 已裁定，本项只修复 runner→Tcl→parser 对 registry 投影的确定性消费。
- evidence: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/bpu-inline-configurable-sta-tool-fix-v1.md`
- evidence_sha256: `d71c00e8eb13192da273ff3d442dda1af4b17d2d857c45124adf880d5843ecce`
- changed: production-owned OpenSTA Tcl/parser；mapped runner；architecture registry 静态合同；定向 tests。
- validation: `bash -n rc=0`; `test_architecture_registry 19/19 rc=0`; 未运行综合/STA。
- state: `IMPLEMENTED_PENDING_INDEPENDENT_REVIEW`

## bpu-inline-configurable-sta-tool-fix-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-inline-configurable-sta-tool-fix-review-v1.json`
- contract_sha256: `a85baa30c0c032621c9e1eea993f51bba12ae9f2963b974a1fd279e30b8aaa44`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、Tcl/parser、测试或 evidence 文件。
- classifier: `read-only reviewer`; physical configuration 已由架构师裁定，本节点只复核三宏 STA 工具修复和 A1 GAP 边界。
- task_kind: `read-only-review`
- shell_ownership: 主节点在派发后显式交付；只执行合同列出的 rg/sed/sha256sum/git diff，不运行 EDA/parser/test、不写文件，完成后归还。
- state: `RETAIN_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-inline-configurable-sta-tool-fix-review-v1.result.md`
- result_sha256: `2c556d24fc28cbdcee4dd327dd6dbea358b8623102734f7e8377056280d6cac2`
- decision: production-owned Tcl/parser、三宏/四宏投影、runner/manifest/stamp 与固定四宏负向静态合同均闭合；无阻断性反例。A1 保持 timing/PPA GAP。
- shell_ownership_returned: `true`

## d3f3-bpu-inline-mapped-a2

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-bpu-inline-mapped-a2.json`
- contract_sha256: `9910bf2874d588ce1d410d93e43b9add4b6f887c207800dcb2bc615e993fa024`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、工具、testbench 或 PPA evidence。
- classifier: `PPA runner`; physical configuration 与 configurable STA 工具均已独立复核，本节点只执行一次新输入身份的 synthesis/OpenSTA。
- task_kind: `ppa-analysis`
- output_run: `.github/task-runs/2026-08-10-rv64-bpu-inline-ppa-d3f3-inline-a2`
- command: `npc/rv64/eval/ppa/run-traceable-mapped-current.sh --run-dir .github/task-runs/2026-08-10-rv64-bpu-inline-ppa-d3f3-inline-a2 --evidence-id traceable-d3f3-bpu-inline-a2 --physical-configuration mapped-5ns-bpu-inline-v1 --expected-rtl-design-id sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`
- shell_ownership: 主节点派发后显式交付；新工具输入下正确命令只执行一次，任何 PASS/GAP/timeout/signal 均不得重试，cleanup 后归还。
- state: `EVIDENCE_PASS_TIMING_PPA_GAP_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-bpu-inline-mapped-a2.result.md`
- result_sha256: `146b296147a7bab98a09793d7bddbbb06fe503748ab618a2a911852e88b4f25a`
- conclusion: v2 d3f3/physical-configuration binding、128-source、三宏+BPU-inline、OpenSTA/Top40 与 cleanup 全闭合；WNS=-50.241458893 ns、TNS=-719693.1875 ns，Top40 40/40 均为 BPU local-PHT internal path，故 evidence PASS、timing/PPA hard gate GAP。
- delta_vs_four_placeholder: cells +87,601；logic area +283,823.40；sequential area +109,068.96；power proxy +0.026 W；WNS -38.691271782 ns；TNS -432228.40625 ns。
- cleanup: runtime_bytes_deleted=1566158238；netlist 未保留；runner/launcher 已结束。
- shell_ownership_returned: `true`

## d3f3-bpu-inline-mapped-a2-independent-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-bpu-inline-mapped-a2-independent-review-v1.json`
- contract_sha256: `8d92cad7e6193edd37846c3ad1779970dd8b38e6eff4f3f8379f449a8807ce93`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、PPA summary 或 raw artifacts。
- classifier: `read-only PPA reviewer`; 只审查 sealed A2 evidence 与 hard-gate 边界，不设计 BPU child split。
- task_kind: `read-only-review`
- shell_ownership: 主节点在派发后显式交付；只执行合同列出的 rg/sed/sha256sum/git diff，不运行 EDA/parser/test、不写文件，完成后归还。
- state: `RETAIN_ROOT_INDEPENDENT_READ_ONLY`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-bpu-inline-mapped-a2-independent-review-v1.result.md`
- result_sha256: `45ca47b612248f9e2d9339a2783f77a7226c9949c153185be24880a1e83a3674`
- decision: sealed status/summary/manifests/raw synth_stat/OpenSTA Top40/traceability/cleanup 与 runner 报告一致；evidence RETAIN，200 MHz timing/PPA 保持 GAP，local-PHT fanout 仅为中等置信度机制假设。
- reviewer_note: 并行子线程槽满，由未执行 A2 runner 的主节点按已校验合同执行只读原始证据复核；未运行 EDA/parser/test、未写 evidence。
- shell_ownership_returned: `true`

## architecture-registry-current-mapped-pointer-bpu-inline-a2

- mapped_summary: `.github/task-runs/2026-08-10-rv64-bpu-inline-ppa-d3f3-inline-a2/evidence/traceable-d3f3-bpu-inline-a2/summary.json`
- action: 更新 registry 的可变 current evidence pointer；不修改 d3f3 RTL identity、physical configuration 或已封存 summary。
- render_check: `[RV64-ARCH-REGISTRY][PASS] snapshot=sha256:99999a55954386713c793ee81a999e9883b2a23b30d6ba607a0ddb9acd3717cf files=141 structural=PASS product=GAP`
- single_entry: `npc/rv64/ARCHITECTURE.md`
- state: `CURRENT_POINTER_BOUND_PRODUCT_GAP`

## bpu-local-pht-production-child-split-architecture-v1

- route_packet: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/bpu-child-split-architect-route-v1.json`
- router_result: `ARCHITECT`; reasons=`LOCAL_RV64_OPEN_STRUCTURAL_DECISION, CAUSAL_BASELINE_AND_EVIDENCE_READY, CORRECTNESS_AND_TRADEOFF_OBJECTIVES_PRESENT`; execution=`SINGLE_PASS`; review=`INDEPENDENT`。
- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-production-child-split-architecture-v1.json`
- contract_sha256: `46da7f0603bbf2c744ffa7f2ad1465c82fc4eec274f0b59cc9b3399584941c60`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec 或 PPA evidence。
- classifier: `ARCHITECT`; 对象是 BPU state/read/update/recovery 的开放结构边界与 CPI/timing/area/complexity 取舍，不是局部脚本、复验或既定实现。
- task_kind: `read-only-review`
- shell_ownership: 主节点派发后显式交付；只执行合同列出的只读命令，不运行仿真/综合/STA/test、不写文件，完成后归还。
- state: `candidate-only-not-dispatched-to-completion`
- reason: render 提示最后一行被主节点手工复制为 `PASS/GAP 范围`，与 canonical render 的 `范围` 不逐字一致；节点立即中止，v1 不得作为下游证据。

## bpu-local-pht-production-child-split-architecture-v2

- route_packet: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/bpu-child-split-architect-route-v1.json`
- router_result: `ARCHITECT`; execution=`SINGLE_PASS`; review=`INDEPENDENT`。
- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-production-child-split-architecture-v2.json`
- contract_sha256: `b8c7f1be25da0b2671af46d5f415ce9cb5d697f0e0842d8c600a453b8f4d4875`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec 或 PPA evidence。
- classifier: `ARCHITECT`; v2 取代提示漂移的 v1，技术范围不变。
- task_kind: `read-only-review`
- shell_ownership: 主节点派发后显式交付；只执行合同列出的只读命令，不运行仿真/综合/STA/test、不写文件，完成后归还。
- state: `FIX_RETURNED_RETAIN_ONE_CANDIDATE`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-production-child-split-architecture-v2.result.md`
- result_sha256: `4c54e261c696b957d7f314bf0d62c27cb7a5bda42efa509ea7d316a9dc2f43e6`
- decision: current whole-inline physical structure FIX/BLOCK promotion；唯一下一候选为 `OooBranchLocalPht` production child + 16×256 explicit bank/write decode，保持 0-cycle dual read、S1/S2 update、RAW/clear/recovery 语义。
- next_config: `mapped-5ns-bpu-local-pht-banked-child-inline-v1`; comparison_parent=`mapped-5ns-bpu-inline-v1`。
- independent_review_required: `true`（router risk=high）。
- shell_ownership_returned: `true`

## bpu-inline-physical-configuration-implementation-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-inline-physical-configuration-implementation-v1.json`
- contract_sha256: `9d1a8b6dc11341e838bf53cd5efbca6b6e915b8cbe73b4d864526dc6f3b13cfa`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 PPA evidence 文件。
- classifier: `WORKER/development`; 架构边界已由前一 ARCHITECT 节点裁定，本节点只实现 registry/schema/tool/runner/tests。
- task_kind: `implementation`
- shell_ownership: 由主节点在派发后显式交付；节点只修改合同声明的五个路径，只运行一次 `bash -n` 和一次定向 unittest，不运行综合/STA。
- state: `PASS_RETURNED_AND_ROOT_REVIEWED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-inline-physical-configuration-implementation-v1.result.md`
- result_sha256: `15da4c203fc1d815a442d73350fdf1c5d0ef0cf4331e15ba893d76c7a5a6ac6d`
- worker_validation: `bash -n rc=0`; `test_architecture_registry 17/17 rc=0`; A2 summary unchanged；未运行 EDA。
- root_review_delta: parameters 新增 run-start policy/configuration/projection hash；binding 独立校验 raw `synth_stat` census 与 synthesis receipts；runner preflight 校验 live RTL design-id。
- final_validation: `bash -n rc=0`; `test_architecture_registry 18/18 rc=0`。
- shell_ownership_returned: `true`

## bpu-inline-physical-boundary-architecture-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-inline-physical-boundary-architecture-review-v1.json`
- contract_sha256: `b41daa736bba267973b4107f877f124fa3418222f8ecfe77385f005d870f7a29`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 PPA evidence 文件。
- classifier: `ARCHITECT`; 原因是本节点裁定 BPU predictor 的 registry-owned physical configuration identity、映射边界与回滚策略，而非运行 EDA 或修改局部 RTL。
- task_kind: `read-only-review`
- shell_ownership: 由主节点在派发后显式交付；节点仅执行合同内 rg/sed/sha256sum/git diff，只读完成后归还。
- state: `FIX_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-inline-physical-boundary-architecture-review-v1.result.md`
- result_sha256: `6b13d99344b5535143c6e94b0192042cac76a933a5bdc0fc4e06017162496e85`
- decision: A2 四宏 baseline RETAIN；registry-authorized physical variant 为唯一推荐 FIX；直接修改 canonical boolean 与非绑定 runner 均 BLOCK。
- shell_ownership_returned: `true`

## d3f3-mapped-macro-boundary-baseline-a1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-mapped-macro-boundary-baseline-a1.json`
- contract_sha256: `40944a84d10e3db275fb5ecbe742d9d0c31f64a49ed9a7209ce7def2b9748a5c`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 PPA evidence 文件。
- task_kind: `ppa-analysis`
- output_run: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-mapped-baseline-a1`
- shell_ownership: 由主节点在派发后显式交付；节点只执行合同中的一次 mapped synthesis/OpenSTA bash 入口，完成、GAP、signal 或异常时清理 runtime 并归还。
- state: `GAP_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-mapped-macro-boundary-baseline-a1.result.md`
- result_sha256: `c432fd4b16dee17a286b6984eb7c2b055493f32e719f6c4a4109c2040209afcb`
- conclusion: Yosys/OpenSTA/parser/Top40 完成，WNS=-11.550187111 ns、TNS=-287464.78125 ns；唯一流程失败为 `binding_rc=2`，由 duplicate `filelist.mk` 与相对 runner 路径造成；原 run 不重写、不重跑。
- cleanup: `runtime_bytes_deleted=1470889796`; `cleanup_rc=0`; netlist 未保留；WSL shell ownership 已归还。

## d3f3-mapped-macro-boundary-baseline-a2

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-mapped-macro-boundary-baseline-a2.json`
- contract_sha256: `e5df0829f91030578798938fd27b1253ccdb14b5c9d3c02b78b2d50ecdc05239`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 PPA evidence 文件。
- task_kind: `ppa-analysis`
- output_run: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-mapped-baseline-a2`
- command: `npc/rv64/eval/ppa/run-traceable-mapped-current.sh --run-dir .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-mapped-baseline-a2 --evidence-id traceable-d3f3-macro-boundary-a2`
- shell_ownership: 由主节点在派发后显式交付；节点只运行上述一次 mapped synthesis/OpenSTA 入口，正确命令返回 PASS/GAP/信号后均不得重试，并在 cleanup 后归还。
- state: `EVIDENCE_BASELINE_PASS_TIMING_GAP_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/d3f3-mapped-macro-boundary-baseline-a2.result.md`
- result_sha256: `d5c960d382bca33d6f4501390dcf3640fba2b4a10672877723ca928a57985352`
- conclusion: summary 精确绑定 d3f3；128-source、四类 placeholder、manifest before/after、Top40 与 cleanup 闭合。WNS=-11.550187111 ns、TNS=-287464.78125 ns，故 evidence baseline PASS、5 ns timing/PPA hard gate GAP。
- a1_a2_delta: mapped netlist SHA/size、source manifest、area/timing/power、Top40、traceability 全部 bit-identical；只修复 manifest duplicate/non-canonical identity，`binding_rc=2→0`。
- shell_ownership_returned: `true`

## arch-stable-d3f3-v11-independent-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/arch-stable-d3f3-v11-independent-review-v1.json`
- contract_sha256: `3933510e15ec24bf2d17e88c3520e3e7ee89d2f0262479a47165b193f1810bb1`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 evidence 文件。
- candidate: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/arch-stable-current-d3f3-v11/candidate.json`
- candidate_sha256: `8322170c192f133f2e93f55e69635c13ce6eb84398e74825cbe37769f4a29e2b`
- task_kind: `read-only-review`
- shell_ownership: 由主节点在派发后显式交付；reviewer 完成允许的 `rg`、`sed`、`sha256sum` 批次后归还。
- state: `APPROVE_ARCH_STABLE_RETURNED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/arch-stable-d3f3-v11-independent-review-v1.result.md`
- result_sha256: `b9cc6b687ee7bbb79500dffd1ce9b55be2c771c7f7e1f07750813e7b8d2a3cce`
- independent_review_receipt: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/arch-stable-current-d3f3-v11/independent-review.json`
- independent_review_receipt_sha256: `dfbe591c722af39f27174400719260255a1e391b6dc498547d41f0d04eb949d4`
- final_audit: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/arch-stable-current-d3f3-v11/final-audit.json`
- final_audit_sha256: `ad44793fe3523c018cfc63906c44228ab3bffc19bcbd85346424dbcfe9e2aff7`
- conclusion: `ARCH_STABLE`; `ppa=UNQUALIFIED`; `promotion_eligible=false`; 147-file production identity 与 128-source/196-instance elaboration 分层闭合，BPU/FP current reachability 已纳入。
- shell_ownership_returned: `true`

## bpu-local-pht-production-child-split-independent-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-production-child-split-independent-review-v1.json`
- contract_sha256: `b0e52bcd58eda350ea0524a288870a4956663fd8e53a6a75cc2fc9ee7354d85b`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench 或 PPA evidence 文件。
- classifier: `REVIEWER/read-only-review`; 高风险架构候选已由 ARCHITECT 形成，本节点独立攻击 bank/row、双读/写冲突、RAW、clear/recovery、logic sharing、OOC 合取与 retain/rollback，不产生新实现。
- task_kind: `read-only-review`
- shell_ownership: 主节点派发时显式交付；节点仅执行合同列出的 rg/sed/sha256sum/git diff，不运行仿真/综合/STA/parser/test、不写文件，结束后立即归还。
- state: `FIX_RETURNED_INLINE_EXPERIMENT_AUTHORIZED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-production-child-split-independent-review-v1.result.md`
- result_sha256: `9d48e90f033fe0155122ed923a4476a0ab28ef4d130dfdf99e928b9cede21e7e`
- decision: 16×256 bank/row 与 current RTL 周期语义成立，但 current candidate 工件与覆盖不存在；只授权一次可逆、全 inline 的因果实验，禁止提前登记 RETAIN/Pareto/OOC。
- implementation_constraints: bank-local S1 `taken/old_ctr`；0-cycle 双读；冻结 S1/S2、RAW、clear、mispredict train/no-restore；先补 directed TB、compile-success mutation、registry identity，再运行一次绑定 PPA。
- shell_ownership_returned: `true`

## bpu-local-pht-banked-child-inline-implementation-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-banked-child-inline-implementation-v1.json`
- contract_sha256: `be6c9c15ac30941cb4eafc742310771af5679ea56636b4b8f18f0154fa9e1a5d`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 RTL、spec、testbench、mutation 或 registry evidence。
- classifier: `WORKER/implementation`; 架构开放决策与独立反例审查已完成，本节点只实现已裁定的可逆 child-inline 实验及其定向门禁，不再启动 ARCHITECT。
- comparison_parent: `mapped-5ns-bpu-inline-v1`
- candidate_configuration: `mapped-5ns-bpu-local-pht-banked-child-inline-v1`
- task_kind: `implementation`
- verification_policy: 选中的 child TB、parent TB、mutation、registry unittest、render/check 各在静态自审后最终执行一次；不运行综合/STA或全量回放，不把未测 PPA 写成改善。
- shell_ownership: 主节点派发时显式交付；节点只使用合同列出的命令和写路径，完成或 GAP 后停止全部工程命令并归还。
- state: `IMPLEMENTED_FUNCTIONAL_PASS_MUTATION_ORACLE_GAP`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/bpu-local-pht-banked-child-implementation-v1/result.md`
- result_sha256: `ed7cfb4fba912d26c3b89ae5a465e6ddc3d9318efc43118e88a5f628e9d0c49c`
- observed: child TB rc=0；parent TB rc=0；11/11 mutations compile-success、9/11 exact-marker rejected，mutation target rc=1；registry unittest 19/19、render/check 与 scoped diff check rc=0；未运行 synthesis/STA。
- live_design: `sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e`
- registry_snapshot: `sha256:d80839220f8f1899484ec32f2cb2e4f6ae423a973099982d604a8ef4c6e4831a`; old d3f3 mapped evidence=`GAP_STALE_DESIGN`。
- shell_ownership_returned: `true`

## bpu-local-pht-banked-child-inline-implementation-review-v1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-banked-child-inline-implementation-review-v1.json`
- contract_sha256: `1286e9d3a69736ec9ea5108549f6b69d77a59bc22f7b897852f452576123b697`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 current RTL/TB/mutation/registry 或 evidence。
- classifier: `REVIEWER/read-only-review`; worker 已完成实现但 mutation receipt 为 9/11 exact-marker GAP，本节点独立攻击实现与 oracle，不产生新架构或修改。
- task_kind: `read-only-review`
- shell_ownership: 主节点派发时显式交付；仅执行合同内只读命令，不运行测试/仿真/综合/STA、不写文件，结束后归还。
- state: `FIX_RETURNED_MINIMAL_A2_AUTHORIZED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-banked-child-inline-implementation-review-v1.result.md`
- result_sha256: `cf3f1a189230e6705e7f644ecc8a597114fe4adf5c96454e20cf2882fd35b4bf`
- decision: 功能 RTL RETAIN；current evidence/PPA promotion BLOCK。最小A2补不同-bank已训练双读、两项strong-marker精确oracle与`==1`计数、task-owned结果路径、配置级keep-hierarchy/share负向门；不改OooFrontend或预测周期。
- shell_ownership_returned: `true`

## bpu-local-pht-banked-child-inline-oracle-a2

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-banked-child-inline-oracle-a2.json`
- contract_sha256: `28f819cf4066a13a7b381b6fe391ed95efba34ca5eab3c5cf13a9a7f3ca8907e`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定 TB/runner/registry 或 A2 evidence。
- classifier: `WORKER/implementation`; 独立review已给出闭合修订，A2只修oracle、directed coverage与physical-config hierarchy投影，不启动ARCHITECT、不改功能RTL。
- task_kind: `implementation`
- verification_policy: changed child TB、11项mutation、registry unittest、render/check、scoped diff各最终执行一次；复用未改parent正向TB收据，不重复运行，不执行synthesis/STA。
- output: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/bpu-local-pht-banked-child-implementation-a2`
- shell_ownership: 主节点派发时显式交付；完成或GAP后停止所有工程命令并归还。
- state: `A2_PASS_FUNCTIONAL_ORACLE_REGISTRY_PPA_UNMEASURED`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/bpu-local-pht-banked-child-implementation-a2/result.md`
- result_sha256: `4c00f9442d61a02fad98ff92ed434da1fcfd2ae94ae47b8afcb15f2c09e3cd19`
- observed: changed child TB rc=0；11/11 compile-success mutation、unique marker、raw-log binding PASS；registry unittest 19/19、render/check、scoped diff rc=0；parent正向TB未重复；未运行synthesis/STA。
- live_design: `sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e`
- registry_snapshot: `sha256:ed0aa8580b8b98ac9737415883c3105745b475b482a690f251b4002c70839b7a`; old d3f3 mapped evidence=`GAP_STALE_DESIGN`。
- next_gate: 新run-id下仅一次`mapped-5ns-bpu-local-pht-banked-child-inline-v1` traceable synthesis/OpenSTA；验证16 bank-local S1结构、旧集中Top40族、WNS/TNS/area delta，不预设改善。
- shell_ownership_returned: `true`

## bpu-local-pht-banked-child-ppa-b279-a1

- contract: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-banked-child-ppa-b279-a1.json`
- contract_sha256: `d54d28961f6326520904f58eb0e0f900af247d9458df4e020c340271fe0a5ff2`
- binding: 上述 SHA-256 只绑定该 JSON 契约，不绑定本次待生成 mapped evidence。
- classifier: `PPA_RUNNER/ppa-analysis`; 功能结构与oracle已闭合，本节点只执行一次固定live-b279 mapped synthesis/OpenSTA并量化因果delta，不启动ARCHITECT、不改输入。
- command: `npc/rv64/eval/ppa/run-traceable-mapped-current.sh --run-dir .github/task-runs/2026-08-10-rv64-bpu-local-pht-banked-child-ppa-b279-a1 --evidence-id traceable-b279-bpu-local-pht-banked-child-a1 --physical-configuration mapped-5ns-bpu-local-pht-banked-child-inline-v1 --expected-rtl-design-id sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e`
- run_policy: fixed command exactly once；任何PASS/GAP/exit/signal/timeout均不重跑；cleanup与sealed evidence后只读核验。
- output: `.github/task-runs/2026-08-10-rv64-bpu-local-pht-banked-child-ppa-b279-a1`
- shell_ownership: 主节点派发时显式交付，runner/只读核验完成后归还。
- state: `EVIDENCE_PASS_ROLLBACK_AREA_GATE_PPA_GAP`
- result: `.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/bpu-local-pht-banked-child-ppa-b279-a1.result.md`
- result_sha256: `c3b4ae16e511a62718e28ca3909666e3447f3cceec9b3ac1bd44f21690b7878f`
- summary_sha256: `fc752a737d3b05edd8ff9f4fe6c94af4b324357bb2857c6c2ea8f7984b62d802`
- observed: runner一次rc=0；receipt/binding/cleanup PASS；1 predictor+1 child+16 banks非零映射；旧40/40 BPU path族移出Top40；WNS=-11.550187111、TNS=-308193.40625、area=2468670.96、relative power=0.160W。
- delta_vs_whole_inline: WNS +38.691271782ns；TNS +411499.78125ns；area +3069.64；power -0.002W。
- decision: 预冻结门要求WNS/TNS/area全部严格改善；面积两项门均超3069.64，因此ROLLBACK，正式PPA=GAP。候选保留为noncanonical engineering archive，等待ARCHITECT裁定是否形成下一面积削减variant。
- cleanup: deleted=1545958874 bytes；netlist retained=NO；netlist SHA=`f387624c73834d5773b8f78568a92859f23c9a14b05d40f89639774f2d07e25e`。
- shell_ownership_returned: `true`

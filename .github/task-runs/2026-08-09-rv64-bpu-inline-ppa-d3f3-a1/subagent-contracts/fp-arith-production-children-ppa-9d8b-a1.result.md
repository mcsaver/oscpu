# FP arithmetic production children mapped PPA 9d8b A1

RV64 RTL 结论｜对象=`NpcTop` / `OooFpArithGate` production-child mapped run `.github/task-runs/2026-08-10-rv64-fp-arith-children-ppa-9d8b-a1`｜周期/配置=5.0 ns、`mapped-5ns-fp-arith-production-children-inline-v1`、design=`sha256:9d8bb6af…`｜TB/EDA 观测=唯一 runner 在 synthesis 内部 5400 s 边界自然终止，`synth_rc=1`；OpenSTA/parser/binding 未运行｜范围=GAP

Preflight 已绑定当前 design、configuration/profile、134-source manifest、三类 placeholder 与 FP wrapper+五 child inline/keep-hierarchy 输入。唯一 invocation 未重跑。宿主 60 分钟客户端超时后，原 PID 486317 与 Yosys/ABC 子树继续同一次运行；主节点拒绝 destructive recovery，最终由 runner 内部 timeout 自然退出并执行自身 cleanup。

终态：`FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`。`command-status.txt` 为 `preflight=0 manifest=0 synth=1 opensta=1 parser=1 trace=1 binding=2 cleanup=0`；exact runtime base 与冻结进程集合均 absent。仅有 before manifest、parameters、source manifest、bounded synth console 与 binding-failure log；无 after manifest、`synth_stat`、OpenSTA、FP inventory、summary 或 binding JSON。

因此 wrapper/五 child exact-one、cells/area、negative slack、internal paths、WNS/TNS、Top40、power 和 four-placeholder delta 全部 unknown；physical 状态保持 `UNMEASURED_UNPROMOTED/GAP`。参数中的 inline/keep 列表不是 mapped hierarchy 证据。

关键 SHA-256：status=`f923a8ae87f26025bdec54301bf96013c31c323228a3c04f266705cfb5a4fe5e`；command-status=`d569048290fb9d403f21c2568e55b18da9e4389d83101b84c3bc3da59d62bc37`；synth-console=`c5dd8022e3a6c0b941eaf23a3be07c027c33ab4d50ee5e8ee2e2626598680545`；sources=`31461879c39a5190c6a59d9ba2073d92f5ebd4f3ddd45e0fe2f71ca532c3450d`；before-manifest=`0a5770ce5894b85cb1ec602e3a9ea524541917046a26e2aee175c46ced80f6da`。

`unknowns`：综合超时的具体 child/cone、是否只需更多 ABC 时间、真实 FP physical metrics。`alternative_hypotheses`：大规模 FMA/rounding logic 导致 ABC 爆炸；keep-hierarchy selection warning 可能只是 pass 时点而非 module 缺失。下一步必须由架构师在完整物理边界方案中裁决，不能复用本 run-id。

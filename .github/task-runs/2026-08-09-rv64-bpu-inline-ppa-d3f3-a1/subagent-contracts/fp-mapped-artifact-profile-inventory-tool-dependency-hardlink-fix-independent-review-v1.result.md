# FP mapped artifact profile tool dependency/hardlink fix independent review

RV64 RTL 结论｜对象=`NpcTop` FP mapped tool v4、`result-identity-v4.json`、`traceable_mapped_sta.py` 与 production runner｜周期/配置=5.0 ns、`mapped-5ns-fp-arith-production-children-inline-v1`、profile=`fp-arith-children-v1`｜TB/EDA 观测=只读复核封存的 6-test/generate/validate/verify PASS；本审查未运行测试、仿真、综合或 OpenSTA｜范围=GAP

独立裁决：**RETAIN 工具链。** 解除工具阻断，仅授权一个全新 run-id 的单次 5.0 ns `NpcTop` mapped run；不得据此宣称 PPA PASS。

- v4 result SHA-256=`bedcaeaf2c64258fc014881edd4fba58a93be0c77a7ac2d5177e47461523e787`。
- detached receipt SHA-256=`2bf6d46dc88a5c21ef460ad290949d70577b09cf7e7e07632d4c538700675805`，receipt ID=`sha256:66832e3192f7e121784bcf9e9303cf7a50a2c4cb9af871592b7fcd0cb349b3a4`。
- Registry catalog/schema/tool、result schema、generator、v4 contract 的 path/size/SHA 均与 result、receipt 和 sealed input manifest 一致；generator 要求 bound `architecture_registry.py` 精确等于运行时 import 文件。
- BPU/FP hardlink 负向测试均使用 `Path.hardlink_to()` 后调用真实 `parse_mapped_profile_evidence()`；`st_nlink==2` 被拒，唯一 inode 正向通过。
- runner 从 `pwd -P`、canonical task-run root 与受限 run-id 构造绝对 `evidence_dir`；创建后通过 `realpath -e`、absolute/non-alias/non-symlink 门，并把同一值传给 parser `--out-dir`；parser、trace、cleanup、after-manifest 与 Registry binding 全部进入最终 PASS 合取。
- v1 `d1edad…` identity error、v2 dependency/hardlink GAP 与未派发 v3 semantic-distortion contract 均可追溯。

未知项：真实 FP mapped cells/area、negative slack、internal timing path 与功耗仍未测量；状态继续 `development/UNMEASURED/GAP/noncanonical/nonchampion`。`scope_extension_request=None`。工具身份与静态调用链置信度高，物理 PPA 无测量置信度。

审查合同 SHA-256=`6ae7f97435f4aed6bccc790e39a1eef02c3807ba1784e43e20c3fd81ad753ea5`。全部只读命令独立执行，无未转义管道/command substitution；无写入或残留工程进程。

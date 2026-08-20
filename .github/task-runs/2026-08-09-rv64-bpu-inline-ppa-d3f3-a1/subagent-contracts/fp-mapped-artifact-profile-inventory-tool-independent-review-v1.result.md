# FP mapped artifact profile inventory tool independent review v1

RV64 RTL 结论｜对象=`NpcTop` mapped artifact profile 工具链及 `fp-mapped-artifact-profile-inventory-tool-v1/result.json`｜周期/配置=5.0 ns、`mapped-5ns-fp-arith-production-children-inline-v1`、profile=`fp-arith-children-v1`｜TB/EDA 观测=既有最终 unittest 39/39 PASS；本审查仅执行合同内只读命令，未运行 Python/仿真/综合/OpenSTA｜范围=GAP

独立裁决：**FIX；修复前 BLOCK 新 production run-id。**

## 承重反例

封存 `result.json` 把 `physical_configuration.configuration_id` 错写成 profile `fp-arith-children-v1`。Registry 的真实配置 ID 是 `mapped-5ns-fp-arith-production-children-inline-v1`，两者不是别名。现有 39-test/final gate 不消费该结果对象，因此错误身份可以与 `[FP-MAPPED-ARTIFACT-PROFILE-INVENTORY-TOOL][FINAL-PASS]` 同时存在；`result.sha256` 只绑定错误内容，不能修复语义。

## 可保留实现

- Registry/schema 分离 configuration ID、profile、projection/hash；runner 把同一 profile 传入 Tcl、parser、stamp 与 binding。
- Tcl 只生成选中 family，parser 要求实际 artifact family 与 profile 精确一致。
- `report_checks -path_delay max -from $fp_pins -to $fp_pins -group_path_count 10 -sort_by_slack -digits 9` 与既有真实 OpenSTA 报告语法/块格式相容；真实 FP 查询尚未执行，缺路径时必须 fail closed。
- `synth_stat` 的 module heading、父子 `<count> - <module>`、cells/area、unknown-area 正则与三份历史真实 Yosys 产物相容；FP exact-one wrapper/五 child 仍只有 synthetic fixture。
- production synthesis/OpenSTA/STA、真实 FP census/path/PPA 均未运行，状态必须保持 `UNMEASURED/GAP`。

## 必需修复

1. 用 canonical generator 从 Registry 生成 tool result，完整 configuration ID 与短 profile 分字段保存。
2. 为 result 增加 machine-checkable schema/validator；将 configuration ID 改成 profile 时必须非零失败。
3. final gate 必须消费最终 result，并生成绑定 result/schema/Registry SHA 的 detached validation receipt。
4. OpenSTA artifact receipt 路径必须精确位于当前 `evidence_dir`，加入跨目录重放负向测试。
5. 只运行受这些新输入影响的定向测试/身份 gate；不重复既有 runner `bash -n`、无关测试或 production EDA。

合同 SHA-256：`364f5a2326b4d6a4c9c6df70faa5011680290c196c5170112865886f00a0ea32`。原错误 `result.json` SHA-256：`d1edadb0b273c1937acc482a119dbfd93b167d1647450ccd5f41b5b415ce58f3`。

`unknowns`：真实 FP internal path、negative slack、mapped cells/area 与生产 binding 尚未观察。`scope_extension_request`：建立 versioned 工具修复合同，修复后方可另建一次性 EDA 合同。`confidence`：身份反例与测试缺口高；静态工具调用链高；生产物理证据无。

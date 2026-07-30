# V9R current-source rebind independent review v1

RV64 RTL 结论｜对象=`OooIntBackend`/`OooMemAxiBridge` SQ-query retry C0 与
CONTROL-EVENT-G1 publisher/currentness 证据链｜周期/配置=当前 design-id、
V9R focused、V9O current-source｜TB/EDA 观测=V9R 2/2 PASS、3/3 变异拒绝，
但任务包内 48 项测试为 47/48 且缺少工作流单测 receipt｜范围=GAP

独立审查发现三个记录层 blocker：

1. `update-current-debt-ledger.py::verify_serialize_entry()` 运行 canonical
   verifier，但没有逐项核对 ledger 的 candidate/contract/review
   `entry.evidence` 三元组；publisher 可把非 canonical evidence 重新哈希后
   写回。
2. `arch-stable-currentness-tests.log` 显示 `Ran 48 tests`、
   `FAILED (failures=1)`，配套 `.rc=1`；fail-fast 后 12 项工作流单测没有
   执行，也没有 PASS receipt。
3. `finalize-postflight.py` 没有消费上述 receipt，仍可发布
   `postflight.result=PASS`。

合同还漏列 `npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv`，因此 v1
不能独立审阅 bridge raw oracle。production RTL 哈希、V9R 2/2 与 3/3、
V9O 167 项 index、16/38/32/0 currentness 声明和 SERIALIZE 当前三元组
哈希本身均得到确认，但不足以消除上述假绿通路。

裁决：`GAP`。要求修复 exact tuple 校验，加入 missing/extra/remapped
负向单测，让 postflight 强制消费 48 项与 task-local receipt，并用包含
bridge TB 的新合同重审。

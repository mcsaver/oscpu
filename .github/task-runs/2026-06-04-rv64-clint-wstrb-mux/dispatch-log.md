# 2026-06-04 RV64 CLINT wstrb mux 派发日志

## 节点图

| node_id | owner_agent | depends_on | inputs | outputs | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- |
| recall | Codex | - | `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、RV64/RTL 规则 | 约束摘要 | 明确 RTL 四段式、验证和记录要求 | 补读相关 instruction |
| select-module | Codex | recall | `NpcSimTop/NpcTop` 实例链、RTL loop 扫描 | 选择 `AxiLiteClint` | 目标在仿真顶层实例链内且有明确仿真式 byte loop | 若范围过大则退到更小 bus 设备 |
| rtl-derive | Codex | select-module | `AxiLiteClint.v`、`tb_axi_lite_clint.sv` | 四段式 RTL 推导 | 写清需求、协议、状态机、不变量、数据通路约束 | 发现协议不清则先补 test |
| implement | Codex | rtl-derive | CLINT byte merge 函数 | RTL + TB patch | 去掉函数内 `for/integer` byte merge，保留 32/64-bit 语义 | 回退到局部 helper 并保留测试 |
| verify | Codex | implement | focused TB、lint、build、OpenSBI smoke | 命令证据 | focused、lint、build、smoke 全部 PASS | 失败则按日志定位 root cause |
| record | Codex | verify | diff 与验证输出 | memory + task-run | 长期结论和边界落盘 | 若记录冲突则先以源码/输出为准修正 |

## 执行记录

- 读取工程规则与 RV64/RTL 约束，确认本轮必须按 `需求 -> 协议规则 + 状态机 + 不变量 + 数据通路约束 -> RTL` 推进。
- 扫描 `npc/rv64/vsrc` 的仿真式写法，选择 `NpcTop` 实例链中的 `AxiLiteClint` 作为 UART 后的下一个总线设备收敛点。
- 修改 `AxiLiteClint.v`：删除 `apply_wstrb/apply_wstrb32` 和两个函数内 byte loop，新增 64-bit write data/strobe padding、8-lane aligned merge、4-lane high-word merge。
- 修改 `tb_axi_lite_clint.sv`：新增 AW/W 分拍写 task，覆盖 AW-first 与 W-first；新增 64-bit `*_HI` offset 写低 lane 和高 lane 忽略用例。
- 验证通过：
  - `rg -n "for\\s*\\(|integer\\s+\\w+" npc/rv64/vsrc/bus/AxiLiteClint.v` 无输出。
  - `make -C npc/rv64/testbench TESTS="tb_axi_lite_clint" run` PASS。
  - `make -C npc/rv64/testbench TESTS="tb_axi_lite_clint tb_ooo_priv_system" run` PASS。
  - `make -C npc/rv64 lint` PASS。
  - `make -C npc/rv64 -j2` PASS。
  - `make -C Linux/tools smoke-opensbi` GOOD TRAP，且 `CLINT mtime = 4847043 (mtime-cycles=+0, match=yes)`。

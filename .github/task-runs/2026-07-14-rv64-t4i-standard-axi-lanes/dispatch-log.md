# 派发日志

## 基本信息

- `task_id`: 2026-07-14-rv64-t4i-standard-axi-lanes
- `task_slug`: rv64-t4i-standard-axi-lanes
- `graph_template`: custom
- `log_policy`: append-only

---

### [2026-07-14 09:00] `contract-and-root-cause` - completed

- `owner_agent`: /root
- `trigger`: LSU split、device lane 与 B-response 精确性尚未闭合。
- `depends_on`: T4A–T4H frontend/PMP/PMA 切片。
- `inputs`: LSU→bridge→xbar→slave 调用链、AXI4 lane/size 规范、既有定向 TB。
- `action`: 将私有 exact-address/low-window 行为拆为 LSU 边界适配与全总线标准 lane 合同。
- `outputs`: adapter、AWSIZE/ARSIZE owner 合同、设备与 DPI 边界规则。
- `evidence`: 设计 specs、RED/GREEN TB。
- `handoff_to`: implementation
- `next_step`: 实现并闭合 AW/W/B 状态机。
- `notes`: 禁止以症状级 lane shift 或忽略 B error 作为修复。

### [2026-07-14 13:00] `implementation` - completed

- `owner_agent`: /root
- `trigger`: root cause 与数据流已冻结。
- `depends_on`: contract-and-root-cause
- `inputs`: RTL/C++/C/eval harness。
- `action`: 新增 standard-lane adapter，贯通 AWSIZE，设备/DPI 标准化，store 等待 B，修复 eval 计数与 benchmark 判定。
- `outputs`: 当前 source tree 与定向 tests。
- `evidence`: module logs、lint、DPI sized log。
- `handoff_to`: functional-regression
- `next_step`: 运行全模块、整机、benchmark。
- `notes`: `NpcSimTop` 删除 Verilator 不支持的 PROCASSINIT lint pragma，但保留寄存器初始化语义。

### [2026-07-14 17:00] `functional-regression` - completed

- `owner_agent`: /root
- `trigger`: 定向测试通过。
- `depends_on`: implementation
- `inputs`: 当前仿真 binary、137 个 RTL/C++ 源。
- `action`: 全模块、official/privileged、AM、CoreMark、Dhrystone 10000-run、DPI sized 回归并做 source/binary binding audit。
- `outputs`: `evidence/functional-*`、`evidence/axi-dpi-sized.log`。
- `evidence`: 100/100、177/177、59/59、两项 GOOD TRAP、functional audit PASS。
- `handoff_to`: fresh-synthesis
- `next_step`: 从冻结输入 fresh 生成网表。
- `notes`: 默认 500000-run Dhrystone 在 20 分钟内 timeout，未冒充 PASS。

### [2026-07-14 18:30] `fresh-synthesis-and-sta` - completed

- `owner_agent`: /root
- `trigger`: 旧 netlist/STA 不能证明当前 source。
- `depends_on`: functional-regression
- `inputs`: source manifest、Yosys、OpenSTA、H7CL liberty/placeholder macros、5ns SDC。
- `action`: fresh synthesis；pre/post binding；exact setup-member derivation；global top40 STA；mutation-negative；final attestation。
- `outputs`: fresh netlist 与 `evidence/synthesis/`、`evidence/opensta-fresh-t4i-final/`。
- `evidence`: netlist `d7e5263f…e93eac`，40/40 MET，worst `+0.017907454ns`，freeze/binding/attestation PASS。
- `handoff_to`: independent-review
- `next_step`: 审查越级结论、证据假绿与覆盖洞。
- `notes`: WNS/TNS 文本为 0/0，实际最差正 slack 从 raw top40 精确提取。

### [2026-07-14 20:00] `independent-review` - completed

- `owner_agent`: reviewer-agent
- `trigger`: 实现者证据齐备。
- `depends_on`: fresh-synthesis-and-sta
- `inputs`: raw STA/setup/completion、functional logs、checker、synthesis audit。
- `action`: 优先寻找旧网表、负 slack `-0.0`、setup count-only、物理 signoff 越级与测试误计数反例。
- `outputs`: P0=0；确认 proxy closure；列出 IO/endpoint/clock/macro/physical 限制。
- `evidence`: evidence-hardening mutation、functional audit、corrected top stat、final attestation。
- `handoff_to`: archive-and-handoff
- `next_step`: e2e/strict guard、memory、selective stage/commit。
- `notes`: 不允许把 17.907ps proxy slack 描述为物理裕量。

### [2026-07-14 20:36] `archive-and-handoff` - in-progress

- `owner_agent`: /root
- `trigger`: 用户要求 `/tmp` 留档并授权 commit。
- `depends_on`: independent-review
- `inputs`: task evidence、OS `/tmp` 相关对象、dirty worktree inventory。
- `action`: 固化 evidence hashes、更新 DB-backed memory、运行 npc-dev e2e/strict guard，只 stage 本目标文件。
- `outputs`: task report、memory snapshot、workspace `tmp/os-tmp-archive/...`、Git commit。
- `evidence`: 待最终 manifest、e2e report、strict guard 与 staged diff audit。
- `handoff_to`: user
- `next_step`: 完成 guard 和提交。
- `notes`: 原有 dirty `npc-linux.log` 被评测覆盖且无可恢复副本；保持 unstaged并显式披露。

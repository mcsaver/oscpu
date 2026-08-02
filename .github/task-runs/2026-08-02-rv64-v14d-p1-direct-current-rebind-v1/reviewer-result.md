# V14D P1 direct current rebind 独立终审

RV64 RTL 结论｜对象=CONTROL/MIQ/STORE 三门及 8 个关联 RTL｜周期/配置=current design-id `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`，C0→C1、flush+pop、B-terminal/ROB-head｜TB/EDA 观测=21/21 正向、24/24 compile-success RTL 反例、24 个唯一指纹｜范围=PASS

- 当前绑定：三门均绑定同一 current design-id；8 个关联 RTL 的实算 SHA-256 全部匹配 `source-after.json`，before/after snapshot hash 相同。
- 正向证据：CONTROL `16/16`、MIQ `1/1`、STORE `4/4`，合计 `21/21`。
- 反例证据：CONTROL `16`、MIQ `3`、STORE `5`，合计 `24/24`；receipt 中 24 个 `variant_sha256` 无重复，`alias_count=0`。
- warning：CONTROL `2792`、MIQ `4`、STORE `1867`，均能归入精确类别，`unexplained=0`。MIQ 四条均绑定当前 `OooMemInflightQueue.v` 的确切行与数组信号；CONTROL/STORE warning replay 均通过未知 warning、错误端口、错误信号及失配行号的拒绝测试。
- 历史状态：`control-run-{1,2}.status` 与 `store-run-{1,2}.status` 原始 `FAIL rc=1 stage=exit-trap` 均保留；P0 rebind 来源状态也仍为 FAIL，未被当前 PASS 或 checker replay 覆写。
- Section13：`architecture_gate_state=RED`、`arch_stable=false`、`current_stale_count=4`，过期项为 `F0-G1/FENCE-G1/SERIALIZE-G1/VECTORED-TRAP-G1`；`ppa_state=BLOCKED_BY_ARCHITECTURE`、`promotion_eligible=false`。未发现将任务局部 PASS 误提升为架构 GREEN/PPA qualified 的情况。
- 未发现门级 design-id 分裂、计数重复、variant 指纹别名、历史 FAIL 改写、warning 漏归类或 Section13 过度晋级。

限定：合同只允许独立实算 8 个关联 RTL，未重新计算 `source-after.json` 全部 146 文件的聚合 design-id；当前结论依赖快照链与三门 receipt 的一致绑定。warning 的数组类采用“当前源码精确路径/行号/信号”动态匹配，而非冻结行号白名单；这与 replay 自测和证据口径一致。

`scope_extension_request: none`。若要求独立重算 146 文件聚合 design-id，需额外开放其余 snapshot 路径及确定性 design-id checker。置信度：高。终审节点已显式归还唯一 WSL shell ownership。

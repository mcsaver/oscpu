RV64 RTL 结论｜对象=live b279 `NpcTop/OooBranchDirectionPredictor→OooBranchLocalPht→16×OooBranchLocalPhtBank` 与 `.github/task-runs/2026-08-10-rv64-bpu-local-pht-banked-child-ppa-b279-a1/evidence/traceable-b279-bpu-local-pht-banked-child-a1`｜周期/配置=5.0ns、`mapped-5ns-bpu-local-pht-banked-child-inline-v1`、129-source、三类 placeholder、10项 keep-hierarchy｜TB/EDA 观测=唯一一次 traceable Yosys/OpenSTA rc=0、evidence receipt PASS；WNS=-11.550187111ns、TNS=-308193.40625ns、area=2468670.96、40 violations/0 loops｜范围=GAP

独立裁决：**ROLLBACK**。证据生成、身份绑定、映射结构和清理均 PASS；旧的40/40 `update_taken_i→local_pht_q[*]` Top40路径族已从本次inline映射Top40消失，WNS/TNS严格优于d3f3 whole-inline。但候选逻辑面积超过两个预先冻结的硬门，不能RETAIN；正式PPA同样未闭合。

## 单次执行与身份

- 合同SHA-256：`d54d28961f6326520904f58eb0e0f900af247d9458df4e020c340271fe0a5ff2`。
- registry expected/live design均为`sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e`。
- 仅启动一次固定runner，未重跑；约2031.5s，rc=0。
- marker：`[TRACEABLE-MAPPED-CURRENT][PASS] run=2026-08-10-rv64-bpu-local-pht-banked-child-ppa-b279-a1 evidence=traceable-b279-bpu-local-pht-banked-child-a1`。
- `preflight/manifest/synth/opensta/parser/trace/binding/cleanup` rc全0。
- production manifest before/after均为`168e651c891bc9f347ee447baa1e92b9e99c5a516cc7af81815bd0bff983ee34`。
- 129 synthesis sources；predictor SHA=`f56cf84f...3fb4`，child SHA=`1b44443f...225`。
- unknown placeholder精确为`Sram4096x199×1`、`Sram4096x113×2`、`OooFpArithGate×1`。
- keep-hierarchy为基础七项加`OooBranchDirectionPredictor/OooBranchLocalPht/OooBranchLocalPhtBank`。

## 16-bank mapped structure

- `OooBranchDirectionPredictor`：1个，19182 cells，82933.20 area，33356.40 sequential area。
- `OooBranchLocalPht` wrapper：1个，124 cells，290.08 area。
- `OooBranchLocalPhtBank`：bank ID 0–15全存在；每bank 2973 cells、12729.36 area、4804.80 sequential area。
- BPU合计：66874 cells、286893.04 area、110233.20 sequential area。
- BPU cell mix：17895 DFF、5393 ICG、14596 MUX4。

三层均以内联标准单元、非零内部面积和真实mapped arcs可见；timing改善不是通过黑盒隐藏路径获得。

## Top40

- 本次Top40对`branch_direction_predictor/local_pht/u_local_pht/g_bank/update_taken`均无命中；16个bank均无Top40 path。
- 40条startpoint全部来自公开CSR `csr_mtvec_q[63]`；endpoint为`u_mem_owner_terminal_collector` 35条、`u_control_plane` 5条。
- WNS与four-placeholder基线相同，支持集中PHT写锥已移出最坏路径的因果解释。
- 该结论只绑定Top40；不能排除较低排名或未约束路径中仍有等价跨bank高负载。

## 精确delta

| 指标 | b279 16-bank | d3f3 whole-inline | 相对whole-inline | four-placeholder | 相对four-placeholder |
|---|---:|---:|---:|---:|---:|
| WNS (ns) | -11.550187111 | -50.241458893 | **+38.691271782** | -11.550187111 | 0 |
| TNS (ns) | -308193.40625 | -719693.1875 | **+411499.78125** | -287464.78125 | **-20728.625** |
| violations | 40 | 40 | 0 | 40 | 0 |
| logic area | 2468670.96 | 2465601.32 | **+3069.64** | 2181777.92 | **+286893.04** |
| sequential area | 680439.76 | 679275.52 | +1164.24 | 570206.56 | +110233.20 |
| known cells | 996124 | 1016851 | -20727 | 929250 | +66874 |
| relative power | 0.160W | 0.162W | -0.002W | 0.136W | +0.024W |

RETAIN门中功能、旧Top40家族消除、WNS/TNS改善通过；但logic area比whole-inline高3069.64，且相对four-placeholder增量也高3069.64，因此按冻结合同ROLLBACK。相对whole-inline DFF+189、ICG+16、MUX4+9136；复制的bank-local read mux/S1是最可能面积来源，但仍是基于cell census的推断。

## 正式PPA与未知项

- 当前`WNS=-11.550187111ns/TNS=-308193.40625ns/violations=40/loops=0`，正式`WNS>=+0.10/TNS=0/violations=0/loops=0`只满足loops。
- fixed-toggle `0.160W`仅relative；placeholder macro power为0；缺macro-inclusive area与qualified activity power。
- constraints仍有missing inputs=304、missing outputs=1906、unconstrained endpoints=1907。
- Top40之外bank-select/write-data路径、布局布线/CTS/multicorner、面积增加的逐cone因果均未知。
- alternative hypotheses：keep-hierarchy/路径排名使BPU跌出Top40；面积回退来自bank read mux/S1复制而非banked write本身；可用共享读结构或更窄bank-local staging形成下一可逆候选。
- `scope_extension_request`：当前ROLLBACK不需扩展；新design-id候选需新合同做一次新runner，并加入全量BPU violating-path/high-fanout inventory。正式promotion仍需真实三类macro、macro-inclusive area/power与child internal/top boundary合取。

## 封存哈希与清理

- `summary.json=fc752a737d3b05edd8ff9f4fe6c94af4b324357bb2857c6c2ea8f7984b62d802`
- `synth_stat.txt=3f2e54c3f6db2ac350593d3c317f2a2394891c47c00f7a84ef9d83749acccff4`
- `opensta-top40.rpt=66b3908bdec0d26c15f480f459b123060c9e67c69064c874647da64121dd51d4`
- `traceability.txt=da0dada5f2e49c690b75228f01d4cf1c0bce792a72999bae5bea1c6543838759`
- 删除1545958874 bytes runtime；netlist未保留，仅留SHA-256 `f387624c73834d5773b8f78568a92859f23c9a14b05d40f89639774f2d07e25e`。

全部工程命令已停止，唯一WSL shell ownership已归还。

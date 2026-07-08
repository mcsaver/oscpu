# 规范：OooFetchPacketCache 取指包缓存

> 模块：`vsrc/cache/OooFetchPacketCache.v`。状态：ACTIVE，描述取指包 cache 的
> cache-visible 语义和综合宏边界前置审核；不是 `OooFetchAxiBridge` 的 AXI/PMP/ITLB
> 事务级规范替代品。

## 1. 目的与范围

`OooFetchPacketCache` 是 `OooFetchAxiBridge` 内部的两槽 fetch packet cache，用于把
已经过桥侧翻译、PMP 检查和 AXI 取回的包保存为 `{inst0, resp0, inst1, resp1}`。

本 spec 只冻结 cache 边界：

- lookup context、exact PC hit 和 packet payload 读出；
- fill、store-driven invalidate 和整体 clear；
- self-modifying-code 相关的 8B store footprint 失效；
- debug/common 旁挂审核方式；
- 进入 Yosys macro/OOC/SRAM 方案前必须保留的行为不变量。

跨页拼接、PMP grant、ITLB/PTW、Svnapot 与 AXI 状态机仍由 `ooo-fetch-axi-bridge.md`
约束。

## 2. 接口契约

| 端口组 | 方向 | 契约 |
| --- | --- | --- |
| `lookup_paging_i/lookup_priv_i/lookup_satp_i` | 输入 | lookup 上下文。paged lookup 必须比较 paging、priv、satp；bare lookup 只比较 paging=0，不比较 priv/satp。 |
| `lookup_pc_i` | 输入 | lookup packet PC。index 由 `lookup_pc_i[INDEX_W:1]` 形成。 |
| `lookup_context_hit_o` | 输出 | valid、paging 和 paged context 命中时为 1；不要求 exact PC 命中。 |
| `lookup_hit_o` | 输出 | `lookup_context_hit_o`、exact PC 和非同拍 store footprint invalidation 同时满足时为 1。 |
| `lookup_inst*/lookup_resp*` | 输出 | 当前 index 的 packet payload。只有 `lookup_hit_o=1` 时 payload 才有语义。 |
| `fill_valid_i/fill_*` | 输入 | 在 `posedge clk` 写入一条 packet；若同拍 store footprint 与 fill PC 重叠，fill 必须被阻止。 |
| `invalidate_valid_i/invalidate_addr_i` | 输入 | 已提交 store 驱动的 SMC 失效。失效窗口按 8B store footprint 与 8B fetch window overlap 判定。 |
| `clear_i` | 输入 | fence.i/sfence/satp 类整体失效入口。reset/clear 只清 valid。 |

## 3. 状态与时序模型

- 默认 `INDEX_W=12`、`ENTRY_COUNT=4096`，直映 VIVT。
- 每 entry 记录 `valid`、`paging`、`priv`、`satp`、`pc`、`inst0/inst1`、`resp0/resp1`。
- lookup 为组合查询；fill/invalidate/clear 在 `posedge clk` 生效。
- reset/clear 只清 `valid_q`；payload/context 在 invalid entry 中不可作为语义值使用。
- 同拍优先级为 reset/clear 优先；否则 invalidate 清命中 entry，且与同拍 store footprint 重叠的
  fill 被阻止；未阻止的 fill 在同一时钟沿写入并从下一拍 lookup 可见。
- invalidate 候选 index 覆盖 m6/m4/m2/p0/p2/p4/p6，保证 8B store footprint 的高半取指包
  `pc=base+4/base+6` 不漏失效。

## 4. 不变量

- **FPC-I1 hit gating**：`lookup_hit_o -> lookup_context_hit_o`。
- **FPC-I2 same-cycle store block**：lookup PC 与同拍 store footprint 重叠时，`lookup_hit_o` 必须为 0。
- **FPC-I3 paged context**：paged lookup 命中必须同时匹配 `priv` 与 `satp`。
- **FPC-I4 bare context**：bare lookup 不比较 `priv/satp`；同 index、paging=0 的 entry 允许在不同
  priv/satp 输入下 context hit。
- **FPC-I5 exact PC**：context hit 不等于 packet hit；`lookup_hit_o` 仍必须 exact PC 匹配。
- **FPC-I6 blocked fill**：fill PC 与同拍 store footprint 重叠时，不得写入 valid packet。
- **FPC-I7 valid-only reset/clear**：reset/clear 后不得命中；payload/context 残值无语义。
- **FPC-I8 8B SMC footprint**：store 地址对应的 8B footprint 必须覆盖 m6/m4/m2/p0/p2/p4/p6
  候选 entry，不得只按 4B store footprint 失效。

## 5. debug/common 审核

当前审核层由两部分组成：

- `vsrc/common/OooFetchPacketCacheFacts.vh`：定义 `LOOKUP_CONTEXT_HIT`、`LOOKUP_HIT`、
  `LOOKUP_INVALIDATED`、`FILL_BLOCKED_BY_STORE`、`INVALIDATE`、`CLEAR` 等外部观测 facts。
  该表只描述 spec 语义，不规定 cache 的物理编码。
- `vsrc/debug/OooFetchPacketCacheChecker.sv`：在 focused TB 中旁挂到真实端口，投影 facts 并用
  立即断言检查 FPC-I1/FPC-I2。它不进入 `RTL_CORE_SRCS`，不参与综合面积。

后续若把取指包 cache 换成 SRAM/macro/OOC module，必须先保持本 checker PASS，或在本文件中
记录被替代的不变量、替代检查和豁免理由。

## 6. Focused TB 覆盖

`tb_ooo_fetch_packet_cache` 当前覆盖：

- reset 后 miss；
- bare mode 下忽略 priv/satp 的 packet hit；
- 同 index 但 exact PC mismatch 时 context hit、packet miss；
- paged mode 下 priv/satp mismatch miss 与 context match hit；
- store-driven invalidate 清掉重叠 packet 且保留其他 packet；
- 8B store footprint 对 `pc=base+4/base+6` 高半取指包失效；
- 同拍 store footprint 阻止同窗口 fill；
- blocked fill 后 refill 可见；
- clear 整体清 valid。

建议命令：

```bash
make -C npc/rv64/testbench TESTS=tb_ooo_fetch_packet_cache \
  RESULT_DIR=/tmp/tb-fetch-cache run
```

## 7. Macro/OOC 待办

- [x] 建 dedicated spec，冻结取指包 cache 边界语义。
- [x] 建 `common` facts 与 `debug` checker，并接入 focused TB。
- [x] focused TB 覆盖 context/hit/fill/invalidate/clear 语义。
- [x] 定义 memory-preserve/OOC placeholder v0 的读写端口、同拍失效/fill 优先级和 reset/valid 初始化假设。
- [x] 给 Yosys-STA 报告提供 non-signoff timing/area placeholder v0，避免 unknown area 被误当闭合。
- [ ] 提供 iEDA/Yosys 可读的真实 Liberty/LEF macro model，或 OOC timing report + 顶层约束接入。
- [ ] 若接入仿真顶层 XMR checker，需登记非真空 evidence；若只保留 focused TB，macro-boundary
  task-run 必须说明边界为何足够局部。

## 8. Macro/OOC Contract v0

> 状态：ACTIVE placeholder。该节只给综合/STA 报告一个可审计的假设边界，不是面积/时序签核。

### 8.1 当前选择

v0 采用 **module-level OOC/blackbox boundary**：顶层 `NpcTop` synthesis 可以继续把
`OooFetchPacketCache` 保留为边界单元；生产 RTL 仍使用当前 Verilog 实现。后续若替换为 SRAM
wrapper，必须先证明 wrapper 对 §2/§3/§4 的外部语义等价，或同步更新 fetch bridge 与 focused TB。

### 8.2 端口与时序假设

| 类别 | v0 假设 | 说明 |
| --- | --- | --- |
| lookup read latency | `0 cycle` | `lookup_*` 到 `lookup_context_hit_o/lookup_hit_o/lookup_inst*/lookup_resp*` 保持组合可见。 |
| write edge | `posedge clk` | `fill_valid_i`、`invalidate_valid_i` 与 `clear_i` 均在时钟沿维护内部状态。 |
| write visibility | `next cycle` | fill/invalidate/clear 对后续 hit/payload 的可见性从下一拍开始；当前 TB 按该模型审核。 |
| same-cycle priority | reset/clear > invalidate > non-blocked fill | reset/clear 清 valid；store footprint 命中的 fill 被阻止；未阻止 fill 写入并下一拍可见。 |
| reset | valid-only clear | reset/clear 只清 `valid_q`；context/payload 在 invalid entry 中无语义值。 |
| read ports | one combinational view | 当前只有一组 lookup 组合读视图。SRAM 化前必须证明读延迟、旁路和 invalidation 同拍行为不漂移。 |

### 8.3 Area Placeholder

默认 `OooFetchAxiBridge` 例化 `OOO_FETCH_PACKET_CACHE_INDEX_W=12`，因此：

| 项 | 数值 |
| --- | --- |
| entries | `4096` |
| valid bits | `4096` |
| context bits | `4096 * (1 + 2 + 64) = 274432` |
| pc bits | `4096 * 64 = 262144` |
| packet payload bits | `4096 * (32 + 2 + 32 + 2) = 278528` |
| total state bits | `819200` |

该数字只是 state-capacity lower bound，不是 stdcell area、SRAM compiler area、leakage 或 timing closure。
在 Liberty/LEF 或 OOC timing report 接入前，`NpcTop` 报告必须继续把 `OooFetchPacketCache`
面积标为未闭合。

### 8.4 STA 接入条件

- 若继续使用 blackbox：报告必须列出 lookup read latency、write visibility、same-cycle priority、
  state bits，并声明 top area/timing 不含真实取指包 cache macro。
- 若使用真实 SRAM/宏：必须提供 Liberty timing arcs 覆盖 lookup 组合输出、clk 到写可见性、
  setup/hold、reset/valid 初始化假设，并同步 `sta.tcl`/PDK 读入。
- 若使用 OOC stdcell netlist：必须给出 OOC synthesis/STA evidence，并说明顶层如何约束 blackbox
  input/output delay；不能只用 `check_macro_contracts.py` PASS 作为 STA 证据。

## 9. 变更记录

- 2026-07-08：新增 dedicated FetchPacketCache spec、debug/common checker 约束和 focused TB 覆盖清单，
  用于四黑盒 Yosys macro-boundary contract 的语义审核前置。
- 2026-07-08：新增 Macro/OOC Contract v0，定义取指包 cache placeholder 的 0-cycle lookup read、
  next-cycle fill/invalidate/clear visibility、same-cycle store block fill 和 819200 state-bit lower bound；
  真实 Liberty/LEF/OOC STA 仍未闭合。

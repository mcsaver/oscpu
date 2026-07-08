# 规范：OooDataWordCache 数据字缓存

> 模块：`vsrc/cache/OooDataWordCache.v`。状态：ACTIVE，描述当前 8B line 直映 D-cache
> 语义和综合宏边界前置审核；不是完整 LSU/AXI FSM 规范的替代品。

## 1. 目的与范围

`OooDataWordCache` 是 `OooMemAxiBridge` 内部的数据侧 8B line cache，用于普通数据 load
和 PTW leaf PTE 读的快速命中。它不拥有 AXI、PMP、Sv39 walk、flush/drop/nokill FSM；
这些事务级语义仍由 `ooo-mem-axi-bridge-fsm.md` 约束。

本 spec 只冻结 cache 边界：

- cacheable 判定、line index/tag、hit/miss 和跨线窗口；
- line fill、store commit 维护、全失效；
- debug/common 旁挂审核方式；
- 进入 Yosys macro/OOC/SRAM 方案前必须保留的行为不变量。

## 2. 接口契约

| 端口组 | 方向 | 契约 |
| --- | --- | --- |
| `req_lookup_addr_i/req_nbytes_i` | 输入 | 普通数据访问窗口。`req_nbytes_i` 必须为 1..8；窗口以 `addr[2:0]` 为偏移。 |
| `req_cacheable_o` | 输出 | 地址落在 `NPC_AXI_PMEM_BASE/MASK` 描述的 PMEM 窗口时为 1。 |
| `req_line_cross_o` | 输出 | `addr[2:0] + req_nbytes_i > 8` 时为 1。跨线请求必须 miss，由桥侧按窗口读且不 fill。 |
| `req_hit_o/req_data_o` | 输出 | 仅当 cacheable、非跨线、valid 且 tag 命中时 hit；`req_data_o` 是 8B line 右移 `addr[2:0]*8` 后的窗口视图。 |
| `walk_lookup_addr_i` | 输入 | PTW leaf PTE 读地址。桥侧保证 8B 对齐；本 cache 不单独生成 walk cross 信号。 |
| `walk_cacheable_o/walk_hit_o/walk_data_o` | 输出 | PTW 读 hit 只允许发生在 PMEM cacheable 地址且 tag/valid 命中时。 |
| `fill_valid_i/fill_addr_i/fill_data_i` | 输入 | 读 miss 回填对齐 8B line。macro/OOC 方案必须保持 `fill_addr_i[2:0]==0`。 |
| `store_commit_i/store_*` | 输入 | 已提交 store 或 HW A/D 写回维护 cache；非跨线命中时 write-update，miss 不分配；跨线时保守失效两条相关 line。 |
| `store_invalidate_all_i` | 输入 | 全失效维护事件，必须挂在 `store_commit_i` 拍上。当前桥侧常态 tie 0，但 cache 模块保留能力。 |

## 3. 状态与时序模型

- 存储结构为直映 `valid_q/tag_q/data_q`，`ENTRY_COUNT = 1 << INDEX_W`，每 entry 存 8B line。
- 读命中为组合查询；fill/store 维护在 `posedge clk` 生效。
- reset 只清 `valid_q`；tag/data 在 invalid 时不可作为语义值使用。
- 同拍 fill 与 store commit 可能同时到达时，RTL 顺序为先 fill、后 store 维护。若未来替换成 SRAM/macro，
  必须在 macro contract 中显式说明同拍优先级，不能让 SRAM 读写模式隐式改变语义。

## 4. 不变量

- **DWC-I1 hit gating**：`req_hit_o -> req_cacheable_o && !req_line_cross_o`。
- **DWC-I2 cross miss**：跨 8B line 的 req 窗口不得命中，且桥侧不得把窗口读回填进 line cache。
- **DWC-I3 window view**：非跨线 hit 的 `req_data_o` 必须等于命中 line 右移 `addr[2:0]*8`。
- **DWC-I4 write-update**：cacheable、非跨线、命中 store commit 只按 `store_wstrb_i << addr[2:0]`
  合并对应字节，保持 line valid/tag 不变。
- **DWC-I5 write-no-allocate**：store miss 不分配新 line。
- **DWC-I6 cross-store invalidation**：跨线 store commit 必须保守失效当前 line 与下一 line 中 tag 匹配者。
- **DWC-I7 PTW hit gating**：`walk_hit_o -> walk_cacheable_o`。
- **DWC-I8 fill alignment**：fill 地址必须为 PMEM cacheable 且 8B 对齐。

## 5. debug/common 审核

当前审核层由两部分组成：

- `vsrc/common/OooDataWordCacheFacts.vh`：定义 `REQ_LINE_CROSS`、`REQ_HIT`、`WALK_HIT`、
  `FILL`、`STORE_LINE_CROSS` 等外部观测 facts。该表只描述 spec 语义，不规定 cache 的物理编码。
- `vsrc/debug/OooDataWordCacheChecker.sv`：在 focused TB 中旁挂到真实端口，投影 facts 并用
  立即断言检查 DWC-I1/I2/I7/I8 和接口合法性。它不进入 `RTL_CORE_SRCS`，不参与综合面积。

后续若把 D-cache 换成 SRAM/macro/OOC module，必须先保持本 checker PASS，或在本文件中记录
被替代的不变量、替代检查和豁免理由。

## 6. Focused TB 覆盖

`tb_ooo_data_word_cache` 当前覆盖：

- reset 后 miss；
- line fill 后 req/walk hit；
- 非对齐但不跨线的窗口读与右移视图；
- 跨线 req 检测与强制 miss；
- partial store 命中 write-update；
- full/partial store miss no-allocate；
- 跨线 store 失效两条相关 line；
- MMIO/uncacheable miss；
- invalidate-all 清 valid。

建议命令：

```bash
make -C npc/rv64/testbench TESTS=tb_ooo_data_word_cache \
  RESULT_DIR=/tmp/tb-dcache run
```

## 7. Macro/OOC 待办

- [x] 建 dedicated spec，冻结 D-cache 边界语义。
- [x] 建 `common` facts 与 `debug` checker，并接入 focused TB。
- [x] focused TB 覆盖 line-cross/window/store/invalidate 语义。
- [x] 定义 memory-preserve/OOC placeholder v0 的读写端口、同拍读写优先级和 reset/valid 初始化假设。
- [x] 给 Yosys-STA 报告提供 non-signoff timing/area placeholder v0，避免 unknown area 被误当闭合。
- [ ] 提供 iEDA/Yosys 可读的真实 Liberty/LEF macro model，或 OOC timing report + 顶层约束接入。
- [ ] 若接入仿真顶层 XMR checker，需登记非真空 evidence；若只保留 focused TB，macro-boundary
  task-run 必须说明边界为何足够局部。

## 8. Macro/OOC Contract v0

> 状态：ACTIVE placeholder。该节只给综合/STA 报告一个可审计的假设边界，不是面积/时序签核。

### 8.1 当前选择

v0 采用 **module-level OOC/blackbox boundary**：顶层 `NpcTop` synthesis 可以继续把
`OooDataWordCache` 保留为边界单元；生产 RTL 仍使用当前 Verilog 实现。后续若替换为 SRAM wrapper，
必须先证明 wrapper 对 §2/§3/§4 的外部语义等价，或同步更新桥 FSM 与 focused TB。

### 8.2 端口与时序假设

| 类别 | v0 假设 | 说明 |
| --- | --- | --- |
| req read latency | `0 cycle` | `req_lookup_addr_i/req_nbytes_i` 到 `req_cacheable_o/req_line_cross_o/req_hit_o/req_data_o` 保持组合可见。 |
| walk read latency | `0 cycle` | `walk_lookup_addr_i` 到 `walk_cacheable_o/walk_hit_o/walk_data_o` 保持组合可见。 |
| write edge | `posedge clk` | `fill_valid_i` 与 `store_commit_i` 均在时钟沿维护内部状态。 |
| write visibility | `next cycle` | fill/store 对后续 hit/data 的可见性从下一拍开始；当前 TB 按该模型审核。 |
| same-cycle priority | fill then store | 若同拍 fill 与 store commit 命中同一 entry，RTL 语义为先 fill 后 store 维护；macro/wrapper 必须保持。 |
| reset | valid-only clear | reset 清 `valid_q`；tag/data 在 invalid entry 中无语义值。 |
| read ports | two combinational views | req 与 walk 当前都是组合读视图。单读口 SRAM 化前必须证明互斥并补仲裁/延迟合同。 |

### 8.3 Area Placeholder

默认 `OOO_DATA_WORD_CACHE_INDEX_W=12`，因此：

| 项 | 数值 |
| --- | --- |
| entries | `4096` |
| data bits | `4096 * 64 = 262144` |
| tag bits | `4096 * (64 - 3 - 12) = 200704` |
| valid bits | `4096` |
| total state bits | `466944` |

该数字只是 state-capacity lower bound，不是 stdcell area、SRAM compiler area、leakage 或 timing closure。
在 Liberty/LEF 或 OOC timing report 接入前，`NpcTop` 报告必须继续把 `OooDataWordCache` 面积标为未闭合。

### 8.4 STA 接入条件

- 若继续使用 blackbox：报告必须列出 read latency、write visibility、same-cycle priority、state bits，
  并声明 top area/timing 不含真实 D-cache macro。
- 若使用真实 SRAM/宏：必须提供 Liberty timing arcs 覆盖 req/walk 读组合输出、clk 到写可见性、
  setup/hold、reset/valid 初始化假设，并同步 `sta.tcl`/PDK 读入。
- 若使用 OOC stdcell netlist：必须给出 OOC synthesis/STA evidence，并说明顶层如何约束 blackbox
  input/output delay；不能只用 `check_macro_contracts.py` PASS 作为 STA 证据。

## 9. 变更记录

- 2026-07-08：新增 dedicated D-cache spec、debug/common checker 约束和 focused TB 覆盖清单，
  用于四黑盒 Yosys macro-boundary contract 的语义审核前置。
- 2026-07-08：新增 Macro/OOC Contract v0，定义 D-cache placeholder 的 0-cycle read、next-cycle
  write visibility、fill-then-store 优先级和 466944 state-bit lower bound；真实 Liberty/LEF/OOC STA
  仍未闭合。

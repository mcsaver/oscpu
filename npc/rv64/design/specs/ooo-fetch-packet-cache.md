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
| `lookup_en_i` | 输入 | lookup fire 拍使能。当拍锁存 lookup 请求并发射 SRAM 同步读；**次拍(判决拍)** lookup 输出针对该锁存请求有效。fire 拍与 fill 拍必须互斥(SRAM 1RW)。 |
| `lookup_paging_i/lookup_priv_i/lookup_satp_i` | 输入 | lookup 上下文(fire 拍采样)。paged lookup 必须比较 paging、priv、satp；bare lookup 只比较 paging=0，不比较 priv/satp。 |
| `lookup_pc_i` | 输入 | lookup packet PC(fire 拍采样)。index 由 `lookup_pc_i[INDEX_W:1]` 形成。 |
| `lookup_context_hit_o` | 输出 | 判决拍有效：valid、paging 和 paged context 命中时为 1；不要求 exact PC 命中。非判决拍恒 0。 |
| `lookup_hit_o` | 输出 | 判决拍有效：`lookup_context_hit_o`、exact PC，且 fire 拍与判决拍两拍窗口内均无 store footprint 重叠时为 1。非判决拍恒 0。 |
| `lookup_inst*/lookup_resp*` | 输出 | 判决拍的 SRAM 读出 payload。只有 `lookup_hit_o=1` 时才有语义。 |
| `fill_valid_i/fill_*` | 输入 | 在 `posedge clk` 写入一条 packet(SRAM 写口)；若同拍 store footprint 与 fill PC 重叠，fill 必须被阻止。 |
| `invalidate_valid_i/invalidate_addr_i` | 输入 | 已提交 store 驱动的 SMC 失效。盲失效：直接清 7 邻域 index 的 valid FF，不读 pc 比较。 |
| `clear_i` | 输入 | fence.i/sfence/satp 类整体失效入口。reset/clear 只清 valid。 |

## 3. 状态与时序模型

- 默认 `INDEX_W=12`、`ENTRY_COUNT=4096`，直映 VIVT。
- payload/tag 全体(`paging/priv/satp/pc/inst0/inst1/resp0/resp1`)集中在 1 个
  `Sram4096x199` 1RW 同步读宏；位段布局
  `{paging[198], priv[197:196], satp[195:132], pc[131:68], inst0[67:36], inst1[35:4], resp0[3:2], resp1[1:0]}`。
  `valid` 保持 `ENTRY_COUNT` bit FF(SRAM 内容无复位，全清/失效语义由 valid FF 承担)。
- lookup 为两拍协议：fire 拍(`lookup_en_i`)锁存请求+发射 SRAM 读，判决拍(次拍)输出有效；
  fill/invalidate/clear 在 `posedge clk` 生效。
- valid 在**判决拍**用锁存 index 组合读 FF(不随 SRAM 走)：fire 拍同拍到达的 invalidate
  在拍尾清 valid，判决拍即可见(两拍窗口①的 FF 侧封堵)。
- 两拍 store 窗口封堵：窗口①(fire 拍 store)由锁存旁路+判决拍 valid 读双保险；
  窗口②(判决拍才到的 store)由锁存 pc 对当拍 invalidate 的旁路比较压掉 hit。
- reset/clear 只清 `valid_q`；payload/context 在 invalid entry 中不可作为语义值使用。
- 同拍优先级为 reset/clear 优先；否则盲失效清 7 邻域 valid，且与同拍 store footprint 重叠的
  fill 被阻止；未阻止的 fill(同 index 后写胜出)在同一时钟沿写入，从下一次 lookup fire 起可见。
- 盲失效候选 index 覆盖 m6/m4/m2/p0/p2/p4/p6：与 store 足迹重叠的取指包 index 必落在该
  邻域内(精确失效集合的严格超集)，多清同 index 异 PC 的 entry 只损 hit 率不损正确性；
  8B store footprint 的高半取指包 `pc=base+4/base+6` 不漏失效。

## 4. 不变量

- **FPC-I1 hit gating**：`lookup_hit_o -> lookup_context_hit_o`(判决拍)。
- **FPC-I2 two-cycle store block**：锁存 lookup PC 与 fire 拍**或**判决拍 store footprint
  重叠时，`lookup_hit_o` 必须为 0(两拍窗口都要封)。
- **FPC-I3 paged context**：paged lookup 命中必须同时匹配 `priv` 与 `satp`。
- **FPC-I4 bare context**：bare lookup 不比较 `priv/satp`；同 index、paging=0 的 entry 允许在不同
  priv/satp 输入下 context hit。
- **FPC-I5 exact PC**：context hit 不等于 packet hit；`lookup_hit_o` 仍必须 exact PC 匹配。
- **FPC-I6 blocked fill**：fill PC 与同拍 store footprint 重叠时，不得写入 valid packet。
- **FPC-I7 valid-only reset/clear**：reset/clear 后不得命中；payload/context 残值无语义。
- **FPC-I8 8B SMC blind footprint**：store 地址对应的 8B footprint 必须盲清 m6/m4/m2/p0/p2/p4/p6
  候选 index 的 valid(不读 pc 比较，超集覆盖)，不得只按 4B store footprint 失效。
- **FPC-I9 decision frame**：非判决拍(上一拍无 `lookup_en_i`)时 `lookup_hit_o` 必须为 0，
  防止 stale SRAM rdata 被误当命中。
- **FPC-I10 1RW exclusivity**：`lookup_en_i` 与 `fill_valid_i` 不得同拍(使用方 FSM 保证；
  cache 内 `OOO_ASSERT` 立即断言 `[CONTRACT-FPC-1RW]` 把关)。

## 5. debug/common 审核

当前审核层由两部分组成：

- `vsrc/common/OooFetchPacketCacheFacts.vh`：定义 `LOOKUP_CONTEXT_HIT`、`LOOKUP_HIT`、
  `LOOKUP_INVALIDATED`、`FILL_BLOCKED_BY_STORE`、`INVALIDATE`、`CLEAR` 等外部观测 facts。
  lookup 类 facts 的参照系是判决拍(fire 拍锁存请求)；该表只描述 spec 语义，不规定
  cache 的物理编码。
- `vsrc/debug/OooFetchPacketCacheChecker.sv`：在 focused TB 中旁挂到真实端口，自建 fire 拍
  锁存影子模型(`lookup_en_i` 次拍为判决拍)，投影 facts 并用立即断言检查
  FPC-I1(`FPC-HIT-GATE`)/FPC-I2(`FPC-LOOKUP-INVALIDATED`，两拍窗口)/FPC-I9(`FPC-HIT-FRAME`)。
  它不进入 `RTL_CORE_SRCS`，不参与综合面积。FPC-I10 的 `[CONTRACT-FPC-1RW]` 断言在
  cache RTL 内(`OOO_ASSERT` 编译门控)。

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
- 两拍窗口①：store 与 lookup fire 同拍时判决拍 miss；
- 两拍窗口②：store 在判决拍才到达时 context hit 但 hit 被旁路压 0，且下一拍 entry 已被盲失效；
- clear 整体清 valid。

所有 lookup 都按两拍协议驱动(`set_lookup` 内含 fire 拍 tick，判决拍采样)。

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
- [x] payload/tag 落 `Sram4096x199` 1RW 同步读行为宏(两拍 lookup 协议+7 邻域盲失效)，
  bridge FSM 加 `S_LOOKUP` 判决拍，checker/focused TB 同刀迁移(Contract v1)。
- [ ] 提供 iEDA/Yosys 可读的真实 Liberty/LEF macro model，或 OOC timing report + 顶层约束接入。
- [ ] 若接入仿真顶层 XMR checker，需登记非真空 evidence；若只保留 focused TB，macro-boundary
  task-run 必须说明边界为何足够局部。

## 8. Macro/OOC Contract v1

> 状态：ACTIVE。v1 起 payload/tag 已真实落进 `Sram4096x199` 1RW 同步读宏
> (`vsrc/sram/Sram4096x199.v` 行为模型，综合期黑盒化)；本节描述该宏边界的可审计合同，
> 仍不是面积/时序签核。

### 8.1 当前选择

v1 采用 **SRAM-macro-inside-module boundary**：模块名 `OooFetchPacketCache` 保持不变
(宏合同 checker 冻结)，`Sram4096x199` 例化在模块**内部**；valid 与 lookup 请求锁存
仍是模块内 FF。对外语义按 §2/§3/§4 的两拍协议冻结。

### 8.2 端口与时序假设

| 类别 | v1 假设 | 说明 |
| --- | --- | --- |
| lookup read latency | `1 cycle` | 同步读：`lookup_en_i` fire 拍锁存请求+发射 SRAM 读，次拍(判决拍)`lookup_context_hit_o/lookup_hit_o/lookup_inst*/lookup_resp*` 针对锁存请求有效；非判决拍 hit 输出恒 0。 |
| write edge | `posedge clk` | `fill_valid_i`(SRAM 写口)、`invalidate_valid_i` 与 `clear_i`(valid FF) 均在时钟沿维护内部状态。 |
| write visibility | `next lookup issue` | fill/invalidate/clear 在拍尾生效；对下一次 fire 的 lookup(判决拍再 +1 拍)可见。fire 拍同拍 invalidate 由判决拍 valid FF 读+锁存旁路封堵，判决拍同拍 invalidate 由锁存 pc 旁路封堵。 |
| same-cycle priority | reset/clear > blind invalidate > non-blocked fill | reset/clear 清 valid；盲失效清 7 邻域 index；store footprint 命中的 fill 被阻止；未阻止 fill 同 index 后写胜出。 |
| reset | valid-only clear | reset/clear 只清 `valid_q`；SRAM 内容无复位，invalid entry 的 context/payload 无语义值。 |
| read ports | one synchronous 1RW SRAM port | lookup 读(fire 拍)与 fill 写分拍复用同一 1RW 口，使用方 FSM 保证互斥(`[CONTRACT-FPC-1RW]` 断言)；valid 为判决拍组合读 FF，不走 SRAM。 |

### 8.3 Area Placeholder

默认 `OooFetchAxiBridge` 例化 `OOO_FETCH_PACKET_CACHE_INDEX_W=12`，因此：

| 项 | 数值 |
| --- | --- |
| entries | `4096` |
| valid bits (FF) | `4096` |
| SRAM macro bits (`Sram4096x199`) | `4096 * 199 = 815104` |
| — 其中 context bits (paging/priv/satp) | `4096 * (1 + 2 + 64) = 274432` |
| — 其中 pc tag bits | `4096 * 64 = 262144` |
| — 其中 packet payload bits | `4096 * (32 + 2 + 32 + 2) = 278528` |
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
- 2026-07-08(SRAM 化)：Contract v0→v1。payload/tag 8 阵列合并进 `Sram4096x199` 1RW 同步读宏
  (模块内例化，模块名不变)；lookup 改两拍协议(`lookup_en_i` fire 拍→判决拍输出，
  1-cycle read latency)；SMC invalidate 改 7 邻域盲失效(pc 失效读口消灭，超集覆盖)；
  新增 FPC-I9(判决拍框架)/FPC-I10(1RW 互斥) 与 `[CONTRACT-FPC-1RW]`/`FPC-HIT-FRAME` 断言；
  satp/paging/priv tag 原样保留(`OOO_CSR_QUEUE_HEAD=1` 时 satp 写不拉 mmu_flush，
  satp tag 是唯一防线)。819200 state bits 数值不变(4096 valid FF + 815104 SRAM 宏 bits)。

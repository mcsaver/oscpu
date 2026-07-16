# 规范：OooDataWordCache 数据字缓存

> 模块：`vsrc/cache/OooDataWordCache.v`。状态：ACTIVE，描述当前 8B line 直映 D-cache
> 的 **SRAM 宏化(1RW 同步读+1拍)** 语义；不是完整 LSU/AXI FSM 规范的替代品。

## 1. 目的与范围

`OooDataWordCache` 是 `OooMemAxiBridge` 内部的数据侧 8B line cache，用于普通数据 load
和 PTW leaf PTE 读的快速命中。它不拥有 AXI、PMP、Sv39 walk、flush/drop/nokill FSM；
这些事务级语义仍由 `ooo-mem-axi-bridge-fsm.md` 约束。

本 spec 只冻结 cache 边界：

- cacheable 判定、line index/tag、单读口两拍 lookup 协议；
- line fill、store commit 2 拍 RMW write-update(A/D 维护路无条件失效)；
- 同步 virtio queue-notify DMA 完成后的 valid-only 全失效；
- debug/common 旁挂审核方式；
- SRAM 宏(Sram4096x113, bit-write-mask 变体)边界必须保留的行为不变量。

## 2. 接口契约

| 端口组 | 方向 | 契约 |
| --- | --- | --- |
| `dma_invalidate_all_i` | 输入 | **1-cycle 运行期维护脉冲**：仅表示当前仿真 `AxiVirtioBlk` 已在一次 queue-notify 的同步 DPI 调用内完成本批 data/status/used-ring PMEM 写。脉冲不占 SRAM 端口，只清全部 `valid_q`，并在脉冲可见拍组合屏蔽 `lookup_hit_o`。它不是通用 autonomous DMA snoop/coherence 接口。 |
| `req_lookup_addr_i/req_nbytes_i` | 输入 | 普通数据访问窗口(纯地址组合视图输入)。`req_nbytes_i` 必须为 1..8；窗口以 `addr[2:0]` 为偏移。 |
| `req_cacheable_o` | 输出 | **0-cycle 组合**：地址落在 `NPC_AXI_PMEM_BASE/MASK` 描述的 PMEM 窗口时为 1。不查存储阵列。 |
| `req_line_cross_o` | 输出 | **0-cycle 组合**：`addr[2:0] + req_nbytes_i > 8` 时为 1。跨线请求由桥在判决拍按 miss 处理(锁存 `read_cross_q` 阻断 hit)且不 fill。 |
| `walk_lookup_addr_i/walk_cacheable_o` | 输入/输出 | PTW 地址的 **0-cycle 组合** cacheable 视图。原 walk 独立读口已并入单 lookup 口。 |
| `lookup_en_i/lookup_addr_i` | 输入 | 单读口发射拍：`en=1` 时读 SRAM 宏并锁存地址上下文；次拍为判决拍。桥保证发射拍与 fill 拍状态互斥(1RW)。 |
| `lookup_hit_o` | 输出 | **判决拍有效**(发射次拍)：锁存地址 cacheable、`valid`、SRAM tag 段命中且本拍 `dma_invalidate_all_i=0`。判决拍之外恒 0；DMA 脉冲与判决拍重合时必须保守 miss。 |
| `lookup_line_o` | 输出 | **判决拍有效**：命中 line 的原始 64b 数据(不移位)。窗口右移 `addr[2:0]*8` 的职责移至桥判决拍(统一用锁存 `paddr_q[2:0]`)。 |
| `fill_valid_i/fill_addr_i/fill_data_i` | 输入 | 读 miss 回填对齐 8B line，全 1 掩码整行写。合法集成的 carrying contract 是：`fill_valid_i -> fill_addr_i` 为 PMEM cacheable 且 8B 对齐，并且该拍与 lookup 发射、RMW 发射、RMW 判决三个 SRAM owner 互斥。地址 mux 直接用 `fill_valid_i` 选 fill index；真正 en/we/wmask/valid 更新仍由重判 cacheable 的 `fill_we` 授权。 |
| `store_commit_i/store_addr_i/store_wdata_i/store_wstrb_i` | 输入 | store/A-D 维护脉冲。`store_rmw_en_i=1`(真 store commit)：**2 拍 RMW write-update**——commit 拍占宏口读 `st_idx` 并锁存上下文，次拍 valid+tag match 则以 wmask 写 line 内被覆盖的 data 字节，并以全 1 tag mask 幂等写回锁存 tag；miss 无动作(write-no-allocate)；跨线 store 的下一行(p1)仍在 commit 拍无条件清 valid(跨线 RMW 不做，保守失效)，本行照常线内合并。`store_wdata_i` 为窗口数据(低位起，与 wstrb 位对齐)。 |
| `store_rmw_en_i` | 输入 | 0 = HW A/D PTE 写回维护路：保持无条件失效(清 valid FF，不读不写宏，0 额外拍，含跨线 p1)——该拍桥的 read 续访问可能同拍发 lookup(宏读口不空闲)。 |
| `rmw_busy_o` | 输出 | RMW 判决拍(commit 次拍)恒且仅该拍为 1：宏口被 RMW 占用，桥必须压 `stage_advance`(刀 M 后; 原 req_ready)/不发 lookup(store 后 1 bubble)。 |

已删除端口(2026-07-08 SRAM 化)：`req_hit_o/req_data_o/walk_hit_o/walk_data_o`(并入
单 lookup 口)、`store_invalidate_all_i`(桥侧恒 0 的死口，物理删除)。
`store_data_i` 曾随一期无条件失效删除，2026-07-09 write-update 赎回以
`store_wdata_i` 名义恢复。2026-07-15 新增的 `dma_invalidate_all_i` 是有真实
queue-notify DMA 完成事件驱动的运行期端口，不是把旧 store 死口改名接回。

## 3. 状态与时序模型

- 存储拆分：`{tag[112:64], data[63:0]}` 拼宽存进 1 个 **Sram4096x113** 1RW 同步读宏
  (`vsrc/sram/Sram4096x113.v`，**bit-write-mask 变体**，综合时黑盒化)；`valid` 保留
  4096b 平铺 FF。`ENTRY_COUNT=4096` 与宏深度定死，`INDEX_W` 参数仅文档化(OOO_ASSERT
  有 elaboration 检查)。
- 读命中为 **1-cycle 同步读**：发射拍 `lookup_en_i` 读宏+锁存地址上下文(idx/tag/cacheable
  与 pend 标志)，判决拍 `lookup_hit_o/lookup_line_o` 针对锁存请求有效。
- valid 判定用判决拍的 FF 值：与发射拍同沿的 store 失效在判决拍已可见，只会把 hit 保守
  判成 miss(走 AXI 取新值)，无正确性洞。
- **fill 地址 owner 提前、写授权不提前（T4S timing boundary）**：SRAM `addr` mux 以
  `fill_valid_i` 直接选择 `fill_idx`，避免把 cacheability reduction/高扇出写控串进宏地址
  setup；宏 `en/we/wmask/wdata` 的 fill 分支以及 `valid_q` 置位仍只认
  `fill_we = fill_valid_i && cacheable(fill_addr_i)`。在 carrying contract
  （fill valid 必为 cacheable/aligned，且与 lookup/RMW owners 互斥）的所有合法 trace 上，
  `fill_valid` 与 `fill_we` 对 owner 等价；非法 trace 必须由 checker/断言拒绝，不能依赖地址
  don't-care 作为功能语义。
- **DMA 全失效为 valid-only maintenance**：`dma_invalidate_all_i` 可见拍组合屏蔽
  `lookup_hit_o`，下一时钟沿清全部 `valid_q`；SRAM tag/data 保留旧位且不占 1RW 宏口。
  因此脉冲与 lookup 判决拍重合时不会把旧 line 融合成 response，随后 miss 可从 DPI 已更新的
  PMEM 重新取数并回填。当前 D-cache 没有 dirty/write-back line（CPU store 在聚合 B 后才做
  cache RMW），所以丢弃全部 valid 不会丢失仅存在于 cache 的新数据。
- **store RMW 两拍**(2026-07-09 write-update 赎回)：commit 拍占宏口读 `st_idx`，同拍锁存
  {idx, tag, line 掩码=wstrb<<off(8b 截断即线内字节), line 数据=wdata<<off*8}；判决拍
  (`rmw_busy_o=1`)`valid[idx] && 宏 tag 段==锁存 tag` 时以
  wmask={tag 段全 1, data 段按掩码展开字节}写宏；tag 数据取锁存 tag，故写回幂等，
  miss 无动作。桥保证 commit 拍宏读口空闲(S_WRITE_RESP b-ok 拍
  不发 lookup/fill)，判决拍以 `rmw_busy_o` 压 `stage_advance`(刀 M 后; store 后
  1 bubble)。
- reset 与 DMA 全失效都只清 `valid_q`；SRAM 内容无复位/运行期擦写，invalid entry 的 tag/data
  不可作为语义值使用。valid 维护优先级固定为 `rst > dma_invalidate_all_i > fill/store`，故同一
  时钟沿的 fill 或 store 维护不能重新暴露被 DMA 判旧的数据。
- fill/lookup 发射/RMW 读/RMW 判决拍四占用者由桥 FSM 状态互斥保证两两不同拍
  (fill 仅 S_READ_DATA；store commit 仅 S_WRITE_RESP/S_AD_UPDATE；RMW 判决拍
  状态∈{S_RESP,S_IDLE} 且 accept 被 rmw_busy 压制)。
- **1RW 合同**：宏口四占用者两两不得同拍(RMW 判决拍即便 miss 不写、口也已保留)，
  `OOO_ASSERT` 下模块内立即断言把关(桥侧另有 MEM-RMW-PORT 断言审门控链)。
- 上述 fill 地址 owner 切分只改变组合锥，不改变 valid 维护顺序；
  `rst > dma_invalidate_all_i > fill/store` 的 DMA 优先级与 DMA 不占 SRAM 口的合同保持不变。
- **生产者完成顺序**：当前唯一生产者 `AxiVirtioBlk` 在 queue-notify 的同步 DPI 调用返回后
  才拉一拍失效事件；事件可见拍隐藏 notify B/IRQ，下一拍才发布锁存的 B response/IRQ。
  本模块不自行推断 MMIO 地址、IRQ 或 DMA 完成，也不承诺处理设备自主发起的异步写。

## 4. 不变量

- **DWC-I1 hit gating(打拍)**：判决拍 `lookup_hit_o -> 上拍有发射(pend) && 锁存地址
  cacheable`。跨线阻断不再由 cache 承担(见 I2)。
- **DWC-I2 cross miss(职责移桥)**：跨 8B line 的读窗口必须按 miss 处理且不得 fill——
  由桥判决拍以锁存 `read_cross_q` 阻断 hit、fill 条件含 `!read_cross_q` 落实。
- **DWC-I3 window view(职责移桥)**：非跨线 hit 的 CPU 视图 = `lookup_line_o` 右移
  `paddr_q[2:0]*8`，由桥判决拍统一完成(req/walk/A-D 三路同一移位点)。
- **DWC-I4 store write-update(2 拍 RMW，二期赎回)**：cacheable 真 store commit
  (`store_rmw_en_i=1`)commit 拍读宏、判决拍 tag match 则线内字节合并写(data 段 wmask，
  tag 段全 1 mask 并幂等写回锁存 tag)，line 保持有效——CoreMark 短步进 store→load 保热恢复；miss 无动作，
  同 index 异 tag 行**不再被误清**(一期无条件失效的性能回归主因，已废止)。
  A/D PTE 写回维护路(`store_rmw_en_i=0`)保持无条件失效(该拍读口不空闲且保热无收益)。
- **DWC-I5 write-no-allocate**：store miss 不分配新 line(RMW 判决 miss 无动作)。
- **DWC-I6 cross-store 保守失效(p1)**：跨线 store commit 在 commit 拍无条件清下一
  line(p1，不比 tag，跨线 RMW 不做)；本 line 照常线内合并(掩码 8b 截断天然只含线内字节)。
- **DWC-I7 fill carrying contract**：`fill_valid_i` 蕴含地址为 PMEM cacheable 且 8B 对齐，
  并蕴含该拍没有 lookup 发射、RMW 发射或 RMW 判决 owner。桥 FSM 负责产生合法 trace；
  checker 的 `DWC-FILL-ADDR/DWC-RMW-PORT` 与模块 1RW 断言共同审计。
- **DWC-I8 1RW 宏口互斥**：lookup 发射/fill 写/RMW 读(commit 拍)/RMW 判决拍四占用者
  两两不得同拍(桥 FSM 状态互斥+`rmw_busy_o` 压 `stage_advance` 保证；模块内与桥内
  OOO_ASSERT 立即断言)。
- **DWC-I9 rmw_busy 恰位**：`rmw_busy_o` 恰为 cacheable RMW commit 的次拍(不多不少)，
  桥据此产生 store 后 1 bubble；checker `DWC-RMW-BUSY` 以独立 pend 模型审计。
- **DWC-I10 DMA 判决屏蔽**：`dma_invalidate_all_i -> !lookup_hit_o`。即使脉冲恰与
  S_LOOKUP 判决拍、lookup 发射拍、fill 或 RMW 两拍窗口重合，也不得消费旧 valid/tag/data 为 hit。
- **DWC-I11 DMA valid 优先级**：`rst > dma invalidate > fill/store valid update`；DMA 沿后
  `valid_q==0`，且 SRAM 不因该事件产生 enable/write。下一次有效 line 只能来自事件后的 fresh fill。
- **DWC-I12 producer scope**：全失效只闭合当前同步 virtio-blk queue-notify 后端；没有
  autonomous DMA request/ack、地址范围、line snoop 或通用 IO-coherence 语义。未来接入自主 DMA
  master 时必须另行冻结完成事件、在途访问和 reservation/coherence 合同，不能复用本脉冲作默认保证。
- **DWC-I13 fill address timing cut**：`sram_addr` 的 fill 优先选择条件是原始
  `fill_valid_i`；`sram_en/we/wmask` 与 `valid_q` 更新的 fill 条件仍是合法 `fill_we`。
  该切分不得改变 write eligibility、1RW owner 互斥或 DMA valid 优先级。

## 5. debug/common 审核

当前审核层由两部分组成：

- `vsrc/common/OooDataWordCacheFacts.vh`：定义 `REQ_LINE_CROSS`(组合)、`LOOKUP_ISSUE`
  (发射拍)、`LOOKUP_HIT/LOOKUP_MISS`(判决拍)、`FILL`、`STORE_LINE_CROSS`、
  `STORE_RMW_ISSUE`(commit 拍)、`STORE_RMW_BUSY`(判决拍)及
  `DMA_INVALIDATE_ALL` 等外部观测 facts。判决拍语义位针对上拍锁存地址/上下文
  (1-cycle 同步读与 RMW 两拍参照系)。
- `vsrc/debug/OooDataWordCacheChecker.sv`：在 focused TB 中旁挂到真实端口，自带一份
  发射拍锁存(pend/addr)与 RMW pend 模型，投影 facts 并用立即断言检查：
  - `DWC-REQ-CACHEABLE/DWC-WALK-CACHEABLE/DWC-LINE-CROSS`：纯地址组合断言，同拍原样保留；
  - `DWC-HIT-GATE`(打拍版)：合并原 REQ/WALK 两同拍断言——hit 只允许出现在判决拍，且
    锁存地址必须 cacheable；
  - `DWC-RMW-BUSY`：`rmw_busy_o` 恰为 cacheable RMW commit 次拍(独立 pend 模型比对)；
  - `DWC-RMW-PORT`：RMW 两拍窗口内宏口不得被 lookup/fill 抢占(A/D 维护路不占口，
    允许与 lookup 同拍)；
  - `DWC-RMW-B2B`：RMW 判决拍不得再来 RMW 发射(防 store 双 commit 类回归)；
  - `DWC-DMA-HIT`：DMA 全失效脉冲可见拍不得同时报告 lookup hit；
  - `DWC-NBYTES/DWC-FILL-ADDR`：同拍保留。
  原 `DWC-INVALL` 随无生产者的 `store_invalidate_all_i` 死口删除；当前
  `DWC-DMA-HIT` 审核的是新的真实 DMA 完成事件，二者语义不同。
  它不进入 `RTL_CORE_SRCS`，不参与综合面积。

## 6. Focused TB 覆盖

`tb_ooo_data_word_cache` 当前覆盖(单读口两拍驱动范式 `issue_lookup`：发射拍拉 en，
tick 后判决拍观测)：

- reset 后 lookup miss + cacheable 组合视图；
- line fill 后判决拍 hit 与原始 line 数据(双查代表原 req/walk 两用途)；
- 判决拍之外 hit 必须回落 0；
- 非对齐窗口：line_cross 组合视图 + 同 line 命中返回原始 line(移位检查移至
  `tb_ooo_mem_axi_bridge` 的 unaligned-hit 场景)；
- 跨线窗口组合检测(跨线阻断 hit 由桥 TB 的跨线读场景审核)；
- store RMW write-update：低位/偏移部分 store 线内字节合并、line 保持有效，
  `commit_store` 任务逐次审核 `rmw_busy` 恰为 commit 次拍；
- full/partial store miss no-allocate；
- 同 index 异 tag store miss 不误清原行(write-update 主收益定向)；
- 跨线 store：本行线内合并 + p1 保守失效；
- A/D 维护路(`store_rmw_en=0`)无条件失效、无 RMW 两拍窗口；
- MMIO/uncacheable store 无 RMW(busy 恒 0) + lookup miss；
- DMA 全失效先预热多个不同 cache line，再覆盖 lookup 判决、lookup 发射、fill、RMW 发射和
  RMW 判决冲突；每种重合都要求所有旧 line miss，事件后的 fresh refill 才能重新 hit。

桥侧配套(`tb_ooo_mem_axi_bridge`)：post-commit/post-drain 同址读命中合并后
line(不发 AR)；`store_rmw_write_update_and_bubble` 定向审核 RMW 判决拍压
`stage_advance`(站内保持=store 后 1 bubble, 刀 M 后判决拍 ready 可为 1=进寄存站排队)与字节合并数据经真实桥路径回读；
`dma_invalidate_blocks_hit_fusion` 先造 hot stale line，再让 DMA 事件与 S_LOOKUP 判决拍重合，
要求禁止 stale-hit fusion、发 AR 读取 fresh PMEM、回填后再次命中。

系统级永久回归 `Linux/tools/virtio-blk-smoke.S` 会在 QueueNotify 前主动读取 status、
used.idx 与 data/ext4 magic 三个设备回写区域，使代表性 line 先驻留 D-cache；这样缺少 DMA
失效时不能再靠冷 miss 假绿。该 smoke 只审核一次同步 virtio-blk 请求的 data/status/used-ring、
IRQ 与完成顺序；截至 2026-07-15，完整 Linux 严格 guest-check + natural-poweroff 门禁仍未闭合，
已有 ext4/systemd 启动推进不能替代该严格门禁，也不能扩张为 autonomous DMA coherence 结论。

建议命令：

```bash
make -C npc/rv64/testbench TESTS=tb_ooo_data_word_cache \
  RESULT_DIR=/tmp/tb-dcache run
```

## 7. Macro/OOC 待办

- [x] 建 dedicated spec，冻结 D-cache 边界语义。
- [x] 建 `common` facts 与 `debug` checker，并接入 focused TB。
- [x] focused TB 覆盖 line-cross/window/store/invalidate 语义。
- [x] 定义 memory-preserve/OOC placeholder 的读写端口、同拍读写优先级和 reset/valid 初始化假设。
- [x] 给 Yosys-STA 报告提供 non-signoff timing/area placeholder，避免 unknown area 被误当闭合。
- [x] SRAM 宏行为模型接入(Sram4096x113，1RW 同步读+1拍；2026-07-08)。
- [x] 二期赎回 store write-update：2 拍 RMW + `rmw_busy` 读口仲裁 + 宏加
  bit-write-mask(2026-07-09；一期无条件失效使 CoreMark load hit 99.3%→76.4%，
  为性能回归主因)。
- [ ] 提供 iEDA/Yosys 可读的真实 Liberty/LEF macro model，或 OOC timing report + 顶层约束接入
  (宏采购/生成时按 bit-write-mask 变体选型)。
- [ ] 若接入仿真顶层 XMR checker，需登记非真空 evidence；若只保留 focused TB，macro-boundary
  task-run 必须说明边界为何足够局部。

## 8. Macro/OOC Contract v1.1

> 状态：ACTIVE。`OooDataWordCache` 模块边界内实例化 1RW 同步读 SRAM 宏
> (Sram4096x113，bit-write-mask 变体)，模块名保持边界单元不变；仍非面积/时序签核。

### 8.1 当前选择

v1 采用 **module-internal SRAM macro**：`OooDataWordCache` 保持边界模块名(合同
checker 冻结)，内部实例化 `Sram4096x113` 行为模型(综合经 `SYNTH_BLACKBOX_MODULES`
黑盒化，实现来自工艺宏/fakeram)。桥 FSM(`OooMemAxiBridge`)已同步改为 S_LOOKUP
判决态协议，focused TB 已按两拍协议重写。v1.1 给宏加 `wmask_i[112:0]`
bit-write-mask 端口(真实 SRAM 宏常见变体)，赎回 store write-update(2 拍 RMW)。

### 8.2 端口与时序假设

| 类别 | v1.1 假设 | 说明 |
| --- | --- | --- |
| lookup read latency | `1 cycle` | 发射拍 `lookup_en_i/lookup_addr_i` 读宏，次拍 `lookup_hit_o/lookup_line_o` 针对锁存请求有效(同步读)。 |
| addr-attribute latency | `0 cycle` | `req_cacheable_o/req_line_cross_o/walk_cacheable_o` 是纯地址组合函数，不查存储阵列。 |
| write edge | `posedge clk` | fill 在时钟沿全 1 掩码写宏+置 valid；store RMW 判决拍在时钟沿按 wmask 写 data 段字节；store/A-D/DMA 失效在时钟沿清 valid FF。 |
| write visibility | `next cycle` | fill/store 对 valid FF 从下一拍可见；fill/RMW 写数据对"下一次 lookup 判决"可见(发射拍在写拍之后即可见，最短 写拍+1 发射、+2 判决)。 |
| store maintenance | `2-cycle RMW write-update` | commit 拍占宏口读 st_idx+锁存上下文；判决拍(`rmw_busy_o`)valid+tag match 则按 byte mask 写 data 段，并以全 1 tag mask 幂等写回锁存 tag；miss 无动作；跨线 p1 与 A/D 维护路(`store_rmw_en_i=0`)保守失效。 |
| same-cycle priority | `rst > DMA invalidate > fill/store` | DMA 是 valid 维护的最高运行期优先级，同沿 fill/store 不得重新置 valid；宏口的 fill、lookup、RMW 仍由桥 FSM 互斥，DMA 本身不占宏口。 |
| read/write conflict | 禁止(1RW) | 宏口四占用者(lookup 发射/fill 写/RMW 读/RMW 判决拍)两两不得重合；`rmw_busy_o` 压 `stage_advance` 出 store 后 1 bubble(刀 M 后)；OOO_ASSERT 立即断言把关(模块内 1RW + 桥内 MEM-RMW-PORT)。 |
| reset/runtime invalidate | valid-only clear | reset 与同步 virtio DMA 事件均清 `valid_q`；SRAM 内容无复位/擦除，invalid entry 无语义值。DMA 可见拍还组合屏蔽 lookup hit。 |
| DMA producer scope | synchronous queue-notify only | DPI 已完成本批 PMEM 写后产生一拍事件；B/IRQ 延后一拍发布。不是 autonomous DMA、line snoop 或通用 IO-coherence 合同。 |
| read ports | one synchronous read port | 原 req/walk two combinational views 已合并；互斥性由桥 FSM 状态证明({S_IDLE,S_RESP}∩{S_WALK_R,S_AD_UPDATE}=∅)。 |
| write mask | per-bit `wmask_i[112:0]` | bit-write-mask 宏变体：写拍仅 wmask=1 位落 wdata；fill 全 1；RMW tag 段恒全 1 并写回锁存 tag，data 段展开 byte mask。 |
| fill address owner | raw `fill_valid_i` | 仅地址 mux 提前选 fill index；en/we/wmask/valid 仍由 `fill_we`。集成必须保证 fill valid 时 cacheable/aligned 且与其他 SRAM owner 互斥。 |

### 8.3 Area Placeholder

`OOO_DATA_WORD_CACHE_INDEX_W=12` 与 Sram4096x113 定死，因此：

| 项 | 数值 |
| --- | --- |
| entries | `4096` |
| SRAM macro bits | `4096 * 113 = 462848`(tag 49b + data 64b 拼宽) |
| data bits | `4096 * 64 = 262144` |
| tag bits | `4096 * (64 - 3 - 12) = 200704` |
| valid bits (FF) | `4096` |
| total state bits | `466944` |

该数字只是 state-capacity lower bound，不是 stdcell area、SRAM compiler area、leakage 或 timing closure。
在 Liberty/LEF 或 OOC timing report 接入前，`NpcTop` 报告必须继续把 `OooDataWordCache` 面积标为未闭合。

### 8.4 STA 接入条件

- 若继续使用 blackbox：报告必须列出 read latency、write visibility、read/write 互斥合同、state bits，
  并声明 top area/timing 不含真实 D-cache macro。
- 若使用真实 SRAM/宏：必须提供 Liberty timing arcs 覆盖 clk→rdata 同步读、clk 到写可见性、
  setup/hold、reset/valid 初始化假设，并同步 `sta.tcl`/PDK 读入。
- 若使用 OOC stdcell netlist：必须给出 OOC synthesis/STA evidence，并说明顶层如何约束 blackbox
  input/output delay；不能只用 `check_macro_contracts.py` PASS 作为 STA 证据。

## 9. 变更记录

- 2026-07-08：新增 dedicated D-cache spec、debug/common checker 约束和 focused TB 覆盖清单，
  用于四黑盒 Yosys macro-boundary contract 的语义审核前置。
- 2026-07-08：新增 Macro/OOC Contract v0，定义 D-cache placeholder 的 0-cycle read、next-cycle
  write visibility、fill-then-store 优先级和 466944 state-bit lower bound。
- 2026-07-08：**SRAM 宏化落地(Contract v0→v1)**——tag+data 拼宽进 1RW 同步读宏
  Sram4096x113(位段 `{tag[112:64], data[63:0]}`)，valid 留 4096b FF；req/walk 双组合读
  视图合并为单读口两拍协议(发射拍/判决拍)，窗口移位与跨线阻断职责移至桥判决拍(锁存
  `paddr_q/read_cross_q`)；store 维护一期改无条件失效(write-update 保热刻意丢弃，
  perf 回归后二期评估 2 拍 RMW)；`store_invalidate_all_i` 死口与 `store_data_i` 一并删除；
  checker HIT-GATE 改打拍版、DWC-INVALL 删除；focused TB 重写为两拍驱动范式。真实
  Liberty/LEF/OOC STA 仍未闭合。
- 2026-07-09：**store write-update 赎回(Contract v1→v1.1)**——一期无条件失效实测把
  CoreMark dcache load hit 从 99.3% 打到 76.4%(性能回归主因)，按预告的 2 拍 RMW 赎回：
  宏加 `wmask_i[112:0]` bit-write-mask 端口(fill 全 1 掩码；store 只写 data 段字节，
  当时 tag 段掩码 0)；真 store commit 拍(当前统一为桥 S_WRITE_RESP b-ok，读口空闲)
  占宏口读+锁存上下文，次拍 tag match 则线内字节合并写、miss 无动作，`rmw_busy_o`
  压桥 `stage_advance`(store 后 1 bubble, 刀 M 后)；跨线 p1 保守失效；A/D PTE 写回维护路保持无条件
  失效(该拍 read 续访问可能同拍发 lookup，读口不空闲)。T4I 删除旧
  AW/W-fire 解耦路后，普通与 flush-drain store 都只会在聚合 B-ok 拍单次提交。
  新增 DWC-I9 与 checker DWC-RMW-BUSY/PORT/B2B；facts 加 STORE_RMW_ISSUE/BUSY；
  focused TB store 场景全部重写为 write-update 预期+新增 rmw 冲突定向。占位 lib 同步
  wmask pin(gen_macro_libs.py 再生成)。
- 2026-07-15：**同步 virtio DMA→D-cache 全失效合同**——新增仅由当前
  `AxiVirtioBlk` queue-notify 同步 DPI 完成事件驱动的 `dma_invalidate_all_i`；事件拍组合屏蔽
  lookup hit，下一沿以 `rst > DMA > fill/store` 优先级清全部 valid，SRAM 不擦除且不占 1RW 口。
  设备端把 notify B/IRQ 延后一拍，确保 cache 已采样失效；focused cache/bridge TB 覆盖全部冲突
  与 stale-hit fusion，永久 virtio smoke 预热 status/used/data line 防冷 miss 假绿。该合同不含
  autonomous DMA；Linux strict guest-check + natural-poweroff 仍是独立未闭合门禁。
- 2026-07-15（T4S）：fill 的 SRAM 地址选择从 `fill_we` 提前到 raw `fill_valid_i`，
  切断 cacheability reduction 到宏 addr 的 setup 锥；en/we/wmask/valid 仍由合法 `fill_we`
  授权，并显式冻结 fill-valid=>cacheable/aligned、与 lookup/RMW owner 互斥的 carrying contract。
  DMA valid 维护优先级不变。
- 2026-07-15（T4T）：RMW 命中时把 tag mask 改为恒全 1，并写回判决前锁存且已匹配的
  `rmw_tag_q`。这与 tag mask=0 在合法命中域功能等价，同时解除 `fill_we` 对 49 个高电容
  SRAM tag-mask pin 和特化 tag payload pin 的直接驱动；fresh netlist 结构审计固定检查该边界。

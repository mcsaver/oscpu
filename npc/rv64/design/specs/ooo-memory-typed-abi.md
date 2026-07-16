# 规范：OoO Memory Typed Post-Translate ABI（R4-S1）

> 状态：**S1.0 合同已冻结；S1.1 typed PMA/classifier 叶模块已实现，端到端 RTL 尚未实现**。
>
> 本文件冻结 final-PA 之后的 memory class、fault、owner identity 与 epoch 语义。当前 live
> bridge/backend/SQ 仍是 R4-S0 的 Boolean `cacheable/serialized` 单 owner 检查点；S1.1
> 新增的 typed 叶模块尚未接到事务 owner。本文出现的其它字段、编码和阶段门槛不得被解释为
> 已有端口、状态或性能已经落地。
>
> 顶层架构依据为 [微架构宪法 §8.6](../arch/ooo-core-architecture.md)，PPA 晋级依据为
> [架构与 PPA 合同](../arch/rv64-architecture-ppa-contract.md)。若局部模块文档与本文件冲突，应先按宪法
> 收敛合同，再修改 RTL。

## 1. 目的、范围与非目标

S1.0 只完成“先冻结合同”：

1. 给 CACHED、NC、IO 固定且不可重解释的编码；
2. 把 fault 从 memory class 中分离；
3. 给翻译、bridge、MIQ、SQ、cache 与 completion 建立同一 owner identity；
4. 冻结 token 与 MMU epoch 的创建、传播、匹配和释放时点；
5. 规定 PMA/PBMT 的唯一合并点、ordering 差异、断言族与后续实现门槛。

S1.0 不修改 RTL，不增加第二个 request port，不增加第二个 AGU、translation owner、data
owner、cache bank 或 completion owner，也不改变现有 CPI、面积、功耗和 200 MHz 证据。
合同冻结只能标记为 `spec_frozen`，不能标记为 `implemented`、`architecture_feasible`
或 PPA winner。

## 2. Memory class 与 fault

### 2.1 固定编码

| 名称 | `class[1:0]` | 语义 |
| --- | --- | --- |
| CACHED | `2'b00` | 可进入 D-cache lookup/fill；普通内存 ordering |
| NC | `2'b01` | 不可缓存、幂等的普通内存；走 exact access |
| IO | `2'b10` | 不可缓存、非幂等、强序设备；禁止投机 target |
| RSVD | `2'b11` | 非法/保留编码；永不作为合法 owner 属性保存或路由 |

`attr_valid` 是 `class` 的资格位：

- `attr_valid=1` 时，class 必须恰为 CACHED、NC 或 IO；
- `attr_valid=0` 时，class 无语义，consumer 不得据其选择 cache、exact 或 device 路径；
- RSVD 不得进入 request station、active transaction、MIQ、LQ/SQ、cache maintenance 或
  response owner。

### 2.2 fault 不是第四种 class

统一响应使用 `fault_valid + fault_cause + fault_tval`。不得再把 fault 编码为
`class=RSVD`、`serialized=1` 或任意可路由属性。

必须区分两个 fault 阶段：

| fault 阶段 | `fault_valid` | `attr_valid` | 规则 |
| --- | --- | --- | --- |
| pre-target：翻译/PTE、PBMT reserved、PMP、PMA | 1 | 0 | 不得发 data AR/AW/W，不得 lookup/fill，不得成功 fill SQ |
| post-target：AXI R/B error | 1 | 1 | 保留已锁存 PA/class/identity；B error 仍做保守 alias 维护 |

因此全局命题 `fault_valid -> !attr_valid` 是错误的；合法断言只能是
`pre_target_fault -> !attr_valid`。动态 R/B error 的 class 不是“fault 路由类别”，而是已经
发出目标事务的 provenance。

`fault_tval` 始终来自原始 faulting VA。SQ physical drain 即使请求地址已经是 PA，也必须
携带 probe 时保存的原始 VA；后端不得从当前 live VA、ROB index 或 PA 重新构造 tval。

## 3. PMA 基础类型与 PBMT 合并

### 3.1 当前平台 PMA 基础类型

PMA checker 必须先判定完整 byte range 是否由同一个真实 region 覆盖，再给出基础类型。
当前 `NpcTop` 地址图冻结为：

| 物理区域 | 基础类型 |
| --- | --- |
| `NPC_AXI_PMEM_BASE/MASK` 子窗口 | CACHED |
| PSRAM 中不属于上述 PMEM 子窗口的剩余区域 | NC |
| `NPC_AXI_SDRAM_BASE/MASK` | NC |
| reset-syscon、CLINT、PLIC、UART、virtio-blk、legacy-MMIO | IO |
| default、空壳 slave、wrap、跨 region、访问权限不合法 | DENY |

PMEM decode 与较宽 PSRAM decode 重叠，分类优先级必须是 PMEM CACHED 在前、PSRAM residual
NC 在后。不得因为 PSRAM 先匹配而把 PMEM 静默降为 NC。

PMA DENY 是访问许可失败，不是一种 memory class。PBMT 只能覆盖允许 region 的类型，不能把
DENY region 变成可访问。

### 3.2 PBMT/PMA 真值矩阵

`PBMT=inherit` 表示 Bare，或 translated leaf 的 PBMT=`00`。PBMTE 关闭时，只有
PBMT=`00` 可以 inherit；任意非零 PBMT 都是 reserved PTE 并在 PMA target 访问之前形成
page fault。PBMTE 开启时，合法 leaf 按下表合并，PBMT=`11` 仍为 page fault。

| PMA 基础结果 | inherit / `00` | `01` | `10` | `11` |
| --- | --- | --- | --- | --- |
| CACHED | CACHED | NC | IO | page fault，无 attr |
| NC | NC | NC | IO | page fault，无 attr |
| IO | IO | NC | IO | page fault，无 attr |
| DENY | access fault，无 attr | access fault，无 attr | access fault，无 attr | page fault，无 attr |

本矩阵采用 Svpbmt 类型覆盖语义。若平台希望禁止把基础 IO 映射为 PBMT-NC，必须另立
fail-closed 平台规则、定义异常类型并增加负测；禁止在 classifier、bridge 或 D-cache 中
无规范地 clamp。

PMP/PMA deny 不得被 PBMT 覆盖。PTE/PBMT 合法性先于最终物理 target 许可；PBMT reserved
因此报告 page fault，而不是先对无效 leaf 做 PMA target access。

### 3.3 唯一合并点

Bare、DTLB hit 与 PTW leaf 必须在 final PA、访问权限、PMP/PMA 和 leaf PBMT 全部已知后，
经同一个 typed classifier 恰好合并一次。成功结果为
`{paddr, attr_valid=1, class, mmu_epoch}`。

该结果进入 owner 后：

- PA/class/epoch/token 到 release 前不可变；
- bridge、SQ、D-cache 与 AXI adapter 只能消费，不能按 PA 再分类；
- pretranslated SQ drain 必须转发 probe 保存值，禁止重新执行 PMA/PBMT 合并；
- page-table fetch 是原 owner 的内部 slow-path phase，不能创建或替换 architectural
  owner identity。

## 4. Typed request/response envelope

本节只冻结跨 owner 边界必须出现的 typed envelope；已有 address/data/size/op payload 可在
模块局部保留原命名，但不得改变以下语义。

### 4.1 Request 必备字段

| 字段 | 宽度 | 语义 |
| --- | --- | --- |
| `owner_kind` | 2 | 逻辑 memory owner 类型，不能由 port/lane 编号推导 |
| `owner_token` | 5 | 一个逻辑 memory uop 的稳定身份 |
| `mmu_epoch` | 2 | owner 创建时捕获的翻译上下文世代 |
| `translate_only` | 1 | store probe；只做翻译/权限/分类，不产生 store side effect |
| `pretranslated` | 1 | 请求地址已是保存的最终 PA；典型为 SQ drain |
| `nonkill` | 1 | 已获精确副作用授权，flush 后只能 drain |
| `address` | XLEN | 普通请求为 VA，pretranslated 请求为最终 PA |
| `fault_tval` | XLEN | 原始 faulting VA，任何 phase 均保持 |
| `attr_valid` | 1 | 仅 pretranslated 请求必须为 1 |
| `class` | 2 | 仅在 request `attr_valid=1` 时有效 |

write/data/mask/size 等原有 operation payload 与上述 envelope 同属 request payload；当
`valid && !ready` 时必须逐位稳定。未翻译请求不得伪造 attr；pretranslated 请求不得仅凭
当前 PA 重新生成 attr。

### 4.2 Response 必备字段

| 字段 | 宽度 | 语义 |
| --- | --- | --- |
| `owner_kind` | 2 | 原样 echo |
| `owner_token` | 5 | 原样 echo |
| `mmu_epoch` | 2 | 原样 echo |
| `paddr` | XLEN | 成功 final PA；fault 时只按 attr/fault 资格消费 |
| `attr_valid` | 1 | final class 是否有效 |
| `class` | 2 | attr 有效时的锁存类型 |
| `rdata` | XLEN | 有效读完成数据 |
| `fault_valid` | 1 | 精确 fault terminal |
| `fault_cause` | `TRAP_CAUSE_W` | 精确 page/access fault cause |
| `fault_tval` | XLEN | 原始 faulting VA |

当 `rsp_valid && !rsp_ready` 时，以上全部字段必须稳定。最终 ABI 不保留
`cacheable`、`serialized`、`error`、`page_fault` 作为平行真源；迁移期兼容信号只能
在一个被点名的 adapter 边界由 typed response 派生，并在 S1 收尾删除。

## 5. Owner kind、token 与 phase

### 5.1 owner kind 固定编码

| `owner_kind[1:0]` | 名称 | 范围 |
| --- | --- | --- |
| `2'b00` | LOAD | 普通 load |
| `2'b01` | STORE | store probe 与同一 store 的 physical drain |
| `2'b10` | ATOMIC | LR/SC/AMO 的同一逻辑 owner |
| `2'b11` | RESERVED | 当前不得发出 |

内部 PTW、A/D update、cache refill、split beat 和 retry 都是原 owner 的 phase，不得改
owner_kind 或重新分配 token。Legacy transport 必须在进入本 ABI 前按真实 ISA 语义归一为
LOAD、STORE 或 ATOMIC，不能占用 RESERVED 逃避 ordering。

### 5.2 token 生命周期

`owner_token[4:0]` 是 modulo-32 的逻辑 owner token，最低面积实现可使用单调 allocator。
合同如下：

1. memory issue reservation 第一次捕获该 uop 时分配一次；
2. request stall、TLB miss、PTW、split、retry、store probe 与 store drain 均保持同一 token；
3. LOAD/ATOMIC 在精确 completion 或 killed response 完全 drain 后释放；
4. STORE 在 probe fault、被 kill 且无外部 owner，或 aggregate B terminal 后释放；
5. 已 fire 的 AXI owner 在 response drain 前仍算 live，flush 不能提前释放 token；
6. allocator 不得发出与任一 live 逻辑 owner 相同的 token。MIQ 与 SQ 同时保存同一 STORE
   token 属于同一个 owner 的多份 provenance，必须同时匹配 kind 与 ROB/SQ 身份；
7. port 号、lane 号、裸 ROB index 和 MIQ FIFO head 都不能替代 token。

如果实现依赖 ROB/MIQ/SQ 容量证明 modulo-32 不会碰撞，必须保留 live-token uniqueness
断言；不能把“正常仿真没绕回”当作证明。S2 双接纳时 allocator 可同拍产生连续两个不同
token，但这不属于 S1。

## 6. MMU epoch 生命周期

`mmu_epoch[1:0]` 是 translation context generation，不是性能预测 tag。唯一 epoch owner
只在“上下文有效改变且 memory context quiet”时递增。

需要推进 epoch 的事件：

- `satp` 有效值改变；
- `SFENCE.VMA` 提交；
- PMP cfg/address 的有效值改变，locked/no-op write 不推进；
- MPRV、MPP、SUM、MXR 的有效值改变；
- `menvcfg.PBMTE` 有效值改变；
- trap/IRQ entry、MRET/SRET 导致当前 privilege 改变。

`FENCE.I`、普通 `FENCE` 和静态 PMA 不单独推进 data-MMU epoch，除非它们同时触发了上述
真实 translation-context 改变。

`mem_context_quiet` 至少覆盖 request station、bridge active owner、MIQ、LQ/SQ、已授权
nonkill store 和 LR/SC/AMO owner。上下文改变只允许在 quiet 时发生，因此 2-bit wrap 不是用
来容忍 stale response；它只在没有旧 owner 时复用。

每个 owner 创建时捕获 epoch，request/response/SQ drain 全程 echo。epoch mismatch：

- 不得完成 WB、SQ fill、cache fill 或 architectural fault；
- speculative/killed owner 可以把总线响应 drain 掉，但 mismatch 必须触发契约断言；
- nonkill STORE drain mismatch 不能静默 drop，否则会丢失已提交副作用，必须作为 fatal
  contract violation。

## 7. Class 对 ordering/cache 的约束

| class | cache 行为 | load ordering | forwarding / speculation |
| --- | --- | --- | --- |
| CACHED | lookup/fill；B=OKAY 的普通 store 可 RMW | 物理 store CAM PASS 后可执行 | 允许合法 full-cover forwarding |
| NC | exact access；禁止 lookup/fill/RMW | 物理 store CAM PASS 后可在 ROB-head 前执行 | 幂等；可允许 full-cover forwarding |
| IO | exact access；禁止 lookup/fill/RMW | ROB-head + older drain terminal + global IO idle | 禁止 forward/prefetch/merge/replay/speculative target |

所有 store 的外部 write 仍只由 ROB-head `commit_authorized` owner 按程序序发出。类型分流
不能放宽 precise store side-effect 合同。

在 S1 单 owner 实现期，translated NC 可继续使用“对未知 older store 保守等待”的正确性
门禁，然后绕过 `S_DEVICE_WAIT` 发 exact access；translated physical forwarding 未完成前
可以保守禁用。该状态证明 NC 与 IO 已有不同 target ordering，但不能宣称已达到最终 NC
physical CAM/forwarding 性能。

D-cache 的地址谓词只能回答“该 PA 是否可能存在 cache alias”，不能产生事务 class。只有
`attr_valid && class==CACHED` 可以授权 lookup/fill/RMW；NC、IO 与任意 B error 都走保守
alias invalidation。

## 8. S1 single-owner claim 与 S2 RED 边界

S1 的合法 claim 仅为：

- typed class/fault 已端到端传播；
- NC 与 IO 的 target ordering 已分离；
- token/epoch/provenance 精确匹配；
- 仍是单 request、单 translation/data owner 的 correctness checkpoint。

以下能力在 S2 证据齐备前保持 RED：

1. lane1 memory uop 的独立 issue owner；
2. 两路独立 AGU；
3. 两个同构 translation request/response slot；
4. 两个 TLB hit 同拍 accept/complete，且一个 PTW miss 不阻塞另一 hit；
5. 两路 final-PA register；
6. 两路物理 SQ CAM/order query；
7. 两路 cache request admission 与真实 bank/conflict replay；
8. 两路 tagged memory completion；
9. 无冲突双 memory pair 的稳态 issue IPC 与 DI-3/DI-5 证据。

S1 不得解除 [架构与 PPA 合同](../arch/rv64-architecture-ppa-contract.md) 中 DI-3、DI-5
与相关 OOO-3 RED，也不得把 issue1 memory tie-off、单 reservation、单 bridge FSM 或
FIFO-head response pairing 描述为
“近似等价”的双 owner。

## 9. 立即断言与 mutation-negative

### 9.1 Class/fault

- `attr_valid -> class inside {CACHED, NC, IO}`；
- RSVD 永不存入 station、active、MIQ、SQ 或 response；
- `pre_target_fault -> !attr_valid` 且无 lookup/fill/AR/AW/W；
- post-target R/B error 保留原 owner identity、PA 与 class；
- Bare、DTLB hit、PTW leaf 的 PMA/PBMT 矩阵结果一致；
- pretranslated drain 的 PA/class/epoch/token 与 SQ head 完全相等。

### 9.2 Identity/epoch

- request backpressure 时 kind/token/epoch/tval/attr/class 与 operation payload 全稳定；
- response backpressure 时完整 typed response 全稳定；
- response 只允许 exact kind/token/epoch owner 消费；
- request fire 与 MIQ push 同拍同身份，response pop 只针对 exact head owner；
- PA/class/epoch/token 从成功 probe fill 到 SQ release 不变；
- context change 只在 `mem_context_quiet`；
- allocator 不与 live owner token 冲突；
- killed response 不 WB、不 SQ fill、不 cache fill、不产生 target side effect。

### 9.3 Class-specific side effect

- CACHED-only lookup/fill/RMW；
- NC exact access 且不进入 device release wait；
- IO release 前无 target AR/AW/W，cancel 优先于 release；
- IO 永不 forwarding/prefetch/merge/replay；
- B error 与 NC/IO store 均执行保守 alias invalidation。

mutation-negative 至少强制触发一次 RSVD class、PBMT reserved、PMA deny、NC RMW、IO lookup、
token mismatch、epoch mismatch、pre-target fault 发 target、pretranslated 属性重分类。每个
marker 必须有 non-vacuity 证据，不能只报告测试进程退出 0。

## 10. 分阶段实现与晋级门槛

| 阶段 | 允许改动 | 退出门槛 |
| --- | --- | --- |
| S1.0 | 仅合同/索引 | 编码、矩阵、生命周期、S1/S2 claim 通过审查；无 RTL 完成声明 |
| S1.1 | typed PMA/classifier 叶模块 | PMA region + PBMT 全矩阵、RSVD/fault negative；兼容 Boolean 只可派生 |
| S1.2 | 单端口 bridge typed station/active/response | hold/echo/no-target-on-fault、CACHED/NC/IO 三路定向测试 |
| S1.3 | backend/MIQ/SQ identity | token exact match、probe→drain 不变、fault 不 fill SQ、B terminal 精确 |
| S1.4 | D-cache typed consumer | CACHED-only lookup/fill/RMW，NC/IO/error maintenance，1RW owner 不变 |
| S1.5 | epoch owner/context gate | effective-change、quiet、wrap 与 mismatch negative 闭合 |
| S1.6 | 删除兼容 Boolean ABI | 无重分类/平行真源；module/AM/official/privileged、synth/STA/PPA 固定输入重跑 |

每个实现阶段必须单独可综合；失败时回退本阶段，不得用 S2 结构掩盖 S1 的 typed correctness。
在 S1.6 前，旧 Boolean 只能是单向 compatibility view，不能继续作为 routing authority。

## 11. 200 MHz 与 PPA carrying constraints

- PMA 宽 region decode 不得进入 request-ready、SRAM address owner 或 response-to-WB 组合回路；
- typed 结果应锁存在现有 final-PA capture 边界，优先复用现有寄存切点，不给 cached hit
  无证据增加一拍；
- token/epoch equality 在寄存响应 consumer 端检查，禁止形成 MIQ-head→bridge ready/valid 回环；
- fault cause/tval 随 response skid 寄存，禁止从 live PTE/PMP/CSR 重新组合；
- epoch owner 消费窄 effective-change pulse，不组合比较完整 CSR/PMP 向量；
- class 只门控 D-cache en/we/valid，不进入 SRAM address mux；
- SQ 只导出选中/head identity，避免把 token/class 高扇出到所有 CAM entry。

任何 S1 候选必须先通过功能与架构 hard gate，再进入固定输入的
Performance/Power/Area Pareto 比较。文档冻结、局部 WNS 或面积改善均不能替代动态 capability
证据。

## 12. S1.0 文档验收

S1.0 只在以下条件同时满足时完成：

- 宪法 §8.6 明确引用本合同并保持 S2 RED；
- 本文件已进入 active specs 索引；
- PMA 与 bridge active spec 明确“合同冻结、RTL 仍为 S0”；
- Markdown 基本结构、相对链接和 `git diff --check` 通过；
- S1.0 path-limited 变更集中没有 `vsrc/`、filelist、config、task report 或索引数据库改动；
  共享工作区已有的其它变更必须在交付时显式排除，不能混作本阶段证据。

后续任何 RTL 实现必须在独立 task-run 中记录定向测试与 mutation-negative。纯组合、尚未接入
live top 的叶模块还必须通过独立 lint/Yosys check，但不得据此声明 PPA；一旦切片影响 live/top
行为、时序或面积，则必须追加 whole-design 综合/STA 与固定 benchmark 证据。不得把 S1.0
docs-only 变更或 S1.1 leaves-only 证据当作端到端/PPA 实现证据。

## 13. S1.1 typed 叶模块实施记录

S1.1 新增 `OooTypedPmaChecker` 与 `OooTypedMemoryClassifier`，但没有迁移 live bridge：

- typed PMA 对完整 byte range 输出 CACHED/NC/IO 或 DENY，PMEM 优先于重叠 PSRAM，跨
  PMEM/PSRAM-residual 属性边界 fail closed；
- classifier 覆盖 PBMTE enabled 的 PMA `{CACHED,NC,IO,DENY}` × PBMT `{00,01,10,11}`
  16 格，以及 PBMTE disabled translated-leaf 的同一 16 格；page/access fault、RSVD poison
  与兼容 Boolean 均由 typed 真值唯一派生；
- 旧 `OooPmaChecker` 保持 P0-A 冻结 SHA256
  `e197b137bfe1126f9191eaf3b2cfce779d26bdce0ead4a94d831552fe5732c2b`，因此 S1.1 不会
  静默改变 bridge 对跨 PMEM→PSRAM footprint 的 S0 行为；有意行为切换必须在 S1.2 与 typed
  station/active/response 原子完成；
- mutation-negative、全核 Verilator lint 与叶模块 Yosys check 已通过，正式证据位于
  task-run 的 `evidence/r4-s1p1-typed-leaves-v2/`。早期端口扩展/runner 失败结果已移入 workspace
  `tmp/`，不得作为有效证据。

因此 S1.1 的合法 claim 仅为 `typed_leaf_truth_table_implemented`。bridge/D-cache/SQ/backend
仍未消费 typed attr，token/epoch 和第二 memory owner 均不存在；S1、S2、DI-3、DI-5、OOO-3
继续 RED。

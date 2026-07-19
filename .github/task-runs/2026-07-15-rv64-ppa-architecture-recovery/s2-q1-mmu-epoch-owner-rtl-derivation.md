# S2-Q1 `OooMmuEpochOwner` RTL 推导

> 状态：`contract_frozen / source-catalog GREEN / live integration RED`
>
> parent completion definition 仍是 R4-S1-ID exact-owner-provenance。Q1 只是可独立回退的
> intermediate checkpoint，不改变完整 S2、architecture seed、200 MHz 或 PPA qualification 状态。

## 阶段 0：接口契约冻结

规范真源为 `npc/rv64/design/specs/ooo-mmu-epoch-owner.md` §2/§3；六类合同摘要：

| 类别 | 本切片判据 |
| --- | --- |
| handshake | request/grant 均为 sticky valid-ready；bundle 到 fire 前稳定 |
| stall | request ready 只看 FSM/cause；capture block look-ahead；quiet 不依赖 ready |
| flush/kill | reset 是唯一清除；普通 flush 不丢已捕获 boundary；block 不阻旧 drain |
| exception order | 上游只送精确 head boundary；叶模块不选年龄、不提交 ROB |
| memory order | quiet+live-empty 后才 grant；grant edge仍封住旧 epoch capture |
| recovery truth | held payload/cause 与本地 epoch 为唯一真源；禁止 live CSR/raw flush 重建 |

同拍优先级为 `reset > state-local handshake/transition > hold`。Q1 没有 AXI 或 store 清除端口，因而
不会违反 committed store/issued AXI 必须 drain 的铁律；后续集成必须证明 block 只作用于新 capture。

## 阶段 1：需求

1. 接收一个由 CsrFile/ROB integration 预先判定为 effective 的 context/SFENCE event。
2. request 首次出现的同一组合拍拉高 capture block，并在 request fire 锁存 opaque payload/cause。
3. 至少经历一个完整 LOCKED_DRAIN 周期，等 `mem_context_quiet && owner_live_empty` 后给出 grant。
4. grant 可无限 backpressure，cause/payload/epoch不得变化；第二请求不得覆盖。
5. grant fire 是唯一 context apply/epoch publish 边界；该 edge epoch `+1 mod 4`，且不能同时接受新请求。
6. reset 后 epoch=0；非法状态 fail closed。
7. 关键路径只允许 `request_valid/state -> capture_block`，payload/quiet不得进入 memory ready。
8. out-of-scope：effective classifier、selective squash/full quiet生产者、commit apply、epoch response enforcement、
   post-grant live/release、双 memory 和所有 PPA 裁决。

端口采用参数化 `CAUSE_W`/`PAYLOAD_W`。payload 可在后续承载 event owner、candidate context 和 apply
metadata；本叶不解释，也不从 live CSR 回读。

## 阶段 2a：协议规则

- request：producer 抬 valid并保持 cause/payload，consumer只在 UNLOCKED+非零 cause 抬 ready；fire 后
  producer可撤回。busy 期间的新 request必须保持到 ready，叶模块不排第二项。
- capture block：不是 request ready 的别名；`state != UNLOCKED || request_valid`。producer valid不得由
  block 反向组合门控，未来 memory capture consumer必须直接消费 block。
- quiet：两个输入都是外部寄存事实/其组合归约，只在 posedge采样，不参与 ready/block 组合网络。
- grant：COMMIT 的 Moore valid；consumer ready可任意背压。fire 前 held bundle与 epoch稳定。
- epoch：fire 的同一 edge `+1`，不是进入 COMMIT 时提前推进；fire edge pre-state仍 blocked，下一拍才开放。
- 错误：zero cause、payload hold违约、quiet在 COMMIT回落、非法 state 在 assert build fatal；release build
  的非法 state保持 `ready=0/block=1/grant=0`。

## 阶段 2b：状态机

| 当前状态 | 条件 | 下一状态 | 时序动作 |
| --- | --- | --- | --- |
| UNLOCKED | request fire | LOCKED_DRAIN | 锁存 cause/payload |
| UNLOCKED | otherwise | UNLOCKED | hold |
| LOCKED_DRAIN | quiet && live-empty | COMMIT | 无；epoch仍旧值 |
| LOCKED_DRAIN | otherwise | LOCKED_DRAIN | hold |
| COMMIT | grant fire | UNLOCKED | epoch+1、清 held bundle |
| COMMIT | otherwise | COMMIT | grant/bundle hold |
| illegal | any | illegal/locked | release fail closed；assert build fatal |

不采用 `UNLOCKED && request && quiet -> grant` 直通；该拍 quiet 未包含与请求同拍可能进入的旧 epoch
capture。不采用第四个 post-grant LIVE 状态：冻结 E1/E3 定义 grant fire就是 context apply边界，额外
release owner会与 `OooMemOwnerTracker` 职责重叠并扩大本切片 completion definition。

## 阶段 2c：不变量

| ID | 触发与表达式 | 结构/检查 | 违约后果 |
| --- | --- | --- | --- |
| Q1-I1 | request_valid -> capture_block | 组合 look-ahead + TB mutation | 同拍旧 epoch owner 泄漏 |
| Q1-I2 | busy -> !request_ready；held bundle不覆盖 | 状态译码 + delayed assertion | 第二 boundary 覆盖第一项 |
| Q1-I3 | grant -> 先前完整 quiet/live-empty | LOCKED_DRAIN 唯一入口 + COMMIT assertion | context混代 |
| Q1-I4 | grant&&!ready -> 下拍 grant/bundle/epoch稳定 | delayed immediate assertion | 单拍事件/候选丢失 |
| Q1-I5 | epoch_next = epoch + grant_fire | delayed expected-value assertion | 重复/提前/漏 bump |
| Q1-I6 | grant_fire edge capture_block=1 && !request_ready | direct assertion | transition gap分配旧 epoch |
| Q1-I7 | request fire cause!=0，多 cause一次 fire | ready资格 + TB wrap sequence | no-op/重复 bump |
| Q1-I8 | state in {00,01,10}；illegal fail closed | output equality + fatal | X/unused encoding打开入口 |

断言用 `always @(posedge clk)` 立即检查，禁止 SVA。negative runner必须命中命名 marker，mutation runner
必须编译成功后由预期 directed marker杀死，不能把编译失败或 timeout算 mutation kill。

## 阶段 2d：数据通路约束

- 状态寄存器 `state_q[1:0]`，编码 00/01/10，11 保留非法。
- bundle寄存器 `held_cause_q[CAUSE_W-1:0]`、`held_payload_q[PAYLOAD_W-1:0]`。
- epoch寄存器 `mmu_epoch_q[1:0]`，唯一加法器是 2-bit `+ 1`，仅 grant fire enable。
- 组合译码：request-ready、request-fire、grant-valid、grant-fire、capture-block、quiet-qualified。
- 没有 RAM、队列、wide compare、shared ALU、function 或 for-loop。
- cause OR-reduction只资格化 request ready；多 bit不做 popcount，不影响 epoch增量。

## 阶段 2e：RTL 级电路拓扑与自审

1. **边界**：单时钟同步 reset；两个 ready-valid端口 + 两个 quiet facts + block/epoch输出。
2. **状态寄存器**：`state_q` reset 00；held bundle reset 0；epoch reset 0；一个 posedge block更新。
3. **组合块**：等值比较/OR/AND 形成 ready/fire/block/grant；无大组合 always。
4. **FSM**：严格按 2b 三态表；default不恢复为 UNLOCKED。
5. **pipeline/flow**：capture edge → 至少一拍 drain → COMMIT sticky grant → consume edge；无直通 grant。
6. **优先级**：reset最高；其后 case state局部动作；无 flush/kill输入。
7. **资源**：2-bit incrementer独占 epoch；bundle寄存器无共享 mux，只由 capture写、grant fire清。
8. **critical path**：`request_valid/state_eq -> capture_block`；其次 `state_eq/cause_or -> request_ready`。
9. **function划分**：不使用 function；FSM、握手和断言全部显式 wire/posedge block。

自审结论：端口能承载后续 candidate/apply metadata；grant backpressure、same-cycle block与transition gap
闭合；quiet和ready无组合环；第二请求不会覆盖；reset以外不丢 accepted event。剩余关键风险位于本叶
外部的 classifier、full quiet与grant apply原子接线，故实现后仍只能声明 Q1 intermediate GREEN。

## 阶段 3 实现状态

`OooMmuEpochOwner.v`、共享 filelist、正式 module TB、canonical focused runner 与
fail-closed adoption checker 已落地。helper 严格验证 pre-increment epoch 为
`expected_epoch - 1 mod 4`；4 个 negative 绑定完整唯一 assertion 行，7 个 mutant
必须先编译成功且各自只命中一个预期 directed FAIL。

## 阶段 4 验证与边界

- focused：release/assert `2/2`、assertion-negative `4/4`、exact mutation
  `7/7`，release/assert Verilator、leaf style、Yosys check、adoption contract 全 PASS；
- 正式 harness：Q1 log 同时包含 focused marker、`[PASS] tb_ooo_mmu_epoch_owner` 和
  `[RESULT] PASS`；
- fresh module aggregate：`104/104 PASS`；其间发现的 `tb_ooo_priv_system`
  typed-response 悬空输入已用平台 `OooTypedPmaChecker` 与 request→response owner/epoch
  锁存修复，未关闭断言；
- source catalog 精确出现 leaf 一次，`check-rtl-style` 与 `check-contract` PASS。

因此 Q1 只升级为 source-catalog GREEN。live precommit classifier、selective squash、完整 quiet、
grant-gated normalized apply、TLB/FPC invalidate、LR clear、response epoch 与真实双 memory 仍是 RED。

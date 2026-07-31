# NPC (RTL CPU) 模块笔记

## RV64 V11R OooIntBackend integer EX1 packet lane1（2026-07-31）

### EX1 common packet 周期合同

- `issue1_exec_fire_w` 的 fixed-latency ALU completion 与
  `mem_issue1_res_local_complete_w` 的 lane1 misaligned-load local
  completion 共享 `ex1_up_payload_w → PipeStageReg →
  ex1_down_payload_w`。
- TB 用独立 allocation schedule 预期
  `P0={generation=1,index=2}`、`P1={generation=1,index=3}`；
  expected ProducerId 不从 `ex1_producer_id_q`、packed alias 或 WB
  回读构造。
- ALU source 必须保持 full ProducerId、result 与 pdest；local-memory
  source 必须从 resident holder identity 保持 full ProducerId、
  exception、cause 与 tval。packed alias 与 raw registered packet
  分别检查。
- `ex1_pre_auth_valid_w` 必须同时满足 packet valid、非 flush/kill 与
  exact `ex1_producer_open_w`。same-edge claim 比较 generation+index；
  相同 index、错误 generation 不得 suppress 或 authorize。
- same-cycle flush 必须切断 completion authority，下一周期 registered
  packet 必须为空；不得用输出去重或弱化 assertion 替代 holder death。

### TB / EDA evidence

- production RTL 未修改；`OooIntBackend.v` SHA-256
  `49ec3d7e…cca5a`，`PipeStageReg.v` SHA-256 `4f260ff5…775`，
  design-id `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- focused marker：
  `[V11R-EX1-ALU-PACKET][PASS]`、
  `[V11R-EX1-AUTH-EDGES][PASS]`、
  `[V11R-EX1-LOCAL-PACKET][PASS]`、
  `[V11R-EX1-DEATH-EDGES][PASS]`、
  `[V11R-INT-LANE1-PACKET-MATRIX][PASS]`。
- 32/32 profile PASS：4/4 `GEN_W=1/4 × assert/release` baseline；
  14 类 compile-success mutation 的 28/28 release profile 均
  `compile.rc=0` 后在声明 exact-stage 被拒绝；3/3 ordinary regression。
- mutation 覆盖 EX1 generation/index/result/pdest pack、alias
  generation/index、ALU/local capture、local source identity、
  exception/tval、flush pre-auth、exact-open bypass 与 index-only
  same-edge claim。
- runner unit 7/7、semantic unit 79/79、combined checker 85/85 PASS；
  source pre/post、production SHA、graph/census 与 V11H replay current
  binding 一致。

### Evidence chain 与边界

- ledger 只把 `integer-ex1-packed-alias`、`integer-ex1-packet` 从 GAP
  提升为 PASS：32→34 PASS、12→10 GAP；其它 42 个 unit 状态不变。
- current graph 为 15 holder modules、17 instances、2 duplicate
  modules；ledger 保持 `status=GAP`、whole architecture=`RED`、
  PPA=`UNPROMOTED`。
- 独立 reviewer contract SHA-256 为 `74d26bb9…eddd`，bounded PASS，
  blocker=0；reviewer 未修改文件并已归还 single-flight ownership。
- A3 原始 FAIL 与冻结 checker replay PASS 分离。replay 只纠正旧 dmesg
  oracle 对 `printk: debug:` 的误判，不构成 system/PPA 晋级。
- 早期 diagnostic 原始 artifact 未 immutable 保存，记录为
  evidence-process GAP。后续所有尝试必须使用唯一 `attempt-N` 目录，
  `--overwrite` 不得作用于 canonical/attempt evidence。
- DB brief 对 `OooIntBackend integer ex1 packet lane1` 由 failed 变为
  complete；`npc-dev` e2e completed 5/5，显式绑定该 run 的 11-path
  scoped strict guard PASS。
- full-worktree strict guard 仅缺范围外
  `nemu/src/isa/riscv64/inst/amo.c → nemu-dev`；NPC profile PASS。
  raw evidence 2,452 项、2,740,579,918 bytes 按 index-only 登记。
  task-run Markdown/memory 已 DB-owned；刷新旧 memory backup hash 后，
  DB-first、Markdown coverage 与 artifact audit PASS，原首次 FAIL 保留。
- task-run：
  `.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic/`。

## RV64 V11P checkpoint irreversible-write ProducerId（2026-07-31）

### OooIntBackend checkpoint irreversible write 周期合同

- accepted non-probe physical STORE/AMO write 产生
  `checkpoint_irrevocable_write_launch_w`；holder 必须从 exact owner token
  的 tracker table 捕获完整 ProducerId，而不是只保存 ROB index。
- STORE B response 由 MIQ drain 完成，不进入 tagged terminal collector
  lane0；AMO write final 才由 collector lane0 接受 exact
  `{kind,token,epoch}`。两类 terminal 都不能提前清
  `checkpoint_irrevocable_write_q/pid_q`。
- AMO tracker 可以在 ROB retirement 前先死亡；此窗口内 checkpoint
  holder、`checkpoint_irrevocable_write_live_mask_w`、
  `transient/external/producer_live_mask_w` 与 restore barrier 都必须保持。
- holder 只允许 lane0 exact full ProducerId retirement 清除。相同 ROB
  index、不同 generation 必须保持；清除后 pending restore 才能在
  `sq_no_active_write_w && !drain_inflight_q` 下 apply。

### TB / EDA evidence

- production `OooIntBackend.v` 未修改，SHA-256
  `49ec3d7e…cca5a`；design-id
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- focused TB 先合法推进一轮 ROB generation，并把 tracker cursor 定向到
  token 28；expected PID/token 来自 stimulus schedule，不读取 holder。
  所有关键状态使用四状态 exact equality。
- 24/24 profile PASS：4 个 GEN_W=1/4、assert/release baseline；10 类
  compile-success RTL mutation 的 20 个 release profile；3/3 ordinary
  regression。runner tests 6/6 PASS。
- mutation 覆盖 capture generation 截断/X、STORE/AMO birth 抑制、
  terminal 提前清 holder/破坏 PID、live-mask 漏项、retire 抑制、
  index-only compare 与 restore gate 漏 holder。每个变体先编译成功，再
  由唯一预期 stage 拒绝。
- V11J/K/L/M/N/O shared current rebind 分别为
  32/32、34/34、34/34、39/39、30/30、20/20 PASS。semantic aggregate
  为 17/17 + 15/15 + 75/75 PASS；V11H replay PASS。

### Evidence chain 与边界

- current product graph 为 15 holder modules、17 instances、2 duplicate
  modules。`npc/rv64/Makefile`、checker 默认 graph、census product config、
  graph/audit、replay 与 ledger 均绑定 V11P 当前路径及 SHA。
- ledger 只把 `checkpoint-irrevocable-write-producer` 从 GAP 提升为
  PASS：28→29 PASS、16→15 GAP；其它 43 项状态不变。
- raw evidence 1,978 项已 index-only 登记；`npc-dev` 第二个与 freshness
  run 均 completed 5/5，12-path scoped strict guard PASS。首个
  recall-blocked run 原样保留；full-worktree guard 的范围外
  `nemu/.../amo.c → nemu-dev` 按 mixed-origin exemption 记录。
- reviewer role verdict 为 `APPROVED_NOT_PROMOTION_ELIGIBLE`。fresh
  isolated reviewer 因 agent task 槽位不可用而未启动，本轮只声明明确的
  main-agent 审查者角色结论。
- 本轮不证明其余 15 个 semantic GAP、global no-live-reuse、whole
  architecture、current-design full-system、synthesis/STA/power/PPA。
  A3 原始 FAIL 保持不可变；此前 V11H production RTL delta 仍要求未来
  system promotion 前再认证。整核 RED，PPA UNPROMOTED，长期 goal
  active。

## RV64 V11O memory-buffer-token（2026-07-31）

### OooIntBackend memory buffer token 产品可达性与 legacy 周期合同

- `NpcCoreTop` 对当前产品实例设置 `ENABLE_DUAL_MEM=1`，参数经
  `OooCoreTopGlue`、`OooExecuteBackend`、`OooAluCoreSlice`、
  `OooAluDecodeBackend` 原值传到 `OooIntBackend`。源码合同要求两个
  buffer birth gate 与 request gate 均受 `!ENABLE_DUAL_MEM` 控制，并且只有
  lane0/lane1 两个 valid-set 写点。
- Yosys 参数专化后，产品实例的 `issue0_mem_buffer_fire_w`、
  `issue1_mem_buffer_fire_w`、`mem_buffer_req_valid_w` 必须精确为
  `["0"]`。源码 regex 与 elaborated full JSON 必须合取，任一漂移均
  fail closed。
- dormant `ENABLE_DUAL_MEM=0` 配置仍保留完整生命周期合同：
  reservation handoff 捕获 full owner token；backpressure 周期保持；
  buffer→MIQ transfer 后清 holder；SQ terminal 或 selective branch cancel
  以同一 token 结束 owner authority。

### TB / EDA evidence

- production `OooIntBackend.v` 未修改，SHA-256
  `49ec3d7e…cca5a`；design-id
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- focused TB 先产生旧 store token 28，再以输入 stimulus 预期 token 29；
  expected state 不读取 `mem_buffer_owner_token_q`，关键检查使用四状态
  exact equality。
- 20/20 profile PASS：4 个 `GEN_W=1/4 × OOO_ASSERT on/off` baseline，
  8 个 compile-success RTL mutation 的 16 个 release profile，以及 3/3
  ordinary regression。
- mutation 覆盖 lane0/lane1 capture 高位截断、lane1 X token、resident
  hold 截断、transfer mux 截断、transfer clear 抑制、cancel authority mask
  截断与 cancel 抑制；所有负向版本先成功编译，再由预期生命周期 stage
  拒绝。
- product static negative tests 8/8、runner tests 4/4、semantic evaluator
  direct 64/64、组合语义门 17/17 + 15/15 + 70/70 PASS。
- V11J/K/L/M/N shared-TB current rebind 分别为 32/32、34/34、34/34、
  39/39、30/30 PASS。

### Evidence chain 与边界

- current graph 为 15 holder modules、17 instances、2 duplicate modules；
  ledger 只把 `memory-buffer-token` 从 GAP 提升为 PASS：
  27→28 PASS、17→16 GAP。
- V11H replay receipt 已重绑 current V11O graph 并 PASS；A3 与 V11H
  原始 FAIL 均保持不可变。
- reviewer role verdict 为 `APPROVED_NOT_PROMOTION_ELIGIBLE`。fresh
  isolated reviewer 因 agent thread 槽位不可用而未启动，这一协作局限
  已记录，不冒充独立 agent 结论。
- raw evidence 1,783 项只写索引；8 份 task-run Markdown DB-owned。
  `npc-dev` freshness run `...revtag-v11o-3` 为 5/5 completed，显式绑定
  该 run 的 13-source-path scoped strict guard PASS；记录层另由 DB-first、
  Markdown coverage 与 artifact audit 约束。full-worktree guard 唯一缺口
  是范围外 `nemu/.../amo.c → nemu-dev`，按 mixed-origin scope exemption
  保留，不外推为 NPC 缺陷。
- V11O macro 内的未调用实验 task `v11o_unused_load_blocked_probe` 不进入
  initial 执行路径或 PASS oracle，保留为后续共享 TB 清理债务。
- 本轮不证明其余 16 个 semantic GAP、global no-live-reuse、whole
  architecture、current-design full-system、synthesis/STA/power/PPA。
  整核 RED，PPA UNPROMOTED，长期 goal active。

## RV64 V11N memory-pending holder（2026-07-30）

### `OooIntBackend` 周期合同

- AMO request fire 后 `mem_pending_q` 持有完整
  `{mem_producer_id_q, mem_owner_kind_q, mem_owner_token_q,
  mem_owner_epoch_q}`；read wait、read→write 相位切换、write grant stall 与
  write fire 后均不得截断或漂移 PID/token。
- successful read response 只进入 write phase，不是 final terminal。
  exact write final/read fault 走 collector lane0；write 前 interphase cancel
  走 lane9。read fault 不得再产生 lane9 duplicate terminal。
- dispatch lane1 可携带 AMO，但 production
  `issue1_is_amo_w=1'b0`；它必须串行晋升到 execution terminal0，不能把
  语法上的 issue1 exclusive 分支当作可达 AMO terminal1。
- terminal/death 使用 edge-old tracker token→ProducerId mapping；同沿死亡
  不得被新出生借用。禁止通过吞事件或去重逻辑掩盖重复 terminal。

### TB / EDA evidence

- production `OooIntBackend.v` 未改动，SHA-256
  `49ec3d7e…cca5a`；design-id
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- focused TB 先完成 ROB generation prime，expected
  `V11N_PID0/1` 固定为 generation=1；tracker cursor 在 reset-domain
  边界定向到 token 28 后立即 release。expected PID/token 不读取 DUT
  pending holder，所有关键比较使用四状态 exact equality。
- canonical runner：30/30 PASS，含 4 个 GEN_W=1/4、assert/release
  baseline，13 类 compile-success release mutation 的 26 次仿真，以及
  3/3 ordinary regression。
- mutation 覆盖 capture/read/write 的 PID generation/token 高位截断或
  X/Z、read-phase 提前清 pending、final 不清 pending、lane9 抑制和错误
  token；所有变体先成功编译，再由唯一目标 stage 失败。
- runner 单测 6/6、semantic evaluator 58/58、combined semantic gate
  64/64 PASS；V11J/V11K/V11L/V11M current rebind 分别为
  32/32、34/34、34/34、39/39 PASS。
- fresh Yosys graph：15 holder modules、17 instances、2 duplicate modules、
  194 reachable instances。`OooIntBackend` 产品实例只有 1 个。

### Evidence chain 与边界

- semantic ledger 只把 `memory-pending-producer-cache` 与
  `memory-pending-token` 从 GAP 提升为 PASS：25→27 PASS、19→17 GAP。
- `memory-buffer-token` 不由本轮代替；current product
  `ENABLE_DUAL_MEM=1` 下 legacy buffer 路径虽为参数关闭，仍需独立
  product-inactive exemption 或配置专属证据。
- 独立终审 v2 为 `APPROVED_NOT_PROMOTION_ELIGIBLE`，blocker=0；
  第一份超时 partial review 明确不作为 approval。
- A3 原状态保持
  `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0`；V10F replay
  独立 PASS 且 `original_status_preserved=true`。该 replay 不重跑 DUT，
  不外推 current-design system 或 PPA。
- 本轮不证明其余 17 个 semantic GAP、global no-live-reuse、whole
  architecture、full-system、synthesis/STA/power/PPA。整核 RED，
  PPA UNPROMOTED，长期 goal active。

## RV64 V11M dual memory-reservation holder（2026-07-30）

### `OooIntBackend` 周期合同

- 两路 memory reservation 只在双 tracker credit 与双 IQ owner 都可接受时
  原子出生；capture 同沿必须同时完成 alloc0/alloc1、IQ pop2 和两份
  `{full ProducerId, owner kind/token/epoch, addr, size, unsigned, pdest, PC}`
  tuple 锁存。
- READY=00 时 valid holder 的完整 tuple 保持；READY=10/01 只允许对应 lane
  request fire，同沿把 exact tuple 交给对应 MIQ。request fire 是 owner
  迁移，不是 tracker terminal。
- local exception、selective recovery 与 global flush 必须优先于 request
  side effect；collector lane6/lane7 只有在 exact kind/token/epoch 被接受后
  才结束对应 tracker lease。
- pair turnover 同沿同时处理旧 lane0/1 `HELD→MIQ` 和新 pair
  `IQ→HELD`；edge-old death 不得提供同沿新出生 credit，survivor lane
  identity 不得被另一 lane 的 ready/terminal/recovery 改写。

### TB / EDA evidence

- production `OooIntBackend.v` 未改动，SHA-256
  `49ec3d7e…cca5a`；design-id
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- focused testbench 先合法消耗一整轮 ROB，使四个 reservation ProducerId
  为 generation=1/raw index 0..3；在 reset-domain 边界把 tracker cursor
  定向到 token 28，随后观察 28/29→30/31。该注入只检验 holder 完整位宽，
  不证明 allocator 自然流到达 28。
- canonical full-width runner 为 39/39 PASS：2 个 assert/release
  production baseline、37 个 compile-success release mutation；3/3
  ordinary regression PASS。所有 mutation 都先证明编译成功，再要求唯一
  lane/stage oracle 非零退出。
- v2 独立审查发现第一版 generation=0、token 0..3 无法区分四个高位截断
  变体；补强后的两路 ProducerId generation truncate 与两路 token high-bit
  truncate 均 `compile rc=0`、`sim rc=1`，在 `@124` 被精确 lane stage
  捕获。
- runner 单测 7/7 PASS，覆盖 37 个 mutation、compile/sim timeout
  fail-closed 与 stage-prefix 拒绝；semantic evaluator 单测 51/51 PASS，
  覆盖 schema、identity、39/37/3 计数和四单元 policy 绑定。

### Evidence chain 与边界

- 共享 TB current rebind：V11J、V11K、V11L 全部 PASS；V11H attempt-4
  frozen-input checker replay 在当前 checker/policy 下 PASS，原始
  `FAIL@semantic-ledger-unit` 不改写。
- current Yosys instance graph 为 15 holder modules、17 holder instances、
  2 duplicate modules；semantic ledger 只把
  `memory-reservation{,1}-{producer,token}` 从 GAP 提升为 PASS：
  21→25 PASS、23→19 GAP。
- 独立终审 v3 为 `APPROVED_NOT_PROMOTION_ELIGIBLE`，未发现 oracle
  coupling、compile-failure 假绿或 edge-old/edge-new identity 混淆。
- 本轮不证明 token allocator 自然可达性、其余 19 个 semantic GAP、
  `global_no_live_reuse`、whole architecture、full-system、
  synthesis/STA/power/PPA。整核保持 RED，PPA UNPROMOTED。
- A3 原 strict FAIL 和独立 checker replay PASS 都保留。V11M 局部结论不
  要求系统重跑；V11H production LoadQueue 变化仍要求未来 current-design
  system promotion 前再认证。
- 下一项优先审计
  `memory-buffer-token`、`memory-pending-producer-cache` 与
  `memory-pending-token`，先建立 current-source binding 与
  stimulus-owned birth/hold/terminal/death 反例。

## RV64 V11L dual memory-retry holder（2026-07-30）

### `OooIntBackend` 周期合同

- 两个 SQ replay lane 在 exact query capture 时分别锁存本 lane
  `{full ProducerId, owner kind/token/epoch, fault_tval, addr, size,
  unsigned, wdata, wstrb}`。期望 tuple 由 reset 后 allocation schedule
  固定，不从 `mem_retry*_q` 或 request 输出反推。
- capture 后源 MIQ 必须为空；READY=00 的连续反压周期中 holder tuple
  不漂移，tracker lease 仍精确 live。C0 full-flush barrier 同时阻断空
  holder capture 与已填充 holder fire。
- READY=10/01 分别只允许 lane0/lane1 迁移；fire 同沿产生对应
  `push_retry*_w`，次周期 holder 清除且目标 MIQ occupancy/token-mask
  精确。request-fire 是非终结迁移，不能提前清 tracker。
- exact response 由 collector lane0/lane1 接受后 tracker 才 death。
  `flush_i && READY=11` 必须 cancel 优先于 fire，无 request/MIQ push，
  collector lane10/lane11 分别接受 exact terminal，次周期 holder、MIQ
  与 tracker 清除。禁止用 dedup 掩盖重复 terminal。

### TB / EDA evidence

- production `OooIntBackend.v` 未改动，SHA-256
  `49ec3d7e…cca5a`；design-id
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- `tb_ooo_int_backend.sv` 的
  `V11L_MEMORY_RETRY_HOLDER_FOCUSED` 分支使用 lane-distinct
  PID/token/address/size、四态 `!==`、source MIQ empty、READY=00、
  READY=10/01、C0+READY=11 与 flush+READY=11。
- canonical runner 34/34 PASS：2 个 production baseline、32 个
  compile-success release mutation；每个 mutation 都记录实际
  `iverilog` command/define/source manifest、`.vvp` 和 sim log，并由
  唯一 expected stage 拒绝。3/3 ordinary regressions PASS。
- 32 个变体覆盖：
  - 两 lane ProducerId/token cross-wire；
  - raw ProducerId/token X/Z；
  - hold tuple drift 与提前 valid death；
  - fire 后 holder 残留、漏 MIQ push；
  - cancel 漏 terminal 与 fire 提前 terminal；
  - C0 capture/resident fire 放行；
  - flush 下 cancel candidate/transport 放行。
- 预审指出的透明跟随源、陈旧 MIQ 命中、两 lane 同 ready、fire 时提前
  tracker death 与 flush-ready 同拍假绿均已转为 TB 检查或变体。终审
  fixed verdict `APPROVED_FOR_CURRENT_SCOPE`。

### Evidence-chain 与边界

- 新 Makefile 入口导致旧 V11J/V11K shared manifest fail-closed；当前
  rebind 分别 32/32 与 34/34 PASS，未通过放宽 checker 续用旧证据。
- V11H attempt-4 frozen checker replay 在当前 checker/policy 哈希下
  PASS；原 checker-local FAIL 保留。
- semantic ledger 只把
  `memory-retry0/1-producer-cache` 与 `memory-retry0/1-token` 四单元从
  GAP 提升为 PASS：17→21 PASS，27→23 GAP；其余 40 单元状态不变。
- 本轮不证明 `global_no_live_reuse`、whole architecture、full-system、
  synthesis/STA/power/PPA。A3 完整系统证据未满足任何重跑触发条件，
  因此继续保留原 FAIL 和独立 checker-replay PASS。
- 下一项优先对象：
  `memory-reservation{0,1}-{producer,token}`；沿用双 lane
  stimulus-owned birth/hold/issue/terminal/death 与 raw tuple X/Z
  mutation 方法。

## RV64 V11K dual-MIQ owner tuple（2026-07-30）

### MIQ 周期合同

- accepted push 捕获完整
  `{owner_kind_i,owner_token_i,mmu_epoch_i}`；valid entry 驻留期间 tuple
  保持，response 仅在完整 tuple 与 FIFO head 精确相等时 pop。
- 相同 ROB、不同 owner 以及两个产品 MIQ 之间交换 tuple 均不得误消费。
  selective/global flush、ROB-walk kill 与 exact consume 后，
  `occupancy_token_mask_o` 必须精确等于所有 valid entry 的 32-bit token
  集合。
- production 功能方程未变；新增
  `[V11K-MIQ-PUSH-TUPLE-KNOWN]`、
  `[V11K-MIQ-POP-TUPLE-KNOWN]`、
  `[V11K-MIQ-OWNER-TUPLE-KNOWN]` 与
  `[V11K-MIQ-OWNER-TUPLE-STABLE]` 均只在 `OOO_ASSERT` 下。

### TB / EDA evidence

- design-id：
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`；
  MIQ SHA-256：`02d2e8a2…7147`；双实例 TB SHA-256：
  `aa1f331c…e56c`。
- attempt-3 为 34/34 PASS：2 baseline、12×2 compile-success RTL
  variants、4×2 push/pop X/Z interface probes。assert profile 精确命中
  push/pop/resident/stability marker；release profile 由
  stimulus-owned oracle 拒绝状态污染，无 negative-escaped marker。
- 三个普通回归分别绑定 7/7/43 个当前输入，pre/post MATCH；`.vvp`、
  log path/hash/size 均保存并由独立 reviewer 实算匹配。
- current graph 为 15 holder modules、17 holder instances、194
  reachable instances，两个 MIQ 产品路径精确。V11J/V11K 两态
  elaboration 均为 130 modules、176087 cells，logic SHA-256 均为
  `c49ad65d…e5b`。

### 审查与边界

- final review attempt 1 的两项 GAP 不改写；remediation 后的 versioned
  attempt 2 给出 `miq-owner-tokens`×两个产品实例局部 PASS。
- release interface probe 的 fail-closed 表示 testbench oracle 检出
  X/Z 导致的 head/count/occupancy 污染，不声称 assertion-off 二态生产
  RTL含四态保护电路。
- semantic ledger 为 17/44 PASS、27/44 GAP；global no-live-reuse、
  whole architecture、system promotion 与 PPA 均未由本轮闭合。
- 日常入口：
  `make -C npc/rv64 check-producer-holder-semantic-coverage`；canonical
  task-run：
  `.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/`。

## RV64 V11J dual-bridge holder semantic coverage（2026-07-30）

### bridge tuple / residency 周期合同

- `stg_owner_*_q` 在 request fire 的下一拍出生，stall 时冻结；
  same-edge advance/refill 把 edge-old station tuple 交给 active，同时接收
  新 station tuple。
- active tuple 从 `stage_advance_w` 起驻留，经过 PTW、SQ query、AXI
  stall、response residence 与 delayed drain，直到真实 response/drop/
  retry-handoff terminal 才死亡。`rsp_owner_*_q` 只在 `S_RESP` 是 live
  holder；verified tuple 只在 active live 且
  `active_owner_verified_q=1` 时是有效 alias。
- `owner_residency_mask_r` 是 active、station、response 三个 live token
  的精确集合；verified alias 不另占 set member。两个产品实例必须逐实例
  检查，不能用 module-level 一份结论替代。
- production 新增
  `[V11J-BRIDGE-ACTIVE-TUPLE-KNOWN]`、
  `[V11J-BRIDGE-STAGE-TUPLE-KNOWN]`、
  `[V11J-BRIDGE-RSP-TUPLE-KNOWN]` 与
  `[V11J-BRIDGE-VERIFIED-TUPLE-KNOWN]`。四者只在 `OOO_ASSERT` 下，
  不改变 release 行为。

### TB / EDA evidence

- design-id：
  `sha256:39533a9ac89f7d91b3bd630e928842e22a4f1dc1ab283d542800f176d0759fcf`；
  bridge SHA-256：
  `3e8ea5e11b09a5e0d04c7d3f02dc00c4c008106d73cc4dc82d4b44e8b9822ff5`。
- stimulus-owned dual-instance oracle 覆盖 reset/idle、双 birth、
  transfer/refill、非对称 SQ retry/response backpressure、global flush
  drop+nokill replace、response terminal、selective recovery、delayed R
  drain、C0 retry hold/release、owner-hold quarantine/recovery 和 held
  response reset。
- canonical matrix 32/32 PASS；13 个 compile-success holder/set/
  wrapper 反例在 assert/release 共 26/26 被拒绝；kind/epoch X 既由
  production exact marker 覆盖，也由 assertion-off oracle 拒绝。
  ordinary AXI bridge、dual wrapper 与 V9R retry-C0 regression 3/3 PASS。
- current Yosys graph fresh/frozen 均 PASS：15 modules、17 holder
  instances、194 reachable instances，`u_bridge0/u_bridge1` 路径精确。
  current census PASS。semantic ledger 为 16/44 PASS、28/44 GAP；五个
  bridge holder/set 单元闭合，但全局架构仍 RED、PPA 未晋级。
- 独立 final review 给出五单元×双产品实例 bounded PASS，blocker=0；
  逐项复核 32/32 profile、13 variants×assert/release=26/26 拒绝、
  3/3 ordinary regression、stimulus-owned oracle、current graph/census/
  ledger 与 V11H receipt binding，未找到二态 RTL 反例或 false-green
  覆盖洞。合同中误列的 standalone
  `tb_ooo_dual_mem_bridge_holder_semantic.sv` 不存在；实际 focused 分支
  在 `tb_ooo_dual_mem_bridge_wrapper.sv`，且 Makefile/manifest/evidence
  均绑定真实文件，因此只记为 non-blocking naming deviation。

### 可执行入口与边界

- 日常只读入口：
  `make -C npc/rv64 check-producer-holder-semantic-coverage`。它依次验证
  current graph/census、V11H frozen-input replay、30 个 semantic
  checker 单测和 current ledger；不会覆盖历史 task-run。
- V11H attempt-4 原始 FAIL 与旧 full-RTL design-id 不改写；current
  receipt 只授予 unchanged LoadQueue RTL + 两份 TB 的 selected binding。
- V11J assertion-only delta 不单独触发 full-system；V11H functional LQ
  delta 仍要求 system promotion 前执行 current-design 完整系统运行。
  synthesis、STA、power 与 PPA 本轮没有新结论。
- Bounded `OooMemAxiBridge` brief 与 object-named `npc-dev` profile
  5/5 PASS；首个日期化 slug run 的五个节点虽均 PASS，但 primary-focus
  recall 未闭合，因此原始 BLOCKED 状态保留。15 条 V11J 路径的 scoped
  strict guard 绑定 corrected run 后 PASS。extended-slug
  `agent-system` 首次 run 因 context focus 保持 BLOCKED，exact-object
  run 随后 11/11 PASS；full-worktree 只保留无关 `nemu/amo.c` 的
  `nemu-dev` evidence GAP。
- V11J 1,757 个 raw evidence asset 已 index-only 入库，八份 task-run
  Markdown 已存储并留下 shim；snapshot、DB-first、Markdown coverage
  与全局 runtime-artifact audit PASS。技术 task-run 无 e2e
  `run-manifest.json`，因此 run-id-specific artifact audit 保持显式 GAP。
- 发布后 `brief V11J --profile npc-dev --focus-scope non-history` 完整
  召回本节，验证 V11J 周期合同、证据入口和剩余边界已自动可发现。
- task-run：
  `.github/task-runs/2026-07-30-rv64-v11j-bridge-holder-semantic-coverage/`。

## RV64 V11I terminal lifecycle token wrap（2026-07-30）

### production source 与周期合同

- 当前 production `OooIntBackend` lane0 terminal 只在 exact response fire
  产生，MIQ entry 同沿 pop；源码没有保存已发射旧 tuple 的状态。
- collector accept 后 pending Q 是 tuple 真源；dequeue fire 同沿，
  tracker 以 edge-old token→ProducerId table 执行 exact free，LQ 读取同一
  edge-old PID 并登记 terminal。tracker allocation 只扫描 edge-old
  `live_q`，不能借同沿 death 复用 token。
- 32 个 LOAD 完成后 token0 从 PID `00` 环回复用到 PID `40`。新 owner
  reservation/LQ 驻留期间，旧 lane0 source 必须保持 ingress/accept
  静默；新 tracker lease 与 LQ `terminal_seen_q=0` 必须保持到自身合法
  terminal。

### TB / EDA evidence

- design-id：
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`。
- terminal-lifecycle attempt-11 的 production assert/release 2/2 PASS；
  compile-success stale-tuple 副本在 assert/release 2/2 被精确拒绝。
  assertions-on 命中 `[V9Y-HOLDER-TERMINAL-NEXT]`；assertions-off 直接
  观察新 tracker 被 free、同 PID LQ 被写 `terminal_seen_q`，命中
  `[V11I-LATE-TUPLE-ABA][FAIL]`。
- runner tests 6/6、独立 evidence-validator tests 8/8、collector/tracker/
  LQ/IntBackend/AXI bridge/dual wrapper/V8X parent recovery 分层回归
  7/7 PASS。缺 focused define 的样例使用
  `commands-without-focused-define/commands.json` 并锁定 exact validator
  error；source 与 canonical RTL pre/post identity 无漂移。
- attempt-9 的 lane6 contract metadata GAP、attempt-10 的 checker-test
  假绿、attempt-1/2 与 layered-attempt-1 的 FAIL 均原样保留并
  superseded，不覆盖或改写。selected attempt-11 summary/receipt 为
  `972273f5…` / `3764e0c5…`。production RTL 无 V11I mutation state，
  也未新增 event dedup 或削弱 assertion。

### 裁决与边界

- 独立 final review v5：`APPROVED_FOR_CURRENT_SCOPE`，bounded APPROVE，
  `blocker=0`。H1 成立；H3 排除；H2 仅作为 source one-shot 违约时的
  compile-success 负向反例。既有 regression 处置为 6×`KEEP` +
  tracker `REBIND`，没有遗留 `UNKNOWN_PENDING_REVIEW`。
- 本轮是 verification + tooling/workflow，production RTL 未修改。局部
  LOAD terminal token-wrap 生命周期闭合，但 arbitrary raw ingress、
  global no-live-reuse、whole architecture、system、synthesis、STA、
  power 与 PPA 仍为 GAP/未晋级。
- A3 继续保持原始 FAIL、系统事务完成、旧 oracle 误判与 checker replay
  PASS。V11H production LQ 语义变化仍要求未来 system promotion 前执行
  current-design 完整系统运行；V11I 未启动该 workload。
- task-run：
  `.github/task-runs/2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear/`。
- workflow 证据同样保留原始失败：首次长 task-slug `npc-dev` run 的
  五个节点均 PASS，但 non-history focus recall 未闭合；精确 `V11I`
  brief 与 `2026-07-30-v11i` 的 `npc-dev` 5/5 PASS。首次
  `agent-system` run `2026-07-30-v11i-2` 因 8 份 live-only task-run
  Markdown 在 `three-layer-contract` 失败；14 份 Markdown 同步到
  stored/backup、coverage 变为 `live_evidence=0` 后，
  `2026-07-30-v11i-3` 为 11/11 PASS。该结果只证明 AI 环境合同，
  不扩张 terminal 生命周期的硬件结论。

## RV64core interactive datasheet Rev D readability（2026-07-30）

### 文档/UI 合同

- `docs/rv64core/study/index.html` 默认以 large profile 显示：正文 16 px、
  caption 12 px；standard/large/xlarge 三档由同一组 typography tokens
  驱动 transaction、table、Self-check 和 WaveDrom 标签。
- 字号按钮在桌面和窄屏都可达，选择写入 local storage；storage 异常时
  回退为 large，并同步更新动态 ARIA label 和 live region。
- transaction 主链为 top-to-bottom，phase header 提供
  `PHASE NN / TOTAL`，每段固定列出 Data In / State / Data Out /
  Guard，HANDOFF 单独显示下游模块与 payload，sidePath 仍与主数据流
  分开表达。
- CSS 静态门拒绝显式小于 11 px、未定义变量和隐藏字号按钮。三个负向
  注入样例均被拒绝；独立审查在移动端按钮 P2 修复后给出
  P0/P1/P2=0。浏览器动态视觉仍是明确 GAP。

### 当前源码绑定

- current-source elaboration 对应 150 files、136 modules、195 instances；
  交互页包含 9 transactions、38 WaveDrom、58 primary phases、
  2 side paths、240 data fields、975 answer slots 与 1,219 sequential
  targets，外部运行时资源为 0。
- HTML SHA-256：
  `80ed008e3e00ac512d00962acbd7ad35448745f98417f67e114f9f488f8d7331`；
  source fingerprint：
  `80bd2b13543597e18091bdb387ff4d75793828de0368a260e23e0181a20a13cd`；
  NpcTop elaboration SHA-256：
  `9eced7569f815ebf763de2a1647d1ccc264ea340f28826f72f600aff4cb79695`。
- 本轮只改交互讲义、生成/审计工具与 README，没有修改 production
  RV64 module/signal/transaction 语义，也没有运行 TB、DiffTest、综合、
  STA 或 PPA 流程。
- scoped strict guard 为 PASS、无 profile 要求；全工作树 guard 只因
  其它并发 V11I RTL/testbench/evidence 路径缺 `npc-dev` evidence 而
  保持 GAP，不能据此扩大或削弱本轮文档结论。

## RV64 V11H LoadQueue terminal-history architecture closure（2026-07-30）

### terminal / completion / recovery 合同

- `valid_q[] + producer_id_q[]` 是 retire-resident full-P holder；
  `terminal_seen_q[]` 是 physical-owner exact-terminal history。normal
  terminal 只结束 physical operation，不结束 ROB retire residency。
- terminal 后 issue/query/response 必须关闭。若下一拍 selective/global
  recovery 命中 terminal-seen entry，直接 clear；只有 launched、
  incomplete、尚未 terminal 的 owner 才进入 killed tombstone。
- same-edge normal terminal 优先于 recovery tombstone 判定；第二个 exact
  terminal 是合同违例并由 `[V11H-LQ-DUP-TERMINAL]` 拒绝。禁止用去重或
  吞事件逻辑隐藏重复 terminal。
- 每个 `valid_q[]` entry 的完整 `producer_id_q[]` 必须 known；
  `[V11H-LQ-PID-KNOWN]` 是 production raw-Q assertion，不能只依赖 TB
  oracle。
- pre-fix legal sequence 固定观测
  `count=1/live=1/killed=1`；post-fix 固定观测
  `prior_terminal=1 recovery_clear=1 ghost=0 PASS`。

### TB / EDA evidence

- design-id 为
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`，
  LQ SHA 为
  `4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427`。
- stimulus-owned 四槽 model 逐沿扫描 raw
  `valid/launched/completed/killed/terminal_seen/producer_id` 与 final-PA
  metadata；DUT 输出只作 observation。GEN_W=1/4、assert/release 四个
  profile PASS；1 个 GEN_W=4 assertion probe 命中
  `[V11H-LQ-PID-KNOWN]`；31×2 assertion-off mutation 仿真全部由
  `[V11H-LQ-PRODUCER-ORACLE][FAIL]` 拒绝。
- 当前实例图为 15 holder modules / 17 instances / 194 reachable；
  fresh Yosys result、receipt、full JSON、script、log 均与 canonical
  逐字节一致。
- focused attempt-4 原始状态保持 `FAIL@semantic-ledger-unit`。独立
  checker replay 绑定冻结的 4+1+62 仿真、source/RTL pre/post 与原失败
  日志，记录 `rtl_simulation_reexecuted=false`，并通过 5/5、10/10、
  24/24 checker tests。
- ordinary LoadQueue 与 parent IntBackend 在 assertions-on、GEN_W=4 下
  PASS；PID-known 与 duplicate-terminal marker 均为 0。

### ledger / promotion boundary

- V11B–V11G 旧 evidence 只允许 exact selected RTL/TB closure replay，
  binding state 为 `CURRENT_SELECTED_SOURCE_AND_TB_BOUND`；不反写旧
  design-id。V8L 为 historical，V11H 为当前 full-RTL bound。
- ledger 为 11 PASS / 33 GAP / 44；只新增
  `load-queue-producers` closure。whole architecture、system、PPA 仍
  RED/未晋级。
- exact `scope.system_rerun` 记录 local closure 不要求重跑、system
  promotion 要求重跑、当前未运行；字段缺失或弱化必须 fail closed。
- versioned final-review v3 对 `load-queue-producers` 给 bounded APPROVE、
  blocker=0；该结论不覆盖 entry 清除后的端到端迟到 duplicate terminal。
- production core 语义已改变，故完整系统重跑是未来 system promotion
  前置条件；本轮未运行 A4。task-run：
  `.github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/`。
- current-source `npc-dev` 5/5、`agent-system` 11/11 与 19-path scoped
  strict guard PASS；全工作树只保留 unrelated shared `rv64-linux`
  evidence GAP。DB-first/Markdown/runtime-artifact audits 与当前 checker
  39/39 PASS。混合工作树未 stage/commit。

## RV64 V11G StoreQueue resident holder semantic coverage（2026-07-30）

### edge-old holder 合同

- `OooStoreQueue.producer_id_q[0:3]` 是 resident full-P holder；
  allocation fire 捕获 exact ProducerId。bind 只对 edge-old valid、
  owner-invalid 且 full-P/ROB 匹配的 entry 捕获独立
  `{owner_kind_q, owner_token_q, mmu_epoch_q}`。
- OOO fill 只更新 payload/fill 状态。physical request 与 exact terminal
  之后 ProducerId 和 owner tuple 都继续 resident；只有 exact terminal
  physical-head release 才清 `valid_q` 与 `owner_valid_q`。
- selective flush 保留 inclusive prefix，global flush 只保留已
  `request_sent_q` owner。full+release 不借 edge-old 空位；release+dual
  allocation、terminal+release+flush、bind+terminal+release 与双 terminal
  依照显式 same-edge bypass 和 count 代数更新。
- local legal-interface 合同不证明上游 flush+allocation、allocate+bind、
  bind+fill 或双 bind alias 的不可达性；该集成边界不能外推为全局
  no-live-reuse GREEN。

### 当前 testbench / EDA 证据

- `tb_ooo_store_queue.sv` 的 `+V11G_SQ_HOLDER_ONLY` 路径维护
  stimulus-owned 四槽 expected state；DUT raw Q、snoop 输出与 masks
  仅作为比较对象，不参与 expected 推进。token/epoch 与 ROB index
  不对称，避免 index 替代 tuple 的假绿。
- canonical `store-queue-holder-attempt-1` 绑定 design-id
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`、
  production SQ SHA
  `5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241`
  与 TB SHA
  `86ea1b71c03071c965fc09af1068475d0c0bca314b73b6b4338bb23ab1516fb0`。
- assert/release × `PRODUCER_GEN_W=1/4` 的四个 positive profile 全
  PASS。二十四个 compile-success variants 在 g1/g4、`OOO_ASSERT`
  关闭配置下 48/48 被 `[V11G-SQ-HOLDER-ORACLE][FAIL]` 拒绝。
- focused 16-source manifest 与 146-file RTL snapshot 均 pre/post
  identical；normal StoreQueue regression 1/1 PASS；evidence tool 8/8、
  semantic-ledger 15/15 PASS。
- 独立预审选择 H1；final reviewer 核对 raw full-P/tuple knownness、
  compiled images、mutation receipts、oracle independence 与 ledger
  差分后给出 bounded APPROVE、blocker=0。

### 自动发现与边界

- `store_queue_holder_semantic_evidence.py` 提供 exact-anchor mutator 与
  source-bound summary；semantic policy 只允许同一 summary 绑定
  `store-queue-producers` 与 `store-queue-owner-tokens`。
- semantic ledger 为 10 PASS / 34 GAP / 44；V11F→V11G 只有上述两项
  从 GAP 到 PASS。global no-live-reuse、whole architecture、system、
  synthesis、STA、power 与 PPA 均未晋级。
- ARCH_STABLE 为 51/53 expected GAP、V11G 新增 failure 为 0。本轮
  production/elaborated RTL、device model 与 simulator semantics
  未变化，A3 不触发完整系统重跑。
- task-specific `npc-dev` 首轮在新 memory 尚未存入 DB 时因独立 focus
  缺失而 blocked；保存 project/NPC memory 后，
  `2026-07-30-store-queue-holder-semantic-revtag-v11g-2` bounded recall
  complete、五个节点 5/5 PASS。首轮失败证据保留，未放宽 fail-closed
  召回合同。
- 8-path scoped strict guard 与 final identity PASS；full-worktree strict
  guard 只保留 shared `rv64-linux` evidence GAP。351 个 raw assets
  已索引，9 份技术 Markdown 与两份 memory 已发布，DB-first、
  Markdown coverage 与 runtime-artifact audit PASS。
- mixed-origin commit gate 观察 254 个 tracked 修改、1,688 个
  untracked 文件与一个无关 staged profile；V11G 未 stage/commit。
- canonical task-run：
  `.github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage/`。

## RV64 V11F integer IQ ProducerId semantic coverage（2026-07-30）

### edge-old holder 合同

- `OooIntIssueQueue.producer_id_q[0:7]` 是 integer IQ resident full-P
  holder。accepted dispatch edge 形成 birth；issue/pair fire 与 selective
  kill 只删除 edge-old entry，survivor 以原 full ProducerId 压缩，同沿
  append 位于 survivor 之后。
- regular/pair fire 当拍 `producer_live_mask_o` 仍扫描 edge-old Q，死亡从
  下一周期生效。READY-low、recover hold 与 pair backpressure 必须保持
  全部 resident PID、顺序和 carrier。
- selective recovery 以 raw ROB 环形年龄删除严格 younger entry；
  boundary 与 older survivor 的 generation 位不得重写。flush/reset edge
  后队列为空。
- IQ-I6 禁止 kill/flush/reset 与新 dispatch acceptance 同拍。无约束端口
  下的 `kill_valid_i && dispatch*_valid_i` 反例属于上游 transaction
  barrier 集成 GAP，不被本轮伪装成 IQ 局部缺陷或局部证明。

### 当前 testbench / EDA 证据

- `tb_ooo_int_issue_queue.sv` 的 `+V11F_INT_IQ_PRODUCER_ONLY` 模式维护
  testbench-owned 八槽 expected list；DUT raw Q 与 live mask 仅作为比较
  对象，不参与 expected 推进。
- canonical `int-iq-producer-attempt-3` 绑定 design-id
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`、
  IQ SHA
  `d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b`
  与 TB SHA
  `cb8e875f772157de0651c0582184c78b4820627ab8b1a2dce56cc604c77e9d2c`。
- assert/release × `PRODUCER_GEN_W=1/4` 的 4 个 positive profile 全
  PASS。二十个 compile-success variants 在 g1/g4 release 配置下 40/40
  被 `[V11F-INT-IQ-ORACLE][FAIL]` 拒绝；每个 compile RC 为 0，未定义
  `OOO_ASSERT`。
- raw PID knownness 由 `dispatch0-pid-x`、`dispatch1-pid-x`、
  `compaction-pid-x` 精确命中。normal IQ regression PASS；evidence
  tool 8/8，semantic ledger tests 合计 22/22 PASS。
- 独立终审核对 source binding、compiled image、mutation receipt、
  oracle independence 与 ledger 差分后给出 bounded APPROVE、
  blocker=0。

### 自动发现与边界

- `int_iq_producer_semantic_evidence.py` 提供 exact-anchor mutator 与
  source-bound summary；semantic policy 只允许 V11F summary 绑定
  `integer-iq-producers`，改绑 ROB unit 的负向单测必须失败。
- semantic ledger 为 8 PASS / 36 GAP / 44。global no-live-reuse、
  whole architecture/system、synthesis、STA、power 与 PPA 均未晋级；
  production IQ 未修改，不触发 A3 完整系统重跑。
- task-specific `npc-dev`
  `2026-07-30-integer-iq-producer-semantic-revtag-v11f` completed 5/5；
  8-path scoped strict guard 与 final identity PASS。全工作树仅保留 shared
  `rv64-linux` evidence GAP；ARCH_STABLE 为 51/53 expected GAP、
  V11F 新增失败 0。873 个 raw assets 已索引；9 份技术 Markdown 与两份
  memory 已存储，snapshot-stored、DB-first、Markdown coverage 与
  runtime-artifact audit 均 PASS。
- mixed-origin commit gate 观察 253 个 tracked 修改、1,639 个 untracked
  文件与一个无关 staged profile；V11F 未 stage/commit。
- canonical task-run：
  `.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/`。

## RV64 V11E ROB slot generation semantic coverage（2026-07-30）

### 逐周期 generation 合同

- `OooRob.slot_generation_q[slot]` 是 16-slot ROB 的 generation authority。
  hard reset seed 为全 1；只有 accepted dispatch fire 写入对应 slot，
  写值为该 slot 的沿前 generation 加一并显式截断到
  `PRODUCER_GEN_W`。ordinary flush 不重置 generation，selective recovery
  只改变 valid/head/tail/count 等 ROB 生命周期状态。
- lane0 actual、lane1 actual 与 lane1 pair candidate 使用各自命名 slot
  的沿前 generation；full ROB 即使同沿 commit 也不借出槽。head、commit、
  walk carrier 与 current/completion0..7/resolve query 必须携带或比较
  exact `{generation, rob_index}`，不能退化为 index-only。
- `PRODUCER_GEN_W=1` 的模回绕是局部定义行为。相同 ProducerId 回绕后是否
  可重新出生由外部 holder collision fence 决定，不归因于 `OooRob`
  局部 slot-generation 实现。

### 当前 testbench / EDA 证据

- `tb_ooo_rob.sv` 的 `+V11E_SLOT_GENERATION_ONLY` 路径维护独立沿前
  generation/valid/done/head/tail/count/recovery model，每个 posedge
  比较全部 16 个 slot。carrier expected 由 model generation 重新组成，
  不捕获或复用 DUT ProducerId。
- canonical `slot-generation-attempt-3` 绑定 design-id
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`、
  production `OooRob.v` SHA
  `bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561`
  与 TB SHA
  `6c5881089fc1437d40f15532279dde1e0c8b1359d4bd5c47ff03b4886a87f4f5`。
  4 个 assert/release × generation-width baseline 全 PASS；17 个
  compile-success variants × `GEN_W=1/4` 的 34 个 release 仿真全部由
  独立 oracle 拒绝。
- attempt-1 保留 `walk-carrier-zero-generation/g1` 假绿，attempt-2
  保留 `recovery-resets-generation/g1` 假绿。attempt-3 在同一 recovery
  pair 中制造 slot4 generation=0、slot3 generation=1，使 zero-carrier
  与 reset-to-ones 都可观测；两类历史失败不进入 ledger。
- normal ROB regression marker 为 `[PASS] tb_ooo_rob`。evidence tool
  9/9 与 semantic ledger 13/13 日志分别归档，合计 22/22；ARCH_STABLE
  保持 51/53 expected GAP 且 V11E 新增 failure 为 0。
- 独立 final reviewer 核对 vvp、compile flags、mutation receipt、
  generation-bit mismatch 与 ledger 差分后给出 bounded APPROVE、
  blocker=0；只允许 `rob-slot-generation` 晋级。ledger 现为
  7 PASS / 37 GAP / 44，整体仍 `GAP`。

### 自动发现、发布与边界

- `rob_slot_generation_semantic_evidence.py` 提供 exact-anchor mutator
  与 fail-closed summary；semantic policy 只允许 V11E summary 绑定
  `rob-slot-generation`，改绑 cursor 的负向单测必须失败。
- active spec 页首已从 v11c/5/39 同步为 v11e/7/37。由于这是终审后的
  documentation-only publication，attempt-3 内原始 spec hash 与 summary
  不重写；`post-review-publication-receipt.json` 显式绑定新旧哈希，
  live rebuild 对文档漂移仍按设计拒绝。当前 146-file RTL、TB、runner、
  evidence tool/tests、ledger tool/tests 与 policy 仍通过 final identity。
- 终审后 current-source `npc-dev`
  `.github/task-runs/2026-07-30-rob-slot-generation-final/` 为 completed
  5/5，7-path scoped strict guard PASS；全工作树只保留 shared
  `rv64-linux` evidence GAP。609 个 raw evidence assets 已索引，8 份
  技术 Markdown 与两份 memory 已存储；snapshot-stored、DB-first、
  Markdown coverage 与 runtime-artifact audit 均 PASS。其余 37 个
  holder、global no-live-reuse、whole architecture/system、synthesis、
  STA、power 与 PPA 均未晋级。
- 本轮没有 production core RTL、实际 elaborated RTL、设备模型或
  simulator 语义变化，也不缺 A3 frozen input/terminal/post-hash 证据，
  因此不触发 A3 完整重跑。A3 原始 FAIL 与 checker-replay 分类不变。
- commit gate 观察 branch `ai`、HEAD
  `af027d1bce085bace474b748dcd89113145f8772`、251 个 tracked 修改、
  1,611 个 untracked 文件及一个无关 staged profile；未执行
  stage/commit。canonical task-run：
  `.github/task-runs/2026-07-30-rv64-v11e-rob-slot-generation-semantic-coverage/`。

## RV64 V11D memory tracker cursor semantic coverage（2026-07-30）

### 逐周期 cursor 合同

- `OooMemOwnerTracker.next_token_q` 命名 edge-old FREE 圆环的扫描起点。
  lane0 取第一 FREE；lane1 只在 lane0 有合法 claim 时排除 lane0 token，
  再取第二 FREE。非原子 lane 独立出生，atomic pair 只在双 credit 时双出生。
- exact free 与 STORE bulk release 对本沿 allocation scan 不可见；cursor
  在 lane1 fire 时取 `token1+1`，否则在 lane0 fire 时取 `token0+1`，
  零 fire 保持，reset 为 0。4/32-token 使用相同自然回绕合同。
- valid-qualified token 是本轮公开合同。若接口以后改为只在 fire 时定义
  token，必须新增 fire-qualified profile；不能从本轮结果外推。

### 当前验证与证据

- 参数化 `tb_ooo_mem_owner_tracker_cursor.sv` 只用 stimulus 与沿前 expected
  live/PID/metadata/cursor 推导 expected ready/token/fire；DUT token 不反喂
  model。`dut.next_token_q` 的直接比较会 `$fatal`，是第二个 oracle，不是
  单纯诊断。
- canonical `cursor-attempt-2` 绑定 design-id
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
  与 tracker SHA
  `fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`。
  4/32-token × assert/release 4/4 PASS；9 个 32-token、
  `OOO_ASSERT` 关闭配置的 compile-success variants 9/9 被定向拒绝。
- attempt-1 的 4/4 + 9/9 原始产物保留，但 lane1 变体可在 invalid lane
  token 输出上过早失败，故不作为 ledger 晋级依据。attempt-2 把 token
  比较限定到对应 valid，并把相关首个拒绝点移到 valid 周期。
- V11C compatibility、V11D evidence 与 semantic ledger tests 合计
  24/24 PASS。policy exact unit-set 与负向重绑测试保证只把
  `tracker-next-token-cursor` 晋级；ledger 为 6 PASS / 38 GAP / 44。
  独立 reviewer bounded APPROVE，blocker=0。

### 自动发现与边界

- cursor evidence builder/mutator、runner、unit test、semantic ledger
  binding 与 ARCH_STABLE workflow binding 已接线。ARCH_STABLE 当前观测
  51/53，V11D 无新增失败；两项既有 current-workspace 漂移继续 fail
  closed，不能外推为 whole-core freeze。
- 其余 38 个 holder、global no-live-reuse、whole architecture/system、
  synthesis、STA、power 与 PPA 保持 GAP/RED/UNPROMOTED。production tracker
  未修改；没有 A3 完整系统重跑触发项。
- task-specific `npc-dev`
  `2026-07-30-memory-tracker-cursor-semantic-revtag-v11d` 为 5/5 completed；
  10-path scoped strict guard PASS。全工作树 guard 只缺 mixed-origin
  `Linux/scripts/check-ubuntu-rootfs.sh` 的 `rv64-linux` evidence，保留范围外
  GAP。V11D 141 个 raw assets 已索引，51/53 ARCH_STABLE 原始日志已保存；
  8 份技术 Markdown 与两份 memory 已存储，snapshot-stored、DB-first、
  Markdown coverage 与 runtime-artifact audit 均 PASS；final identity
  helper 重算的 146-file RTL binding 与 canonical attempt-2 一致。共享
  工作树的 249 个 tracked 修改、1,564 个 untracked 文件和一个无关 staged
  profile 使提交门保持 mixed-origin GAP；V11D 未 stage/commit。
- canonical task-run：
  `.github/task-runs/2026-07-30-rv64-v11d-memory-tracker-cursor-semantic-coverage/`。

## RV64 V11C memory tracker semantic coverage（2026-07-29）

### 逐周期合同与根因裁决

- `OooMemOwnerTracker` 的 allocation encoder 只扫描 edge-old `live_q`；
  exact free 与 STORE bulk release 只形成 old-live `death_mask_r`，birth
  只命名 old-free token，edge-new 状态为
  `(live_q & ~death_mask_r) | birth_mask_r`。ProducerId bitmap 以同一
  death/birth 集合 clear/set，同一 dying token/PID 不在本沿重生。
- H1（合法二态 map 数据路）PASS；H2（合法二态 live-set 数据路）静态无反例；
  H3（旧证据已足够闭合）拒绝。根因是验证缺口：旧 TB 只由 count/PID
  间接推断 live set，没有 exact token membership oracle，也没有当前绑定的
  tracker mutation。
- `next_token_q` 只决定空闲 token 的扫描起点。本轮 scoreboard 使用 DUT
  返回 token 建立期望映射，不预测选择顺序，因此
  `tracker-next-token-cursor` 明确保留 GAP。

### 当前验证与证据

- `tb_ooo_mem_owner_tracker.sv` 新增独立 expected live/PID/kind/epoch
  模型，逐沿检查 dual birth、lane1-only birth、exact/free1 death、
  duplicate-PID single winner、STORE bulk death、full backpressure、
  exact/bulk full-table same-edge no-reuse、next-cycle reuse 与 atomic
  scarcity zero-birth。
- verification-only
  `tb_ooo_mem_owner_tracker_semantic_checker.sv` 检查 valid allocation/free
  tuple、release mask、registered live mask/summary 与 live metadata
  二态性；它不修改生产 RTL，也不进入 PPA 数据通路。
- attempt-2 绑定 design-id
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
  与 tracker SHA
  `fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`。
  assert/release 2/2、X-known 4/4、compile-success mutation 9/9 PASS；
  mutation profile 同时关闭 checker 与 `OOO_ASSERT`，排除内部断言自证。
- attempt-1 的原始 PASS 不删除，但其 Makefile/policy source manifest
  后续漂移，policy 只引用 attempt-2。独立 reviewer 核对 vvp、compile
  flags、marker、manifest 和 exact unit-set 后 bounded APPROVE。

### 自动发现与边界

- `memory_tracker_semantic_evidence.py` 同时提供 exact-anchor mutator 与
  fail-closed evidence builder；policy 只允许 V11C summary 绑定
  `memory-tracker-producer-map`、`memory-tracker-live-set`，改绑 cursor
  的单测必须失败。
- ledger 当前 5 PASS / 39 GAP / 44，整体 `status=GAP`。V11C tool/test/
  runner 已进入 ARCH_STABLE workflow exact binding；verification-only
  checker 由 `test_sources` 精确绑定，旧 full-core candidate 不自动重绑。
- V11C 定向 Python 复核 16/16 PASS；ARCH_STABLE 53 项自检为 51/53，
  V11C fixture 无新增失败。剩余两项为既有 V9R identity/status 漂移与
  full-core candidate dynamic-inventory 重绑缺口，继续 fail closed。
- task-specific `npc-dev` 5/5 completed 且 DB publication 可召回；
  V11C 12-path scoped strict guard PASS。全工作树 strict guard 仅因共享
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence 而 FAIL，
  该项保持范围外 GAP。V11C 165 个 raw evidence asset 已索引，8 份
  task-run Markdown 已同步；DB-first 与全局 artifact audit PASS。
- 本轮无 production RTL、synthesis、STA、power 或 PPA 变化；不要求 A3
  完整系统重跑。生产尺寸扫描、公平性、cursor、其它 holder、global
  no-live-reuse、whole architecture 与 PPA 保持未晋级。

## RV64 V11B holder semantic coverage（2026-07-29）

### 当前对象与账本

- 当前 product RTL design-id 为
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`。
  census 为 20 direct、5 packed、15 token、3 token-set、1 generation，
  合计 44 个语义单元；V11A 为 15 module、17 instance、194 reachable。
- 语义 ledger 形成 50 条 unit×instance binding。34 个单元有 candidate
  evidence，10 个没有 candidate，0 个 ledger-only。candidate 只说明可审计，
  不能自动晋级；当前只有 collector 的 output0/output1 token 与 pending-set
  三项 PASS，41 项保持 GAP。
- 两个 `OooMemInflightQueue` 与两个 `OooMemAxiBridge` 按 exact instance
  path 区分。任何 module-name dedup 都会使 per-instance oracle 不完整。

### Terminal collector 合同

- `OooMemOwnerTerminalCollector` 的 12 路 ingress 必须逐 lane 保持
  `{valid, kind, token, epoch}` 对应关系，2 路 raw tracker-free dequeue
  也必须保持各自 lane；transfer authority 只来自 accepted mask。
- 同 token 重复 terminal 由 duplicate/same-edge/owner/conservation assertion
  暴露，禁止用 RTL 或 TB 去重隐藏。TB 的 raw dequeue fire 直接计数，并覆盖
  lane1 turnover/lane0 hold 与 lane0 turnover/lane1 hold。
- assertion-only RTL 新增 pending、valid ingress、tracker truth 与 output
  tuple 的二态性检查；release 功能逻辑未变，既有断言未削弱。
- attempt-3 为 assert/release 2/2、unknown negative、3/3 compile-success
  mutation rejection、12+2 lane static contract 全 PASS；146-file RTL
  pre/post binding 相同。attempt-1/2 失败与 currentness attempt-21 的
  10 项 semantic GAP 均保留。
- 独立 reviewer 发现 policy 可把 V11B closure evidence 改绑无关单实例
  unit。checker 现要求 exact 三项 collector unit set，并用改绑
  `pending-system-producer` 的负向测试 fail closed；semantic/lane
  tests 修订后 16/16 PASS。

### 自动发现与边界

- `producer_holder_semantic_coverage.py` 与 policy 负责 44×instance 账本；
  `terminal_collector_lane_contract.py` 负责 12+2 lane 静态关系。
  两个 checker、policy、tests 和 collector runner/builder/mutator 已加入
  ARCH_STABLE workflow exact binding。
- V8L current lifecycle 为 5 个承重 marker、9/9 mutation rejection；
  V9R retry C0 为 2/2 baseline、3/3 mutation rejection。旧 closed-debt
  evidence 在 workflow/source identity 全量重绑前继续 fail closed。
- 当前 `semantic_complete=false`、global no-live-reuse/whole architecture
  为 RED/GAP、PPA 为 `UNPROMOTED/UNQUALIFIED`。assertion-only source
  变化不改变 release product 语义，不触发 A3 全系统重跑。task-specific
  `npc-dev` 5/5 completed；strict guard 只剩本轮范围外
  `Linux/scripts/check-ubuntu-rootfs.sh` 的 `rv64-linux` evidence GAP。

## RV64 V11A holder elaborated instance graph（2026-07-29）

### 稳定实例合同

- 当前 product top 为 `NpcTop`，配置为
  `OOO_CSR_QUEUE_HEAD=1`、`OOO_TERMINAL_HOLDER_ASSERT=1`，输入为固定
  顺序的 127 个 synthesizable RTL 文件。design-id 为
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`。
- fresh Yosys hierarchy 得到 194 个 reachable user-module instances；
  15 个 ProducerId/owner-token holder modules 对应 17 条 exact paths。
  `OooMemInflightQueue` 与 `OooMemAxiBridge` 各有 2 个物理实例，任何
  module-name dedup 都会遗漏 holder。
- `scope.instance_graph_complete=true` 只说明当前配置的 instance
  multiplicity 完整，不能替代 transaction birth/hold/death、no-live-reuse
  或 terminal uniqueness 的动态/形式证明。

### 五件套与 fail-closed runner

- canonical evidence 固定为
  `holder-instance-graph.json`、`yosys-instance-graph-receipt.json`、
  `yosys-instance-graph.full.json.gz`、`yosys-instance-graph.ys` 与
  `yosys-instance-graph.log`。receipt 和 reachable graph 都从完整 JSON
  重算，不能从 result 镜像生成。
- 完整 JSON 保留整个 Yosys document，只把 map key 中的进程局部
  `$0x<hex>:` token 规范化为 `$0xADDR:`；values 和其它 keys 不变，
  规范化碰撞直接拒绝。两次独立 canonical document 均为
  197,075,777 bytes，uncompressed SHA-256
  `db0a066a1e7e23c1b118212095267eed72d51a0439e1b7c29d7bd5fe04cfc949`。
- runner 的 PASS 必须晚于 helper/source pre/post binding、23/23
  instance+runner tests、15/15 census tests、task-status test、fresh
  五件套 byte identity、frozen/census audit 和 cleanup evidence
  completion。missing helper、unit failure、full mismatch、source drift
  与 cleanup signal 均有动态 stale-PASS 负向 fixture。
- ARCH_STABLE workflow dependency tests 50/50；V9N refresh 后 closed
  currentness 为 16/38/32/0，production RTL postflight 不变。独立 reviewer
  v3 为 `APPROVED_FOR_CURRENT_SCOPE`。
- task-specific `npc-dev`
  `.github/task-runs/2026-07-29-producerid-holder-revtag-v11a/` 为
  completed 5/5，V11A 12-path scoped strict guard PASS。首次过宽 focus
  run 保持 blocked；全工作树的独立 `rv64-linux` 缺证据不改写为 V11A
  RTL GAP。

### 晋级边界

- 本轮没有修改 `npc/rv64/vsrc/**`，未执行 synthesis mapping、STA、power
  或 Pareto publication。
- `semantic_complete=false`、
  `global_no_live_reuse=SEMANTIC_COVERAGE_REQUIRED`、whole architecture
  `RED`、PPA `UNPROMOTED/UNQUALIFIED`。V11A 是 architecture freeze 的
  instance-census 前置证据，不是完整 OoO 核或 PPA signoff。

## RV64core interactive datasheet Rev C（2026-07-29）

### 当前 CSR 分流与周期边界

- 产品配置 `OOO_CSR_QUEUE_HEAD=1`，fallback 为 `1'b1`。合法非 FP head0 CSR 的教学主链为 `OooFrontend → OooDispatchBackend → OooIntBackend → OooRob → OooCsrAccessRequestMux → CsrFile → OooControlEventApplySequencer`；lane1 CSR、`fflags/frm/fcsr` 和非 CSR SYSTEM/trap 仍进入 pending/full-drain 域。
- `head0_csr_inflight` 在 CSR 离开 frontend FIFO 后继续保持 stop owner。queue-head pregrant 只等待 `mem_idle`，不得加入 `mem_retire_quiet` 或 SQ-empty；否则 younger Store 可与 head CSR 构成循环等待。
- C0 同拍发生 ROB commit/barrier、CsrFile request/architectural write，并从 `CsrFile` 分出 `head0_csr_commit → OooControlCommitSequencer.serial_flush_q`；C1 为 typed full-flush/apply 与 registered serial flush，C2 request/apply/serial flush 回到 quiet。head0 SATP 使用该 C0/C1 链，lane1 SATP 仍走 pending。

### 文档证据与验证边界

- `docs/rv64core/study/tools/generate_elaboration_xml.sh` 从当前 Makefile/filelist/product defaults 生成 `NpcTop` 和 `NpcSimTop+OOO_ASSERT` XML；builder 对全部 elaboration 输入 fail-closed freshness 检查。最终 HTML 包含 150 files、136 modules、195 instances、9 transaction、38 WaveDrom、58 main phases、2 sidePaths 和 240 显式数据字段。
- `audit_vsrc_coverage.py`、`audit_interactive_datasheet.py`、stale-XML 负向测试和 CSR sidePath-parent 负向测试均 PASS。独立 reviewer 的唯一 P1 已关闭并复核 PASS。
- 当前证据只证明源码快照、elaborated 静态层次、内嵌资源完整性和文档语义门；未执行浏览器动态 QA、RTL testbench、DiffTest、综合、STA 或 PPA。`docs/rv64core/study` scoped strict guard PASS；全工作树 strict guard 的 `rv64-linux`/`npc-dev` 缺证据来自大量既有/并发路径，保留为范围外 GAP。

## RV64 SQ-query retry current-source contract V9R

### C0 transaction 合同

- 在 edge-old full-flush barrier 周期，`OooIntBackend` 两路 SQ-query retry-ready/capture/fire 与 `OooMemAxiBridge.S_SQ_QUERY` handoff 必须被阻断，MIQ/SQ owner 保持；barrier 撤销后才允许精确 handoff。不得用 terminal 去重或弱化断言掩盖重复/提前事件。
- current production SHA-256 为 `OooIntBackend.v=49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`、`OooMemAxiBridge.v=2d6f33182e02e516e03864849e6d7299db44163a847b814f88ba8ea8d821a062`。验证源绑定必须同时覆盖 `testbench/Makefile`、`tb_ooo_int_backend.sv` 和 `tb_ooo_mem_axi_bridge.sv`。
- 当前 raw oracle 为 baseline 2/2 PASS；bank0、bank1、bridge 三个 compile-success RTL version 分别在 `@18/@39/@24` 被拒绝，3/3 PASS。V9O index 167/167，closed-debt currentness 为 16/38/32/0。

### A3 与晋级边界

- A3 定义为“系统 transaction 完成、旧 dmesg oracle 误判”，但原始 `FAIL rc=1` 永远保留。冻结 dmesg/console replay 只发布独立 checker PASS，不反写旧状态；checker 必须接受 `printk: debug:` 并拒绝真正 `BUG:`。
- 只有 production core RTL 语义、当前配置下实际 elaborated RTL、device model/simulator execution semantics 发生变化，或 A3 缺少原始输入、terminal chain、post-hash，才要求完整系统重跑。
- historical `VD0/VD1` 已清零并不等于 whole-core freeze；当前仍有 33 个 inventory/census/proof-depth blocker，故 `ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`。

## RV64 queue-head CSR stop owner historical VD3（2026-07-29）

### 稳定微架构合同

- queue-head CSR 从真实 dispatch birth 到 C0 前同时拥有两项前端合同：
  `OooStopPendingSequencer.head0_csr_inflight` 保持 registered
  `stop_pending`，`OooFrontendRunGate.head0_csr_inflight` 参与 owner OR，
  保证 `orphan=0, busy=1, can_run=0`。`stop_pending=1` 单独不能证明前端
  已停发。
- current `OooPendingDrainResolveGate.backend_drained` 要求 ROB empty，
  因此 queue-head CSR 仍 inflight 时 ordinary drain 不是可达 clear root。
  older-control kill、C0 exact commit 与 local/top flush 才是该 transaction
  的合法 owner death。
- C0 commit/barrier/CsrFile request、C1 typed apply/serial flush 与 C2 raw
  quiet 必须逐 transaction 计数；不能用 sticky seen/reported 去重掩盖重复
  terminal。

### 历史边界与动态证据

- `7f66f9d9...^` 同时缺 sequencer inflight hold 与 RunGate inflight owner；
  `7f66f9d9...` 只补前者，`2a77fd4b6...` 后续补后者。当前组合 negative
  是 current-topology root-cone equivalent，不冒充历史 checkout 的逐字节
  等价。
- 同一 product glue program 对四种语义各跑 assertion on/off：
  `8/8 compile-success`。current 与 drop-stop-hold 均为 zero
  gap/drop/run/overlap；drop-RunGate-owner 在 stop 仍为 1 时已出现
  `busy=0, can_run=1` 与真实 younger lane1 CSR capture；两项同时删除时
  orphan clear 进一步使 stop drop。
- current 与 hold-only 的 raw marker 为
  `hold_cycles=6, ordinary_drain_root=0, owner_gap=0, stop_drop=0,
  inflight_can_run=0, lane1_overlap=0, C0=2, C1=2, C2_quiet=2`。
  `successor_packet_cycles=0` 明确阻止把 hold-only survival 外推成 production
  删除或 PPA 资格。
- assertion-on combined negative 保留并触发 `[T3U-CSR-STOP-OWNER]` 与
  `[V9X-STOP-QCSR-HOLD]`；assertion-off 到达 older
  `0x80000010`/younger `0x8000001c` 的真实 lane1 overlap。负向版本均
  compile-success，不靠编译失败或削弱断言获得结论。
- matrix replay 的 summary bytes、case logs 与 allocator-normalized VVP
  identities 稳定；raw VVP bytes 因 allocator 标识变化只保留 receipt，不作
  semantic identity。runner/oracle 单测 7/7、V9O/standalone assertion
  on/off 与 module 113/113 PASS。
- 独立 reviewer 合同 SHA-256
  `f585e77a3b99d950897d91c527f1c542cb5008445c0eaf26ad1ebce9ca693988`
  裁决 bounded VD3 PASS。ledger 现为
  `VD0×0, VD1×0, VD3×3, VD4×2, selected=NONE`；这只清除 historical
  backfill blocker，不关闭 exact-history、formal、full-system、
  architecture-stable、综合、STA 或 PPA。
- production stop sequencer/RunGate 未改，design-id 保持
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。
  A3 原始 FAIL 与 checker-replay PASS 继续分别保留，本轮不满足完整系统
  重跑触发条件。
- task-specific `npc-dev`
  `2026-07-29-rv64-queue-head-stop-owner-historical` completed 5/5，
  7 个 evidence asset 已索引；20 条 scoped path 的 strict guard PASS。
  本轮 NPC/project memory 已 snapshot 且无 DB hash mismatch；全局仅保留
  8 个既有历史 task-run `missing_backup`。

## RV64 queue-head serialization and historical backfill V10G

### 稳定微架构合同

- product-default `OOO_CSR_QUEUE_HEAD=1` 只允许合法非 FP lane0/head0 CSR 在 ROB head 直接 C0 retirement；lane1/FP CSR 与其它 SYSTEM/trap/exit 不得借用该入口。
- queue-head CSR 的 typed C0 request、C1 registered apply/CsrFile request 与 C2 no-repeat 必须使用同一 PID/PC/inst transaction。killed CSR 不得产生任何 C0/C1/C2 side effect；不得用 seen-bit 去重掩盖重复 terminal。
- SYSTEM pending holder 继续覆盖 SATP/SFENCE/FENCE.I/FENCE/WFI/ECALL/xRET/IRQ 等 full-drain classes；owner/stop death、MMU/FPC action 与 typed redirect 均保留原断言强度。

### 当前证据

- design-id `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。queue-head assertion/release PASS；两份 compile-success C2 RTL version 均被拒绝；SYSTEM 3/3+14/14；layered replay 26/26，module 113/113、official 177/177、AM 59/59、DiffTest 0、architecture 9/9 GREEN。
- `SERIALIZE-G1` 经隔离 reviewer v2/v3 批准为 Phase1 CLOSED；v3 确认 `GAP_MARKER_SCHEMA_ONLY` 只属于旧 marker schema，当前 owner-bound raw scoreboard 会拒绝同一 compile-success RTL version。该状态不能外推到 later serialization phases、whole-core freeze 或 PPA。
- A3 是“系统 transaction 完成、旧 oracle 误判”，但原始 FAIL 不变；A4 是 TERM/FAIL。只有 production core、实际 elaborated RTL、device model/simulator semantics 或 A3 必需原始证据变化才要求完整系统重跑。

### Historical defect gate

- backfill 深度使用 VD0–VD4；VD0/VD1 阻止 architecture freeze。
  `HIST-SER-QH-YOUNGER-STORE-CYCLE` 已达到限域 VD3：产品前端 3 个
  committed 与 2 个 killed queue-head CSR birth 均为 `lane1_fire=0`；
  backend 双派发只用于构造历史根窗口。
- 同一原始计数器在 current owner guard、历史 transport-idle fixed 和历史
  `mem_idle && mem_retire_quiet` cycle 三种可编译语义上完成 assertion-on/off
  六组对照。fixed 在 `root_window=1` 恰有一次 C0/C1、C2 无重复且
  physical write=0；cycle 在 `root_window=4, mem_idle=1,
  mem_retire_quiet=0, hold=1, SQ=1, owner=1` 被动态拒绝。两个历史版本
  是 root-cone reconstruction，不是完整历史快照。
- Icarus `.vvp` 的内部 allocator-derived 地址不作为稳定设计身份：runner v2
  每次保留 raw image receipt，ledger-bound summary 使用地址归一化后的
  elaboration SHA。normalizer 2/2 单测与两次完整 replay 的 summary
  字节相等检查均 PASS；RTL oracle 未变化。
- production `OooIntBackend.v` 未变，design-id 仍为
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。
  reviewer v3/v4 均批准 `APPROVED_FOR_BOUNDED_VD3`；v4 确认 normalized
  SHA 未替代 source/log/oracle/raw receipt，并保留 normalizer 对未来
  VVP 语法非完备的边界。ledger audit valid，定向单测 4/4 PASS。
- 当前五项深度为 `VD4×2, VD3×2, VD1×1`。唯一 blocker 与下一选择是
  `HIST-SER-QH-STOP-HOLD-DROP`，需要真实 younger lane1 CSR overlap、
  assertion-on/off 原始计数，以及删除 `head0_csr_inflight` hold 的可编译
  `OooStopPendingSequencer` 负向版本。
- non-history bounded brief 已独立命中 backfill 蓝图；task-specific
  `npc-dev` 5/5 与 17 路径 scoped strict guard PASS。全局 DB-first
  仍因 183 个本轮范围外的历史 task-run live-content drift 返回 GAP，
  当前 NPC memory 与本 task-run 没有 missing/mismatch。
- current arch-stable checker 48/48、V9O index 167/167 属于既有 currentness
  证据；由于仍有一个 VD1、incomplete whole-core census 和空 freeze-input
  inventory，`ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`。
- 该 backfill 图已作为 `.github/agentic-hardware-blueprint.md` 的非历史入口；bounded recall、`npc-dev` 5/5、`agent-system` 11/11 和 strict guard 双 profile 均 PASS。具体活动缺陷仍只由 versioned ledger 维护。

## RV64 A3 systemd checker replay V10F（2026-07-28）

### 系统事务与 checker 绑定

- A3 设计为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`，
  仿真器 SHA-256 为
  `dc8a175a53bf45f1f1bd9b2228bf9bdf4f6981eb9e01f66ae86bb500cf91f218`。
  运行完成 5,071,521,696 cycles / 1,223,536,213 commits；六类 raw
  terminal marker 在 `guest/console.log` 中各一次且有序，RTL assertion
  证据为空，全部 pre/post binding 无漂移。
- A3 原始 strict 结果固定为 16/17、`done_rc=1`、唯一 FAIL
  `__NPC_CHECK_FAIL__:dmesg-no-critical`；源 status 继续是 rc=1，不能由
  replay 改写。
- A3 rootfs 内实际执行的 checker SHA-256 为
  `83b6a538…053f9a`，与 launch binding 相等。其 legacy
  `...|BUG:|...` 在冻结 console 中只匹配两条
  `printk: debug:`。生产 checker 改为
  `...|(^|[^[:alnum:]_])BUG:|...` 后，同一 console 零命中；
  `printk: debug:` fixture 接受、真实 `BUG:` fixture 拒绝，单测 3/3。

### 证据与边界

- V10F V2 status 为 PASS；独立 reviewer verdict 为
  `APPROVED_NOT_PROMOTION_ELIGIBLE`，合同 SHA-256
  `f4db46c5…bc21`。实现/审查共同结论仅为
  `A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`。
- 完整重跑仅在 core RTL 语义、实际 elaborated RTL、device/simulator
  执行语义变化或 A3 必需冻结证据缺失时触发。本轮四项均为 false；
  A4 的 TERM 中断记录保留且不得作为 PASS。
- exact terminal 计数只使用 SHA-bound raw guest console；
  `terminal-markers.txt` 的聚合 driver 摘录含重复 `GOOD TRAP` 和 stale
  `rc=0` 文本，不能代替原始事务计数。
- replay 比较器未来应补 A3/A4 generated filename set 双向相等门；
  当前 V2 由 51 个 A3 generated files 归一化零差异、八个 device object
  同哈希和 scoped source diff 支撑，不追改已完成证据。
- `npc-systemd-strict-check.sh`、systemd transaction checker 及其定向
  单测/fixture 的七个精确路径只要求 `rv64-systemd-contract`；其它
  `Linux/` 路径仍要求 `rv64-linux`。agent-system 路由自检同时证明
  `Linux/scripts/check-ubuntu-rootfs.sh` 不能被降级到 checker-only profile。
  该 guard 分类仅减少无关完整重跑，不改变四项硬件重跑触发条件。
- `2026-07-28-rv64-a3-checker-replay` 与
  `2026-07-28-a3-printk-debug` 均 completed；八路径 scoped strict guard
  对 `rv64-systemd-contract + agent-system` 为 PASS。全工作树 guard 的
  `rv64-linux + npc-dev` 缺证据来自本切片以外的 mixed-origin dirty 路径，
  继续保持显式 FAIL/豁免，不能外推为这些路径已验证。
- 本切片未修改 production RTL，不关闭 `SERIALIZE-G1`，不授予
  architecture freeze、综合/STA/power/PPA 或 promotion。

## RV64 Core 交互式 Datasheet（2026-07-28）

### 常驻入口与数据绑定

- 交互入口为 `docs/rv64core/study/index.html`；单文件离线 HTML 内嵌样式、脚本、
  WaveDrom 3.6.2 runtime/skin/license 和当前结构 payload。默认根为
  `NpcTop.u_core : NpcCoreTop`，可切到 `NpcTop` SoC 根。
- payload 当前精确计数为 150 个 `vsrc` 文件、136 个 module 定义、195 个
  `NpcTop` 实例、8 条 transaction、51 个主阶段、1 条 sidePath、208 个数据字段、
  37 个 WaveDrom；module/file/instance 三种身份分栏显示，源码页提供全部生产实例
  反向索引。
- 实例树用于回答“谁例化谁”；transaction 图用于回答 fetch/dispatch/execute/
  memory/completion/commit/redirect 如何流动。transaction phase 只表达 module-definition
  flow，不猜 lane；点击阶段进入定义页，再选择完整实例路径。

### 学习与验证合同

- 模块页固定为 General Description、Features、Quick Facts、Functional Block Diagram、
  Theory of Operation、Interfaces、Timing、Invariants、Source Evidence、Self-check 和
  Revision History。实例路径、module 类型和源码路径不会混成一个名字。
- 8 条主线为 instruction life、fetch packet、integer completion、FP completion、
  load、store、branch recovery 和 precise trap；每条均显示 owner、terminal、
  backpressure、flush 与 architectural effect。每个阶段按 Data In、State Update、
  Data Out、Guard 自上而下阅读；阶段编号表示相对先后而非固定拍数。
- 无 module-specific timing binding 时不展示其他模块波形；接口 filter 在 route
  切换时复位，transaction flow 不再通过 `firstInstanceForModule` 猜双 memory lane。
  用户截图中的固定宽单行、独立箭头和绝对定位标签已删除；phase 使用全宽纵向有序
  列表，handoff 收入卡片，Features/lead-grid/callout 使用 container-adaptive grid、
  长词断行和窄屏单列，print CSS 强制单列。
- WaveDrom 保持电平不得重复写显式 `0`/`1`。本轮规范化 9 章 71 个 wave 字段为
  `.` 保持符号，周期长度和跃迁不变；formatter、Markdown audit、generator 防御性
  规范化、最终 payload audit 共同防止伪尖峰回归。
- 每个实例页有 5 个原生 `<details>` Self-check 答案，共 975 个答案槽；状态证据机械
  提取 1218 个 sequential target，覆盖 `always`/`always_ff`。
  `AxiDpiSlave=1/11`、`AxiVirtioBlk=2/16`（posedge blocks/targets）。ADD/DIV 案例
  明确 older DIV 可被 younger ADD 先完成但不可被越序退休。
- Store 主完成链为 bridge B→带 tuple/error 的 response→`OooIntBackend` exact live-table
  映射恢复 ProducerId/ROB→formal WB + SQ terminal→ROB；卡内并行 owner-lifetime
  sidePath 只把 `{kind,token,epoch}` 送 collector/tracker 回收，不携带 error/fault/PID。
- `build_interactive_datasheet.py` 最新生成 1054123-byte HTML；交互审计为
  `150 files / 136 modules / 195 instances / 8 transactions / 51 phases /
  1 sidePath / 208 fields / 975 answers / 1218 state targets / 37 wavedrom /
  external_resources=0 / PASS`。原讲义 atlas 为 150/150 PASS；JavaScript `vm.Script`
  和五个 Python 工具语法检查 PASS。
- 独立 reviewer 修正前发现 4 个 P1，首轮闭环后给出 0 P0/P1；波形/横向溢出定点
  复核为 0 P0/P1/P2。Rev. B 复核又关闭 always_ff、Store 回程、窄容器与
  tuple/completion 混画反例，最终为 0 P0/P1/P2。Codex 内置浏览器对本地 `file://`
  的安全策略拒绝实际打开，
  且未绕过；因此真实 320/375 px、触控、打印预览以及 RTL TB/综合/STA/PPA 均保持
  GAP；本任务未修改
  `npc/rv64/vsrc/**`。证据见
  `.github/task-runs/2026-07-28-rv64core-interactive-datasheet/`。
- 全工作树 strict guard 因 764 个共享 dirty paths 要求 `agent-system/rv64-linux/npc-dev`
  新 evidence；这些触发路径不是本 HTML 任务产生，故显式豁免，不运行越出文档范围的
  Linux/RTL profile。以 docs、task-run 与两份 memory 共 4 个实际交付 path root
  运行 scoped strict guard 为
  `required_profiles=0`、PASS；这不证明当前脏工作树里的生产 RTL 或 Linux 改动。

## RV64 Core 学习讲义与当前拓扑基线（2026-07-28）

### 常驻入口与清册

- 学习入口为 `docs/rv64core/study/README.md`；00–10 按 transaction/周期讲解，11 为
  `npc/rv64/vsrc` 全部 150 文件逐项地图，12 为可复核实验。覆盖门
  `tools/audit_vsrc_coverage.py` 当前为 150 个结构化 atlas row、150/150 路径、
  37 WaveDrom、全部本地链接与严格 JSON PASS；每路径必须恰好一次，六类身份计数
  必须精确为 124/6/3/3/9/5。
- `extract_vsrc_inventory.py` 结合当前 `NpcTop`、`NpcSimTop` Verilator XML 的分类：
  `NpcTop-reachable=124`、`simulation-only=6`、`focused-checker=3`、
  `catalog-only=3`、`header/include=9`、`document/build=5`。
- 3 个 catalog-only memory leaf 是 `OooMmuEpochOwner`、`OooPmaChecker`、
  `OooPostTranslateMemoryClass`；当前 typed production 路径使用
  `OooTypedPmaChecker/OooTypedMemoryClassifier`。源码存在或进入 filelist 均不能替代
  顶层实例证明。

### 当前结构与周期合同

- 真实层次：
  `NpcTop → NpcCoreTop → {OooFetchAxiBridge,
  OooDualMemBridgeWrapper, OooLsuAxiLaneAdapter, OooCoreTopGlue, CsrFile}`。
  `OooCoreTopGlue` 下接 `OooFrontend/OooExecuteBackend/OooControlPlane/
  OooMemoryAccess/OooWriteback`；`OooExecuteBackend → OooAluCoreSlice →
  OooAluDecodeBackend → OooIntBackend → OooDispatchBackend`。
- 双 memory production 路径已经启用：2×bridge/DTLB/D-cache 在 raw AXI 层经
  `OooDualMemAxiArbiter` 锁 owner；旧 README/filelist 的 F2 “未实例化”说明过期。
  `AxiXbar` 是 2-master/16-slave single-outstanding 子集，R 有 registered response
  slice，AW/W 分别 capture。
- 前端 packet FIFO 是 4 个 packet，不是 8 个独立 slot；cache-hit C0 request、
  C1/H1 response/enqueue、C2 registered head dispatch。当前无 response bypass、
  full+pop look-through 或同拍 redirect request；redirect 后旧响应仍由
  `discard_fetch_rsp_q` 物理消费，但禁止进入 FIFO，这不是 epoch 丢弃。BPU 为
  gshare1024/GHR10 + local-history256×8/local-PHT4096；RAS 为 32 entry。
- Decode、rename、resource-ready 和 dispatch 是组合融合；dispatch fire 上升沿同时写
  RAT/FreeList/Busy/ROB/IQ。IQ 无 dispatch bypass，新 entry 下一周期才选择；PRF
  stored-only，`early_wakeup` 只改 IQ sticky-ready，值来自 registered EX forwarding。
- ProducerId 为 generation4+ROB-index4；完整 holder live-mask 与 exact-open 才是
  防止槽复用/晚到结果的安全合同，generation 单独不是安全证明。ROB 16 entry，
  formal WB 沿写 done，最早下一周期 commit；异常 entry 可从 head dequeue，但不写架构
  状态、不计 `instret`，head0/head1 exception 均阻止 commit1。
- FP 使用独立 RAT/FreeList/IQ8/PRF64。FADD2/FMUL3/FMA5 内部深度统一对齐
  meta-stage5；authorized raw result 可先写 FP PRF/wake，并进入 8-entry done FIFO；
  FIFO head 获 formal FPWB 后 ROB 才 done，架构 FPR/fflags 在 commit 更新。
- SQ 为 4-entry 程序序 owner：allocate/bind/fill/forwarding 后，只在 SQ head 匹配
  ROB head 且 `rob_head_launch_open` 时发物理 Store，AW/W 可异步，B terminal 后精确
  释放。LQ16 对已 launch 后被 kill 的 Load 仍等 terminal；MIQ0/1 各 4 entry，
  LOAD/PROBE 可 kill，DRAIN 存活。
- serialized SYSTEM/trap/exit 必须等 exact `mem_owner_terminalized`，普通 FENCE 额外
  等 `mem_idle`。`OooControlEventApplySequencer` 将 request 的 reason/kill-index 延迟
  一拍 apply；redirect arbiter 先按 ROB 年龄，平龄 `trap > branch > direct`。

### 证据边界

- 三个领域隔离只读 reviewer 分别复核 frontend/decode、backend/FP/retire、
  memory/control/integration；第四个最终隔离 reviewer 对抗式复核全讲义，得到
  0 个 P0、2 个 P1、2 个 P2。四项已分别修正 IFU discard、Store B-terminal
  精确链、branch resolve/formal-WB 语义和 atlas 结构性防假绿；实现者用当前
  XML/路径清册和机械门重验。
- 本轮未修改 RTL，未运行 TB/仿真/综合/STA/PPA；学习讲义对静态 owner/周期合同给出
  高置信解释，对动态功能、性能、Linux 与 physical timing 保持 GAP。bounded
  non-history recall 与 strict guard 已 PASS。
- task-run：`.github/task-runs/2026-07-28-rv64core-study-manual/`。

## RV64 simulation-exit exactly-once V10D

### 稳定微架构合同

- `pending_exit` 与 pending SYSTEM、pending architectural trap 共用
  exact memory-owner terminal 边界：
  `!(pending_system_i || pending_arch_trap_i || pending_exit_i) ||
  mem_owner_terminalized_i`。ROB/issue drain 不能替代 older memory
  holder 的 accepted terminal handoff。
- lane0/lane1 accepted exit birth 进入唯一 registered holder；
  active-holder 周期 raw exit 必须为 0。exact terminal C0 只产生一个
  `OooTrapExitEventMux.exit_o`，同沿清 exit holder/stop 并由 output
  sequencer 锁存 status；无新 capture 时 C1/C2 raw exit 为 0。
- `core_local_flush` kill 必须同时清 exit owner 与 stop，不产生 raw
  exit 或新 output latch。older terminal trap/recovery 在 raw mux 与
  sticky output 两个边界都优先于 exit，禁止同事务双 terminal latch。
- `OooIntBackend.mem_owner_terminalized_o` 只消费
  `OooMemOwnerTerminalCollector.ingress_accept_o` 等价 mask与 exact SQ
  release；production predicate 位于 `OOO_ASSERT` 外。raw ingress、
  tuple mismatch、duplicate 或 same-edge dequeue/re-enqueue 不能授权
  serialized exit。
- exactly-once oracle 直接计 raw mux pulse，不使用
  `NpcSimTop.exit_reported_q` 或其它 seen/report 去重；不得削弱
  owner/stop/memory-terminal/C1/C2 assertion。

### 当前证据与边界

- current design-id 为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`。
  assertion-on/off focused 各 5/5，七个 compile-success RTL variant
  7/7 拒绝，module 113/113、functional
  113/113+177/177+59/59 且 DiffTest mismatch 0、architecture 9/9
  GREEN、closed currentness 15/35/0。
- 独立 reviewer 给出 `APPROVED_FOR_CURRENT_SCOPE`，未发现当前
  simulation-exit transaction 的 blocking RTL 反例。standalone output
  sequencer 的人工跨周期 trap→exit 双 sticky 尚无专门 adversarial
  TB；批准依赖 integrated halted/run-gate 与 holder clear 的不可达性，
  该项是非阻断增强候选。
- V10C replay stage-order 现把 index build 与
  `control-event-index-verify` 都置于 ledger/currentness 之前；无条件
  preflight 以 candidate-before-architecture、missing-index-verify、
  verify-after-ledger 三个负向 fixture fail closed。attempt 13 持久化
  marker 后 currentness PASS。
- `npc-dev` task-specific e2e
  `.github/task-runs/2026-07-27-simulation-exit-exactly-once-revtag-v10d/`
  completed 5/5 并完成 DB marker publication；最终 strict guard 对
  `npc-dev` current evidence 判 PASS。该工作流证据只闭合 V10D
  记录层，不替代 Linux/rootfs、综合、STA 或 PPA 证据。
- `SERIALIZE-G1` 仍为 P1/OPEN。历史 V9Q rootfs 是旧设计 405M commit
  timeout、空 terminal marker，不是 current-design system evidence。
  当前 `architecture_freeze=GAP`、PPA `UNQUALIFIED`、promotion=false；
  本节不外推 Linux/rootfs、synthesis、STA、power 或长期目标完成。
- canonical task-run：
  `.github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/`。

## RV64 serialized SYSTEM post-fire V10B

### 稳定微架构合同

- `OooPendingSystemSequencer.kind_q` 的八类 canonical transaction
  继续是 `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ`。非 CSR
  transaction 在 exact memory-owner terminal 的 C0 产生唯一 raw
  action，C1 清 holder/stop 并提交对应架构或控制 side effect；无新
  capture 时 C2 不得重复。
- CSR 在 dispatch 后建立 exact ProducerId/PC lease；错误 PID 或 PC
  不得写 `CsrFile`、不得产生 CSR commit redirect，也不得杀 lease。
  exact commit 才能写 CSR、产生 `CSR_COMMIT/NONE` redirect 并清
  holder/stop。SATP write 的注册 MMU pulse与 CSR write phase 对齐。
- ECALL/IRQ 只允许 selected trap record 写 xEPC/xCAUSE/xTVAL 并产生
  TRAP redirect；XRET 只允许真实 MRET/SRET state transition；WFI 按
  frozen cohort 执行 immediate-resume SERIAL transaction，且不得制造
  CSR/trap/MMU action。
- 四种 SFENCE-family encoding 统一产生 SFENCE typed redirect 与注册
  MMU pulse；FENCE.I 产生 FENCEI redirect、注册 MMU pulse并清
  `OooFetchPacketCache`/ITLB，使同 PC 下一次 fetch 重新发 AXI request。
  ordinary FENCE 额外等待 full `mem_idle_i`，并保持零 CSR/trap/MMU。
- 所有 checker 直接计 raw pulse 与周期，不使用 seen-bit 去重；不得用
  terminal-event 去重、静默丢弃或削弱 assertion 掩盖重复/幽灵事件。

### 当前证据与边界

- current design-id 为
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。
  V10B 未修改 production RTL；pre-change FENCE.I MMU 断线版本在旧
  TB 上仍 PASS，证明原 observation gap。
- V3 为 3/3 baseline PASS、14/14 compile-success RTL version 动态
  拒绝，四个 TB path/SHA 逐 case 绑定。切断
  `OooFetchPacketCache.clear_i(mmu_flush_i)` 的版本会出现 stale
  response、无 AXI refetch 与旧 packet，由 typed/local/final marker
  一致判 FAIL。
- module 113/113、functional 113/113+177/177+59/59 且 DiffTest
  mismatch 0、CoreMark/Dhrystone PASS、architecture 9/9 GREEN，
  全部绑定相同 design-id。final-reviewer-v2 标准化 verdict 为
  `APPROVED_FOR_CURRENT_SCOPE`。
- FENCE.I 是 production pulse、top wiring 与 bridge consumer 的组合
  证明，不是 full-core self-modifying/Linux 证明；未做形式穷举。
  `fdg-arch-trap-current.json` 仍绑定旧 design-id/111-module，
  `SERIALIZE-G1=P1/OPEN`。simulation exit、Linux terminal、
  architecture-stable、synthesis/STA/power/PPA 均为 GAP/UNQUALIFIED。
- canonical task-run：
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/`。
  task-specific `npc-dev` 为 completed 5/5，限定本轮路径的 strict
  guard PASS；该 workflow 结果不替代未运行的 Linux/PPA 业务 gate。

## RV64 clocked serialized-owner exactly-once V10A

### 稳定微架构合同

- `OooCsrTrapRequestMux` 的 drained pending control authority 为 `!core_commit_exception_trap_o && stop_pending_i && drain_complete_i`。ROB-head commit exception 与 pending architectural trap 同沿时，生产 `CsrFile` 只采样 selected mem record，raw pending trap request、trap-ex request 与 predictor boundary 必须保持 0。
- registered architectural-trap owner 与 registered pending-system owner 必须 onehot。live serialized owner 必须保持 `stop_pending_o=1`，并通过 `OooFrontendRunGate.can_run=0` 构造性阻止 head0/lane1 ECALL、xRET、CSR、FENCE 类以及新 IRQ owner birth。
- exact memory-owner terminal 的 C0 只允许当前 pending owner 对应的一类 request；该沿由 `CsrFile` 采样一次，并使 trap/system holder 与 stop 在 C1 清除。无新 accepted capture 时，C1/C2 不得再次产生同一 transaction 的 raw request、CSR record 或 typed redirect。
- priority 保持 `rst/core_local_flush > selected trap > xRET > CSR write > ordinary clear/capture`。修复只增加组合 priority term；不得引入 terminal-event 去重，不得用静默丢弃或 assertion 降级掩盖合法 overlap。

### 当前证据与边界

- current design-id 为 `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。production clocked TB 覆盖 head0/lane1 birth onehot、IRQ-over-arch、五类 SYSTEM standalone exact-one、live arch owner 对五类 overlap、commit-trap priority、older memory holder 与 C0/C1/C2 no-repeat。
- assertion-on/off focused 均 PASS；6 个 compile-success variants 分别删除 commit mask、head0/lane1 exclusion、IRQ priority、arch holder clear 和 stop clear，均编译成功并被动态 oracle 拒绝。module 113/113、functional 113/113+177/177+59/59 且 DiffTest mismatch 0、architecture 9/9 GREEN，canonical aggregate 均绑定相同 design-id。
- 独立审查将 pending architectural-trap clocked exactly-once 子范围判 `PASS`，同时保留三项 provenance/coverage 边界：pre-fix RED 无完整历史源码快照，focused log 无内嵌 design-id，TB 未单独逐拍计数最终 frontend redirect / `priv_predictor_boundary`。本节不能外推为八类 SYSTEM post-fire、Linux terminal、architecture-stable 或 PPA。
- `SERIALIZE-G1=OPEN`，`ppa=UNQUALIFIED`。canonical task-run：`.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/`。

## RV64 pending architectural-trap memory terminal V9Z

### 稳定微架构合同

- `OooPendingDrainResolveGate` 对 pending SYSTEM 与 pending architectural trap 共用同一 exact memory-owner terminal 边界：`!(pending_system_i || pending_arch_trap_i) || mem_owner_terminalized_i`。旧 memory holder active 且没有 exact accepted terminal transfer 时，`drain_complete_o`、`pending_arch_trap_fire_o`、trap request 与 predictor boundary 必须保持 0。
- exact same-edge accepted transfer、collector-pending-only 与 full-idle phase 继续由 production `mem_owner_terminalized_i` 标量表达；没有 serialized owner 的无关 control cycle 不受该标量约束。ordinary FENCE 仍额外等待 full `mem_idle_i`。
- 该修复只增加组合 consumer term，不增加寄存器、terminal 去重或 collector filter；`OooMemOwnerTerminalCollector` 与 owner/tracker fail-loud 合同保持不变。

### 当前证据与边界

- current design-id 为 `sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`。原始 pre-fix 集成 TB 编译成功并在 active-holder case 精确拒绝 drain/fire/trap-request/predictor-boundary 四项观测；原日志不含 pre-fix RTL SHA，后续 hash-bound `drop-arch-trap-terminal-term` 是独立等价反例，不与原日志混写。
- assertion-on focused 3/3、assertion-off 2/2、compile-success RTL variants 4/4 动态拒绝、module 112/112、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark/Dhrystone PASS；DI-1..DI-5/OOO-1..OOO-4 共 9/9 GREEN。gate、mux、integrated TB 与 146-file architecture manifest 均绑定当前设计。
- V2 reviewer 将 gate→mux 的 V9Z 组合边界判 `PASS`，但 clocked owner clear、无新 capture 时副作用 exactly-once，以及 arch-trap 与 ECALL/IRQ/xRET/CSR/FENCE overlap 的 priority 或 constructive unreachability 尚未证明。
- `SERIALIZE-G1` 保持 `OPEN`。下一步应把 `OooPendingTrapExitSequencer`、`OooPendingSystemSequencer`、`OooControlEventApplySequencer` 与生产 `CsrFile` 纳入 clocked gate-to-owner-to-CSR testbench；七类 serialized exactly-once、完整 Linux terminal、architecture-stable 与 synthesis/STA/power/PPA 均保持 GAP/UNQUALIFIED。
- canonical task-run：`.github/task-runs/2026-07-27-rv64-v9z-serialize-arch-trap-terminal/`。

## RV64 accepted memory-owner terminal V9Y

### 稳定微架构合同

- `OooMemOwnerTerminalCollector.ingress_accept_o` 是 collector handoff 的唯一 current-edge authority：每一 lane 必须同时满足 edge-old tracker live、非 reserved kind、kind/epoch exact、无同批 token duplicate、无 edge-old pending 和无 same-edge dequeue/re-enqueue。raw `ingress_valid_i` 只表示事件到达，不能授权 `mem_owner_terminalized_o`。
- `OooIntBackend` 的 active-holder census 覆盖 MIQ0/1、bridge0/1 active+station residency、reservation0/1、legacy buffer、`mem_pending_q`、retry0/1、SQ owner、request-fire handoff与 same-edge reservation birth。terminal transfer 只取 accepted collector mask 或 `sq_owner_release_effective_mask_w`。
- production census 与 `mem_owner_terminalized_o` 必须位于 `OOO_ASSERT` 外；宏只保护 shadow/fail-loud checks。active/no-transfer 为 0，exact accepted transfer、collector-pending-only、full-idle 和 exact final SQ release为 1；wrong tuple/duplicate active raw ingress保持 0。
- 标量经 DecodeBackend→CoreSlice→ExecuteBackend→CoreGlue→ControlPlane 原值传递。CSR Cresolve 与非 CSR pending-system drain 都必须消费；ordinary FENCE 继续额外要求 full `mem_idle_i`。不得用 full idle 替代 exact phase predicate，也不得用去重/丢弃重复 terminal 制造 PASS。

### 当前证据与边界

- current design-id 为 `sha256:3c933ec82fd17c6038335f9208b496cacfb755dfd10b9e419c73f276b5e2a428`。assert/release V8W 与 collector 均 PASS；12-lane batch capture/drain exactly once、wrong-epoch、duplicate、same-edge reenqueue、SD/FSD exact SQ release均有 production marker。
- pre-fix CSR/non-CSR RED 保留。删除两个 gate、退化 full `mem_idle` 的三项 compile-success 变体 3/3 拒绝；raw-ingress authority、raw-valid acceptance、assertion-only predicate 的三项 `OOO_ASSERT=0` 变体 3/3 拒绝。live backend/collector/TB SHA 与 mutation summary 完全一致。
- module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark/Dhrystone PASS；DI-1..DI-5/OOO-1..OOO-4 共 9/9 GREEN。V4 独立 reviewer 在 V3 RTL review 基础上完成最终 provenance PASS。
- task-specific `npc-dev` 为 bounded recall 完整、5/5、exit 0；V9Y evidence index 为 491 assets/296,521,308 bytes，SHA-256 `8e077496388028dff7f8ce4f3053a55be76a6cc9585cc5d3f586c13a2f39c50b`，包含 strict-guard status。strict guard 的 `agent-system/npc-dev/difftest/github-index` 均 PASS；`rv64-linux` 仍缺 17/17 guest checks、natural poweroff、reset-syscon、`GOOD TRAP` 与 terminal transaction 完成证据，按系统层 GAP/豁免记录。
- V9Y 只关闭 non-FENCE pending-system memory-owner terminalized 子范围。pending arch-trap、七类 transaction exactly-once、完整 Linux flag-on、`SERIALIZE-G1`、architecture-stable 与 synthesis/STA/power/PPA 保持 OPEN/UNQUALIFIED。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/`。

## RV64 recovery/owner-birth phase alignment V9X

### 稳定微架构合同

- `stop_pending_o` 的 birth 只能来自 holder 已接受的 owner event：pending SYSTEM/CSR/IRQ 使用 `pending_owner_birth_w`，trap/exit 使用 holder-valid transition，queue-head CSR 使用 canonical `head0_csr_dispatch_fire_w`。raw instruction classification 和 merged backend fire 都不是 owner-birth authority。
- edge-old exact CSR `ProducerId` lease 与 live queue-head inflight 都是 stop 的保持资格；普通 recovery 不能杀 exact lease，matching commit/death、older-control queue-head kill 或 C1 reset 才能按 owner phase 清除。reset/C1、exact death、lease/inflight hold、accepted clear/birth 的顺序由一个显式 next-state chain 决定。
- `OooPendingTrapExitSequencer` 与 `OooStopPendingSequencer` 必须同时消费 C1 `core_local_flush_w`；squash clear 与 same-edge wrong-path capture collision 由 clear-wins，payload/valid 不得复活。
- terminal collector 的 duplicate/conservation assertion 保持 fail-loud；V9X 没有增加 terminal-event 去重或事件丢弃逻辑。

### 当前证据与边界

- current design-id 为 `sha256:a2ccc0c2a61be3d8922245f7d145eadc186b701fca1f38ef534aafdd983e994b`。checkpoint recovery × 两 lane 与 exit-squash RED 均有对应 green；五项 assertion-negative 命中，最终 queue-head flag-on 同时观察 real-fire single-source 与 C1 holder reset。
- 两项 compile-success RTL mutation 2/2 拒绝；module 111/111、functional 111/111+177/177+59/59、DiffTest mismatch 0、architecture 9/9 GREEN。V4 reviewer 逐项核对相关 RTL SHA 与 final source map 后，将 owner-birth 子范围判 PASS。
- mutation summary 直接绑定 production `OooControlPlane.v` 的 before/after SHA，而不是完整 mutant cohort/TB 的统一 aggregate hash；保存的 mutant source/log hash、临时编译路径、V9P marker 与 return code 已独立复核。该项记录为证据强度 caveat，不是当前 blocker。
- `SERIALIZE-G1` 仍 OPEN。下一步必须沿 `OooMemOwnerTerminalCollector` 的实际 ingress lane 对追踪非 FENCE serialized transaction，从 registered owner/holder 到 bridge/MMU/commit/trap/return terminal 建立逐类 exactly-once 证据；不得用去重掩盖重复 terminal，也不得从 focused owner-birth PASS 外推完整 Linux、arch-stable 或 PPA。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/`。

## RV64 pending-system canonical type and typed redirect V9W

### 稳定微架构合同

- `OooPendingSystemSequencer.kind_q` 是 serialized SYSTEM/CSR/IRQ 类型的唯一注册真源；`valid_o` 当且仅当 kind 非 NONE，valid holder 的八个公开类型 exact-one。非空 holder 不接受 recapture，kind/payload 保持到授权 clear/death。
- 普通 FENCE 由 holder 输出 `fence_o`，`OooControlPlane` 不得再从 raw instruction 建立第二类型真源。SFENCE.VMA/SINVAL family 与 FENCE.I 的 redirect reason 必须消费 exact holder-derived commit pulse。
- CSR ProducerId lease 只在 CSR dispatch birth，必须由 matching PID+PC commit death 或 backend-global reset 终止；非 CSR serialized transaction 不制造 ProducerId。

### 当前证据与边界

- current design-id 为 `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`。两 lane × 七类非 IRQ capture/hold/clear 为 14/14；SINVAL 产生 SFENCE reason、FENCE.I 产生 FENCEI reason；四个 compile-success RTL 变体分别验证 onehot、kind-valid 与两条 typed redirect oracle。
- focused 2/2、layered 6/6、module 111/111、architecture 9/9 GREEN。该证据只关闭 canonical type/typed redirect 局部切片。
- 当前 `rv64-linux` 绑定相同 design-id 与 simulator SHA-256 `4b0be491fbe1305e79bbaf599787f1321c8ac7dcc8ea5236a23a735edda8441d`：7 个前置节点 PASS，rootfs 节点在 Linux 0.059199 秒、EFI 初始化后达到 1200 秒 host boundary；未看到 mount/systemd/terminal 或 RTL assertion-failure marker。因此它只增加 forward-progress 边界，不关闭 serialized terminal transaction。
- `SERIALIZE-G1` 仍为 OPEN：尚需七类 × 两 lane × holder phase × recovery source 的交叉反例、`core_mem_idle_w/core_mem_retire_quiet_w` 真实 owner 终态，以及 commit/trap/return、redirect、holder/stop clear、MMU flush、bridge terminal 的 exactly-once 联合观测。禁止用 terminal 去重或 assertion 降级掩盖重复/幽灵事件。
- full-core architecture freeze 保持 GAP/32 blockers，PPA UNQUALIFIED、promotion=false。

## RV64 full-core capability cohort V9V

### 稳定微架构合同

- `full-core-single-hart-rv64-dual-issue-ooo-v1` 是当前 full-core candidate 的规范 capability cohort，并严格绑定 design-id `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。cohort exclusion 不是因缺测试自动产生；必须有明确 rationale、当前 design/cohort、规范合同路径/hash 和 candidate/ledger 完全对称集合。
- A-extension 只承诺单 hart local reservation：successful LR 建立，SC consumption 与 hart-issued store/AMO write 清除；autonomous coherent/exclusive peer invalidation 不属于当前产品 cohort。
- WFI 是经过 pending-system drain 的 legal immediate-resume hint，`mstatus.TW` below M 的非法路径保留；不承诺 clock/power sleep、interrupt-only wakeup 或 wake latency。
- accepted `SFENCE.VMA` / Svinval-family encoding 统一进入 serialized pending-system，并形成 global `mmu_flush`；不承诺 address/ASID selective invalidation。reserved encoding 与 TVM legality 不变。
- simulation observability、`OOO_ASSERT` 与 semihost EBREAK 不是 architectural Debug。当前 cohort 不广告 Debug Module、debug mode、halt/resume transport 或 executable trigger action。

### Terminal owner/holder 与验证边界

- `OooIntBackend` 的 collector ingress 0..11 仍依次为双 bank response、双 bank active/station drop、双 reservation、legacy buffer、AMO interphase、双 retry terminal。collector 只保存 exact `{kind,token,epoch}`，duplicate/pending/same-edge-reenqueue/conservation 继续 fail-loud；禁止以去重或丢弃重复 terminal 形成 PASS。
- 当前 8 个定向 testbench 8/8 PASS；collector 为 `pending=12` / `seen=12`，V9R backend 为 `banks=2 forced=2 natural_trap=1`，bridge 为 `S_SQ_QUERY held=1 release=1`。design-id 与 verification-source-id 前后稳定。
- canonical architecture gates 9/9 GREEN、V9O index 165 artifacts、arch-stable 单测 48/48，四项 cohort exclusion 与 exact membership PASS，15 个 CLOSED debt current binding PASS。
- historical rootfs terminal-pair 运行绑定旧设计并以 host timeout 结束，空 terminal marker 只算有界未复现。当前 full-core 仍为 `GAP`/32 blockers，`SERIALIZE-G1=OPEN`，census/freeze-input inventory 未完成，PPA `UNQUALIFIED`。
- `npc-dev` e2e 为 5/5 PASS，V9V evidence index 与 DB-first audit PASS；strict guard 的剩余项仅为 `agent-system` Markdown coverage 与 `rv64-linux` V9S systemd-strict，二者保持 GAP。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9v-full-core-cohort-scope/`。

## RV64 CsrFile vectored trap / interrupt delegation V9U

### 稳定微架构合同

- `mtvec/stvec` MODE=00/01 必须原样保存，MODE=10/11 写入时钳位为同 BASE 的 Direct。只有被 `mem > ex > irq` 选中的 interrupt 在 MODE=01 时加入 `4×cause`；同步 mem/ex trap 始终到 BASE。
- supervisor pending bit 的 cause 与目标特权级分离：未委派 SSI/STI/SEI 保留原 cause 并进入 M，已委派项只在当前 privilege 低于 M 时进入 S；M-mode 中已委派 supervisor interrupt 被屏蔽。标准优先级为 MEI>MSI>MTI>SEI>SSI>STI。
- A1/A2 独立重构 trap record/target，A3/A4 检查 tvec WARL，A5 独立重构 interrupt pending/cause。禁止以生产表达式自证或通过丢弃 terminal event 形成 PASS。

### 当前证据与边界

- current design-id `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。V9U focused 13/13、full-core paths 3/3、CSR regression 1/1、compile-success negative RTL variants 7/7；定向 `rv64mi-p-illegal` 与完整 official 177/177 均通过。
- 完整 F0 为 module 111/111、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000；CONTROL/V9R 与 9 个 architecture gate 已在相同设计 SHA 重放。
- full-core candidate 仍为 `GAP`、36 blockers、PPA `UNQUALIFIED`、promotion=false。未完成项包括 SERIALIZE、scope decisions、完整 producer-holder census、cohort inventory 与 freeze inputs；V9S systemd-strict 仍为 RED。
- 配套 AI 环境的 `github-index` bounded chunk 修复已由 `.github/task-runs/2026-07-26-default-chunk-max-tokens/` 完成验证；它不改变 RTL design-id 或本节微架构结论。strict guard 的 `agent-system` Markdown coverage 与 `rv64-linux` V9S RED 继续按 GAP/豁免记录。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design/`。

## RV64 12-lane terminal collector V9T

### 稳定微架构合同

- `OooIntBackend.u_mem_owner_terminal_collector` 的 ingress 0..11 顺序为 bank0 response、bank1 response、bank0 active drop0、bank0 station drop1、bank1 active drop0、bank1 station drop1、reservation0、reservation1、legacy buffer、AMO interphase、retry0、retry1。结构门同时核对 `INGRESS_N=12`、每个 packed signal 的宽度与完整有序 concatenation。
- collector 只接受 edge-old tracker 中 live 的 exact `{kind,token,epoch}`；duplicate ingress、already-pending duplicate、same-edge re-enqueue、tuple mismatch、non-live owner、output duplicate/hold 与 conservation 继续 fail-loud。禁止用丢弃或去重 terminal event 的逻辑制造 PASS。
- V9R producer-side C0 barrier 仍是最小生产修复：full-flush C0 关闭 backend 两个 retry READY 和 bridge `sq_query_retry_fire_w`，保留 edge-old MIQ/retry/bridge owner，barrier 解除后恢复原 transfer。

### 当前证据与边界

- design-id `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`；focused release/assert 均为 12 ingress capture、12 exact drains、0 ghost，canonical DI-3 为 GREEN。hard-gate 单测 33/33 覆盖 lane10/lane11 顺序反例；pair matrix 的 15 个 compile-success variants 全部被 simulation/source checker 拒绝。
- module aggregate 110/110 PASS，verification SHA 为 `73466b559c293cc34c9825aabca7c0f2490ce1e846f04a7d710af1e76daccca3`。V9R baseline 2/2 与 C0 READY/fire 三个 compile-success variants 3/3 仍绑定 live source。
- V9S 当前最远到 640,000,001 commits、PC `0xffffffff8013e132`，没有 collector/V9Q/RTL assertion marker，但 36,000 秒后仍只完成 14/17 guest checks且没有 natural poweroff。该观察是有界不复现，不能识别历史 340M duplicate 的 exact lane pair，也不能关闭系统、full-core freeze 或 PPA gate。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9t-terminal-collector-12lane/`。queue-head 默认值在系统 17/17 + reset-syscon + `GOOD TRAP` 前不翻转。

## RV64 SQ-query retry C0 handoff V9R

### 稳定微架构合同

- 当 `control_full_flush_barrier_w/i=1` 时，SQ-query retry 的 C0 传输必须暂停：`OooIntBackend` bank0/bank1 retry READY 均为 0，`OooMemAxiBridge.sq_query_retry_fire_w` 为 0。MIQ、retry holder 与 bridge `S_SQ_QUERY` 中已有的 exact owner 保持，不得在 barrier 周期制造新的跨 holder 所有权关系。
- barrier 解除后沿用原有 READY/fire 规则恢复传输；该修正不增加寄存器、队列深度、owner token、AXI channel gate 或仲裁级，因此没有独立面积/时序收益声明。
- V8T empty-slot progress assertion 必须把 C0 barrier pause 视为合法暂停；V9R assertion 则直接拒绝 C0 上的 backend capture exposure 与 bridge owner release，二者职责不能互换。

### 当前设计证据与边界

- current design-id 为 `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`。V9R baseline 2/2 覆盖 bank0/bank1 forced C0、natural ROB trap-head C0、bridge `S_SQ_QUERY` hold/release；三份可编译 RTL 反例 3/3 被精确 assertion marker 拒绝。V9R v2 summary SHA-256 为 `35f2337f15acdfcc77ef20a1b536e7edfe86aa901068c743cc5b53c312f041b5`。
- 完整顶层使用显式 `--timescale 1ns/1ps`；SQ forwarding 组合块补齐局部默认值，owner assertion 计数改为无状态函数，sim-only arm counter 改为显式 time-0 初始化，TLB/cache 私有函数采用模块限定命名。`make -C npc/rv64 lint` 与完整 `NpcSimTop + OOO_ASSERT` 构建通过，未用全局 warning-fatal 豁免掩盖 RTL latch 或名称诊断。
- V9O focused 10/10、queue-head config 3/3、module 110/110、RTL variants 11/11、architecture hard gates 9/9、negative tests 30/30 已在相同 design-id 重放；十组语义门也全部通过。debt ledger 的 `F0-G1` 与 `CONTROL-EVENT-G1` 为 `CLOSED/current_design_bound=true`，`SERIALIZE-G1` 保持 OPEN。
- 功能聚合为 module 110/110、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000。current-design Linux profile 为 7 PASS / 1 FAIL：rootfs 在 1200 秒内进入 Linux 6.6 并到达 heap init，但未到达 virtio/VFS mount 或 systemd banner；这是有界未完成，不是 RTL assertion failure 或 rootfs PASS。
- arch-stable validator 140/140 PASS；完整核 candidate 仍是旧 `sha256:2eff...c8b2`，所以候选审计仍为 `GAP`、71 blockers、PPA `UNQUALIFIED`、promotion=false。该 cohort 差异不回退 V9R 局部结论，也不允许将其外推为 full-core freeze 或 PPA 晋级。

## RV64 unified control event current design V9O

### 稳定微架构合同

- `OooRob` 的 edge-old Q、commit permits、Q-only LQ terminal permit 和 exact pending CSR ProducerId 共同形成 full-event pregrant；`OooCoreTopGlue.control_event_request_valid_w` 只取该 full pregrant。trap commit 与 `TRAP` reason、queue-head CSR commit 与 `CSR_COMMIT` reason必须双向等价，不能在 C0 由 consequence pulse 重构 request。
- `OooControlEventApplySequencer` 是唯一 C0→C1 状态持有者。C0 full barrier 同拍阻止新的 dispatch、INT/FP issue、8 类 completion authorization、memory station/pre-owner launch；C1 再输出 typed apply。branch selective recovery 只在 authorized raw request 且没有 head full-event pregrant 时成立。
- ROB strict-younger 比较使用环形年龄而非 `>=`；pending CSR owner 同时匹配 full ProducerId 和 event type；LQ ordinary retirement 仍走普通 ready，只有 edge-old full-event pregrant 使用 Q-only terminal permit。已寄存的 AXI AR/AW/W owner 在 barrier 期间保持并 drain，未寄存的新 owner 不得建立。

### current-design 证据与边界

- RTL design-id `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`，146 RTL files；verification source-id `sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1`，133 verification files。
- focused 10/10、`OOO_CSR_QUEUE_HEAD=1` config 3/3、module 110/110、compile-success RTL variants 11/11、full-C0 completion classes 8/8、dual registered AR 2 lanes/4 hold cycles/2 terminals、architecture gates 9/9、negative tests 30/30 均 PASS。`make -C npc/rv64 check-contract` 为 471 assertions、13/13 tests。
- evidence index 164 artifacts，SHA-256 `d73a69cdfd92f42ed87e9e60a0c5389c343e4261ab6cf8b6fddc957245124da0`；mutation summary SHA-256 `28d594c312a893acc250814f356fef23b03cac1991f84d8b34caf93fbf4f319d`。共享 validator 绑定 exact provenance、11-name mutation mapping、live 110-module inventory、canonical architecture result/manifest/refresh path 与 current source identity。
- `CONTROL-EVENT-G1.semantic_evidence=PASS` 只对 current design 局部成立。完整核 candidate 仍是旧 `sha256:2eff...c8b2`，所以 `closed_binding=GAP`、full-core 59 blockers、PPA `UNQUALIFIED`、promotion=false；这不回退局部 RTL 结论，也不允许外推为完整 OoO/PPA 完成。

## RV64 STORE/AMO next-edge owner residency V9N

### 稳定微架构合同

- `OooStoreQueue` 的 plain STORE 在 physical request fire 后、exact SQ terminal 接受前，下一拍必须保留 `valid/owner_valid/request_sent/!terminal`、full ProducerId、owner token 与 MMU epoch；SQ release、ROB early-done、checkpoint recovery 或无 terminal 的 holder 清除都不能结束该期待。
- `OooIntBackend` 的 AMO singleton 在 write fire 后、exact final response 前，下一拍必须保留 `mem_pending_q/mem_amo_q/mem_amo_write_sent_q` 与完整 owner tuple。canonical `NpcCoreTop.u_ooo_core.flush_i=1'b0` 静态排除 leaf global-flush 清除路径；该事实不得外推到其它装配。
- checker 必须在每个时钟沿先比较上一拍 shadow，再捕获本拍 launch，从而跨过 NBA 更新观察 Q；既有 holder-qualified same-edge assertion 不能替代该 next-edge 不变量。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。focused STORE/AMO 2/2；`sq_clear_owner_valid_on_request_fire` 与 `amo_clear_kind_on_write_fire` 两份 compile-success RTL 源码变体均只由 V9N checker 精确拒绝，旧 V9L 同沿 assertion 保持 quiet；证据单测 8/8。
- result/raw SHA-256 分别为 `34090add201aece110bc3423fec7460e33cecb35ce2da1ac73ca788a7cb0d709` 与 `379d16ebbe790b80315943d2420581c9446c8690ffcd076ab1aba44b592e1746`。`arch_stable_freeze.py` 从 live RTL 重构两份变体并独立校验唯一失败 oracle、source/artifact/provenance hash 与 top binding。
- canonical 9 门 architecture aggregate 为 GREEN，arch-stable 135/135 单测通过；full-core 仍为 GAP/38 blockers，PPA UNQUALIFIED、promotion=false。该动态证据不等价于全状态空间形式化证明，也不产生面积、频率或功耗改善结论。

## RV64 ordinary FENCE current-design V9M

### 稳定合同

- 普通 `OPCODE_MISC_MEM + FUNCT3_FENCE` 进入 pending-system drain；其完成条件除 backend/SQ quiet 外必须包含 `mem_idle_i`。非 FENCE pending-system 事件不额外依赖该条件。
- `OooIntBackend.mem_idle_o` 覆盖双 MIQ、pending/buffer、双 retry holder、双 memory issue reservation、owner-live 与 terminal-pending count，经 DecodeBackend→CoreSlice→ExecuteBackend→CoreGlue→ControlPlane 原值传到 `OooPendingDrainResolveGate`。
- full-core testbench 在 pending ordinary FENCE 且 `core_mem_idle_w=0` 周期直接要求 `u_control_plane.mem_idle_i === core_mem_idle_w`；older store 必须先 probe/drain，FENCE 才退休，younger device read 只能在两者之后观察。

### 当前证据与边界

- canonical `make -C npc/rv64 check-fence-ordering`：focused 2/2、module aggregate 109/109、compile-success negative RTL variants 2/2、validator unittest 12/12，design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。
- 两份 negative RTL variant 分别常量化 drain gate 的 FENCE memory-idle 条件与 CoreGlue→ControlPlane `mem_idle` 连接；日志必须精确只有目标 `[CHECK-FAIL]`、`errors=1` 与 `status=1`，不能用前缀/子串或 JSON 自报字段替代。
- `FENCE-G1=CLOSED` 只对当前 design-id 与 result `792b8c2c9454d01eb5143019136d6b3add734019ff20cd66cd36efef961e2ec0` 成立。九门 architecture aggregate 为 GREEN，但 full-core freeze 仍为 GAP/38 blockers，PPA UNQUALIFIED。
- STORE/AMO outstanding owner 的同沿清除仍需独立 `next(entry resident || terminal accepted)` 生命周期守恒证据，不由 FENCE closure 外推。

## RV64 V9L memory ownership and current functional aggregate

### 稳定微架构合同

- `rob_head_launch_open_o` 只授权新的 AMO/SQ request launch，包含 flush/recovery quiet 条件；`rob_head_owner_open_o` 表示当前 exact ROB head 仍 valid 且 unfinished，供已经 launch 的事务在 recovery 期间保持 owner。两者不能互换，post-launch owner 检查必须使用后者并同时比较 ROB index 与 full ProducerId。
- `OooMemAxiBridge` 的 station allow 与 lookup 必须由同一 `rsp_ready_w` response credit 决定；没有 response credit 时不得发起 lookup。retry bank 与 station 可以保存不同 token，禁止项仅是同一 exact retry token 同时出现在 retry Q 与 active/station owner 中。
- 对应生产断言为 `[V9L-SQ-POST-LAUNCH-OWNER]`、`[V9L-SQ-LOOKAHEAD-CREDIT]` 与 `[V9L-RETRY-OWNER-DISJOINT]`；V9L 四个 current-source 编译成功 RTL 变体分别切断这些合同并全部被动态拒绝。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。canonical functional aggregate 为模块 `109/109`、official `177/177`、AM `59/59`、DiffTest mismatch `0`、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000，F0 evidence mutations `11/11`。
- `npc/sim/Makefile` 的递归 backend 调用显式传递 `NPC_HOME=$(BACKEND_DIR)`；外层 AM/NPC 环境中的 platform-root `NPC_HOME` 不再污染 rv64 backend 子 make。该修正属于构建入口绑定，不改变处理器 RTL。
- V8L holder evidence 在 assert/release 共 `8/8` 基线及 `9/9` 编译成功 RTL 变体上通过；汇总产物只替换 runner 自有随机临时目录，并经连续两轮 SHA 文件 `cmp` 验证确定性。producer-holder census 仍保留 `instance_graph_complete=false`、`semantic_complete=false` 和非 GREEN 状态，局部动态证据不提升整核 census。
- 九个 directed architecture gates 为当前 design-id 全 GREEN，arch-stable 审计 `134/134` 单测通过；完整冻结仍为 `GAP`、39 blockers，PPA `UNQUALIFIED`。长期 goal 继续 active。

## RV64 PTW PTE WRITE PMP current design V9K

### 稳定合同

- IFU 隐式 PTE A-bit write checker tuple 为 `(walk_pte_addr_q, 8B, PRIV_S, WRITE)`，LSU load-A/store-D checker tuple 为 `(walk_pte_addr_w, 8B, PRIV_S, WRITE)`；PTE READ grant 不能替代独立 PTE WRITE grant，只覆盖 PTE 前 4B 的 PMP entry 必须对 8B write fail closed。
- grant 后 IFU `AWADDR=walk_pte_addr_q`、`WDATA=ad_pte_q`；LSU `S_AD_UPDATE` 中 `AWADDR=walk_pte_addr_w`、`WDATA=ad_pte_q`。`AWVALID&&!AWREADY` 和 `WVALID&&!WREADY` 期间 payload 保持，AW/W 可以任意合法顺序各接受一次，同一 PTE owner 保持到 AW、W、B 均完成。
- deny 不进入 `S_AD_UPDATE`；IFU 形成 exact `resp0_bytes=F` 与 instruction access fault，LSU 形成原 load/store 的 access fault 而非 page fault。LSU response 反压期间 owner kind/token/MMU epoch/original VA `fault_tval` 和 fault class 保持，deny 到 response handshake 闭区间不得建立 PTE AW/W owner。
- PTW-PMP-G1 的 IFU 边界终止于 bridge successful-prefix/access-fault；lane owner、fault PC 与 `tval` 由 current-design `IFU-ACCESS-G1`/`IFU-TVAL-G1` 独立闭合。本地 PTE WRITE 接口无 `AWPROT` port，不虚构该字段。

### V9K 当前证据

- canonical command：`make -C npc/rv64 check-ptw-pmp`。
- focused 2/2、module aggregate 109/109、schema `npc-rv64-ptw-pmp-evidence-v4`、current-source compile-success RTL variants 28/28 动态拒绝、fail-closed 证据测试 13/13；production RTL SHA 前后一致。
- IFU allow 行阻塞 AW/W 两拍并以 AW-first 分离接受；LSU load-A 为 W-first、store-D 为 AW-first。每行直接检查 checker address-to-`AWADDR`、`AWSIZE=3`、`WDATA/WSTRB` 保持、accepted channel 不重发和 B-after-both。
- IFU deny 覆盖 F=0/2/4/6 与 8B partial-cover；LSU deny 覆盖 load-A readonly、store-D readonly、load-A partial8，在 response READY 延迟 0/1/2/3/5 下共 15 行、33 个 stalled-response 周期，逐拍检查 owner/fault/quiet tuple。
- 12 个 IFU 与 16 个 LSU 变体覆盖 checker WRITE/address/privilege/width、deny/grant polarity、fault class、deny-cycle AW/W、A/D `AWADDR`、split-handshake 后 pending channel 撤回、LSU response token 改接 live input，以及第三个 stalled-response 周期脉冲 AW、W 或 AW+W。
- 任意长 response stall 安全性由完整状态译码证书闭合：AW/W VALID 解码仅包含 `S_WRITE_REQ`/`S_AD_UPDATE`，deny 进入并自保持 `S_RESP` 直到 `rsp_ready_w` 或精确 drop terminal；将 `S_RESP` 加入 AWVALID 的证据变体会使证书 fail closed。response liveness 不从该 safety 证书外推。
- result SHA-256 为 `54d39545dea4a43310501499ad7a1e5d84c1af5e8244c859b0d868fb7774fc49`；raw log SHA-256 为 `1947a4c5f3ae713f28fcf0b19d29155955ee4f8cab5f086f0538877336611ea9`；V5 reviewer 合同 SHA-256 为 `7a01e924e4f5c8af71e425417404473506981bceac9afd245b8817a8da775cf9`，在同一 design_id 的限定范围内 PASS。

### 架构与协作边界

- `PTW-PMP-G1` 在 debt ledger 中为 `CLOSED` 且 `current_design_bound=true`；V9K-V4 字节证明来源重绑只改一份 LSU bridge TB 的 provenance，不改对应 directed record 的非来源语义。
- 共享 freeze validator 已纳入 IFU-TVAL 与 PTW-PMP 证据单测；所有相关 CLOSED result 经 canonical 本地 RTL 仿真重放，final 130 tests PASS。full-core audit 仍为 `GAP`、36 blockers，PPA `UNQUALIFIED`、promotion false。
- 长期 goal 继续 active；下一个直接架构项为 `F0-G1` current functional aggregate，继续使用 versioned RTL task contract 与 Windows→WSL single-flight。

## RV64 V11Q integer lane0 completion resolve paired packet（2026-07-31）

### OooIntBackend lane0 completion resolve paired packet V11Q 周期合同

- testbench 用 18 个 lane0 `DIVU x0,x0` retirement 推进独立 allocation
  schedule，expected ProducerId 固定为
  `P={generation=1,index=2}`；expected state 不从 EX0 或 resolve packet
  读取。
- capture 周期观察 `ex0_up_payload_w` 与
  `branch_resolve_up_payload_w`；下一周期分别观察
  `ex0_down_payload_w`、packed alias 和
  `branch_resolve_down_payload_w`。
- EX0 packet 必须保持 full ProducerId、result、physical destination 与
  completion authority；branch packet 必须保持 full ProducerId、
  PC/next-PC/control，并与 raw EX0 registered holder 作完整 ProducerId
  coherence。
- 相同 index、错误 generation 不得通过 resolve fence；same-cycle flush
  必须同时抑制 completion/resolve，next-cycle packet 必须为空。
- 本轮只关闭 `integer-ex0-packed-alias`、`integer-ex0-packet` 与
  `branch-resolve-packet`；lane1 两个单元保留为后续独立机制。

### TB / EDA evidence

- generation width 1/4 × assert/release 的 4/4 production baseline PASS；
  12 类 compile-success release RTL semantic variant × 2 width 的 24/24
  被 exact-stage oracle 拒绝；ordinary regression 3/3、runner unit 6/6
  PASS。
- attempt 1 `FAIL 18/28` 与 attempt 2 `FAIL 26/28` 原样保留；canonical
  attempt 3 `PASS 28/28`，summary SHA-256 为
  `c4ce58074c9602978f51940973a6b38737ba464bedc60af15f46f0084ea58d9f`。
- final combined semantic gate `PASS rc=0`，log SHA-256 为
  `189cd229294d346a4d7f2c6bbbb9d5a63659ae9e959dacc9f11294b292cb948d`；
  semantic/replay unit 80/80 PASS。
- current product graph/census 为 15 holder modules、17 holder instances、
  2 duplicate modules；current ledger 为 44 units、50 bindings、
  32 PASS / 12 GAP。

### Evidence chain 与边界

- production `OooIntBackend.v` SHA-256 为
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`，
  V11Q 无 production RTL 修改。
- A3 原始 `FAIL rc=1` 不改写；独立 checker replay 在冻结 console 上
  接受 `printk: debug:`、拒绝真实 `BUG:`，结论为“系统事务完成、旧
  oracle 误判”。该 dmesg replay 不与 V11H RTL checker replay 合并。
- 反例优先复核确认 expected PID 独立、EX0 raw/alias 分离、resolve
  full-PID coherence、wrong-generation fence、flush 与 next-cycle empty
  均有 compile-success 负向版本；bounded verdict 为
  `APPROVED_NOT_PROMOTION_ELIGIBLE`。
- whole architecture 仍为 `RED`，PPA 为 `UNPROMOTED`；未运行完整系统、
  综合、STA 或功耗，剩余 12 个 semantic GAP 不外推关闭。
- 同标题 bounded brief 为 `ok=true / recall_status=complete`；
  canonical `npc-dev` e2e run
  `2026-07-31-OooIntBackend-Lane0-completion-resolve-paired-packet-V11Q`
  completed 5/5，V11Q 12-path scoped strict guard PASS。
- full-worktree strict guard 的 NPC profile PASS；唯一缺口是 V11Q 范围外
  `nemu/src/isa/riscv64/inst/amo.c → nemu-dev`，不得把该 NEMU 缺口归入
  lane0 packet RTL 结论。

## RV64 V11S OooMulDivUnit producer lifecycle（2026-07-31）

### 周期合同与 RTL 边界

- product instance
  `NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_muldiv_unit`
  的 `OooMulDivUnit.producer_id_q` 必须从 request acceptance 经
  REQ_BUF、MUL/DIV iterative state、RESP、authorized writeback 与
  retirement 全程保持完整 `{generation, rob_idx}`。
- wrong-generation completion query/authorization/claim 必须全为零；
  正确 terminal 只产生一次完整 ProducerId 公共副作用。response
  consume、matching kill 或 flush 的 death edge 保留 edge-old lease，
  下一周期 holder/PID/live mask 清空。
- 本轮未修改 `OooIntBackend.v`、`OooMulDivUnit.v` 或 `define.v`；
  design-id 保持
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。

### TB / EDA evidence

- generated overlay 用 stimulus-owned
  `P={generation=1,index=2}` 驱动 MUL、DIVU，并分别叠加 V8N 八条
  younger dual-issue pressure；V11R base TB 与共享 testbench Makefile
  SHA 不变。
- canonical focused attempt-4 为 22/22 PASS：4/4 production baseline、
  9 类 compile-success mutation × 2 generation width 的 18/18、
  ordinary regression 4/4；runner unit 10/10。
- final graph unit 19/19、census unit 15/15、V11H replay unit 6/6、
  semantic-ledger unit 85/85；combined gate 为
  graph 19/19、census 15/15、replay＋semantic 91/91 PASS。
- focused summary SHA-256 为
  `2eb4984961fe34bdac751ae2dfb455de7c9256dd03bab4c31e25de0948a8e93b`；
  final ledger SHA-256 为
  `80d50ba80916a4823479748cfa69dc4ecea1a4025abf50ff3414caa0a7205944`。

### 证据工作流纠偏

- instance-graph 原合同把整个 `npc/rv64/Makefile` SHA 当作 product
  config，导致只更新 task-run evidence path 也被误判为 elaborated RTL
  漂移。
- 现只用 `product-rtl-defaults.mk` 绑定 production define；精确
  `print-synth-rtl` 源列表、graph tool、Yosys script、完整 JSON 与
  instance declaration 继续独立哈希。
- 正负单测证明 define/source-list 变化仍 fail closed，而不改变
  elaboration 的 Makefile evidence 注释不再制造假漂移。新旧 graph 的
  194 reachable instances、15 holder modules、17 holder instances、
  topology SHA、source-list SHA 与完整 Yosys JSON 完全一致。
- 冻结 V11O summary 的历史 graph-tool SHA 改为与其冻结 graph result
  `bindings.tool_sha256` 自洽；当前 graph tool 由 V11S graph bundle 与
  V11H replay 另行绑定，因此 checker 更新不要求重跑旧 V11O 动态矩阵。

### 结论与保留范围

- current semantic ledger 从 34 PASS / 10 GAP 变为 35 PASS / 9 GAP；
  只关闭 `muldiv-producer`。独立 reviewer blocker=0，bounded PASS。
- 保留覆盖洞：product path 未单独枚举 vacant/done-closed 全矩阵，
  代表 opcode 仅 MUL/DIVU，selective kill 细粒度主要由 leaf TB 覆盖；
  未运行 formal、完整系统、综合、STA 或功耗。
- A3 原始 `FAIL rc=1` 与 strict 16/17 不改写；冻结 dmesg/console
  checker replay 继续接受 `printk: debug:` 并拒绝真实 `BUG:`。本轮
  production/elaborated RTL、device model 与 simulator semantics 未变，
  不触发完整系统重跑。
- whole architecture 仍为 `RED`，PPA 为 `UNPROMOTED`。剩余 GAP 为
  CLMUL、pending-system 与七个 FP producer 单元。
- canonical task-run：
  `.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic/`。

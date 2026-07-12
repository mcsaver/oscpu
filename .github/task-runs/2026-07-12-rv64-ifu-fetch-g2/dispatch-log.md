# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-ifu-fetch-g2
- `graph_template`: contract-first bugfix + byte-range reference model
- `log_policy`: append-only

---

### [2026-07-12 22:24 +0800] `recall-map` - PASS

- `owner_agent`: root + prior ifu_axi_contract_review。
- `action`: DB brief 后沿 bridge→top→glue→frontend→decoder→head fault 追踪跨页 response。
- `outputs`: word response 丢失 byte-segment provenance；仅改 `<4` 或 resp0 会产生其它假绿。
- `handoff_to`: freeze-contract, red-matrix, abi-map, falsify。

### [2026-07-12 22:25 +0800] `freeze-contract` - PASS

- `owner_agent`: root。
- `action`: 冻结六类合同、B=2/4/6 长度矩阵与 page-fault provenance ABI。
- `outputs`: segment response + decoder 单一长度 owner；非跨页/cache/fusion/FSM 保持。
- `handoff_to`: red-matrix。

### [2026-07-12 22:29 +0800] `scope-falsification` - PASS

- `owner_agent`: fetch_g2_abi_map + fetch_g2_falsify + root。
- `action`: 反例审查 B/(8-B) PMP 草案、xbar/slave ARSIZE、RRESP footprint 与 lane1 access trap。
- `outputs`: 固定 segment size 仍会 overcheck；物理 8B overread 也不能靠 response mask 修复。
  G2 收窄为原始 page-fault provenance，PMP/RRESP/control capture 合并进后续 IFU-ACCESS-G1；
  variable-length fault portion `mtval` 另登记 IFU-TVAL-G1。
- `handoff_to`: implement-provenance；禁止越级写 access-fault CLOSED。

### [2026-07-12 22:35 +0800] `red-matrix` - PASS

- `owner_agent`: fetch_g2_red。
- `action`: 在修生产 RTL 前，用真实 Sv39 两页三级 walk 跑 FFA/FFC/FFE × C/32 12 行矩阵。
- `outputs`: compile rc=0、sim rc=1、精确 4 RED；8 个控制行通过，区分 bridge 粗判与 decoder
  固定 word response 两类根因。
- `handoff_to`: implement-provenance。

### [2026-07-12 22:43 +0800] `implement-provenance` - PASS

- `owner_agent`: root。
- `action`: 增加 bridge→top→glue→frontend→decoder 3-bit byte split；删除 bridge 长度猜测，
  decoder 单点按半开 byte range 映射 segment response；加入 9 条独立断言。
- `outputs`: focused page matrix 12/12，非跨页 ABI 保持 split=4，contract baseline 50→59。
- `handoff_to`: adversarial-review。

### [2026-07-12 22:49 +0800] `adversarial-review` - FAIL-THEN-PASS

- `owner_agent`: fetch_g2_falsify + root。
- `action`: 沿 decoder output 追踪到 HeadPairGate semihost peer，构造 prefix OK、32-bit tail fault
  且垃圾恰为 `32'h40705013` 的反例。
- `outputs`: 第一版暴露 faulted raw inst；实现改为完整 effective-range fault 净化 NOP，production
  poison regression 与 reviewer B2/B6 noninterference 均 PASS。
- `handoff_to`: regression。

### [2026-07-12 22:53 +0800] `assertion-nonvacuity` - PASS

- `owner_agent`: fetch_g2_falsify。
- `action`: production sources 不改写，只用 reviewer second-top 单拍 force 独立违约 9 个 marker。
- `outputs`: 9/9 每例 target=1、total ERROR=1、done=1；前后 SHA-256 一致。
- `handoff_to`: regression。

### [2026-07-12 22:56 +0800] `abi-final-review` - PASS

- `owner_agent`: fetch_g2_abi_map。
- `action`: 对最新 full-range sanitize 工作树复核 B2/B4/B6、fault priority、stall/flush、端口
  tie-off 与 ready/valid 组合边界，并独立跑 8 项。
- `outputs`: 8/8 PASS，NO G2 PAGE-FAULT BLOCKER；ACCESS/TVAL/200MHz 保持开放。
- `handoff_to`: full-regression + fresh-sta。

### [2026-07-12 22:59 +0800] `bounded-regression-start` - RUNNING

- `owner_agent`: root。
- `action`: current-source focused 5/5、module 89/89、contract 59/59、style/lint/clean build 已
  PASS；启动 AM+official 全套及同配置 5 ns target-driven 全核重映射。
- `outputs`: 等待原始 status/OpenSTA top40，不预填最终结论。
- `handoff_to`: record-review。

### [2026-07-12 23:00 +0800] `core-regression` - PASS

- `owner_agent`: root。
- `action`: 复用 fresh clean build，运行 AM cpu-tests 与 default+privileged official suites；
  module/lint/build 已有独立 current-source证据故在聚合脚本中跳过。
- `outputs`: overall_rc=0；AM checker 59/59；official 177/177，含 rv64mi/rv64si。
- `handoff_to`: fresh-sta。

### [2026-07-12 23:06 +0800] `performance-nonregression` - PASS

- `owner_agent`: root。
- `action`: 在 current Difftest-OFF performance config 运行 CoreMark 10 iterations。
- `outputs`: crcfinal=0xfcaf、GOOD TRAP、2,852,201 cycles/3,218,573 commits、CPI=0.886、
  CoreMark/MHz=3.561；与 slice 前 current baseline cycle-exact。
- `handoff_to`: fresh-sta。

### [2026-07-12 23:18 +0800] `fresh-5ns-remap` - PASS

- `owner_agent`: root。
- `action`: 对完整 current vsrc diff 执行 200MHz target-driven 四宏/七 keep-hierarchy full remap。
- `outputs`: rc=0；105/105 `&nf -D 5000.0`；三次 check=0；End of script；1407.67s、
  3637.86MB；netlist SHA-256=`37f83709...`。
- `handoff_to`: independent-opensta-review。

### [2026-07-12 23:22 +0800] `independent-opensta-review` - PASS

- `owner_agent`: g2_timing_review。
- `action`: 对 fresh netlist 只运行一次 OpenSTA，并审查 check_setup 与 top40 命名锥。
- `outputs`: rc=0；WNS/TNS=`-9.99/-121006.91ns`，诊断约 14.986ns/66.7MHz；top40=39
  D-cache→MIQ + 1 D-cache→branch/fetch→fetch-cache，G2 named cone=0。1851 unconstrained、109
  loops、ideal clock/placeholder macro，明确拒绝 200MHz/signoff 与无同源 A/B 的归因。
- `handoff_to`: record-review。

### [2026-07-12 23:27 +0800] `next-slice-boundary-recon` - PASS

- `owner_agent`: ifu_access_recon。
- `action`: 只读追踪 G2 之后的 physical access 与 downstream fault owner，寻找越级关闭反例。
- `outputs`: IFU-ACCESS-G1 冻结四个联动缺口：2B exact footprint/ARSIZE/RRESP、
  `pmp_active=0` 的 M-fill→S default-deny cache bypass、pred-NT branch 后 lane1 PF/AF owner、
  non-executable-device firewall；IFU-TVAL 继续独立。G2 bridge→decoder 结论不推翻。
- `handoff_to`: next IFU-ACCESS-G1 task-run。

### [2026-07-12 23:35 +0800] `record-review` - PASS

- `owner_agent`: root + reviewers。
- `action`: 更新 active design/spec 与 DB-backed memory，生成 evidence index；运行 npc-dev
  final-2、yosys-sta、agent-system profile，DB-first/coverage/doctor 与 strict guard。
- `outputs`: 三 profile rc=0；strict guard current hash PASS；reviewer 对 G2 `NO BLOCKER`，
  bookkeeping 与用户 dirty staging 边界已修正。parent goal/ACCESS/TVAL/PTW-PMP/physical 200MHz
  保持 OPEN。
- `handoff_to`: scoped commit，然后启动 IFU-ACCESS-G1。

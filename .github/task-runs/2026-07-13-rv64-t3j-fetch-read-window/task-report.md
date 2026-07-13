# T3J fetch-cache physical read window task report

- task_id: `2026-07-13-rv64-t3j-fetch-read-window`
- profile: `npc-dev`
- status: `completed`
- updated_at: `2026-07-13T17:43:22+08:00`
- baseline: `8532bad0794cb34199c8adf49b080e1773b1f16f`
- slice status: `RTL / function / cycle equivalence / directed timing GREEN`
- physical verdict: `fresh H7CL 5ns WNS=-8.840ns，未达 200MHz`
- parent goal: 完整功能且 current-source fresh 5ns WNS `>= 0`；仍 active，继续 T3K。

## Root cause 与架构切点

T3I 的全局 top1 是 integer EX 到取指 payload SRAM `en_i` 的
request/ready/fire 长组合锥，slack `-9.377ns`。旧接口把同一根
`fetch_req_fire_w` 同时用于：

1. 物理 SRAM 同步读使能；
2. 请求 context 锁存；
3. 次拍 semantic decision 资格。

T3J 将这三个职责拆成两个端口：

```text
physical read window = state==S_IDLE || state==S_RESP || state==S_LOOKUP
semantic accept      = fetch_req_fire_w
SRAM enable          = physical read window || actual fill write
decision/context     = semantic accept only
```

`S_LOOKUP` 必须在读窗内以支持 hit-fusion A→B；`S_RESP` 必须在读窗内以支持
消费旧响应同拍 accept B。最终成功 fill 只发生在 `S_R0`，该拍 read window=0、
write=1。读地址仍取 live request PC；dummy read 可以改变 raw SRAM rdata，但没有
decision 资格时不得形成 context hit、packet hit 或架构 payload。

## 实现与合同

- `OooFetchPacketCache` 新增 `lookup_read_en_i`；`lookup_en_i` 保持 semantic accept。
- `sram_en_w` 改为 `lookup_read_en_i || sram_we_w`；地址 write-priority/live-PC
  选择不变，`dec_en_q` 与五项 context 锁存仍只由 `lookup_en_i` 驱动。
- 新增 `[FPC-ACCEPT-REQUIRES-READ]`，并把 `[CONTRACT-FPC-1RW]` 改为审核真实
  physical read 与 `sram_we_w`；assertion ratchet `86 -> 87`。
- facts/checker 增加 `LOOKUP_READ` 与 `LOOKUP_ACCEPT`；packet-cache 与 bridge TB
  覆盖 dummy read、S_IDLE/S_LOOKUP/S_RESP 三态、不同 index fusion、S_RESP 同拍
  accept、最终 `S_R0` fill。
- dedicated fetch-cache/bridge/macro-boundary spec、刀 F supersession 注记、RTL README
  与 yosys-sta e2e 合同同步；macro checker新增 read/accept split 防漂移。

## 可执行证明、mutation 与 negative teeth

- `check-t3j-source-contract.py` fail-closed 解析真实 Verilog，冻结 exact 三态窗口、
  semantic fire、SRAM en/we/address mux、`dec_en_q` 与 context capture owner。
- `prove-t3j-window-domain.py` 从 RTL 提取 ready/fire/window/fill/we 前提，有限域
  `1024/1024` cases PASS：fire=>read、semantic==fire、read/write mutex。
- 9/9 mutation PASS：缺 S_LOOKUP、缺 S_RESP、window=fire、semantic/read 混用、
  把 S_R0 纳入读窗、SRAM-en AND、decision由read驱动、读地址改锁存PC、读写地址臂互换。
- 两个独立 dynamic negative probe 都由 hardened global TB runner 判失败：
  `[FPC-ACCEPT-REQUIRES-READ]` 与 `[CONTRACT-FPC-1RW]` 各精确一次，内层 TB
  即便打印 PASS，最终仍是 make rc=2 / `[RESULT] FAIL`。缺失、重复、串错 marker
  self-test 均 RED。
- current source/proof/mutation 最终输入前后哈希冻结在 `evidence/current-contract-final/`。

## 功能、回归与周期等价

- focused fetch-cache + bridge `2/2`；最终 module TB `96/96`。
- Verilator 5.051 lint、RTL style、`check-contract 87/87`、macro placeholder checker、
  `git diff --check` PASS。
- 完整 core regression 位于 `evidence/core-regress/20260713-164726-2511058/`：
  module、lint、build、AM cpu-tests、official+privileged `177/177` 全 PASS，
  `overall_rc=0`。
- CoreMark 10 iterations：GOOD TRAP、CRC `0xfcaf`、`3020147` cycles、
  `3218532` commits、CPI `0.938`、`3.379/MHz`；与 T3I cycle/commit/CRC 精确相同。
- 保护的 `build/linux-logs/npc-linux.log` 前后 SHA 仍为
  `3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`。

## Fresh synthesis 与 5ns OpenSTA

fresh synthesis 从 `16:54:16+08:00` 开始，现有 wrapper 前后冻结 110 个 synth RTL、
完整 133-file vsrc tree 与 5 个明确 flow inputs。hardened audit 结果：

- 110/110 modules；ABC `220 candidates / 10 empty / 210 result+done`；
- 三次 zero-problem check、Yosys error=0、DELAY-4 与 `5000.0ps` exact markers；
- fresh netlist SHA
  `e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a`；
- area `1574381.48`，runtime `1403.87s`，peak `3608.49MB`。

正式 `-final` OpenSTA 使用与 synthesis 相同的 H7CL typical 1.2V/25C 标准库、
四个 macro Liberty 和 5.000ns period。门禁结果：

- old T3I：semantic accept→payload SRAM en 路径存在；read-window port 精确不存在；
- fresh T3J：accept→en 路径消失，PC→address residual `12/12` 保留；
- fresh read window 的三个真实 startpoint 均闭环为
  `CK -> same-cell Q -> state_q_{0,6,8}`，且不含 request/valid/ready/fire/PC alias；
- check_setup 告警闭集精确为 input-delay `303`、output-delay `1861`、
  unconstrained endpoints `1863`，无第四类 Warning/Error；loops=0；
- global top40 全部转为 `pending_trap_exit`，fetch SRAM endpoint=0；
- WNS `-8.840ns`、TNS `-199477.67ns`、power proxy `0.117W`。

相对 T3I top1 `-9.377ns`，T3J 回收约 `0.537ns` 并使瓶颈按预期转移；但独立
`check-t3j-target-200mhz.py --expect miss` 精确记录 rc=1 expected RED，父目标未完成。

## 审查者发现并保留的失败证据

1. 开工 focused-smoke 的第一次命令因 shell 变量为空只生成路径错误，随后绝对路径
   2/2 PASS；该早期目录不是 canonical final。
2. packet-cache TB 两个手写窗口最初只拉 semantic accept，漏 physical read；合同审查
   立即指出并在最终回归前修复。
3. negative runner 首次用相对 OUT_DIR 受 `make -C` 改变解析基准而找不到日志；runner
   现先绝对化，真实相对目录复跑 PASS；`negative-probes-root-rerun` 标为 superseded。
4. 首次正式 focused upstream gate 错把 OpenSTA sequential startpoint 预期成 Q；真实 API
   返回 CK。首跑 fresh checker RED 被保留，修复后用独立 hardening-smoke 证明
   `CK->same-cell Q->state_q`，最后 `-final` 全量重跑 PASS。
5. 证据审查发现初版 netlist gate 只验端口名、global checker未闭合告警、archive易被误读
   成 target PASS；最终分别补 startpoint provenance、告警闭集和独立 target expected-RED。

## Provenance 限制与归档

当前 T3J synthesis wrapper 只对 5 个 flow inputs 做了 pre/post freeze；hardened audit
明确输出 `limited_freeze_inputs=5`，没有虚构未预哈希依赖。记录的 HEAD 也不是单独可
复现边界：综合网表包含共享工作树中受保护的 dirty `OooFrontend.v` 等输入。最终达到
200MHz 的切片必须扩展 pre/post manifest 至 Make/config/common Tcl/PDK Tcl/H7CL+四宏库、
Yosys/ABC/OpenSTA binary 和 exact parameter KV，并重新综合，不能只复用本刀网表。

- fresh synth/STA 共 60 个精确成员归档为
  `tmp/2026-07-13-rv64-t3j-fetch-read-window/fresh-sta-archive/`
  `NpcTop-200MHz-t3j-fetch-read-window.tar.zst`，27,729,635 bytes，SHA256
  `38dcb67f...e36`；zstd/tar/inventory/SHA 全 PASS。
- OS `/tmp` 中本轮唯一持久相关对象 `/tmp/ysyx-t3j-user-npc-linux.log` 已复制到
  workspace `tmp/.../tmp-archive/t3j-related-tmp.tar.zst`；1 entry、4132 logical bytes、
  archive 1650 bytes，SHA256 `36dc39cc...5da`。pre/post/unpacked inventory 一致，
  源未删除。Yosys/ABC 的匿名临时目录在工具完成时自行清理，未按时间/PID误收其他任务。

## 审查者裁决与下一刀

实现者证据证明 T3J 功能、周期、source theorem、综合网表结构和 directed timing 切点
闭合；审查者反例覆盖地址错位、window=fire 时序回退、OpenSTA startpoint API、额外告警、
target/archive混淆与有限 provenance。唯一未闭合的是父目标：WNS 仍为 `-8.840ns`。

新 top40 的 40 条路径均为 EX0→same-cycle WB/ROB commit→共享 CSR legality→lane1
pending-trap payload。T3K 的推荐零预期 CPI 切点是把 commit side-effect CSR access 与
无副作用 head legality probe 分成两个物理 view，复用同一 legality predicate，禁止
commit/pending selector 进入 probe cone；不得用 false path 或错拍 legality。T3K 必须独立
冻结合同、RED/等价证明、功能回归与 fresh 5ns STA。

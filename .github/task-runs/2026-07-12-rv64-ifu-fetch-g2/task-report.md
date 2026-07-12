# RV64 IFU-FETCH-G2：跨页字节段 fault provenance

## 基本信息

- `task_id`: 2026-07-12-rv64-ifu-fetch-g2
- `task_slug`: rv64-ifu-fetch-g2
- `graph_template`: contract-first bugfix + byte-range reference model
- `graph_mode`: static+dynamic
- `profile`: npc-dev
- `status`: completed (scoped G2; parent goal remains active)
- `owner`: root + fetch_g2_red + fetch_g2_abi_map + fetch_g2_falsify + g2_timing_review
- `started_at`: 2026-07-12 22:24:00 +0800
- `updated_at`: 2026-07-12 23:35:00 +0800

## 目标与范围

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `slice_goal`: 关闭 IFU-FETCH-G2：跨 4KiB 页的 8B fetch packet 必须先保留“第一页字节段 /
  第二页字节段”的 response provenance，再由唯一 RVC 长度 owner 映射到 slot0/slot1；下一页
  fault 不得提前污染完全位于第一页的指令，也不得被无效 tail halfword 吞掉。
- `scope`: bridge response ABI、NpcCoreTop/OooCoreTopGlue/OooFrontend 结构透传、
  OooFetchPacketDecode、Sv39 second-page page-fault slot mapping、focused/module tests、active specs 与证据。
- `explicit boundary`: 本刀按原始 G2 定义只关闭 **page-fault provenance**。当前 xbar→slave
  不透传 ARSIZE，bridge 的 exact-address 8B read 会物理过读；PMP 又固定按 4B word 检查，
  PairGate 还会在 head0 branch 后压掉 lane1 page/access fault，ROB-walk control 对 access fault
  另有 cause-based filter。因此 PMP/RRESP/side-effect 与下游 lane1 fetch-fault capture 的端到端
  精确性登记为紧接本刀的 `IFU-ACCESS-G1`（含 `IFU-LANE1-OWNER` 子节点），不得被 response
  remap 越级关闭。
- variable-length instruction fault 的 `mtval` 若非零还应指向 faulting instruction portion；
  当前 control path 统一使用 slot 起始 PC。本刀不改变 trap payload，登记 `IFU-TVAL-G1`，
  只声明 slot response/page-fault owner，不能声明跨页 fault-address 语义完整。
- `dirty boundary`: 用户已有 `OooFrontend.v` comment hunk、`OooAdUpdateChecker.sv`、
  `NpcSimTop.sv`、运行日志与 `.superpowers/` 均保留；若必须改 `OooFrontend.v`，仅修改不重叠
  端口/decoder 连接，最终分 hunk staging 排除用户 comment。

## Root cause

- bridge 保存了 `packet_cross_page_q/packet_first_bytes_q`，但输出只有两个 32-bit word response。
- 第二页 page/PMP/RRESP fault 先写 `resp1_q`，随后 bridge 以 `first_bytes<4` 猜 slot0 是否跨页；
  该判据不知道 inst0 是 16b 还是 32b，也无法表达 slot1 在 B=2/4/6 下的真实 byte range。
- 真正的指令长度 owner 在 `OooFetchPacketDecode`。边界 provenance 未到达 decoder，导致：
  `FFE+C` 提前 fault、`FFA+C+32/32+C` 错 fault、只删 resp0 覆写又会让无效 tail 看似 C 时
  生成幽灵 slot1。
- fixed-word PMP、8B 物理过读与 branch 后 lane1 page/access-fault capture 是同一邻域的后续
  缺口，但不是本刀 bridge→decoder page-fault RED 的 root cause；简单改成 B/(8-B) 会因
  未先知道 L0/L1 而继续过查。

## 接口合同冻结

### ① 握手

- provenance 与现有 `fetch_rsp_valid/ready` 同 owner、同 stall 生命周期；valid=1 且 ready=0 时
  `cross_page/first_bytes/inst/segment_resp` 全部稳定。
- 非跨页 response ABI 保持现有 per-word mapping；跨页时 `resp0/resp1` 明确定义为
  first-segment / second-segment response，decoder 负责一次性归一为 per-slot response。

### ② 反压 / stall

- 不增加 ready→valid 组合依赖；桥状态与 payload 仍由既有 S_LOOKUP/S_RESP skid 持有。
- fault prefix 不可读时，decoder 必须让 fault 胜过长度，不得读取无效 halfword 决定 slot1 长度。

### ③ flush/reset/同拍优先级

- reset/mmu_flush/read-drain 与刚关闭的 IFU-AXI-G1 语义不变；本刀不新增 bridge FSM owner。
- provenance 随请求 fire 锁存，随该 response 交付；flush 丢弃旧 response 时一起丢弃，不可串包。

### ④ 异常序

- slot0 response 只由 `[0,L0)` 覆盖的 segment 决定；slot1 response 只由
  `[L0,L0+L1)` 覆盖的 segment 决定。segment1 fault 对完全落在 B 之前的指令不可见。
- slot prefix 本身位于 fault segment 时，无需读取其长度即可把该 slot 标 fault。
- 第一 segment fault 仍使 slot0 fault；slot0 fault 后 slot1 无架构 owner，不得产生额外 side effect。

### ⑤ 访存 / page-walk 序

- 真实 Sv39 walk 对第二页 invalid/noncanonical/permission fault 只标 second segment；第一页
  已成功翻译/读取的字节保持 first segment OK。decoder 再按 slot byte range 归属 page fault。
- 本刀不得改变 page-walk 次序、A-update、read-drain 或跨页包“不缓存”规则。
- PMP 精确范围不能固定成 B/(8-B)：真正需要量由 L0+L1 决定，且 prefix 位于 fault segment 时
  长度不可先读；连同 ARSIZE/物理 footprint 与 branch 后 lane1 page/access-fault capture 移交
  IFU-ACCESS-G1/IFU-LANE1-OWNER。

### ⑥ 投机恢复 / 单一真源

- RVC 长度只在 `OooFetchPacketDecode` 解释；bridge 不复制 compressed decode。
- bridge 只输出已经锁存的 segment provenance；decoder 后只剩 per-slot response，provenance
  不进入 packet FIFO/cache。跨页包仍禁止 cache fill，非跨页 hit-fusion ABI 周期不变。

## RED 矩阵（第一批必须全部有牙）

| B / PC | bytes | second segment fault 的正确结果 |
| --- | --- | --- |
| 2 / FFE | C + unknown tail | slot0 OK；slot1 fault，tail 伪装 C 也不能吞 fault |
| 2 / FFE | 32 + unknown tail | slot0 fault；slot1 无架构意义 |
| 4 / FFC | C+C | 两槽 OK |
| 4 / FFC | C+32 | slot0 OK；slot1 fault |
| 4 / FFC | 32+* | slot0 OK；slot1 fault |
| 6 / FFA | C+C / C+32 / 32+C | 两槽 OK |
| 6 / FFA | 32+32 | slot0 OK；slot1 fault |

全部第一批 PAGE_FAULT 行优先走真实三级 Sv39 walk；deposit 只可作局部补充。PMP/RRESP 矩阵
不是本刀关闭证据，归 IFU-ACCESS-G1。old RTL 必须精确 RED，不能先改生产 RTL。

## 实现

- bridge 新增 3-bit `fetch_rsp_resp0_bytes_o`。非跨页/cache response 恒为 4；跨页 response
  为当前 transaction 锁存的 `packet_first_bytes_q`。该 ABI 经 NpcCoreTop→OooCoreTopGlue→
  OooFrontend 原宽透传，三个 direct Glue TB 显式 tie `3'd4`。
- bridge 删除 `first_inst_cross_page_w`，不再解释 raw prefix。S_R0/S_R1/second-page walk fault
  只维护 first/second segment response；slot owner 全部交给 decoder。
- decoder 增加独立半开区间 reference function：先在 prefix 所需 segment 全 OK 后读取长度，
  再以真实 L0/L1 映射完整 byte range；slot0 fault 向 slot1 传播，防止无 owner 副作用。
- 独立审查发现第一版只在 prefix fault 时净化 inst，导致“prefix OK、32-bit tail fault”仍可把
  垃圾送入 semihost peer 比较。当前按完整 effective range response 将 dec0/dec1 faulted inst
  统一净化为 `32'h0000_0013`；production TB 用 fault tail 精确拼成 `32'h40705013` 锁住反例。
- 新增 9 条立即断言：bridge stall/split/noncross 3 条，Frontend 独立 B2/B6 矩阵 6 条；
  contract ratchet 从 50 提升为 59。

## 验证进度

- old RTL permanent RED：12 行真实 Sv39 两页三级 walk，compile rc=0、simulation rc=1，
  精确 4 个错误；8 个必要对照行通过。
- current-source focused：decoder + real page-end + Glue/priv/fetch-trap 5/5 PASS。
- module testbench：89/89 PASS；新增 `tb_ooo_fetch_page_end_fault` 已注册为常驻项。
- structural gates：`check-contract` 59/59、`check-rtl-style`、Verilator 5.051 lint、clean NPC
  build 全部 rc=0。
- assertion non-vacuity：9/9，每例目标 marker=1、总 ERROR=1、done=1；production source
  前后 SHA-256 完全一致。reviewer-positive 覆盖 B2 tail poison、B6 CU/UC/UU 与 bridge
  response stall，全部 PASS 且 0 production assertion error。
- independent ABI reviewer：基于最新 full-range sanitize 工作树复跑 decoder/page-end/bridge/
  xbar/Glue/trap/priv/Sv39 boot 8/8 PASS，裁决 NO G2 PAGE-FAULT BLOCKER。
- core-regress（跳过已独立执行的 module/lint/build）overall rc=0：AM result checker 59/59，
  official rv64ui/um/ua/uc/uf/ud/Zba/Zbb/Zbc/Zbs/mi/si 共 177/177。
- CoreMark `ITERATIONS=10`：crcfinal=`0xfcaf`、GOOD TRAP、cycles=2,852,201、
  commits=3,218,573、CPI=0.886、CoreMark/MHz=3.561，与本切片前 current baseline cycle-exact。
- fresh 5 ns target-driven remap rc=0：105/105 个最终 ABC cone 均执行 `&nf -D 5000.0`，
  final check=0、Yosys `End of script`，1407.67s / 3637.86MB；网表 68,143,270 bytes，
  SHA-256=`37f83709...`。同一网表 OpenSTA rc=0，WNS=`-9.99ns`、TNS=`-121006.91ns`；
  check_setup 仍有 303 input/1849 output delay 缺口、1851 unconstrained endpoints、109 loops。
- workflow：fresh `npc-dev`（final-2）、`yosys-sta`、`agent-system` profile 均 rc=0；DB-first/
  markdown-coverage/doctor 全绿，最终 strict guard 对 current changed-path hash PASS。

## 与 200 MHz 的关系

- 本刀是 P0 correctness 前置，不直接声明 Fmax 收益。
- provenance 只来自 bridge 寄存态，跨页比较限定 2/4/6B；不把 translation/PMP 动态锥重新
  串入 hit-fusion request path。
- fresh 5ns top40 为 39 条 D-cache SRAM→MIQ 与 1 条 D-cache SRAM→branch recovery/fetch
  control→fetch-cache SRAM enable；没有 `resp0_bytes`/packet-decode 命名锥。不同历史报告的 RTL/
  BPU placeholder ABI 不同，因此 fresh 数字作为 current standalone 真源，不机械归因于 G2。
- 该 ideal-clock/placeholder-macro 临界周期约 14.99ns（诊断约 66.7MHz），仍不是 5ns，更不是
  post-route 200MHz；mandatory registered boundary 与真实宏/物理签核仍不可跳过。

## 审查者人格裁决

- narrowed second-page page-fault provenance 当前无剩余 RTL blocker；第一版 fault-tail
  sanitize 漏洞已由 reviewer 反例修复并进入永久 production regression。
- 不接受“page/PMP/AXI fault 全矩阵已闭合”的旧口径。ARSIZE 丢失、exact-address 8B overread、
  固定 4B word PMP、PairGate 对 branch 后 lane1 fetch fault 的无条件抑制与 ROB-walk
  instruction-access cause filter 均为 IFU-ACCESS-G1/IFU-LANE1-OWNER blocker。G2 只关闭
  bridge→decoder response owner，不证明下游 page-fault trap capture 完整。
- cache hit 的 `pmp_active ? grant : allow` 还会在 M-mode 填充后切 S-mode、`pmpcfg=0` 时绕过
  S/U 默认拒绝；IFU-ACCESS-G1 必须用 M-fill→S/no-PMP RED 锁住，不能把 fixed-word checker
  的 conservative fast-hit 判定直接当 architecture fault owner。
- variable-length faulting portion 的 trap value 仍为 IFU-TVAL-G1；G2 response owner 不能证明
  `mtval/stval` 地址完整。
- 3-bit split 小比较/加法位于 decoder 锥，但 fresh 5ns top40 未出现其命名锥；这只证明本轮
  top40 排序未由 G2 主导，不等于零面积/零时序代价。

## 当前裁决

- `status`: IFU-FETCH-G2 bridge→decoder page-fault provenance scoped COMPLETE；功能、性能、时序、
  memory/profile/strict-guard 与独立审查证据均已闭合，可提交本切片。
- `parent_goal`: active；即使 G2 收窄关闭，IFU-ACCESS-G1、IFU-TVAL-G1、PTW-PMP-G1 与
  pre-layout/physical 200 MHz 均未完成。

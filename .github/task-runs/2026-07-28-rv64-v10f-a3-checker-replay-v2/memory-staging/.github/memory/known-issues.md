# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

## 活跃问题
<!-- 当前未解决的问题 -->

### [124] A3 `dmesg-no-critical` 把 `printk: debug:` 误判为 `BUG:`（2026-07-28）

- **症状**：A3 已完成 5,071,521,696 cycles / 1,223,536,213 commits 和
  六类 natural-poweroff/system-reset terminal 事务，RTL assertion 为空且
  binding 无漂移，但 strict 仅 16/17、rc=1，唯一 FAIL 是
  `dmesg-no-critical`。
- **根因**：A3 rootfs 内实际 checker 使用未限定的 `BUG:` alternative；
  case-insensitive grep 会匹配 `printk: debug:` 的后缀。提取脚本哈希
  `83b6a538…053f9a` 与 A3 `strict_checker_sha256` 相等，排除了历史脚本
  身份不确定性。
- **修复/门禁**：production regex 把该 token 限定为
  `(^|[^[:alnum:]_])BUG:`；同一冻结 console 的 legacy/current replay 为
  2/0 matches，且 3/3 单测证明 benign debug 接受、真实 `BUG:` 拒绝。
  A3 原始 FAIL 不改写，另建 V2 PASS 证据并由独立 reviewer 给出
  `APPROVED_NOT_PROMOTION_ELIGIBLE`。
- **重跑规则**：只有 core RTL 语义、实际 elaborated RTL、
  device/simulator 执行语义变化或 A3 冻结输入/终端/post-hash 缺失才完整
  重跑。本轮均未触发；A4 中断不是 PASS。
- **guard 路由**：systemd checker/transaction evidence 的七个精确路径只映射
  `rv64-systemd-contract`，其它 `Linux/` 路径继续映射 `rv64-linux`；
  agent-system 自检保留 `check-ubuntu-rootfs.sh → rv64-linux` 反例。
  checker 实际 changed paths 的 scoped strict guard 已 PASS，不能用该路由
  豁免 production RTL、rootfs、device model 或 simulator 语义变化。
- **收尾证据**：systemd-contract task-run completed，agent-system 11/11
  PASS，八路径 scoped strict guard PASS。全 dirty worktree guard 对既有
  `rv64-linux`、`npc-dev` 路径仍 FAIL；这是显式 mixed-origin 范围豁免，
  不是 checker 修复或其它脏路径的假绿。
- **剩余工具债务**：future comparator 应对 A3/A4 generated filename set
  做双向相等检查；该项为低风险工具强化，不表示 A3 checker 分类仍开放。

### [123] NEMU reference smoke 把 TARGET_AM 当作可执行 reference 会递归构建（2026-07-22）

- **症状**：native NEMU 配置被旧 `nemu-add-smoke` 误判为不兼容并 SKIP；切到 `riscv64-am_defconfig` 后先出现 SoftFloat/unused helper/AM libc link 边界，越过编译后产生 `make[1] ... make[2231]` 递归链，直到节点预算耗尽。
- **根因**：`ARCH=riscv*-nemu` 的 cpu-tests run 需要宿主 NEMU executable；`CONFIG_TARGET_AM=y` 却把 NEMU 本体构建为 AM program，随后 `abstract-machine/scripts/platform/nemu.mk` 为运行该镜像再次进入同一 NEMU `run`，因而递归。旧 helper 名称和判定把 AM program target 错当成 AM guest reference compatibility。
- **修复/门禁**：reference selector 只接受 `CONFIG_TARGET_NATIVE_ELF=y` 且 `CONFIG_ISA` 为 `riscv32`/`riscv64`；新增 `nemu-reference-config-contract` 自动接受 native RISC-V、拒绝 AM/SHARE/native 非 RISC-V/native 缺失 ISA/missing，并证明旧强制变量不能绕过。`nemu.tsv` 与 `quick.tsv` 统一绑定 native RISC-V smoke；错误 AM 路径上的临时 NEMU 源码兼容改动全部撤回。
- **当前状态**：native RV64 `add` reference smoke `1/1 PASS`、`HIT GOOD TRAP`、844 instructions；最终 `difftest` run `2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2` completed，配置前后哈希一致。历史 blocked runs 仅保留为反例，不得作为完成证据。

### [122] V8L 汇总直接绑定随机临时编译路径会造成重复运行哈希漂移（2026-07-22）

- **症状**：`check-global-producer-no-live-reuse` 连续两次 `8/8` baseline、`9/9` compile-success RTL variant 均通过，但 holder lifecycle 汇总 SHA-256 不同；mutation 结构化摘要本身稳定。
- **根因**：baseline 与 mutation 的编译命令记录 runner 创建的 `/tmp/v8l-global-lease.<random>` build root。直接把原始日志 SHA 写入冻结汇总，会把非语义随机目录当成设计证据的一部分；第二轮从零运行因此使 manifest 中的 artifact hash 过期。
- **稳定门禁**：先完整检查原始日志的 PASS/FAIL marker、变体编译产物和独立失败后果，再仅把 runner 自有 `/tmp/v8l-global-lease.[A-Za-z0-9]+` 规范化为 `<V8L_TEMP>` 后生成被哈希绑定的日志。不得删除 assertion、RTL 路径、周期值、错误文本或其它未知字段；规范化后的 lifecycle/mutation 产物必须再做至少两次 canonical run 的字节级 `cmp`。
- **当前状态**：V8L 两次从零重放产物完全一致，lifecycle/mutation SHA-256 分别为 `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97`、`494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`；arch-stable 的 `census.dynamic_lifecycle_evidence` 为 PASS。本条是所有含 runner-owned 随机路径的 RTL 证据聚合通用风险，不表示仿真语义不确定。

### [121] Compile-success mutation 的激活标记不能单独证明 RTL 字节发生变化（2026-07-21）

- **症状**：v8v 的 F2 parent mutation summary 已记录 18 项 compile-success/dynamic rejection，但 reviewer 对 `duplicate_bridge_drop_token` 提出 byte-identical no-op 怀疑；直接比较证明该具体 mutation 确实把第二个 `mem1_drop0_owner_token_i` 改成 `mem_drop0_owner_token_i`，然而原证据链没有机械证明全部 18 项都不是空替换。
- **根因**：宏激活、编译成功和动态 oracle 拒绝分别证明 runner 路径、语法/例化与行为后果，却不自动证明 live source 中存在唯一旧 anchor、替换前后字节不同、以及 summary 中的同名 SHA 确实由当前源码重建。单个 mutation 的人工抽查也不能外推到整个 identity set。
- **稳定门禁**：对每个 source mutation 从 live RTL 重建，要求 mutation 名集合精确相等、旧 anchor 唯一、old/new 与 source/mutant 均 byte-nonidentical，并逐名复算 SHA-256 与 summary 匹配；缺失 anchor、多 anchor、空替换、名称漂移或摘要 SHA 不一致均 fail closed。compile-success、elaboration/activation、独立动态后果和唯一目标拒绝仍必须另行保留，重建门不能替代它们。
- **当前状态**：`memory_ordering_evidence.py` 已覆盖全部 18 项 F2 parent mutation，并新增真实 owner-token cut、byte-identical、missing-anchor、ambiguous-anchor 四个正反单测；fresh OOO-3 run 报告 `f2_reconstructed_non_noop_mutations=18`，v6 frozen-material reviewer 只对 nonidentity/identity/SHA reconstruction 限域 PASS。本条保留为所有本地 RTL source-mutation 证据的通用假绿风险，不表示当前 OOO-3 scope 仍有该缺口。

### [120] 连接类 mutation 在自端与对端 payload 同值时会变成不可观测假绿（2026-07-20）

- **症状**：v8r 的 `swap_peer_addr` mutation 已成功编译、例化并激活，但最初仍通过 wrapper TB；runner/变异器本身没有漏执行。
- **根因**：消费 lane 当前 load 地址与生产 lane peer-maintenance 地址恰好相同；错误地把 peer 地址接成 self 地址后，DUT 观察值不变。只证明“mutation 宏被激活”和“测试经过维护路径”不足以证明被改连接具有可观测性。
- **稳定门禁**：连接/仲裁类 mutation 必须为 source A、source B 注入互异且语义允许的 payload/control，并先证明交换前后的预期观测不同；对于当前不应生效的 self payload，可只在 mutation 专用 probe 中设置互异哨兵，不能改变 baseline 功能场景。每个 mutation 仍需 compile-success、elaborated、activated、唯一目标拒绝和无其它 assertion 抢先失败。
- **当前状态**：v8r wrapper TB 已把该场景改成非对称 wiring counterexample，10/10 mutation fresh PASS；本条保留为所有多 lane/多源 RTL 连接变异的通用风险，不表示当前 wrapper 仍有已知功能故障。

### [119] Verilog variable `force/release` 可保留旧值，跨探针复用同一 P 会制造 holder-census 假绿（2026-07-20）

- **症状**：v8l transient holder TB 先后 force mem-res/EX0/EX1/branch，最初四段复用同一个 full ProducerId；删掉 EX1 union 项的 compile-success mutation 仍通过，而删 EX0 能被真实 IQ→EX0 路径捕获。
- **根因**：对过程变量/reg 执行 `release` 后，不保证立即恢复 reset 前驱动值；Icarus 会保留 force 值，直到下一次过程赋值。因而前一 holder 的 valid/P 仍可能在完整 mask 中替后一 holder 遮蔽，单独检查“本域 onehot”和“完整 mask 同一 bit”为 common-mode 假绿。
- **稳定门禁**：每个 forced holder 使用互异 full-P；release 后必须跨真实 reset/赋值边界，并先断言该 P 在 complete mask 中清零，再进入下一探针。还必须为每个 union 项提供“删除该项、仍可成功编译、由独立后果失败”的 mutation；不能用 assertion marker 数量或 production mask 自扫描单独授予 GREEN。
- **当前状态**：v8l 已按上述规则修复，删 mem-res/EX0/EX1/branch 四项 mutation 均被捕获；此条保留为所有 Icarus procedural-force RTL TB 的通用已知风险，不表示 simulator 或架构整体有故障。

### [118] 200MHz proxy 已闭合，physical signoff 与默认 Dhrystone 长跑仍开放（2026-07-14）

- **已闭合范围**：T3J–T4I 已消除 #114–#116 所指的当前架构组合长链与 LSU 私有 lane/B-owner 缺口；fresh source→Yosys netlist→OpenSTA binding 全绿，exact 5ns top40 40/40 MET，actual worst `+0.017907454ns`。功能为 module 100/100、official/privileged 177/177、AM59/59、CoreMark、Dhrystone-10000 与 sized DPI。
- **仍开放边界**：303 inputs 无 input delay、1873 outputs 无 output delay、1875 unconstrained endpoints；ideal clock、无 SPEF/CTS/OCV/uncertainty，四类 macro 使用非签核 placeholder liberty。17.907ps 仅占5ns的0.36%，只能称 current frozen RTL gate-level proxy 200MHz，不能称 physical/tapeout/board signoff。
- **长跑边界**：Dhrystone 默认500000-run 在20分钟预算内 timeout；harness 已改为 timeout/非零返回/缺 GOOD TRAP 任一即 FAIL。当前只有10000-run 功能 smoke 可声明 PASS，需要性能数字时单独给足预算。
- **工作树保护事故**：whole-system eval 覆盖了开工前已有 dirty `build/linux-logs/npc-linux.log`；原始 SHA256 为 `4b0a3561…f23a7`，在 workspace、OS `/tmp` 与 Codex 缓存均未找到可恢复字节。该文件必须保持 unstaged，并在交付中披露，不能用 HEAD 或新日志伪装恢复。

### [116] T3I 后 200MHz 仍未闭合：EX→FPC physical read enable 与 pending-trap 长链（2026-07-13）

- **已关闭切片**：ROB-empty严格蕴含零retire，drain gate/control-plane/glue中的retire-count ABI和条件已物理删除；assertion、顶层纯AND theorem ratchet、删除guard/OR-bypass mutation、96/96 module、177/177与cycle-exact CoreMark共同闭合功能。旧canonical-retire fanout命中fetch/trap=1/137，fresh为0/0且仍有66个合法instret/debug endpoints，ROB residual path继续存在，故不是空collection假绿。
- **仍开放根因**：fresh correct-H7CL 5ns WNS/TNS=`-9.38/-199464.16ns`；top40只剩1条integer EX→fetch payload SRAM `en_i`（明细`-9.377ns`）和39条EX→pending-trap D（`-8.843ns`）。T3I只回收约0.72ns，parent 200MHz明确未完成。
- **下一切点**：FPC把物理SRAM读窗口与语义accept分开；`S_IDLE|S_RESP|S_LOOKUP`三态window驱动`en_i`，现有fetch request fire继续独占decision enable/context capture，fill与window必须互斥。不能只含IDLE/RESP（会破坏fused A→B），不能改address source，也不能把dummy-read raw rdata变化当架构payload。预计先切掉`en_i`长链，地址链仍可能约`-8.17ns`，必须fresh STA后再裁决。
- **工具假绿门禁**：H7L网表若误配H7CR liberty会出现204类`Warning 198 ... Creating black box`并把真实路径报成NO_PATH；所有focused/global checker必须拒绝unknown-module blackbox。层级input/output pin不是可靠`report_checks -from/-to`对象，定向路径应用`-through`并绑定exact collection，absence还需canonical fanout endpoint交集与非空残余证明。TB runner必须拒绝`ERROR:`/`%Error`后exact PASS；文本定理必须有OR-bypass mutation，不能只搜索guard字符串。
- **2026-07-14 收口**：T3J–T4I 后上述 architecture timing family 在 current frozen RTL 的 exact-5ns gate-level proxy 中已由 fresh netlist 40/40 MET 关闭；physical signoff 限制转记 #118。

### [115] T3H 后 physical 200MHz 仍未闭合：整数 EX fast consumer 跨 IQ/PRF/双 ALU/ROB/redirect（2026-07-13）

- **已关闭切片**：T3H 已将 FP execution/load wake 到 FpIQ、IntIQ FP-store 与 FpPRF R0–R3 的同拍 ready/data 消费切为 sticky/stored-only；95/95 module、整核+177/177、CoreMark、fresh synthesis 与 fail-closed directed STA 全绿。旧 T3G directed preflight RED，fresh 20 个 forbidden path 全为 NO_TIMING_PATH；DCache 到三类 execute stage 只剩 `+1.468/+1.373/+0.155ns` 的合法短控制弧。
- **仍开放根因**：fresh 5ns WNS/TNS=`-10.10/-201564.20ns`。top40 40/40 从 `ex0_valid_q` 起并共同经过 integer `fast_wb0`→IntIQ `select_wakeup0`→IntPRF bypass0→ALU0→cross-lane/ALU1→MulDiv→ROB→drain/trap，随后到 FPC payload en（1）、fetch outstanding（21）或 CSR（18）。ROB 末累计约 11.860ns，违例不只是 SRAM 1.842ns setup 假象。
- **下一切点**：成对移除 IntIQ resident EX same-cycle lookahead 与 IntPRF read0–3 EX bypass，让 EX completion 在 N 沿 formal write/sticky，dependent consumer N+1 issue；保留 formal WB/ROB/exception owner。必须用双发 RAW、branch/redirect、kill/flush/recover、WB0/WB1 collision、x0、backpressure 的 RED/GREEN/negative 与 fresh STA 证明。禁止仅给 FPC `en_i` 打拍（会错位请求上下文且不解决 CSR/fetch-outstanding 链），禁止 false path。
- **非 signoff 边界**：当前仍是 ideal clock、四 placeholder macro、无 SPEF/CTS/OCV，且有 303 input/1861 output delay缺失、1863 unconstrained endpoints；即使后续 pre-layout WNS≥0，也只能称 current-source architecture timing closure，不能越级声明 physical signoff。
- **2026-07-14 收口**：resident EX fast consumer、PRF bypass 与后续 owner/credit 长链已在 T3M–T4I 切片中关闭，current frozen proxy exact-5ns MET；physical 限制统一转记 #118。

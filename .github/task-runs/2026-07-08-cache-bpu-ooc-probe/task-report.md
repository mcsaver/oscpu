# 任务报告：cache/BPU 三黑盒 OOC 综合失败根因定位（容量扫描 + 卡点 pass 级定位）

## 目标

继续 `[112]` 综合线：此前 NpcTop 级 blackbox 开关矩阵已把失败定位到模块级
（full 卡 FetchPacketCache → +dcache 卡 BPU → +BPU 卡 FP Mul/FMA → 四黑盒 PASS），
且 PmpChecker/FP 已用 OOC probe 拆账。本轮把同一方法应用到剩余三个黑盒模块
（OooFetchPacketCache / OooDataWordCache / OooBranchDirectionPredictor），回答
"到底是什么导致综合失败"：定位卡死的具体 pass、量化容量-可行性曲线、盘点结构性死重。

## 实现者人格

方法：`make -C npc/rv64 syn` 单模块 OOC（`STA_CLK_FREQ_MHZ=100 STA_SYNTH_FLATTEN=1
STA_SYNTH_PUBLIC_AUTONAME=0`），coarse(=1) 与 full(=0) 各一轮，timeout 600s；
容量经 `STA_VERILOG_DEFINES="OOO_*_CACHE_INDEX_W=<n>"` 扫描。不改任何生产 RTL。

### 结果矩阵（full stdcell, 100MHz, timeout 600s）

| 模块 | 配置 | 状态位 | 结果 | 关键数字 / 卡点 |
| --- | --- | --- | --- | --- |
| OooBranchDirectionPredictor | 默认 | 26892 | **PASS 282.92s** | 80968 gates, area 434416, delay 30, 峰值内存 1.26GB |
| OooFetchPacketCache | iw=12(4096 项,默认) | 819200 | **timeout** | 卡 `7.6.1 ABC extracting gate netlist`（memory_map 已完成） |
| OooFetchPacketCache | iw=10(1024 项) | 204800 | **timeout** | 同上 |
| OooFetchPacketCache | iw=8(256 项) | 51200 | **PASS 522.69s（贴边）** | 102771 gates, area 581712, delay 39, 693MB |
| OooDataWordCache | iw=12(4096 项,默认) | 466944 | **timeout** | 卡二次 ABC（liberty map）`14.1 extracting gate netlist` |
| OooDataWordCache | iw=8(256 项) | ~30k | **timeout（容量已极小仍不过）** | 同上——结构问题非容量 |

coarse 全部秒过（memory 仍是 `$mem_v2` 黑盒未展开，8 个/2 个阵列）。

### 根因结论

1. **主根因（三模块同族）：大寄存器阵列 + 0-cycle 多口组合读**。full 流程中
   `memory_map` 把阵列展开成 FF 海 + 每读口一棵 `ENTRY_COUNT:1 × 位宽` 组合 mux 树，
   到 ABC 的 blif 提取阶段即卡死（不是 timing 优化慢，是 netlist 提取都完不成）。
   这**不是"组合判断逻辑该 FSM 化"能解决的**——属于存储组织/宏边界问题。
2. **结构性死重（放大器）**，读 RTL 逐项确认：
   - `OooFetchPacketCache` 每 entry 存 **64bit satp 并全宽比较**（`satp_q`），但
     `clear_i` 接 `mmu_flush`，而 `OooMemoryRequestGate.v:62` 证实
     `mmu_flush = satp 写提交 || sfence || fence.i` ⇒ **satp 一写 cache 必全清 ⇒
     entry 内 satp 匹配恒真 = 纯死硅**（64/200 bit ≈ 32% 容量 + 一个 64bit 比较器）。
   - `pc_q` 全 64bit 存储+比较：直映 tag 只需去掉 index 后的高位（VA39 规范化 ≈27bit）。
     `OooDataWordCache` tag 53bit 按 64bit 地址空间计，PA 实宽收窄可砍一半以上。
   - `pc_q` 有 **8 个组合读口**（lookup + SMC 失效邻域 m6..p6 七个），每口都是完整 mux 树。
   - dcache 连 256 项都过不去：req+walk **双组合读视图** + line-cross 窗口移位 +
     store byte-merge（read-modify-write 组合闭环）叠加，端口×移位×merge 是结构性的。
3. **BPU**：能过但 8 万门/43 万 area/1.26GB 峰值内存——纯 FF 表的固有成本；在
   NpcTop flatten + 500MHz 语境下成为 ABC 负担（与三黑盒探针"卡 BPU ABC"一致）。
4. **FP Mul/FMA**（引用既有拆账 `2026-07-08-fp-arith-internal-cones`）：子段全部
   standalone 可过，失败是完整输出 cone 融合后的累计成本——流水级间寄存边界在
   flatten 后没有把 ABC cone 切开。

### 对重构主线的建议（供决策，未动 RTL）

- **表类模块的正解是存储边界改造，不是 FSM 化**：
  1. 零架构风险的纯删减：删 `satp_q`（恒真匹配）、tag 收窄（VA39/PA 实宽）、
     SMC 失效邻域 8 读口合并（改短 tag 比较或失效位图）。收益 ≈ 每 entry 减半，
     但 stdcell 曲线（256 可过/1024 不可过）表明这最多把可行容量推一档，救不了 4096。
  2. 架构决策（真正的解）：**SRAM macro 边界（同步读，lookup +1 拍，需前端/访存
     流水配合）**——即四黑盒 placeholder v0 预设的"真实 macro model"路径；或接受
     小容量（≤256 项）stdcell 版本。CPI vs 面积 vs 可综合性的取舍需用户拍板。
  3. dcache 另需结构手术：双读视图/移位窗口/byte-merge 时序化——这里才是
     "FSM/时序化替代纯组合"的适用场（store RMW 可走 1 拍时序）。
- **FP Mul/FMA**：把 product / align-add 的流水级边界做成真寄存切割
  （防 flatten 后 cone 融合），或走 OOC/child split。

## 关键证据

- `evidence/OooBranchDirectionPredictor-full.log`：`ABC: netlist ... nd = 80968 ...
  area =216722.52 delay =30.00`，`Chip area ... 434416.92`，`time: 282.92s ... MEM: 1257.70 MB peak`。
- `evidence/OooFetchPacketCache-full.log`（iw12）与 yosys.log 尾部：停在
  `7.6.1. Extracting gate netlist ... to input.blif`，exit=124。
- `evidence/OooFetchPacketCache-full-iw8.log`：`nd =102771 ... area =264743.92 delay =39.00`，
  `Chip area ... 581712.88`，`time: 522.69s`。
- `evidence/OooFetchPacketCache-full-iw10.log`：exit=124，同卡点。
- `evidence/OooDataWordCache-full.log`（iw12）/`-full-iw8.log`：停在
  `14.1. Extracting gate netlist`（二次 ABC/liberty map），exit=124。
- satp 恒真链：`npc/rv64/vsrc/memory/OooMemoryRequestGate.v:62-65`（mmu_flush 组成）
  + `OooFetchAxiBridge` 的 `u_fetch_packet_cache(.clear_i(mmu_flush_i))`
  + `OooFetchPacketCache.v:118-122`（satp 全宽比较）。

## 方法边界

- OOC 单模块 ≠ NpcTop flatten 语境：顶层还有 cone 融合与 500MHz 约束，OOC PASS
  只是必要条件；OOC timeout 则必然是顶层 blocker。
- 100MHz/600s/本机（WSL2）预算下的结论；更大 timeout 可能让 iw=10 勉强通过，
  但 522s/256 项的曲线斜率已说明 stdcell FF 阵列路线不可行。
- 未修改生产 RTL，无功能回归需求；`satp_q 恒真`结论基于 mmu_flush 驱动链静态阅读，
  正式删除前应加 focused TB/checker 验证语义等价（含 ASID 未来扩展的取舍记录）。

## 审查者人格

- 未闭合：本轮只定位根因与量化曲线，**没有**给出任何模块的重构落地；
  4096 项 stdcell 不可行的结论不能越级引申为"SRAM macro 方案已验证"——macro 的
  Liberty/LEF/时序接入仍全 open（[112] 原状态不变）。
- dcache "结构问题非容量" 的证据是 iw=8 仍 timeout，但未做进一步 cone 拆分
  （读口/移位/merge 分别贡献多少未量化）——列为下一步候选 probe。
- BPU OOC PASS 与三黑盒探针"卡 BPU ABC"不矛盾（后者是 NpcTop flatten+500MHz），
  但未复测"BPU 在顶层语境下的临界条件"，不能断言 BPU 无需重构。

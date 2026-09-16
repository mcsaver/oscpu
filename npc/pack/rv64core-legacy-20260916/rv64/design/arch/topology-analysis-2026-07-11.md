# 全电路拓扑分析：拍界地图、融合经济学与结构重划方案（2026-07-11）

> 性质：snapshot / 实施记录。§1-§4 是本轮修改前的 baseline 与方案预测；§5 是同日
> post-change 结果，§6 是可提炼的方法学。本文不作为 current authority；当前现状见
> `rtl-ground-truth-2026-07-11.md`。
> 数据源：真弧 STA top-40 全族解剖（派生索引：
> `.github/task-runs/2026-07-11-knife-b2-s2s3/evidence-index.md`；本地 raw：
> `.github/task-runs/2026-07-11-knife-b2-s2s3/evidence/topo40.rpt`，
> SHA-256 `f2b292686adef90056a7fe0ea7977d6a0085d98a7d5aa9cf0c3b346ffe10d512`）+
> 性能战役全部刀的实测 CPI 账（各 task-run）。post-firewall 报告位于
> `npc/rv64/build/sta/NpcTop-100MHz/topo40.rpt`。上述 raw 路径属于 ignored runtime
> artifact，clean checkout 不保证存在；可持久追溯信息以派生索引中的 size/hash 为准。
> pre-change baseline：CoreMark CPI 0.877 / WNS -15.37 @100MHz（真弧）。

## 1. 拍界地图：一拍内的架构事件传递闭包

Top-40 违例**全族单一同源**——一条 25.0ns 的超级组合链，把五个流水级缝成一拍：

```
dcache SRAM rdata (clk2q 1.28)                       ── MEM 级
→ hit 判决 → rsp 组合交付 (刀D 融合, ~1.6ns)
→ LSU 展开 → wb → PRF 写读 bypass
→ issue 前递网 (~7.3ns)                              ── WB/ISSUE 级
→ EX (分支比较/resolve 判定, ~0.5ns)                  ── EX 级
→ jal/ret direct fire → redirect (同拍臂)             ── 控制交叉点
→ fetch fire (刀F 融合连发)
→ fetch SRAM 判决 → RVC 解压 → 分支识别 (跨域段 7.9ns) ── IF 级
→ bimm 提取 → BPU 判决 → pred_next_pc (刀B2, ~2.0ns)  ── ID/BP 级
→ next_fetch_pc_q / packet_next_pc_q (寄存)
```

**拓扑病理**：每个融合点单独看都是"局部两级并一级"的合理优化，且各自过了
0.5ns 门禁；但它们没有公共拍界隔断，**传递闭包**把 5 个流水级并成了一拍。
这是"每刀阈值内≠叠加安全"教训（刀 F 时初次记录）的全局版。

## 2. 融合经济学表（全部实测数据）

| 融合点 | CPI 价值（实测来源） | 链上 ns 占用 | 价值密度 | 处置建议 |
| --- | --- | --- | --- | --- |
| wb→issue 同拍前递 | **0.3~0.5**（T3 否决时估） | ~7.3 | **高** | 保留（它是 OoO 核的命脉） |
| fetch 融合连发（刀 F） | **0.43**（实测） | 判决锥（域内） | **高** | 保留 |
| B2 pred 同拍判决 | **0.19**（S2 实测） | ~2.0 | 中高 | 保留 |
| jal/ret 同拍 redirect | ~0.05-0.1（K1 同族推算） | 小（mux）但**串联两域** | 中 | **候选切点** |
| dcache hit 融合（刀 D） | 0.066~**0.143**（T2 实验双测） | ~1.6+起点 1.28 | **低** | **候选切点**（T2 已证可逆） |
| resolve 同拍 redirect | 0.025（T1 实测） | 已断 | — | 已次拍化（T1） |

核心洞察：**链的两端价值密度低（dcache 融合、jal/ret 同拍 redirect），中间价值
密度高（前递网、fetch 融合）**——拓扑处方不是撤销所有融合，而是在低价值的
"域间缝合点"立防火墙，让高价值融合在各自域内独立成链。

## 3. 结构重划方案："redirect 防火墙"（推荐主案）

**在 backend→frontend 的唯一控制交叉点（redirect）立强制拍界**：

- **全部 redirect 次拍化**：T1 已做 resolve 族；跟进 jal/ret/jump_spec direct fire
  与 trap（K1 的最后残留臂退役）。redirect PC 恒经 `next_fetch_pc_q` 寄存，
  frontend 的每一拍都从 FF 起。
- 重划后两个独立时序域：
  - **backend 域**：dcache rdata(1.28)→hit 融合→wb→前递网(7.3)→EX/resolve→FF
    ≈ **9.1ns**（临界但可微调——若不够，切 dcache 融合=T2 已证形态，回吐 0.14）；
  - **frontend 域**：fetch SRAM rdata(1.54)→融合判决→RVC/dec(域内后布线缩短)
    →BPU→pred 判决→FF ≈ **需实测**（当前 7.9ns 跨域段的大头是跨核布线与
    domain 交叠，防火墙后预期显著缩；若仍超，pred 判决挪包驻留拍——
    lookup 不动（S1.5 教训），只挪加法+判决）。
- **CPI 代价预算**：jal/ret 重取 +1 拍 × 频率（CoreMark jump/branch 20.4% 中
  jal/jalr/ret ≈7%，全预测 100% 正确）≈ **+0.05~0.10**——从 0.877 回到
  0.93-0.98，仍在 F2 峰值带；换取的是 WNS 从 -15.37 回到单域 max(-1~0) 带
  =**Fmax 逼近 100MHz，综合性能（f/CPI）翻倍不止**。
- 实施半径：RequestMux/FlowControl（T1 同型扩展）+ ActionGate（direct flush
  次拍化配套）+ sequencer 记账核对（E4 臂语义迁移）——中刀，T1/S2 的先例齐备。

## 4. 备选与配套方案

| 方案 | 内容 | 定位 |
| --- | --- | --- |
| C（对齐窗口取指） | `next_window=window+8` 内容无关，消灭 dec→地址递归 | 防火墙后若 frontend 域仍超，升级用；结构重构大 |
| BPU 表 SRAM 化 | lookup 两拍（表读打拍） | 与防火墙正交；S1.5 教训=lookup 时点精度敏感，需带"GHR 对齐"设计，缓做 |
| dcache 融合切除 | T2 已证形态（tie-0 可逆） | backend 域不够 9.1ns 时的调节阀 |
| SQ snoop 打拍 | snoop→fetch 失效链（历史 top 族 B） | 防火墙不治此族；需 SMC 窗口语义论证，独立小刀 |

## 5. 防火墙战役落地记录（2026-07-11 同日，post-change 结果）

### 实施三刀（真链解剖推翻了 §3 的预判——redirect 防火墙只是序章）

| 刀 | 内容 | WNS 效果 | CPI 代价 |
| --- | --- | --- | --- |
| v1: redirect 全次拍化 | redirect_fetch_req_valid 退役，direct 族 fire 拍封顺序臂次拍发 target（K1 完全退役） | -15.37→-15.37（未切中——链不走 redirect！） | +0.010 |
| v2a: 盲失效打拍 | store 发射→icache invalidate 寄存一拍（SMC 无架构承诺，合法） | -15.37→-12.56 | ~0 |
| v2b: **mmu_flush 出口打拍** | 真缝合点=组合生成链（rsp→wb→ROB commit→retire_count→drain_complete→组合 flush→fetch 桥 ITLB/融合门）；satp/sfence/fence.i 整机静止事件晚一拍零语义 | **-12.56→-5.35** | ~0 |

**合计：WNS -15.37 → -5.35（收回 10ns，历史最好），CPI 0.877→0.886（+0.009）。**

### 教训与事故

- **逐 cell 真链解剖两次推翻假设**（redirect 臂→invalidate→mmu_flush）——拓扑修复
  必须先解剖后动刀，"语义上合理的缝合点"不等于"STA 上的真缝合点"。
- **mmu_flush 打拍引发 0/178 全挂事故**：flush 晚一拍后与重启取指 fire 拍相撞，
  复位分支吞掉已 fire 请求→sequencer 记账悬空挂死（fence.i 在全部 riscv-tests
  crt 中）。修复=两桥 ready 加 flush 拍门（请求次拍重发，零代价）。
  **教训：给"广播式复位类信号"打拍时，必须审计所有"该信号拍不得发生"的
  同拍事件（fire/enqueue 类），配套压 ready。**

### 统一测试（2026-07-11 日志复核校正）

summary 层曾记录 module TB 86/86、lint、riscv-tests 177/177、AM PASS 与
overall_rc=0；日志级复核后，当前可采信范围应改为：

- official riscv-tests 177 项逐项 PASS；
- CoreMark 0xfcaf、CPI 0.886；WNS -5.35/TNS -34780；
- module summary 的 86/86 不能直接采信：3 个原始 TB 日志含 FAIL 后仍写 `[RESULT] PASS`；
- AM 实际 58/59，`fp-difftest-probe` FAIL；
- 当前 `.config` 未开启 Difftest，不能用本轮 core-regress 声称 177 项/ CoreMark 全状态对拍。

因此本战役当时的时序/CPI 结果仍成立，但“统一测试全绿”结论撤回。

**后续 F0 收口（同日）**：结果聚合器、三个 sequencer TB 和 FP destination-domain
资格已另行闭合；新鲜结果为 module 86/86、AM 59/59（Difftest ON）、official
177/177。本节保留的是 F0 前审计事实，current gate 以
`.github/task-runs/2026-07-11-rv64-f0-truthful-regression/` 为准。

### 新拓扑（防火墙后 top-40 全景）

**跨域传递闭包已消灭**：40 条 top 路径全部收敛于 frontend 域内——
25 条 fetch 桥→FIFO（融合判决→dec→pred→包字段寄存）、15 条 fetch 桥→
next_fetch_pc（同链→sequencer）。约 -5.4ns 的域内链构成：fetch 桥 pc_q→
融合判决（ITLB/PMP/tag）→rsp 交付→RVC 解压→分支识别（含 ~8ns 扇出布线
虚胖，真实后端 buffer 树可大幅缓解）→bimm→pred 判决→寄存。
下一步候选（frontend 域内战役）：①dec1_branch 高扇出手动 buffer/逻辑复制
（先试，虚胖可能占大头）；②pred 判决挪包驻留拍（lookup 不动）；③方案 C
对齐取指（结构级，消 dec 依赖）。backend 不在当前 top-40，只能说明它未进入这组最差
endpoint，不能推出所有 backend 路径已经满足 10ns。

## 6. 方法学固化（进宪法候选）

1. **拍界预算制**：每个时序域(拍)有 ns 预算账本；任何"同拍化/融合"优化必须
   申报其所在域的预算占用，超预算即触发域重划评估——不再只看单刀 WNS 增量。
2. **域间缝合点登记**：跨 keep_hierarchy 模块的同拍组合路径（现状：redirect、
   snoop、rsp 数据、ready/fire 握手）全部登记造册，每条标注 CPI 价值与 ns
   占用——本表（§2）是第一版。
3. **传递闭包检查**：新刀 STA 门禁从"WNS 增量 <0.5ns"升级为"top 路径族语义
   审查+该路径经过的融合点计数不增"。

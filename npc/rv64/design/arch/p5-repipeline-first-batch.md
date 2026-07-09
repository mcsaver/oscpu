# 规范：P5 重新流水化第一批（PLIC 打拍 + B 刀删 IQ bypass + M 刀预告）

> 状态：**spec 冻结（2026-07-09，基于全核 OpenSTA 关键路径解剖 + 切点决策材料，
> 两份侦查原文存 `.github/task-runs/2026-07-09-p5-recon/`）**。
> 隶属 `pipeline-stage-boundary.md` P5（重新流水化类——改 IPC/时序语义，独立 spec+数据决策）。
> 数据基线：全核 OpenSTA @100MHz WNS −10.31ns，top10 全部为**同一条 19.8ns/240 级路径**：
> PLIC 优先级比较森林(0–3.4ns) → CSR irq → frontend dispatch 门控(→4.1) → IQ dispatch→issue
> bypass 直通(→4.24) → 误预测全宽比较+wb 仲裁 4 连跳(→9.3，含 clmul_rsp_to_wb0 高扇出链) →
> 唤醒 CAM+select(→10.4) → PRF 读+SC 保留比较+旁路(→13.9) → AGU/SQ CAM/can_fire+req mux(→17.0)
> → DTLB CAM→dcache SRAM addr(→19.8)。一拍串 7 个架构决策、跨 5 个 keep 边界。

## 1. 第一批两刀（本 spec 排期）

### 刀 P（PLIC meip 出口打拍）——白送 3.4ns，先做

- 现状：`AxiLitePlic.v:163` 每源 `priority_q[i] > threshold` 32 位幅值比较 ×32 源 + claim
  归约，**组合直通** meip → CsrFile `irq_pending_o` → frontend dispatch 许可门。
- 改法：PLIC 的 meip/seip 输出寄存一拍（模块内出口打拍）。
- 语义论证：外部中断本就异步于指令流，pending 晚一拍可见不改变任何架构语义
  （mip.MEIP 采样本来就无时序承诺）；riscv-tests 中断用例判定的是"最终响应"非拍数。
- IPC 代价：零（中断响应延迟 +1 拍，非流水吞吐路径）。
- 风险：CLINT 的 mtip/msip 是否同链（顺手核查，同改）；tb_axi_lite_plic 拍数适配。
- **落地（2026-07-09）**：PLIC `external_irq_o` 出口寄存一拍（复位 0，claim/complete 仲裁
  仍取组合值，AXI 读拍语义不变）；CLINT 核查实锤 `mtip_irq_o` 同属组合比较直通
  （64 位 `mtime>=mtimecmp`），同改打拍，`msip_irq_o` 本就直连寄存器免改。
  tb_axi_lite_plic/tb_axi_lite_clint 中断可见性适配 +1 拍并**新增**"出口寄存一拍"
  契约检查（对旧组合直通实现必 fire，负测试证据已留 log）；module TB 86/86、
  lint 双变体、check-contract（21≥20）全 PASS，priv_system/core_top_glue 集成 TB 无回归。

### 刀 B（删 IQ dispatch→issue 同拍 bypass）——历史已实测的正刀

- 现状：`OooIntIssueQueue.v` :274-320 bypass 函数族 / :336-435 allowed/entry_ready /
  :525-629 虚拟队尾臂 / :636-679 payload 直通臂——dispatch 活值直通 issue 口，把前端锥
  与后端锥缝合成单拍。
- 历史数据（`timing-dispatch-issue-path.md` §6c B-cut-1）：级数 39→24（−38%）、logic
  delay −54%、**CPI +5.5%**（依赖密集 ALU 环集中：wanshu +39%/select-sort +36%；
  访存受限用例几乎不变）。当年不 ship 唯一理由=routed Fmax 不可验——yosys-sta+OpenSTA
  全核流程现已在，重启条件满足。
- 正确形态澄清：IQ 阵列本身就是寄存，B 刀=纯删除 bypass 族（"寄存 rename 结果再喂
  bypass"变体被支配，弃）；ROB/SQ/busytable/rename map 写路径全不动。
- 时序收益预估：砍掉 0–9.3ns 全部头段（PLIC 树/frontend/busytable 比较树/8 级 BUF 链
  随 fan-in 消失）→ 新周期 ≈12ns（~83MHz，WNS −10.3→约 −2）。线性外推，真值以重跑 STA 为准。
- 执行门槛：S0 先重测现核 CPI（06-28 数据基于 F2/SQ/FP 大改前的老核）；kill 窗口核对
  （删 bypass 后"当拍 dispatch 写入+同拍 kill"的新写项须被 IQ kill younger-后缀清除覆盖）；
  TB 契约重写不可弱化；负测试=故意保留一条 bypass 臂应使新断言 fire。

## 2. 第二批预告（S2 数据后决策，另立实施记录）

- **刀 M（桥侧 req 寄存站）**：mem_req 桥内寄存、dcache lookup 次拍（load hit 2→3 拍，
  CPI 估 +3~8% 需实测）。六类契约草案已在侦查存档（MIQ push 时点/nokill 透传/AMO 独占
  谓词计入寄存站——mem_quiet 中间态死锁家族教训）。B+M 后预估 ~9.3ns（~105MHz）。
- **刀 A（Issue→RegRead/EX 打拍+确定性早唤醒）**：本核利好=ALU 类从 issue-reg 广播是
  确定性早唤醒非投机（EX 恒 1 拍/ex_q 恒收/PRF 写透）；真雷=mem 类队头独占谓词依赖
  EX 拍地址，驻留 issue-reg 堵死 store 端口=队头序死锁家族。**完整形态绑定 LSQ 战役**，
  本批不做。
- 达成 ~100MHz 后新瓶颈=FpBackend（ABC delay 90）/FetchAxiBridge（50），P5 不治。

## 3. 验证策略

每刀：focused TB → 全量 module TB → lint 双变体 → check-contract 计数不降 →
大节点 tohost（riscv 177+AM+CoreMark）→ 全核 STA WNS 对比。cycle-exact 禁用（拍数必变）；
全状态 difftest 按既定策略留重构整体收口。CPI 用 CoreMark 10 迭代 cycles 与 eval 样本对比。

## 4. 变更记录

- 2026-07-09：spec 冻结；刀 P/刀 B 排期，刀 M/A 预告。

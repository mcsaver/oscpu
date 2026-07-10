# 规范：刀 B2——fetch-time BPU（分支预测介入点前移到 resp 拍）

> 状态：**spec 冻结（2026-07-10，侦查存 `.github/task-runs/2026-07-10-knife-k1-impl/evidence/b2-recon.jsonl`）**。
> 前置已落地：刀 K1（taken fire 同拍重取，`d19c4790e`）把空窗 3→2 拍并验证了
> 同拍 redirect 语义；P4 契约禁止项①已作废。本刀是根治项：把 taken 分支从
> "flush 事件"降格为"顺序流地址选择"。
> 基线：CoreMark CPI 1.038，fetch 等待 94.2%，branch_flush 桶 17.7%（592406 拍）。

## 1. 冻结形态："包内预测位 + taken 拍断融合"

- **resp 拍预测**：fetch rsp 判决拍（=刀 F 融合拍）对 dec0/dec1 做分支识别
  （OooFetchPacketDecode 已有 OPCODE_BRANCH 判别）+ B-imm 提取 + BPU lookup：
  - slot0 taken → 包内截断（slot1_valid=0），pred_next_pc = pc0+imm0；
  - slot0 not-taken、slot1 taken → 整包有效，pred_next_pc = pc1+imm1；
  - 均 not-taken → pred_next_pc = packet_next_pc（现状顺序流）。
- **FIFO 包新增字段**：per-slot pred_taken/bht_idx/bht_valid ×2、slot1_valid
  截断位、包 pred_next_pc（现 packet_next_pc 字段的 head 侧消费者已死
  OooCoreTopGlue.v:807，可改造承载）。
- **taken 拍断融合（R1 叠加缓解，冻结为默认形态）**：pred 在 resp 拍算出但
  寄存；预测 taken 的拍压掉同拍融合 req（单 bit 关断，刀 F invalidate 降级臂
  同款手法），次拍从寄存值发 target req——仅 taken 包付 1 拍（比 K1 后仍净省
  1 拍），fetch_req_pc 组合锥零增长。**禁止**首版就做"taken 拍组合改流"
  （= 重演刀 F 首版 WNS -6.73 家族：BPU local 两级串联读+imm 加法器进
  fetch_req_pc 回环）。
- **预测一次定格**：dispatch 消费的 pred_taken/bht_idx 全部改包内存储位，
  活查询口物理断开（两点查询分歧=F2 #105 同源教训）；BPU update 用包内
  存储 bht_idx（训 fetch 拍查过的表项）。
- **dispatch 拍分支 direct fire 删除**（不作兜底——兜底会 flush 掉已正确预取
  的 target 路径且破坏 pred_npc 机械一致性）；JAL/RET/非返回 JALR direct fire
  原样保留。dual_go 改存储位驱动（stored not-taken && slot1_valid && head1
  平凡）；taken 分支变"solo dispatch + pred_npc=target"（复用 dispatch1_squash
  臂）对称免 flush。
- **E4 去 branch 项**；顺序臂改流仅两处（Sequencer 顺序推进臂 :98-103 与
  RequestMux 顺序臂 :45-47 的 rsp 项换 pred_next_pc）——resp 拍改流是"顺序流
  地址变化"非新事件，outstanding/discard/seed/clear 记账零触碰。
- **纠错通道零新增**：预测错→后端 mispredict→E3 untracked redirect+ROB-walk
  kill+FIFO clear——该通道已被 dual_go 误预测与 count<2 哨兵高频演练。
- **顺手消灭 count<2 哨兵缺口**：pred_npc 从包内直取，不再依赖 FIFO count
  （F2 已知遗留的"target 包未到→伪 mispredict"消失）。
- **不动**：RAS push/pop 时点（全在 dispatch 拍 jal/ret 事件）；
  BranchSpecTracker（mode=1 已休眠，tie 保留）；fetch 桥本体。

## 2. 关键正确性要点（侦查 §三逐项，实施时照单验收）

1. 截断位单点门控：head1 谓词族（HeadPairGate ~40 输出）以 facts 总线生成处
   gate slot1_valid，不逐消费者补。
2. 截断编码禁用 resp 字段/NOP 替换（resp 是 fault 通道，撞 fetch-fault drain）。
3. 故障 slot（resp≠OK）不预测；双分支包 slot0 优先。
4. flush 拍改流 mux 当拍组合赢 + 立即断言（pred-taken rsp 拍 ⇒ 下一 req
   pc==target）——F2 障碍①家族。
5. E3 redirect 拍与同拍 rsp enqueue 竞争（FIFO clear 文本序压 enqueue）进
   focused TB 真值表——fetch-ahead 更深后此窗口暴露频率上升。
6. NpcSimTop branch_flush/bpu 观测口同刀迁移（避免收益数字失真）。

## 3. 改动清单与工程量

约 10 个 RTL 模块（PacketDecode/BPU 接线/FIFO/SeedMux/HeadMux/RequestMux/
Sequencer/DispatchGate/ControlFlowGate/ActionGate/Frontend）+ 5-8 个 TB/checker
——"中刀"，F2 量级但失败史可复用。分三步：
- **S1（台阶）**：包内预测位基建（resp 拍 lookup+字段入 FIFO+dispatch 改存储位
  消费，行为等价——预测点前移但仍走 dispatch fire 路径），cycle 影响≈0，
  全量验证一轮。
- **S2（主刀）**：taken 拍断融合改流+dispatch 分支 fire 删除+E4 去 branch+
  dual_go 存储位化+哨兵缺口消灭。
- **S3**：全量+difftest 收口（本刀动前端预测语义，收口必做）+STA+文档。

## 4. 收益预估（K1 后口径修正）

K1 已吃掉每事件 1 拍；方案 A 增量=再省 1 拍（断融合形态）+分支包 control_stop
断流拍+哨兵伪 mispredict 全代价+not-taken 包断流放行。修正预期带
**ΔCPI ≈ -0.06~-0.15（1.038 → 0.89-0.98）**，逼近或越过 F2 后峰值 0.93。
验收以 CoreMark 实测为准。

## 5. 风险表

| # | 风险 | 缓解 |
| --- | --- | --- |
| R1 | resp 拍组合链叠加（融合拍+BPU 两级串联读+imm 提取） | 断融合形态冻结为默认（pred 寄存、taken 拍压融合）；STA 门禁 >0.5ns 退 |
| R2 | 预测-载荷分叉（dispatch 残留活查询） | 全部存储位化，活查询口物理断开+断言 |
| R3 | 截断位漏消费者→幽灵 lane1 | facts 总线单点门控 |
| R4 | F2 kill 窗口家族①②（flush 拍旧值泄漏/同拍 push 漏标） | 改流 mux 当拍赢+断言；E3×enqueue 真值表 TB |
| R5 | 契约文档漂移 | ooo-flush-redirect-contract.md 同刀修订（K1 已开先例） |

## 6. S1 落地记录（2026-07-10）

- S1 台阶落地（`fac7468ca`）：BPU lookup 迁 resp 拍、预测位随包存 FIFO（+6 字段）、
  dispatch 全存储位消费（活查询口物理断开）。CoreMark CPI 1.064 持平（cycle 中性✓）、
  accuracy 88.6%（-0.1pp，GHR 时点前移预期微变）；86/86+lint 双变体+contract 32+
  riscv 177/177+0xfcaf 全绿。seed fallthrough 臂预测位接同拍 BPU 组合输出
  （防 bht_idx=0 回训污染——实施中的正确决策）。
- **STA 验收暴露新锥（WNS -7.51→-10.78）**：BPU lookup 挂在融合组合 rsp 上，
  接在 dcache rdata→…→fetch 融合交付→dec→imm 提取→BPU lookup 的长链尾部——
  比 spec R1 预想深（R1 只预防了"pred→改流"方向，未预防"数据→lookup 输入"方向）。
- **S1.5（下一步，先于 S2）**：lookup 挪到 enqueue 次拍——预测位补写 FIFO 表项
  （包在 FIFO 至少驻留 1 拍，dispatch 前补写完成；FIFO 空直达 head 场景 fallback
  静态预测位）。把 BPU 查询彻底摘出融合组合拍，锥断开。

## 7. 变更记录

- 2026-07-10：spec 冻结（K1 前置已落地；断融合形态定为默认）。
- 2026-07-10（同日）：S1 落地+STA 暴露 lookup 锥+S1.5 方案（§6）。

# 任务报告：刀 D 实施——dcache hit 融合拍

spec：`npc/rv64/design/arch/knife-d-dcache-hit-fusion.md`（同日冻结+落地回填 §5）。

- **CoreMark CPI 1.206 → 1.140（-5.5%）**；三刀累计（X+F+D）**3.280 → 1.140（-65%）**。
- riscv 177/177（含特权）+86/86+lint+contract 32+0xfcaf 全绿。
- WNS -5.69→-6.05（0.36ns<0.5ns 阈值，R1' 未触发）；新 top=dcache rdata→发射决策锥，
  两融合刀累计 -0.46ns，后续劣化需回头治（预案在 spec §3）。
- hit 锥无 snoop 对应物的侦查判定被落地证实（无需降级臂，与刀 F 的关键差异）。
- mutation 首轮逃逸→"miss 判决拍+站有下一项"杀手用例闭环；TB 直映 index 冲突坑
  （0x9000/0x1000 同 index）记录在案。
- 等待源新格局：fetch 87.9%（绝对值随 cycles 下降继续缩）/mem 56.6%/branch_flush 16.1%。
  下一步候选：fetch 残余（redirect 重启空窗→fetch-time BPU）为主，mem 残余=miss
  延迟+store 通道；全状态 difftest 整体收口时点渐近（三刀重构面已大，建议下一刀前收口）。

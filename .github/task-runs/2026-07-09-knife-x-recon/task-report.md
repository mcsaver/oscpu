# 任务报告：刀 X（MUL 拍数收复）侦查与 spec 冻结

三路侦查（RTL 现状契约 / 方案设计 / 验证策略）+ 对抗审查，spec 已冻结：
`npc/rv64/design/arch/knife-x-mul-latency-recovery.md`。

- 推荐形态：radix-4 无符号数字（3M 装载拍寄存，镜像 DIV div_d3_q）+ CLZ 早退出
  （swap 选 min 幅值侧）+ 两侧零特判直进 RESP；零新 FSM 状态；显式弃用 Booth。
- 审查关键修正：①侦查材料间 Booth/非 Booth 矛盾钉死；②零特判必须查两侧
  （单侧+swap 漏判→count 绕回 64 拍全门禁假 pass=R1 最高危）；③收益模型偏乐观
  （busy 阴影内 issue1 仍单发），验收改 matrix-mul cycles 绝对值（67766→~1-2 万）；
  ④否决 MUL_EARLY_EXIT 参数化常驻负测试，改拍数上限断言+一次性 mutation。
- 侦查原文：evidence/recon.json（rtl/design/verify/review 四份全文）。

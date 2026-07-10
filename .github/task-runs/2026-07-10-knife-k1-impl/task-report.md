# 任务报告：刀 K1——taken 分支 fire 同拍重取（redirect 空窗 3→2 拍）

刀 B2（fetch-time BPU）侦查的即食小刀（保守替代 K1，完整侦查在 evidence/b2-recon.jsonl）。

- 改动：branch0/1_fire 加进 `redirect_fetch_req_valid_o` 或集（OooFetchRequestMux
  +2 端口 2 行，PC 经 arbiter e4 臂早已就位）；有意作废 P4 契约禁止项①
  （"taken 分支同拍取指请求=时序变化"——P4 周期中性时代冻结项，性能刀战役下失效），
  头注已改写。direct_redirect_fetch_o 成员集**未动**（两个 direct 定义不一致的
  收口问题不顺手处理——历史禁忌③）。
- **CoreMark CPI 1.140 → 1.038（-8.9%，超预估带 -0.05~-0.08）**——outstanding
  门命中率好于预期（融合拍下 rsp fire 高频，同拍窗口常开）。0xfcaf GOOD TRAP。
- **五步累计（考证→X→F→D→K1）：CPI 3.280 → 1.038（-68%）**，距 F2 后峰值
  0.93 残差 0.11。
- riscv 177/177（含特权）+86/86+lint+contract 32 全绿；TB 补 K1 定向 4 用例
  （branch0/1 fire valid+PC 走 arbiter+outstanding 门保持）。
- 等待源：fetch 94.2%/mem 56.1%/branch_flush 17.7%——方案 A（fetch-time BPU
  完整版："包内预测位+taken 拍断融合"）仍有 -0.1~-0.2 CPI 空间，侦查已备齐，
  spec 待冻结。

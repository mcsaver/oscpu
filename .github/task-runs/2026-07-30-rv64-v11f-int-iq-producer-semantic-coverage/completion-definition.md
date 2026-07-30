# V11F completion definition

- [x] 独立预审裁决 H1/H2/H3，并冻结合法 IQ-I6 周期合同。
- [x] production IQ、selector、testbench、runner 与 full RTL pre/post identity
      可核验。
- [x] testbench-owned 八槽 full-ProducerId model 不从 DUT raw Q 或 live mask
      反喂 expected。
- [x] `PRODUCER_GEN_W=1/4` 的 assert/release baseline 4/4 PASS。
- [x] birth、READY-low/recover hold、regular single/dual issue、memory pair、
      compaction、selective kill、flush/reset 与 raw identity knownness 均有
      定向 marker。
- [x] 二十个声明的 compile-success RTL 变体都实际生成仿真镜像。
- [x] 关闭 `OOO_ASSERT` 后，二十个变体在 `GEN_W=1/4` 下的 40 次仿真
      均由独立 oracle 拒绝。
- [x] attempt-3 summary 绑定 design-id、16 个 focused source、146-file RTL、
      工具版本、编译命令、日志、镜像和 mutation receipt。
- [x] normal `tb_ooo_int_issue_queue` regression PASS。
- [x] semantic ledger 只把 `integer-iq-producers` 从 GAP 晋级 PASS。
- [x] 独立终审确认没有 oracle 反喂、assert-only 假绿、变体漏编译或范围越级。
- [x] task-specific e2e、evidence index、memory、DB 与 strict guard 收口。
- [x] 明确记录 global no-live-reuse、whole architecture、system、synthesis、
      STA、power 与 PPA 仍未由本轮闭合。

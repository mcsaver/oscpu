# Completion definition

- [x] 当前 RTL design-id 前后相同。
- [x] `tb_ooo_mem_owner_terminal_collector` 在 `OOO_ASSERT` 配置捕获 12 个不同
  terminal tuple，并精确排空 12 个。
- [x] backend/bridge V9R C0 retry-holder testbench 3 个精确 marker 全部出现。
- [x] decode、CSR、fetch-head-classify、priv-system、int-backend scope testbench
  全部 PASS。
- [x] `test_arch_stable_freeze` 全部通过。
- [x] 四个 cohort exclusion 与 exact membership 均为 PASS。
- [x] 9 项 architecture hard gate 保持 GREEN。
- [x] `SERIALIZE-G1`、census 与 freeze-input inventory 未被误闭合。
- [x] PPA 保持 `UNQUALIFIED`。
- [x] 实现者与审查者分别复核证据和反例边界。

# Dispatch Log

- 读取现有 `OooAluFetchCore` RAS/direct return 逻辑，确认 `ENABLE_DIRECT_RAS_RET` 被硬编码为禁用，而 return candidate、RAS reliable/non-empty gate、direct redirect、RAS pop 逻辑已存在。
- 开启 `ENABLE_DIRECT_RAS_RET` 后先跑 `branch-fallthrough-save`，结果 PASS，`cycles=1597/commits=1457/CPI=1.096`，`jump wait=0`。
- 跑 `tb_ooo_alu_fetch_core` 时发现 elaboration 卡在陈旧层级引用 `fast_branch_resolve_valid_q`。将观测点切到当前 `core_dispatch_branch_resolve_valid_w`。
- 继续跑 `tb_ooo_alu_fetch_core` 发现行为断言大面积失败；临时关回 direct RAS 后仍失败，判定为旧 testbench 与当前 RV64 协议不匹配，记录到 known issue [33]，本轮不以该旧 testbench 作为 direct RAS gate。
- 跑可靠 SV 子集 `tb_ooo_priv_system/tb_ooo_sv39_boot/tb_ooo_mem_axi_bridge`，3/3 PASS。
- 跑高风险 CPU-tests：`branch-fallthrough-save/sv39-ras-relocate/sbi-ipi-reset-hsm/linux-mini-boot/plic-sirq/uart-plic-sirq`，6/6 PASS。
- 跑完整 `riscv64-npc` cpu-tests，56/56 PASS，并保存 `cpu-tests.log`。
- 对比上一轮 `.github/task-runs/2026-06-01-rv64-tlb-paged-cache/cpu-tests.log`：总 cycles `188587->183747`，weighted CPI `1.271->1.238`；无单项 cycles regression。
- 强制重建 `npc/rv64` Verilator 产物 PASS。
- `git diff --check` PASS。

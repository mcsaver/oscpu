# Dispatch Log

- 读取 `.github/AGENTS.md`、copilot instructions、project status、known issues、NPC/SoC module notes 及相关 RV64/Linux/optimization instructions。
- 定位 RV64 主路径：`OooFetchAxiBridge` 负责 Sv39 IFU page-walk 和 packet cache，`OooMemAxiBridge` 负责 LSU page-walk 和 word D-cache；发现分页开启时 LSU D-cache 仅在未翻译地址路径命中。
- 在 LSU bridge 增加 DTLB，并把 D-cache tag 切到最终物理地址；page-walk leaf 后填 DTLB，load miss 填 physical D-cache，store 更新/分配 physical D-cache。
- 在 IFU bridge 增加 ITLB，page-walk leaf 后填 ITLB，后续同页取指复用翻译并保持执行权限检查。
- 将 `ooo_mmu_flush_w` 接入 LSU bridge 的 `mmu_flush_i`，保证 `satp/sfence.vma` 清 DTLB。
- 新增 focused test：`tb_ooo_mem_axi_bridge` 覆盖首次 Sv39 walk + 第二次 DTLB/D-cache hit；`tb_ooo_sv39_boot` 增加 page-walk 次数断言。
- 全量 cpu-tests 初跑发现 `plic-sirq` 与 `uart-plic-sirq` 失败；排查确认不是 cache stale，而是测试仍写 `mideleg[MEI]`，与当前 CSR 的 `mideleg[SEI] -> SEIP` 决策不一致。
- 修正两个 S external interrupt 测试的 delegation 位并单项复测通过。
- 完成 focused testbench、强制 Verilator build、全量 cpu-tests 与 `git diff --check`。

# RV64 TLB And Paged Cache Optimization

## 背景

分页接入后，OoO RV64 主路径中的 IFU/LSU bridge 仍频繁为同页访问重复 page-walk，且 LSU 在分页开启时绕过既有 D-cache，导致 guest CPI 的大头集中在 Sv39 翻译和 AXI-Lite miss 串行化上。本轮先做低风险、局部可验证的优化，不一次性改 line-based cache 或 AXI 多 outstanding。

## 改动

- `OooFetchAxiBridge` 增加 64-entry direct-mapped ITLB，leaf PTE 填充后按 `satp + VPN + level` 命中，命中时重新检查取指权限并直接生成物理取指地址。
- `OooMemAxiBridge` 增加 64-entry direct-mapped DTLB，load/store 命中后以最终物理地址访问既有 D-cache；page-walk 后的 load 会填 physical D-cache，store 会更新或分配 physical D-cache。
- `NpcCoreTop` 将 `ooo_mmu_flush_w` 接到 LSU bridge 的 `mmu_flush_i`，`satp/sfence.vma` 会清 DTLB；IFU 既有 `mmu_flush_i` 同时清 ITLB。
- `plic-sirq` 与 `uart-plic-sirq` 修正为设置 `mideleg[SEI]`，与当前 `CsrFile` 外部中断 delegation 语义一致。

## 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_mem_axi_bridge tb_ooo_sv39_boot tb_axi_lite_plic tb_ooo_priv_system" RESULT_DIR=/tmp/rv64tb-cpi-opt LOG_DIR=/tmp/rv64tb-cpi-opt/logs run`: 4/4 PASS。
- `make -B -C npc/rv64 -j1`: PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc ALL=plic-sirq run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`: PASS, `cycles=401/commits=98/CPI=4.092`。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc ALL=uart-plic-sirq run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`: PASS, `cycles=460/commits=115/CPI=4.000`。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`: 56/56 PASS, `cycles=188587/commits=148426/weighted CPI=1.271`。
- `git diff --check`: PASS。

Focused Sv39 证据：`tb_ooo_sv39_boot` 打印 `sv39 page walks ifu=2 ifu_fault=1 lsu=1 lsu_fault=1 data_load=1 data_store=1`；`tb_ooo_mem_axi_bridge` 断言第二次同 VA 访问无 AXI AR，由 DTLB + physical D-cache 返回。

## 剩余方向

- 当前仍是 packet I-cache 和 word D-cache，尚未 line-based fill。
- page-walk cache 尚未单独实现；目前由 ITLB/DTLB 避免重复 walk。
- AXI-Lite xbar/bridge 仍是单 outstanding 串行 miss。
- `branch-fallthrough-save` 仍显示 jump wait 热点，`pc=0x80000040` 为 833 cycles、`pc=0x80000048` 为 129 cycles，后续应继续治理 JALR/return/flush 空退休。

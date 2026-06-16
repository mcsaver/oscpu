# Dispatch log

- 读取项目规范与 memory，确认必须先分析调用链/语义差异，再修改跨文件任务。
- 复现 `tb_ooo_alu_fetch_core` baseline：26 个失败，集中于旧 RV32/早期 OoO 语义。
- 对比当前 RV64 core 语义：
  - `EBREAK` 是实验壳退出。
  - `ECALL` 是架构 trap，跳 `mtvec`。
  - `MRET` 是合法 xRET 控制事件。
  - LSU 是 RV64 8-byte strobe。
  - `LUI 0x80000` 在 RV64 中会符号扩展，不适合作为 `0x8000_0000` 地址构造。
- 修改 `tb_ooo_alu_fetch_core.sv`：
  - 宽度、地址构造、ECALL handler、EBREAK 退出、fetch resp fault 编码、层次化观测点。
  - 删除旧 lane1 fetch-fault 集成断言。
- 第一次重跑后仅剩 semihost breakpoint trap 相关 4 个失败。
- 收敛首个 smoke case：不再用 semihost/MRET 做默认停止条件，改成普通 RV64 EBREAK exit。
- 验证通过：
  - `tb_ooo_alu_fetch_core` PASS。
  - 相邻 fetch/mem/priv/sv39 focused tests 4/4 PASS。
  - targeted `git diff --check` PASS。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md` 和本 task-run 记录。

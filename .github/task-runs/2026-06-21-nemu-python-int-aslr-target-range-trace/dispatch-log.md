# Dispatch Log

- 2026-06-21: 继续 NEMU-only PyLong/int [76] 根因定位，不从 `.github/db-backup` 取答案；DB doctor 历史 manual log 缺失和旧 shim stale 只作为非本轮噪声处理。
- 2026-06-21: 增加默认关闭的 `NEMU_FP_LOAD_TRACE`、vaddr/paddr value trace、pc-gpr FPR 扩展字段，并接入 preflight summary 与 `nemu-dev` e2e 合同。
- 2026-06-21: 通过 CPython `PyLong_FromString` PC trace 定位到 `log(10)` 返回 `-inf`，进而污染 base conversion table，再由 `fcvt.l.d` 产生 `INT64_MIN` 和坏 `ob_size`。
- 2026-06-21: 通过 libm `log` PC/FPR trace 定位到首次 `.rodata` 常量 `c.fld` page fault 后 FPR 状态未保存，`ft3/fa0` 被清零；结合 Linux `switch_to.h` 确认 `SR_SD` 是 FPU 保存判定。
- 2026-06-21: 修复 NEMU CSR 读路径，按 `FS=Dirty` 派生只读 `mstatus/sstatus.SD`。
- 2026-06-21: 验证 NEMU build PASS，`nemu-dev` SD CSR 合同 PASS，根因定点重型复跑 PASS，默认重型复跑 PASS。

# Dispatch Log

- 复核当前 Linux boot 缺口，确认 `CsrFile` 仅支持 `cycle/mcycle`，缺 `time/instret` 与 `mcounteren/scounteren`。
- 按 RTL 四段式推导 counter CSR 边界：需求、协议规则、状态机、不变量/数据路。
- 修改 `define.v` 与 `CsrFile.v`，增加 counter CSR、权限门控、`minstret` 和 inhibit 支持。
- 将 `NpcSimTop` 的 CLINT `mtime` 通过 `NpcCoreTop/OooAluFetchCore` 接入 CSRFile 的 `time_i`，并将 OoO retire count 接入 `instret_inc_i`。
- 新增 `counteren-time.c`，覆盖 S-mode 未授权 `rdtime` trap、M-mode 授权、S-mode counter 读递增。
- 串行执行 rv64 lint、`counteren-time`、focused testbench、rv64 build、`add` smoke、`counteren-time sbi-timer` 组合与空白检查。
- 更新 memory 与 task-run 记录。

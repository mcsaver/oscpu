# Dispatch Log

日期：2026-06-03

## 1. 现状复核

- `action`: 复核 `AxiLiteXbar.v`、相关 memory 和工作树状态。
- `finding`: 当前文件存在文件级 `UNUSEDSIGNAL` waiver；read grant 在 `S_COUNT*M_COUNT` 仲裁内层重复执行 `decode_slave(m_araddr[cand])`；write AW 侧已有 `awtarget_decode_r/wr_awtarget_q` 预译码/锁存结构。
- `decision`: 本轮只做 read-side 预译码与 helper 位宽清理，不改变 active/owner/drop-drain 状态机。

## 2. RTL 修改

- `action`: 在 `AxiLiteXbar` 中新增 `artarget_decode_r`，与 `awtarget_decode_r` 一起按 master 组合预译码。
- `action`: read grant 条件改为使用 `artarget_decode_r[cand]`。
- `action`: helper 函数索引入参从 `integer` 收窄为 `MASTER_W/SLAVE_W`，并移除文件级 `UNUSEDSIGNAL` waiver。
- `evidence`: `npc/rv64/vsrc/bus/AxiLiteXbar.v`

## 3. Lint 反馈

- `attempt`: 首次单模块严格 lint 暴露 `integer idx` 高位未使用。
- `root_cause`: 参数默认 `S_COUNT=1/M_COUNT=2` 时，helper 只消费低位索引；原文件级 waiver 掩盖了该参数化位宽问题。
- `fix`: helper 入参改为实际索引宽度，保留工程已有 `WIDTHEXPAND/WIDTHTRUNC` 抑制覆盖参数化调用扩展/截断。
- `evidence`: 单模块严格 lint PASS，且 `AxiLiteXbar.v` 不再包含 `UNUSEDSIGNAL` waiver。

## 4. 验证

- `command`: `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --top-module AxiLiteXbar npc/rv64/vsrc/bus/AxiLiteXbar.v`
- `result`: PASS
- `command`: `make -C npc/rv64 lint`
- `result`: PASS
- `command`: `make -C npc/rv64 -j2`
- `result`: PASS
- `command`: `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv`
- `result`: PASS，三个用例均 GOOD TRAP
- `command`: `git diff --check`
- `result`: PASS

## 5. 结论

- `final_result`: `AxiLiteXbar` read-side 重复译码已收敛为每 master 一次的组合预译码，文件级 lint waiver 已移除，现有 read abort/drop-drain 和 write AW/W 合并协议未改变。
- `remaining_risk`: 尚未完成 route queue、多 outstanding 或专用 xbar testbench；后续若优化 fetch refill 重叠，必须重新设计 xbar owner/response route，而不是局部硬接 ready/valid。

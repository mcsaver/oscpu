# Dispatch Log

## RECALL

- 读取并遵守 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/modules/npc.md`、RTL 生成与 NPC study 相关 instructions。
- 已知前序状态：OoO 基础件、issue/PRF/busy table、dispatch backend、ALU backend、decode adapter、arch commit slice 均已存在并通过独立 testbench，但默认 `NpcCore` 仍未被替换。
- 工作树存在与本轮无关的便携包修改和删除，未触碰。

## PLAN

1. 审计 `OooAluCoreSlice` 可接入接口和 IFU 读协议边界。
2. 新增 ALU-only fetch shell，先支持 32-bit 顺序双取指和受控 illegal/fetch fault 停机。
3. 写定向 testbench 覆盖双发、双提交、same-packet RAW/WAW、unsupported 停机。
4. 跑 lint、OoO 套件、全量模块回归、Verilator build 与 AM smoke。
5. 更新 memory 与 task-runs，保留 CPI 目标未完成的真实状态。

## DISPATCH

- 实现 `OooAluFetchCore` FSM：`FETCH0_REQ`、`FETCH0_WAIT`、`FETCH1_REQ`、`FETCH1_WAIT`、`DISPATCH`、`HALT`。
- lane0 使用 `packet_pc_q`，lane1 使用 `packet_pc_q + 4`；整包成功 fire 后 packet PC 前进 8。
- `commit_ready_i` 透传给 `OooAluCoreSlice`，双路 commit/debug/perf 信号直接对外暴露。
- unsupported branch 边界选择为 stop/trap，而不是误发到后端或做症状级跳过。

## ADAPT

- 初次 `make -C npc/single lint` 触发 Verilator `PINCONNECTEMPTY`，根因是新壳实例化 `OooAluCoreSlice` 时对未用输出使用空连接。已改为显式 unused wires 并聚合到 `unused_core_slice_observe_w`，lint 通过。
- Icarus 对 `OooIntIssueQueue` 数组选择继续打印既有 warning，不影响本轮 PASS 结果；未在本轮扩散修改已有 issue queue 逻辑。

## VERIFY

- `tb_ooo_alu_fetch_core`：PASS。
- OoO 定向套件：11/11 PASS。
- `make -C npc/single lint`：PASS。
- `npc/single/testbench run`：38/38 PASS。
- `make -C npc/single -j4`：PASS。
- `cpu-tests add`：GOOD TRAP，`cycles=1509`、`commits=838`、`CPI=1.801`。

## RECORD

- 更新 `.github/memory/project-status.md`。
- 更新 `.github/memory/modules/npc.md`。
- 新增本目录 `task-report.md` 与 `dispatch-log.md`。

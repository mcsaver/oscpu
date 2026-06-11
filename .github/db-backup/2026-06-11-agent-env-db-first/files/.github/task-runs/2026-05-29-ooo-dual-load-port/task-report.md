# OoO 双 load 读端口推进记录

## 目标

- 继续推进 `NPC_OOO_ALU_EXPERIMENT=1` 乱序超标量实验核，向完整 AM `cpu-tests add` 的 `CPI=0.5` 收敛。
- 在 `cycles=541/commits=839/CPI=0.645` 基线上验证 memory 端口是否仍是主要瓶颈。

## 本轮改动

- `OooIntIssueQueue` 放开受限的 `load+load` 双发射：仅两条都是 load 时允许同拍占用两个 memory read port，store 或 mixed memory 仍按原保守规则阻塞。
- `OooIntBackend` 增加 lane1 read-only `mem1` request/response 端口、独立 pending metadata、第二条 LSU response 格式化路径和双 memory response 写回仲裁。
- 双 load 只有在 lane0 load 确认能通过 port0 当拍 handshake 时才允许 lane1 load 走 port1，避免更年轻 lane1 load 越过被缓冲的更老 lane0 load。
- `OooAluDecodeBackend`、`OooAluCoreSlice`、`OooAluFetchCore`、`NpcSimTop` 透传第二 memory 端口；仿真顶层提供第二组一拍 memory response。
- 更新 focused tests，覆盖 issue queue 双 load 选择、backend 双 load request/response/dual commit，以及 wrappers 的第二 memory 端口连接。

## 验证证据

```sh
make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-dual-load-focused \
  /tmp/ysyx-ooo-dual-load-focused/logs/tb_ooo_int_issue_queue.log \
  /tmp/ysyx-ooo-dual-load-focused/logs/tb_ooo_int_backend.log \
  /tmp/ysyx-ooo-dual-load-focused/logs/tb_ooo_alu_fetch_core.log \
  /tmp/ysyx-ooo-dual-load-focused/logs/tb_ooo_dispatch_backend.log -B

make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-dual-load-focused \
  /tmp/ysyx-ooo-dual-load-focused/logs/tb_ooo_alu_decode_backend.log \
  /tmp/ysyx-ooo-dual-load-focused/logs/tb_ooo_alu_core_slice.log -B

make -C npc/single BUILD_DIR=/tmp/npc-ooo-dual-load NPC_OOO_ALU_EXPERIMENT=1 -j14

/tmp/npc-ooo-dual-load/NpcSimTop \
  am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000
```

- focused tests PASS：`tb_ooo_int_issue_queue`、`tb_ooo_int_backend`、`tb_ooo_alu_fetch_core`、`tb_ooo_dispatch_backend`、`tb_ooo_alu_decode_backend`、`tb_ooo_alu_core_slice`。
- 实验 OoO Verilator build PASS。
- AM `cpu-tests add` GOOD TRAP，结果为 `cycles=537/commits=839/CPI=0.640`。
- 相比上一稳定基线 `541/839/0.645`，本轮只减少 4 cycles。

## Trace 结论

- 新 trace：`mem req0/req1/rsp0/rsp1 = 95/62/95/62`，说明第二 read port 确实被使用。
- 提交分布：`commit_hist = {0:72, 1:101, 2:369}`。
- 单提交热点最高的是 `0x80000010 ret`，共 72 次；热路径是 `jal check -> beqz -> ret`。
- 现有 lane0 branch + lane1 return fast path 已能直接 redirect 到 RAS target，但 return 仍作为 pending lane1-ret 单 uop 进入后端并单独退休。继续优化需要设计可证明的 branch/ret pairing、synthetic control commit 或更细粒度 speculative/commit 协议，不能简单把 ready/commit 组合进现有路径。

## 后续方向

- 优先研究不引入 dispatch-ready 组合环的 `branch + lane1 ret` 控制流折叠。
- 若继续压 memory，应从真正 LSU response queue、多 outstanding、LSQ 和 commit-time store 入手；单纯再放宽 issue/buffer 对当前 AM add 收益很小。
- 当前完整 `CPI=0.5` 目标尚未完成，最新可信点是 `CPI=0.640`。

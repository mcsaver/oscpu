# RV64 fetch beat and trap-flush CPI pass

## 背景

用户指出剩余 guest CPI 大头集中在 packet/word cache、AXI-Lite miss 单 outstanding、以及 `branch-fallthrough-save`/JALR/return/flush 空退休。本轮选择先做低风险且能直接降低 IFU miss 串行化的改动：利用现有 64-bit AXI/DPI 取指 beat，一次 demand miss 同时返回 `PC` 与 `PC+4` 两条 32-bit 指令；同时修复该优化暴露出的同拍 commit exception 与年轻前端状态捕获冲突。

## RTL workflow

- Requirement: 降低当前 2-wide packet IFU miss 中 `PC`/`PC+4` 两次串行读造成的空等；不改变外部 IFU bridge 接口、不新增 outstanding；保持 Sv39/permission/page-fault 行为精确；治理 faster IFU 后暴露的 flush 空退休/年轻异常覆盖问题。
- Protocol: demand instruction miss 仍只发一个 AXI-Lite read request，但 read data 使用完整 64-bit beat，`rdata[31:0]` 对应 `PC`，`rdata[63:32]` 对应 `PC+4`；page-walk/direct fetch 协议不变。commit exception 是同拍精确屏障，不能再让 drain/dispatch 捕获更年轻 fetch fault 或 JALR 状态。
- FSM: `OooFetchAxiBridge` 的 demand path 从 `S_AR0 -> S_R0 -> S_AR1 -> S_R1 -> S_RESP` 收敛为 `S_AR0 -> S_R0 -> S_RESP`；原 `S_AR1/S_R1` 保留为不可达遗留状态。`OooAluFetchCore` 的 trap flush latch 保持到 backend drained，且 drain/dispatch capture 受 `!csr_trap_mem_valid_w` 保护。
- Invariants: 只有两个 halfword 对应的 response 都 OK 且总线 OK 时才填 I-cache packet；lane1 fetch fault 仍可独立报告；commit exception 优先级高于同拍 stop/drain/dispatch capture；`sfence.vma/satp` 既有 TLB/RAS/JALR 状态清理不放宽。
- Datapath: fetch beat 拆成 `inst0_q <= rdata[31:0]`、`inst1_q <= rdata[63:32]` 并写入 packet cache；`tb_ooo_sv39_boot` 的 fake instruction memory 改为返回 `{program_word(addr+4), program_word(addr)}`，匹配 64-bit beat。

## 改动

- `npc/rv64/vsrc/core/OooFetchAxiBridge.v`: demand fetch miss 使用单次 64-bit beat 填充两条指令，减少 packet miss 串行读。
- `npc/rv64/testbench/tests/tb_ooo_sv39_boot.sv`: instruction read64 mock 返回同 packet 双 word，覆盖新取指协议。
- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`: commit exception 同拍阻断 stop/drain/dispatch 年轻状态捕获；trap flush 保持至 backend drained。

## 验证

- Focused SV:
  `make -C npc/rv64/testbench -B TESTS="tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_priv_system" RESULT_DIR=/tmp/npc-fetch-beat-tb run`
  结果：3/3 PASS。
- RV64 build:
  `make -C npc/rv64 -j1`
  结果：PASS。
- Full cpu-tests:
  `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`
  结果：56/56 PASS。

## 性能 A/B

对比上一轮 direct RAS return 基线 `.github/task-runs/2026-06-01-rv64-direct-ras-ret/cpu-tests.log`：

| 项目 | direct RAS 基线 | 本轮 | 变化 |
| --- | ---: | ---: | ---: |
| total cycles | 183747 | 175112 | -8635 |
| total commits | 148426 | 148426 | 0 |
| weighted CPI | 1.237970 | 1.179793 | -4.7% |

代表收益：

- `bitmanip`: `1000 -> 542` cycles
- `stdio-format`: `2501 -> 2082`
- `hello-str`: `2259 -> 1856`
- `linux-mini-boot`: `18154 -> 17795`
- `mem-test`: `1016 -> 674`
- `quick-sort`: `3131 -> 2828`
- `recursion`: `6038 -> 5756`
- `branch-fallthrough-save`: `1597 -> 1502`

已知小回退：

- `bubble-sort`: `3225 -> 3266`，增加 41 cycles。完整 cpu-tests 仍 PASS，后续若继续做 line-based cache 时可复核其局部取指/分支画像。

## 剩余热点

- 当前还不是完整 line-based I/D cache：IFU demand miss 已利用 64-bit beat 形成 packet mini-line，但 D-cache 仍是 word 风格，I-cache 也未做多 beat line fill。
- AXI-Lite bridge 仍单 outstanding，未做 miss queue、response queue 或 xbar 并行化。
- direct return RAS 已消掉 `branch-fallthrough-save` 的 jump wait；`recursion` 剩余 `jump wait=2777` 主要来自非 return 间接 `jalr/jr` 函数指针路径，RAS 命中已是 `129/129`。下一刀若继续治理 jump wait，应做非 return JALR target prediction/BTB 或更系统的 squash/response queue，而不是再压 return fast path。

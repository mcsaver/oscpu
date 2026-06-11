# RV64 CoreMark CPI Dispatch Log

## 任务

- 用户给出 `riscv64-npc` CoreMark 默认 1000 iterations 结果：`cycles=1915750770`、`commits=318393500`、`CPI=6.017`，并要求压回 RV32 历史基线 `0.78/0.8` 左右后再交付。
- 当前仓库规范要求复杂 RTL 性能任务先定位 root cause、全量 CPU-tests 验证、记录同轮 `cycles/commits/CPI` 与任务证据链。

## 调度与分析

1. 读取工程规则与记忆：
   - `AGENTS.md`
   - `.github/AGENTS.md`
   - `.github/copilot-instructions.md`
   - `.github/instructions/npc-optimization-workflow.instructions.md`
   - `.github/instructions/rtl-generation-workflow.instructions.md`
   - `.github/memory/project-status.md`
   - `.github/memory/known-issues.md`
   - `.github/memory/modules/npc.md`
   - `.github/memory/modules/am-kernels.md`
2. 第一层根因定位：
   - `cpu-tests add` 的 RV64 in-order 路径 CPI 同样约 `6.018`，且 cache 统计全 0。
   - `define.v` 中 RV64 cacheable 范围未覆盖 `0x8000_0000`，等价于关闭 I/D cache。
   - ICache fill/line-byte 仍按 32-bit beat 计算，不满足 RV64 `XLEN=64`。
3. 第一层修复：
   - 恢复 PMEM cacheable 范围 `0x8000_0000..0x87ff_fffc`。
   - I/D cache line 改为 `8 x 64-bit beat`。
   - ICache refill stride 和 line byte select 改为 `XLEN_BYTE_W/XLEN_BIT_SHIFT`。
   - 结果：CoreMark 1000 从 `CPI=6.017` 降到 `CPI=1.274`，但仍未达到用户要求。
4. 第二层根因定位：
   - 默认 `NpcCoreTop` 仍走顺序核，天然无法低于 1 CPI。
   - 切到 `NPC_OOO_ALU_EXPERIMENT=1` 后 `add` 初始 BAD TRAP，说明 OoO RV64 路径尚不能作为默认性能后端。
   - OoO 后端缺 RV64 `*W` sign-extension、RV64M/W、RV64 bitmanip 和 8-bit `wstrb`/8-byte aligned memory path。
5. 第二层修复：
   - `OooIntBackend` 补 `ADDW/ADDIW/*W` sign-extend、RV64M/W 和 RV64 bitmanip 结果。
   - OoO memory path 的 request/response `wstrb` 扩到 `STRB_W=8`。
   - `OooMemAxiBridge` D-cache index/merge/full-store 判断按 8-byte word 与 8-bit strobe 处理。
   - `npc/rv64/Makefile` 默认启用已通过 RV64 全量测试的双发射 OoO 后端。

## RTL 推导摘要

- 需求：`riscv64-npc` 默认 CoreMark CPI 需要回到 `0.78/0.8`，同时保持 RV64 功能正确。
- 协议规则：
  - RV64 普通 PMEM 访问以 64-bit bus word/8-bit strobe 为基本 beat。
  - `OP-IMM-32/OP-32` 与 RV64M/W 的写回必须 sign-extend 低 32 位。
  - Zba/Zbb/Zbc/Zbs 在 RV64 下的 `clz/ctz/cpop/rol/ror/rev8/orc.b/clmul/*.uw` 宽度必须按 XLEN/OP-32 区分。
  - cache hit/miss 统计必须来自真实 RTL cache/bridge 事件，不应绕回 host cache。
- 状态机与不变量：
  - ICache refill 每个 beat 前进 `XLEN_BYTE_W` 字节，line 内 byte select 使用 `XLEN_BIT_SHIFT`。
  - OoO memory bridge 保持单 outstanding 所有权，load/store merge 只在对应 8-byte word 内发生。
  - Store full-word 判断从 `4'b1111` 改为 `{STRB_W{1'b1}}`，避免 RV64 SD 被误判为非完整写。
  - OoO 默认化前必须先让 cpu-tests 全量通过，不能只凭 CoreMark 或 `add` 判断。
- 数据通路约束：
  - `mem_req_wstrb_o/mem1_req_wstrb_o/lsu_axi_wstrb_o` 全链路同宽为 `STRB_W`。
  - D-cache index 使用 `addr[DCACHE_INDEX_W+XLEN_BYTE_W-1:XLEN_BYTE_W]`，低 3 位只作为 lane/byte offset。
  - `rv64_word_alu_result`、`rv64m_result` 和 `rv32b_result` 必须共同覆盖 RV64 `*W`、M/B 扩展写回语义。

## 关键验证

- `make -C npc/sim BACKEND=rv64 NPC_OOO_ALU_EXPERIMENT=1 lint` PASS。
- `make -C npc/sim BACKEND=rv64 NPC_OOO_ALU_EXPERIMENT=1 -j4` PASS。
- `ARCH=riscv64-npc ALL=bitmanip` PASS，`cycles=797`、`commits=306`、`CPI=2.605`。
- 默认重建：
  - `make -C npc/sim BACKEND=rv64 clean`
  - `make -C npc/sim BACKEND=rv64 lint`
  - `make -C npc/sim BACKEND=rv64 -j4`
  - PASS，构建命令含 `-DNPC_OOO_ALU_EXPERIMENT`。
- 默认 `ARCH=riscv64-npc ALL=add` PASS，`cycles=755`、`commits=839`、`CPI=0.900`。
- 默认 cpu-tests 全量 `40/40 PASS`：
  - 平均 CPI `1.414`
  - 最高 `dummy`：`cycles=46`、`commits=12`、`CPI=3.833`
  - 最低 `shuixianhua`：`cycles=3429`、`commits=6077`、`CPI=0.564`
  - 近平均 `hello-str`：`cycles=2128`、`commits=1510`、`CPI=1.409`
- 默认 CoreMark 1000 PASS：
  - 命令：`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=1000 run NPC_RUN_ARGS="--no-progress --max-cycles 1000000000"`
  - `CoreMark PASS 8 Marks`
  - `cycles=247287515`
  - `commits=317356136`
  - `CPI=0.779`
  - I-cache `access=172654949`、`hit=171394450`、`miss=1260499`
  - D-cache `access=68500747`、`hit=68000703`、`miss=450408`

## 注意

- 最终性能验证基于当前生成配置，日志显示 `Difftest: OFF`；本次目标是 guest-cycle CPI，DiffTest 开关主要影响 host 运行时间，不改变 RTL guest cycle 计数。

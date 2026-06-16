# OoO RVC fetch 与真实 next_pc

## 目标

让 `NPC_OOO_ALU_EXPERIMENT=1` 实验 OoO 核心能从 raw smoke 进一步运行 AM `cpu-tests add` 这类默认带 RVC 的镜像。当前首个失败点是 `0x8000000c` 的 `c.jal` 与 `c.beqz` 半字指令包被前端当成一条 32-bit 非法指令，触发 `EXC_ILLEGAL_INST`。

## RTL 四阶段记录

### 1. 需求

- OoO 实验前端支持从 64-bit fetch window 中最多解出两条 RV32I/RVC 指令。
- RVC 先解压成既有 `DecodeStage` 可消费的 32-bit 指令，避免复制后端译码语义。
- 每条 uop 必须携带真实 `pc` 与 `next_pc`；`c.jal/c.jalr` 写回 link 时不能再使用固定 `pc+4`。
- 分支 synthetic commit、jump/memory drain barrier、commit 对外边界都使用真实 `next_pc`。
- 本轮不新增预测/checkpoint/LSQ；control 与 memory 仍保留当前精确 drain barrier。

### 2. 协议/状态机/不变量

- fetch request PC 为下一条指令 PC，允许半字对齐；response 提供从该 PC 起的两个 32-bit word，组成四个连续 halfword。
- lane0 从 window offset 0 解码；若低两位不是 `2'b11`，长度为 2 并调用 RVC 解压，否则长度为 4 并使用完整 word0。
- lane1 PC 等于 `lane0_pc + lane0_len`；它从 offset 2 或 offset 4 取 halfword，必要时把 offset 2 的跨 word 32-bit 指令组装为 `{word1[15:0], word0[31:16]}`。
- packet 下一取指 PC 等于 `lane1_pc + lane1_len`；前端同拍接收 response 并发下一 request 时，request PC 必须使用刚解出的 packet next PC。
- fetch fault 精确到 lane：
  - lane0 依赖 word0 response。
  - lane1 若只使用 word0 高半字 compressed 指令，则不依赖 word1 response。
  - lane1 若从 word1 开始或是 offset 2 的 32-bit 跨 word 指令，则依赖 word1 response。
- 不变量：
  - FIFO head 的 lane0/lane1 PC 单调递增，增量只可能是 2 或 4。
  - 后端 WBU 的 `pc_plus4_i` 实际接入 uop `next_pc`，名称沿用既有接口但语义变为 link/seq PC。
  - ROB commit 输出的 `next_pc` 与对应 dispatch uop 一起入队、按序提交。

### 3. 数据通路

- `OooAluFetchCore` 复用/内嵌 `IfStage` 的 RVC 解压 helper，将 fetch response 解成 `inst0/inst1`、`pc0/pc1`、`next_pc0/next_pc1`、`packet_next_pc`。
- fetch FIFO 新增 lane1 PC、lane0/lane1 next PC 和 packet next PC 字段；现有 resp 字段改为“解码后 lane fault response”。
- `OooAluCoreSlice`、`OooAluDecodeBackend`、`OooIntBackend`、`OooDispatchBackend`、`OooIntIssueQueue` 贯通 dispatch/issue `next_pc`。
- `OooRob` 保存并提交 `next_pc`，供实验顶层对外 commit next_pc 使用。
- jump pending 和 memory pending 保存对应 uop 的 `next_pc`；branch fallthrough 使用 pending branch 的真实 `next_pc`。

### 4. RTL 修改计划

- 在 `OooAluFetchCore` 增加 RVC 解压与 2-wide variable-length packet predecode。
- 把所有 `head_pc_w + 32'd4/8` 的 lane/packet 语义替换为 FIFO 中保存的真实 PC/next PC。
- 将 `next_pc` 贯通后端 issue/WBU/ROB/commit 接口，并更新相关 testbench 实例化。
- 增加/调整 `tb_ooo_alu_fetch_core` 覆盖 RVC `c.jal`/`c.beqz` packet；回归 OoO module、实验 AM add、默认主线。

## 验证记录

- `make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-rvc-tb /tmp/ysyx-ooo-rvc-tb/logs/tb_ooo_alu_fetch_core.log` PASS；新增 `c.addi + c.jal + c.ebreak` 半字 packet 覆盖，确认 `c.jal` link 为 `PC+2`，半字 fallthrough 未执行。
- `make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-rvc-module summary` PASS，模块回归 `38/38`。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint` PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 default` PASS。
- 实验 OoO 路径运行默认 RVC 版 `cpu-tests add` GOOD TRAP：`pc=0x800000b4`、`cycles=3647`、`commits=839`、`CPI=4.347`。
- raw 4096 独立 ALU smoke 仍 GOOD TRAP：`pc=0x80004000`、`cycles=2055`、`commits=4096`、`CPI=0.502`。
- `make -C npc/single lint` PASS。
- `make -C npc/single clean && make -C npc/single default` PASS；确认切回默认构建。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="--no-progress -m 200000"` PASS / GOOD TRAP：`cycles=1509`、`commits=838`、`CPI=1.801`。

## 结果与限制

- 本轮把实验 OoO 从 raw 片段推进到能跑完默认 AM RVC `add` 程序，消除了首个真实镜像失败点 `0x8000000c: c.jal` 被误判非法指令的问题。
- 后端现在以每条 uop 的真实 `next_pc` 作为 jump link/commit next_pc，RVC `c.jal/c.jalr` 不再落入固定 `pc+4` 假设。
- raw 独立 ALU 吞吐仍保持接近双发上限的 `CPI=0.502`。
- AM `add` 在实验 OoO 下目前 `CPI=4.347`，说明 control/memory drain barrier 仍是主要瓶颈；后续要靠 branch/jump checkpoint/rollback、RAS/BTB/BHT 接入、LSQ/store-commit 和真正可综合宽 I-cache 继续向完整 OoO 收敛。

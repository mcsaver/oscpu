# RV64 bitmanip count-tree cleanup

## 范围

- 修改 `npc/rv64/vsrc/ooo/backend/OooIntBackend.v`。
- 修改 `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`，增加 direct Zbb count 类覆盖。

## 四段式推导

- 需求：保持 bitmanip 一拍执行和 OoO 后端协议不变，把 `clz/ctz/cpop` 从 64 次循环扫描/累加改成更清晰的分层组合树，降低组合链审查风险。
- 协议规则、状态机、不变量：`CTRL_BITMANIP_BIT`、issue lane 选择、WBU/ROB 提交、forwarding 均不变；不新增状态；必须保持 `clz(0)=64`、`ctz(0)=64`、`cpop` 准确计数和双 lane 互不影响。
- RTL：新增 `bitmanip_clz8`、`bitmanip_ctz8`、`bitmanip_popcount8`、`bitmanip_clz64`、`bitmanip_ctz64`、`bitmanip_cpop64`。`clz/ctz` 通过 byte priority mux tree 选择首个非零 byte 并加 offset；`cpop` 通过 byte popcount 与两级加法树求和。`bitmanip_result()` 的 `imm5=0/1/2` case 改为调用这些 helper。
- 验证：跑后端 direct TB、decode/fetch 集成 TB、AM bitmanip、lint、build、Linux focused smoke、结构搜索、活动 RTL waiver 扫描和 whitespace 检查。

## 验证记录

- `make -C npc/rv64/testbench TESTS=tb_ooo_int_backend RESULT_TIMESTAMP=20260603-rv64-bitmanip-count-tree run`: PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_int_backend tb_ooo_alu_decode_backend tb_ooo_alu_fetch_core" RESULT_TIMESTAMP=20260603-rv64-bitmanip-count-tree-integ run`: all PASS。
- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL=bitmanip run NPC_RUN_ARGS="--no-progress --max-cycles 8000000"`: PASS，`cycles=638/commits=358`。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user-sv39-halfword`: all GOOD TRAP；采样分别为 `41/16`、`192541/122893`、`637/88`、`362/134`。
- `rg -n "5'h00: begin|5'h01: begin|5'h02: begin|bitmanip_result = 64'd64|bitmanip_result = bitmanip_result \\+" npc/rv64/vsrc/ooo/backend/OooIntBackend.v`: 无命中。
- `rg -n "bitmanip_clz64|bitmanip_ctz64|bitmanip_cpop64|for \\(i = 0; i < 64|for \\(i = 1; i < 64" npc/rv64/vsrc/ooo/backend/OooIntBackend.v`: 新 helper 命中；剩余 64 次循环限定在 Zbc `clmul/clmulr/clmulh` case。
- `rg -n "UNOPTFLAT|UNUSEDSIGNAL|BLKSEQ|lint_off|lint_on" npc/rv64/vsrc -g "*.v" -g "*.sv" | rg -v "[/\\\\]legacy[/\\\\]"`: 无命中。
- `git diff --check`: PASS。

## 边界

- 本轮不改变 bitmanip latency，也不引入独立 bitmanip 长延迟单元。
- `clmul/clmulr/clmulh` 仍是组合循环，后续若继续 PPA 收敛应单独处理。
- 没有跑综合/STA/功耗工具，不能声明最终 PPA signoff。

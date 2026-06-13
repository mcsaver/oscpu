# 2026-06-03 RV64 CLMUL Iter Unit Dispatch Log

## Context

- 目标：继续按商业 ASIC RTL 风格收敛 RV64 `OooIntBackend`，本轮聚焦 Zbc `clmul/clmulh/clmulr`。
- 旧实现：三条指令在 `bitmanip_result()` 内使用 64 次函数循环和变量位选择，形成一拍大组合 carry-less multiply。
- 约束：保持 ISA 语义、OoO 后端提交协议、WBU/ROB 写回边界；可按验证需要修改 testbench。

## Derivation

- 需求：把功能仿真式 CLMUL 组合循环替换为面积/时序更可控的 RTL 结构。
- 协议规则：CLMUL 从普通一拍 bitmanip helper 中拆出，`OooIntBackend` 通过 `req_valid/req_ready` 启动长操作，response 携带 `rob_idx/pdest/data` 回到既有 writeback mux；lane0 优先，lane1 在同拍 lane0 CLMUL 时等待；flush/checkpoint restore 清 in-flight。
- 状态机：`OooClmulUnit` 为 `IDLE/RUN/RESP`，RUN 固定 64 step，RESP 保持到 ready。
- 不变量：单元内最多一个请求；zero operand 结果为 0；`clmul/clmulh/clmulr` 等价原参考循环；flush 后无旧 response；CLMUL 不可被 issue queue 当作普通 ALU 结果 forward。
- 数据通路约束：每拍一次 bit test、条件 xor、固定方向寄存器移位；运行态无 64-way variable select/循环展开。

## Implementation Notes

- 新增 `npc/rv64/vsrc/ooo/backend/OooClmulUnit.v`。
- `OooIntBackend.v` 删除 CLMUL 组合循环，新增 CLMUL op decode、ready/valid 接入和 writeback response mux。
- `filelist.mk` 与 `testbench/Makefile` 纳入新 RTL/TB。
- 新增 `tb_ooo_clmul_unit.sv`；扩展 `tb_ooo_int_backend.sv` 覆盖真实后端 CLMUL。
- `OooIntIssueQueue.v` 的 `ctrl_can_forward()` 新增 `ctrl_muldiv/ctrl_clmul` 门控，避免 CLMUL producer 的消费者读到未完成旧值。
- `tb_ooo_int_issue_queue.sv` 新增 CLMUL 非 forward 覆盖，并修正建队列场景里对独立 lane1 backpressure 的期望。

## Verification

- `make -C npc/rv64/testbench TESTS=tb_ooo_int_issue_queue run`：PASS。
- `make -C npc/rv64/testbench TESTS='tb_ooo_int_issue_queue tb_ooo_clmul_unit tb_ooo_int_backend tb_ooo_alu_decode_backend tb_ooo_alu_fetch_core' run`：5/5 PASS。
- `git diff --check -- <本轮相关文件>`：PASS。
- 静态扫描 `for (i = [01]; i < 64|src1 << i|src1 >>`：后端仅命中 rotate 可变移位，未命中 CLMUL 组合循环。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C am-kernels/tests/cpu-tests ... ALL=bitmanip ...`：PASS，GOOD TRAP，`cycles=815/commits=358`。
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user-sv39-halfword`：全部 GOOD TRAP，分别为 `41/16`、`192541/122893`、`637/88`、`362/134`。


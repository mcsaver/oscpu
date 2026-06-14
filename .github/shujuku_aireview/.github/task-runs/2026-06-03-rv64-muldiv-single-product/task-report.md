# RV64 MulDiv single-product PPA cleanup

## 范围

- 修改 `npc/rv64/vsrc/ooo/backend/OooMulDivUnit.v`。
- 修改 `npc/rv64/testbench/Makefile`，把 direct MulDiv TB 纳入 testbench 入口。
- 新增 `npc/rv64/testbench/tests/tb_ooo_muldiv_unit.sv`。

## 四段式推导

- 需求：把 `OooMulDivUnit` 中功能仿真式三路并行乘积收敛为更适合 ASIC 面积/时序审查的单路已选乘积，同时保持模块协议、payload、乘法一拍响应和既有除法迭代行为。
- 协议规则、状态机、不变量：request 只在 `IDLE` fire；乘法仍下一拍 `RESP`，除法仍 `DIV_RUN` 迭代后 `RESP`；`resp_valid_o` 等待 `resp_ready_i`；reset/flush 清旧状态；低半乘法不依赖 signedness，高半乘法必须按 funct3 精确选择 signedness；busy 期间新 start 被拒绝。
- RTL：`mul_result()` 先从 funct3 推导 `mul_op1_signed/mul_op2_signed`，再构造唯一的 `mul_op1_ext/mul_op2_ext`，只计算 `selected_prod` 一个 `2*XLEN` 乘积，最后选择低半、高半或 W 型 sign-extension。删除 `ss_prod/su_prod/uu_prod` 三路并行乘积。
- 验证：新增模块级 TB 覆盖 multiply signedness、W 型、除法 corner、busy/flush 协议；再跑后端集成、lint、全量 build、Linux smoke、结构搜索、waiver 扫描和 whitespace 检查。

## 验证记录

- `make -C npc/rv64/testbench TESTS=tb_ooo_muldiv_unit RESULT_TIMESTAMP=20260603-rv64-muldiv-single-product run`: PASS。
- `make -C npc/rv64/testbench TESTS='tb_ooo_int_backend tb_ooo_alu_decode_backend tb_ooo_alu_fetch_core' RESULT_TIMESTAMP=20260603-rv64-muldiv-single-product-integ run`: all PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C Linux/tools smoke-muldiv smoke-jal-link smoke-branch-raw smoke-sret-user-sv39-halfword`: all GOOD TRAP。
- 精简采样：`smoke-muldiv 637/88`，`smoke-jal-link 41/16`，`smoke-branch-raw 192541/122893`，`smoke-sret-user-sv39-halfword 362/134`。
- `rg -n "ss_prod|su_prod|uu_prod|selected_prod|mul_op[12]_signed|mul_op[12]_ext" npc/rv64/vsrc/ooo/backend/OooMulDivUnit.v`: 旧三路 product 名称无命中，新 `selected_prod` 与符号扩展选择命中限定在 `mul_result()`。
- `rg -n "UNOPTFLAT|UNUSEDSIGNAL|BLKSEQ|lint_off|lint_on" npc/rv64/vsrc | rg -v "[/\\]legacy[/\\]"`: 无命中。
- `git diff --check`: PASS。

## 边界

- 本轮减少的是乘法组合资源复制，不改变乘法对外一拍响应，也不改变除法 latency。
- 该实现仍是组合乘法器，不是迭代乘法器或流水乘法器。
- 没有跑综合/STA/功耗工具，不能声明最终 PPA signoff。

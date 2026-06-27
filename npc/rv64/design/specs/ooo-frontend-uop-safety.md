# OoO Frontend Uop Safety Policy

## 1. 需求

`OooFrontendUopSafety` 负责把前端中多处重复的“普通 uop 是否可安全用于 fast path”组合白名单收敛为一个可复用 helper。

使用场景包括：

- lane1 return fast path 前，检查 lane0 是否不会破坏 return 源寄存器或进入复杂控制边界。
- JAL return-continuation capture，检查 lane1 是否是可延后重放的普通 uop。
- branch fallthrough/target append candidate，检查附带的 slot 是否适合作为普通 uop。
- branch prefetch packet 转正/直接派发候选，检查预取 packet 的两个 slot 是否都是普通 uop。

本模块只判断组合安全谓词，不产生 dispatch、redirect、trap、flush 或 commit 动作。

## 2. 协议

输入：

- `ctrl_i` 是 DecodeStage 输出的控制总线。
- `resp_i` 是对应 slot 的 fetch response code。
- `inst_i` 是对应 slot 的 32-bit 指令，用于可选排除 semihost marker。
- `rd_i` / `hazard_rs_i` 用于可选的 rd-vs-rs RAW hazard 检查。

参数：

- `REQUIRE_RESP_OK`：为 1 时要求 `resp_i == 2'b00`。
- `REJECT_SEMIHOST_ENTER`：为 1 时排除 `32'h0010_0073`。
- `ALLOW_*`：控制 load/store/muldiv/bitmanip/sfence/sret/amo 是否允许通过。
- `CHECK_RD_HAZARD`：为 1 时，若 `ctrl_i` 会写非 x0 且 `rd_i == hazard_rs_i`，则不安全。

输出：

- `safe_o` 为最终组合白名单结果。

## 3. 状态机

本模块无状态、无 ready/valid、无时序元素。参数只定义组合过滤规则。

## 4. 不变量

- 必须始终要求 `CTRL_VALID`、非 `CTRL_ILLEGAL`、`CTRL_NEED_EXEC`。
- 必须始终拒绝 branch/JAL/JALR、ecall/ebreak/system/CSR/fence/misc-mem/mret/wfi。
- 不改变 DecodeStage 对 illegal、CSR、system、AMO、FP 等控制位的定义。
- 不读取或修改 RAS、FIFO、ROB、CSR、branch predictor 或 outstanding fetch 状态。
- 实例参数必须保留原 `OooAluFetchCore` 各 fast path 的差异，不能为了合并而扩大或缩小旧白名单。

## 5. 当前实例映射

- lane0-before-ret：允许 load/store，禁止 muldiv/bitmanip/sfence/sret/amo，并启用 rd hazard 检查。
- return-continuation：禁止 load/store/muldiv/bitmanip，保持旧逻辑不单独禁止 sfence/sret/amo。
- branch fallthrough / branch target capture：要求 resp OK，排除 semihost marker，允许 load，禁止 store/muldiv/bitmanip，保持旧逻辑不单独禁止 sfence/sret/amo。
- branch prefetch dispatch candidate：要求 resp OK，禁止 store/sfence/sret/amo，保持旧逻辑允许 load/muldiv/bitmanip。

# OoO Fetch Branch Target

## 1. 需求

`OooFetchBranchTarget` 计算当前 fetch response 中一个已解压条件分支的 RV64 PC-relative
目标。模块只接受 64-bit PC 与原始 13-bit B-type immediate，消除跨模块 64-bit
sign-extended immediate 的无语义扇出，同时保持目标逐位等价。

## 2. 接口契约

- `pc_i[63:0]`：该 slot 的指令 PC。
- `bimm_i[12:0]`：`{inst[31],inst[7],inst[30:25],inst[11:8],1'b0}`。
- `target_o[63:0]`：必须等于 `pc_i + {{51{bimm_i[12]}},bimm_i}`，按 RV64 模 2^64。
- `valid_i`、`clk`、`rst` 只供 `OOO_ASSERT` 下的非真空立即断言采样；不参与综合 target
  数据通路，不形成握手或状态。
- 模块无 ready/backpressure、异常、访存、flush/redirect 或架构副作用。

## 3. 状态与时序

模块无寄存器和 FSM，target 是 0-cycle 纯组合 view。reset/stall/flush 不清理或保持任何
内部状态；当 `valid_i=0` 时 target 仍是确定组合值，但没有消费语义。

数学分解：

```text
low_sum[12:0] = {1'b0,pc_i[11:0]} + {1'b0,bimm_i[11:0]}
target_o[11:0] = low_sum[11:0]
target_o[63:12] = pc_i[63:12]
                  + zero_extend_52(low_sum[12])
                  - zero_extend_52(bimm_i[12])
```

## 4. 不变量

- 对任意 PC 与全部 13-bit immediate，上式逐位等价于 RV64 sign-extended reference add；
  对合法 B-type immediate，bit0 必为 0、范围为 -4096..4094。
- `pc[11:0]+imm[11:0]` 的 carry 与 sign 相等时页号不变；`carry=1/sign=0` 页号 +1；
  `carry=0/sign=1` 页号 -1。52-bit 运算自然覆盖地址高位 wrap。
- 不允许把 `bimm_i[12]` 复制成 XLEN 宽跨模块 operand；predictor 只消费 decoder bit12。
- lane0/lane1 各自实例化，不共享或串接 PC/immediate payload。

## 5. 验证合同

- immediate assertion `[FETCH-BRANCH-TARGET-EQUIV]` 使用独立 wide-reference，只在
  `OOO_ASSERT` 仿真中存在；mutation 必须证明它能响。
- module TB 覆盖正/负、carry/borrow、±4KiB 边界、PC 高位 wrap 与随机 case。
- task-run 穷举全部 16777216 个 low-PC/immediate 组合，并以 source/netlist checker 拒绝
  wide ABI、空路径与旧网表冒充 fresh。
- 本模块只证明算术等价；不能替代 fetch response、BPU、FIFO、outstanding 或全核 STA。

# R3 capability-aware terminal steering candidate

## 结论

本候选删除的是“issue0/issue1 等于程序序 lane0/lane1”的永久语义，不复制第二套 LSU：

- Universal terminal（现有 `issue0` 物理端）可承载 control、memory、long-op、simple ALU。
- ALU terminal（现有 `issue1` 物理端）只承载 fixed-latency simple ALU。
- 当 older simple ALU 后面出现 ready complex uop 时，IQ 原子交换 terminal：complex → Universal，older ALU → ALU terminal。
- ROB index、pdest、PC 和完整 payload 随 entry 路由，退休仍完全由 ROB head 决定。

这不是把 memory tie-off 冒充双发：来自原 dispatch1/年轻程序序位置的 store 已在完整 IntBackend 测试中实际路由到 Universal reservation；older ALU 同拍在 ALU terminal formal-WB。store 随后只产生一次 probe、一次 SQ/physical request 和一次 ROB terminal。

## PPA 约束下的实现

- 不增加 LSU、AGU、MIQ、SQ、memory request 或 writeback 端口。
- 每个 IQ entry 增加 1 bit `alu_terminal_capable_q`，在 dispatch 时预解码并随 compaction 移动，避免 select critical path 重复解码宽 `ctrl` bus。
- select 只增加 capability swap 的 index assignment。
- memory admission 采用最小安全放宽：只有 IQ 中恰好一条更老、ready、ALU-terminal-capable uop 时，年轻 memory 才能与它原子成对；其他 older-valid 情况仍阻塞，memory-memory 程序序保持不变。
- 该限制避免 memory reservation 占用后反向阻塞尚未完成的 older branch/long-op。

## RED → GREEN 证据

测试矩阵覆盖 branch、JAL、JALR、load、store，各自两种程序顺序。通过要求两个 resident uop 在同一周期分别出现在 Universal/ALU terminal；串行 promotion 不算通过。

- test-only RED：五个 `older ALU → younger complex` 场景共 20 个精确检查失败；五个反向顺序通过。
- GREEN：十个方向全部同周期双 terminal，队列下一沿完全 drain。
- 完整回归：`tb_ooo_int_issue_queue`、`tb_ooo_dispatch_backend`、`tb_ooo_int_backend` 均精确 `[PASS]` / `[RESULT] PASS`。
- IntBackend 新 directed 检查证明 `older ALU + younger store` 同拍离开 IQ，ALU 从 WB1 exactly-once 完成，store 从单槽 reservation exactly-once 完成，并按 ROB 顺序退休。

## 保持的不变量

1. 同一 IQ entry 不会同时占两个 terminal。
2. ALU terminal 永远不产生 LSU/request/MIQ owner；这是物理资源 capability，不是程序序 lane 限制。
3. memory 只从 Universal 进入现有 registered reservation。
4. reservation capture、request consume、branch kill/flush 路径未复制或旁路。
5. memory-memory 程序序和 AMO ROB-head admission 未放宽。
6. ROB in-order retire、exception precise、exactly-once completion 仍由现有 ROB/SQ/MIQ 合同承担，完整后端回归已通过。

## 尚未覆盖/不得宣称

- 按要求未运行 Linux、综合或 STA，因此此 patch 只是功能候选，不能宣称 200 MHz 或 PPA 获胜。
- 尚未实现 older unresolved store 后的 nonalias load bypass/alias forwarding directed gate。
- occupied memory reservation 期间，单独一条 younger simple ALU 仍可能因 Universal blocked 而等待；后续可用显式 registered terminal-availability/capability credit 修复，不能让 valid 组合依赖 ready。
- branch/JAL/JALR 的双顺序在 IQ 级有 directed evidence；本轮完整 backend regression 证明整体兼容，但没有为每一类都新增独立端到端 resolve 测试。

## 快照和应用

- canonical HEAD：`31e90c679050a3a9138c967151b240f0fa2ab158`
- isolated current-working snapshot commit：`e058e38681f541e42e1da29813ab8c5d078dbafe`
- candidate patch SHA-256：`a99e1a8c71ed0534c4c59524fdb98fe90b1e041effd102fb0e4c873c39707132`
- `git diff --check`：PASS

在 R2 frozen synthesis 完成且 canonical source 解冻后，从 canonical workspace 根目录应用 candidate patch；应用前应确认四个目标文件仍与快照基线一致或先做三方合并。

# v8p 任务报告：双普通整数访存 terminal owner 与审查状态隔离

## 本轮结果

当前完整 `vsrc` 摘要
`sha256:913023efa40ab33e4505bde3561a9fce3b392b3b44c90c8f3e5bbc9ab67195de`
上，`DI-3 pair_matrix` 已获得限定 GREEN。普通整数 LL/LS/SL/SS
可以在同一拍从 resident IQ 形成两个真实 issue fire、两个原子 tracker
birth、两个非 fall-through reservation owner 和两个独立 captured-data AGU；共享
request、translation、cache、MIQ 与 response 仍保持串行。

同摘要的 `DI-4`、`OOO-1`、`OOO-2` 由 fresh sibling rerun 保持 GREEN。
`DI-1`、`DI-2`、`DI-5`、`OOO-3`、`OOO-4` 和 overall 继续 RED，PPA
没有 promotion 资格。本轮结论不能解释为完整双端口 LSU、完整 OoO 或 PPA 达标。

## 实现闭环

- IQ 为每个 resident entry 保存独立的 ordinary integer memory capability；AMO、
  LR、SC、FP load/store 不具备该 capability。
- packed-age selector 可把两个合法 memory entry 分别送到 terminal0/terminal1；
  双请求只有在两个 tracker credit 同时可用时才原子 fire 和 birth。
- backend 保存两个完整 payload/full ProducerId/token reservation Q，并由两个只读
  捕获数据的 LSU/AGU 计算地址；live raw source 扰动不能改变已捕获地址。
- bank0 是 pair 中较老 owner。bank1 只有在 edge-old bank0 无效时才能消费，进入
  shared request 的仲裁也保持 bank0 优先。
- store-store 同沿通过 SQ `owner_bind0/owner_bind1` 按 full ProducerId 精确命中两个
  entry；七入口 terminal collector 在双 dequeue stall 下保存 exact-live tuple 并
  exactly-once 排空。

## 可执行证据

固定入口为：

`make -C npc/rv64 check-pair-matrix`

该入口独立运行 release/`OOO_ASSERT` 的 backend、tracker、七入口 collector 和 SQ，
共 8/8 baseline；15 个双发射矩阵 key 全部命中，LL/LS/SL/SS 四类各有真实双 fire，
10 个特殊访存排列全部排除，四对事务携带八个互异且 generation 非零的 full
ProducerId。15 个 compile-success/elaborated/activated 定向变异均由专属 oracle
拒绝，包括部分 birth、token alias、bank1 空壳或 raw fall-through、AGU1 复制、
SQ bind 丢失/交叉、特殊访存误接纳、年龄越过、PID 截断、取消泄漏和 checker
vacuity。architecture checker 及 manifest 共 28 个单测通过；完整非 focused backend
release/assert 也分别通过。

证据 manifest 只包含同摘要的 `pair_matrix`、`no_static_lane_semantics`、
`selective_scheduling`、`true_ooo_long_latency`，发布后 GREEN 集合精确为
`{DI-3, DI-4, OOO-1, OOO-2}`，overall 保持 RED。

## 独立审查

实现审查使用已校验的原生 `self-contained-no-tools` JSON 契约：

- 路径：`subagent-contracts/v8p-dual-memory-implementation-review.json`
- SHA-256：`afb5c8ab14f0fe23c03d5bf629ed59282c143abbdff7832387a11b1b3dcb148c`
- 权限：无工具、无 shell、无文件访问、无网络、无账号/凭据、无写入。

reviewer 的严格结论为 `pass`、blockers 为空；部分 birth、身份泄漏、第二 AGU
空壳、特殊访存误接纳、bank1 年龄越过、SQ 错绑、取消丢失、未激活变异、空壳
checker 和跨摘要/越级发布反例均被现有可执行证据拒绝。审查文本只作为独立挑战
记录，不替代仿真、变异、静态 checker 或同摘要 provenance。

## 工作流固化与受阻分流

仓库入口、path-specific instruction、`prepare-rtl-task-contract` skill、canonical
JSON contract 与 `agent-system` e2e gate 已统一以下规则：

1. 子任务只描述本地 RV64 Verilog/SystemVerilog 设计、验证、PPA 或独立反例复核，
   不把减少平台检查或改变分类结果写成目标。
2. 冻结材料足够时使用原生 `prompt-supplied-self-contained` 模式；JSON 必须精确为
   `allowed_commands=[]`、`write_paths=[]`，来源路径只作 provenance，提示内直接给出
   全部事实和合同 JSON 的路径/SHA。
3. Windows/Codex→WSL 工程命令由主 agent single-flight 串行执行；子 agent 只并行
   无 shell 推理，不共享工作树写权限。
4. reviewer 的可操作反例必须转成 spec、定向 TB、compile-success mutation 或
   fail-closed checker；自然语言意见不能直接把硬门置绿。
5. 平台不展示或不处理某个合法审查时，只把该节点记为 `review_pending`，保留原始
   请求、截图/提示、JSON 路径与 SHA、时间和既有本地证据；不得改变 RTL 语义反复
   重提，也不得把长期父目标改成 global blocked 或 completed。

该机制用于准确表达、最小权限、状态隔离和可审计复现；它不绕过或削弱平台审查，
也不承诺平台永不误判。

## 剩余风险

- directed/mutation evidence 不是形式化穷尽；设计摘要或 exact provenance 变化后
  必须重新运行固定入口。
- downstream memory 仍串行，尚未关闭 `DI-5` 和 `OOO-3`。
- 完整架构、Linux/official workload、fresh synthesis/STA/power/Pareto 均未由本轮证明。
- 长期父目标保持 `active`；下一轮应从仍为 RED 的硬门选择单一、可执行子目标。

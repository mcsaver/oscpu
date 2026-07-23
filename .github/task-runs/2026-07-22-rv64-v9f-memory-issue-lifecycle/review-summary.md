# RV64 V9F 内存发射生命周期独立审查摘要

## 最终结论

`VERDICT=PASS（限定性 PASS）`。

最终 reviewer 没有发现足以推翻 `MEM-ISSUE-G1` 或 `MIQ-FLUSH-G1`
当前设计闭环的证据矛盾或合法输入反例。两项债务可在以下共同边界内保持
`CLOSED`：当前完整 design-id、`TB_ENABLE_DUAL_MEM=0` 单内存端口配置、
给定 focused 仿真、11 个 compile-success RTL 验证变异、109 模块 aggregate、
当前 architecture hard gates 与 arch-stable 诊断审计。

## GAP 到闭环的审查链

1. v1 reviewer 判 `GAP`：初始五个变异不足以证明 ready backpressure、
   exactly-once 和 owner identity。
2. v2 reviewer 判 `GAP`：补证后仍缺少“其它请求 owner fire 不消费 terminal1”
   和“valid 但无 pop fire 的 DRAIN head 仍保留”两条负向场景。
3. v3 reviewer 判条件式 `GAP`：要求证明单端口下
   `grant_issue1 && mem_req_fire_any` 与 terminal1 自身 request fire 的关系，
   以及 MIQ `pop_valid/pop_fire` 的合法输入域。
4. v4 reviewer 判局部条件式 `PASS`：静态拓扑证明单端口代数等价；MIQ
   `pop_fire=pop_valid && head_valid && pop_owner_match`，owner mismatch 由
   assertion 定义为非法输入，不存在独立 `pop_ready`。它同时限定 3 拍窗口
   和非双端口边界。
5. 最终 reviewer 对 result、账本、来源 rebind、9/9 architecture gate、
   arch-stable GAP 边界做第二遍冻结材料审查，给出限定性 `PASS`。

所有早期 GAP 都保留在 `dispatch-log.md`，并已转换为当前 focused 场景、
静态拓扑检查或 11 项变异；没有把文字审查本身当作 GREEN 证据。

## 最终逐项裁定

- 请求 owner / terminal consume：PASS。terminal1 只在自身 selected request
  fire 或本地 terminal event 上释放；terminal0 fire、本地异常和 ready
  backpressure 都不能错误消费 terminal1。
- MIQ owner birth：PASS。birth 使用实际请求 fire；正常路径 15 字段一致，
  竞争路径的 5 个抽查字段属于实际 terminal0 owner。
- MIQ flush survivor：PASS。exact-owner fired DRAIN 先扣除；未消费 DRAIN
  和 valid/no-pop head 均保留；绕回 survivor FIFO 顺序不变。
- 变异灵敏度：PASS，限于指定故障模型。MEM 8/8、MIQ 3/3 均编译成功并
  被指定动态 oracle 检出；这不等价于形式完备性。
- 来源绑定：内部一致。design/result/raw/architecture-current/contract SHA
  各自职责分离；三路径、九 record、十三 section 的来源 rebind 保持非来源
  语义投影不变。
- arch-stable：局部 debt CLOSED 与全核 GAP 不矛盾。全核仍有 41 个 blocker，
  PPA unqualified、promotion false。

## 剩余非 blocker 风险

- 上游必须满足 exact-owner response 合同；冻结摘要没有独立证明全部上游。
- 竞争 owner 场景只抽查 15 个身份字段中的 5 个；更强的“所有竞争交错全部
  15 字段”命题尚未证明。
- 两拍 backpressure 和 `t+1..t+3` 安静窗口不能外推任意时长或无限时域。
- 11/11 只证明指定变异敏感，不排除未建模控制、payload、队列边界或多事件
  同拍故障。

## 声明边界

不能外推双端口全部交错、完整 DiffTest/Linux、全核 functional census、
全部架构债务、full-core arch-stable、正式 PPA 或其它 design-id。

`scope_extension_request=none`。若扩大到系统级 CLOSED，需要新版合同纳入
双端口交错、任意时长/形式性质、竞争条件下全部 15 字段和 exact-owner
上游不变量。

`confidence_and_basis=中高`：事务级正反场景、静态拓扑、定向变异、模块
aggregate、来源 rebind 和 hard gate 相互印证；reviewer 未读取原始 RTL/log
或独立重算哈希，因此不评为高置信。

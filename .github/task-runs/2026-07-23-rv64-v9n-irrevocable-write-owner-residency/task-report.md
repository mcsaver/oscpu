# V9N irrevocable-write owner residency

## 状态

`PASS`（仅本地 RV64 STORE/AMO 次拍 transaction-owner 驻留切片）。长期 RV64 OoO/PPA
goal 保持 active；full-core 仍为 `GAP`，PPA 为 `UNQUALIFIED`，promotion=false。

## RECALL 与根因

- DB brief 对四个 STORE/AMO owner 关键词组合均返回
  `no independent primary focus match`，本轮按规范入口直接读取 ledger、stored memory、
  STORE/AMO spec、生产 RTL 与 module TB 驱动链；该结果保留为 index recall gap。
- 独立 V1 reviewer 确认：既有 V9L STORE/AMO holder-qualified 同沿断言读取 edge-old Q；
  若 holder 在同一时钟沿的 NBA 更新中被过早清除，下一拍断言前件也会消失，因此无法
  独立证明 next-edge residency。
- `OooStoreQueue` 生产保持路径正确；AMO leaf 的 `flush_i` 清除路径由 canonical
  `NpcCoreTop.u_ooo_core.flush_i=1'b0` 静态排除。该结论只适用于当前生产顶层装配。

## 实施

- 新增两个 verification-only wrapper：
  - `tb_v9n_sq_owner_residency.sv`：STORE request fire 后跨 NBA 检查下一拍
    `valid/owner_valid/request_sent/!terminal` 与 full ProducerId/token/epoch；
  - `tb_v9n_amo_owner_residency.sv`：AMO write fire 后跨 NBA 检查下一拍
    `mem_pending_q/mem_amo_q/mem_amo_write_sent_q` 与完整 owner tuple。
- 新增两份 current-source、compile-success RTL 源码变体：
  - `sq_clear_owner_valid_on_request_fire`；
  - `amo_clear_kind_on_write_fire`。
  两者均以 V9N checker 为首个且唯一 `[CHECK-FAIL]`，旧 V9L 同沿 assertion 保持 quiet。
- 新增 fail-closed evidence builder 与 8 项单测；builder 从 live RTL 重构源码变体，绑定
  focused/variant 日志、current design-id、provenance SHA 和 canonical top flush 连接。
- `arch_stable_freeze.py` 对 STORE-BRESP-G1 独立重复 result/raw、变体重构、唯一失败
  oracle、source/artifact/provenance hash 与 top binding 校验；synthetic fixture 增加 owner
  residency 语义反例。
- `check-memory-ordering` 先运行 V9N，再运行既有 V8V OOO-3 链；V8V runner 在局部回放时
  只保存同 design-id 的 DI-1/DI-2/OOO-4 独立记录，回放后无冲突恢复，拒绝未知 test id。
- 新增 10-target 依赖证据刷新入口，串行回放 FENCE、异常/返回、INSTRET、memory issue、
  IFU AXI/fetch/access/tval 与 PTW/PMP 的局部 RTL 证据。

## 验证证据

- RTL design-id：
  `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。
- V9N focused：STORE 1/1、AMO 1/1；均有非真空 launch/preserved/exact-terminal marker。
- V9N variants：required=2、compile_success=2、dynamic_rejected=2、source_unchanged=true。
- V9N evidence 单测：8/8 PASS。
- 模块级聚合：109/109 PASS。
- 依赖证据刷新：10/10 target PASS。
- 最终 canonical `make -C npc/rv64 check-width-continuity`：V9A focused=2、stall=1、
  mutations=11/11、regressions=8/8、DI-2=GREEN、architecture=GREEN；PPA 未资格化。
- 完整 `run-arch-stable-audit.sh`：135/135 单测 PASS；当前结果稳定为
  38 blockers、`architecture_freeze=GAP`、PPA `UNQUALIFIED`、promotion=false。

## 独立终审与 freshness 纠偏

- V2 reviewer 技术复核未发现 STORE/AMO 局部属性反例，但发现其 dispatch 记录在旧 owner
  evidence 生成后追加，而 `dispatch-log.md` 属于 provenance `SOURCE_PATHS`，因此旧证据
  必须判 freshness GAP。
- 主 agent 冻结 dispatch 记录后，从 9 门顶层 canonical 链完整回放，而不是只更新摘要；
  随后更新 STORE-BRESP-G1 四项实际产物 SHA，并重新通过 135 项 arch-stable 单测。
- 固化规则：凡 reviewer/协调记录属于某证据的 provenance，必须在最终证据生成前冻结；
  若终审后发生字节变化，必须重放该证据及其上层聚合，不能只改 ledger hash。

## 声明边界与剩余风险

- 本轮没有修改生产 datapath/FSM，也没有产生面积、频率或功耗改善结论。
- 当前证据是定向动态仿真、可编译 RTL 源码变体与 fail-closed 重构，不等价于全状态空间
  形式化证明。
- 38 个 full-core blocker 仍由架构债务、producer-holder census、功能镜像绑定和完整冻结
  输入硬门构成；本轮不得据此宣称全核闭合或 PPA promotion。

# RV64 V9I IFU-ACCESS-G1 当前设计重绑定

状态：scoped_closed；长期 goal 继续 active

本轮关闭本地 RV64 双发射 OoO 核的 `IFU-ACCESS-G1`：instruction exact-halfword 物理访问、
2B EXEC PMP、RRESP transaction owner、AXI `ARSIZE/ARPROT`、`ARPROT[2]` default-slave
选择、PMEM 尾界读取及 lane0/lane1 precise fault owner。生产 `.v` RTL 未修改；改动集中在
testbench、current-design 证据生成器、冻结语义验证器、canonical 入口和架构债务账本。

## Current-design 结论

- `design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- `make -C npc/rv64 check-ifu-access`：focused 4/4、module aggregate 109/109、PMEM 尾界
  2B 读取 oracle PASS、编译成功负向 RTL 变体 19/19、证据单测 10/10。
- footprint 矩阵为 4 行，invalid-tail sentinel 为 4 行；RRESP 为 36 行并按 lane0/lane1
  18/18、EXOKAY/SLVERR/DECERR 12/12/12 分解；PMP 为 14 行并按 lane owner 6/6 分解。
- instruction AR 为 `ARSIZE=1, ARPROT=4`，PTW PTE AR 为 `ARSIZE=3, ARPROT=0`；
  `ARVALID && !ARREADY` 周期内 `ARADDR/ARSIZE/ARPROT` 由锁存 owner 保持。
- decoder 12 行 C/C、C/U、U/C、U/U 与 F0/F2/F4/F6 矩阵得到 lane0/lane1 owner 6/6，
  PC/cause/tval 经 capture、pending 与 drain 一致。
- current result SHA-256：
  `9776d139c4d9b406187b17008b6657b8094e59600487ad29ee018c283f3c3898`；raw log：
  `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a`。

## 审查者结论

- 最终限定材料复核使用
  `subagent-contracts/v9i-ifu-access-coverage-review-v2.json`
  （SHA-256 `00a2e4db3475a6dec764404aca44095eaac88a8289dc2fae0268066b7de09991`）。
- 审查结论为高置信度 PASS：现有矩阵与 19 个负向 RTL 变体未暴露共同盲点；保留项仅是合同未随附
  逐变体 patch/marker 的完整明细，不构成可执行周期级 GAP。
- 该结论只覆盖冻结材料和 `IFU-ACCESS-G1`，不替代独立仓库读取，也不外推到 `IFU-TVAL-G1`、
  `PTW-PMP-G1`、LSU split transaction、full-core freeze 或 PPA。

## 集成与全局边界

- `IFU-ACCESS-G1` 已在 `architecture-debt-ledger.json` 中绑定当前 design-id、canonical command、
  正向/反例/负向 RTL 变体覆盖以及 result/raw-log SHA，并标记为 `CLOSED`。
- 公共冻结验证器扩展后，6 个既有 CLOSED 条目均通过自身 canonical 入口重建；九个 directed
  architecture records 从 DI-2 根入口按依赖链重建，DI-1…DI-5 与 OOO-1…OOO-4 全 GREEN。
- `run-arch-stable-audit.sh` 已把 IFU-ACCESS 证据单测纳入常驻回归；最终 105 项单测通过。
- full-core audit 为 `architecture_freeze=GAP`、`ppa=UNQUALIFIED`、
  `promotion_eligible=false`、38 blockers；所有 CLOSED 条目的当前证据均通过。
- 下一优先级仍为 P0 `IFU-TVAL-G1` 与 `PTW-PMP-G1`；完整功能汇总、holder census、冻结输入集和
  正式 PPA 晋级保持独立。

## AI 工作流纠偏

- 子 agent 渲染提示自动加入 AXI/PMP/IFU 字段级叙述：`ARADDR/ARSIZE/ARPROT`、握手周期、
  2B EXEC 检查、PMEM 读取边界和 lane fault owner；真实 file/module/signal/TB/log 标识符保持原样。
- 规则不建立关键词黑名单，也不减少源码探索、实现工具、负向 RTL 变体、断言、覆盖矩阵或成功条件。
- task-contract self-test 25/25、CLI self-test 20/20、wiring audit 与 skill quick validation 全部 PASS。

## DB memory、e2e 与 strict guard

- project-status、NPC module 与 agent-system module 的稳定事实均通过
  `scripts/github_index_db.py update-stored` 发布；bounded non-history brief 对
  `rv64 IFU access current design` 返回 complete。
- `npc-dev` run：`.github/task-runs/2026-07-22-rv64-ifu-access-current-v9i/`，completed。
- `agent-system` run：`.github/task-runs/2026-07-22-rv64-ifu-access-current-v9i-2/`，10/10 completed。
- `github-index` run：`.github/task-runs/2026-07-22-rv64-ifu-access-current-v9i-3/`，completed。
- 两个保留的 blocked 反例分别证明：persistent skill 源目录不能残留生成的 `.pyc`；task slug 的每个
  领域词必须命中独立 non-history focus，不能由同一 task-run 自证。
- `scripts/agent-e2e.sh --guard --guard-mode strict` 对 `agent-system`、`npc-dev`、`github-index`
  三个 required profile 全部 PASS。

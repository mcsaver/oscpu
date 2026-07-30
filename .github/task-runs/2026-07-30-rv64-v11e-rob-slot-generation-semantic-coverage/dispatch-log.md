# V11E dispatch log

## RECALL

- bounded brief：
  `python3 scripts/github_index_db.py brief 'rob slot generation' --profile npc-dev --focus-scope non-history`
  返回 `ok=true`、`recall_status=complete`。
- 当前 architecture debt ledger 没有新开放 P0/P1；V11D semantic ledger
  保留 `rob-slot-generation` GAP，因此选择该单一技术目标。
- V8L 已有 `PRODUCER_GEN_W=1` 全局 finite-generation wrap 证据，但其
  compile-success mutations 未直接变异 `OooRob` generation authority。

## PLAN

1. 冻结 `OooRob` candidate、accepted-write、lifecycle、carrier 与 query
   周期合同。
2. 用机器可校验合同派发只读独立预审。
3. 依据预审只修改 verification/evidence 路径；发现 production 反例才重分类。
4. 跑 assert/release baseline、compile-success mutation、Python/ledger
   与 task-specific e2e。
5. 独立终审后更新 task-run、memory、DB 与 guard。

## DISPATCH

- 预审合同：
  `subagent-contracts/v11e-rob-slot-generation-pre-review.json`
- 合同 SHA-256：
  `7c55f6283f851028011dbeff98faab0a666ebceb93568b0b63fcf592fb084bf5`
- `create → validate → render` 均通过；render 首屏明确本地
  `OooRob.slot_generation_q`、`PRODUCER_GEN_W=1/4`、testbench 与
  compile-success RTL 变体证据边界。
- Windows→WSL 工程命令保持 single-flight；reviewer 持有执行权期间，
  主节点不运行 WSL 工程命令。

## PRE-REVIEW RESULT

- reviewer 合同内只读命令完成并归还 shell ownership。
- production `OooRob.v` 静态未发现合法二态反例，保持 `verification`
  分类；H4 确认存在。
- 可操作假绿包括：
  - `GEN_W=1` full ROB 连续两个 rejected edge 可让 valid-qualified
    错误写入 `0→1→0` 后回到原值；
  - lane1 actual 与 pair candidate 必须先制造相邻 slot generation 不同；
  - carrier/query expected 不能捕获 DUT ProducerId 后回用；
  - `GEN_W=4` stale query 必须逐 generation bit 翻转。
- 预审合同误列不存在的 `npc/rv64/vsrc/define.v`；reviewer 返回
  `scope_extension_request`，实现阶段使用真实
  `npc/rv64/vsrc/include/define.v` 与 `npc/rv64/vsrc/filelist.mk`。原合同
  JSON/SHA 保持不变，不把路径修正伪装成原预审输入。

## IMPLEMENTATION AND EVIDENCE

- production `OooRob.v` 未修改，SHA-256：
  `bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561`。
- `tb_ooo_rob.sv` 新增 V11E 独立沿前 model；当前 SHA-256：
  `6c5881089fc1437d40f15532279dde1e0c8b1359d4bd5c47ff03b4886a87f4f5`。
- attempt-1 原样保留：`walk-carrier-zero-generation/g1` 存活；首次
  recovery 的 carrier generation 为 0，使错误零值不可判别。
- attempt-2 原样保留：`recovery-resets-generation/g1` 存活；全部 recovery
  slot generation 为 1，使错误 reset-to-ones 不改变状态。
- attempt-3 以 slot4 generation=0、slot3 generation=1 的同一 recovery
  pair 同时区分两类错误，成为 canonical：
  - baseline：`GEN_W=1/4 × assert/release` 4/4 PASS；
  - 17 个 compile-success RTL variants × 两种 generation width；
  - 34/34 release 仿真均由
    `[V11E-SLOT-GEN-ORACLE][FAIL]` 拒绝；
  - 146-file pre/post RTL snapshot 均为
    `665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca`；
  - summary SHA-256：
    `c4800737dd6e9e7155f0fff1acfa04dd61a649935d769210f62c893247686a23`。
- 正常 `tb_ooo_rob` regression PASS；V11E evidence/semantic 定向 Python
  tests 为 22/22 PASS。
- semantic ledger 为 7 PASS / 37 GAP / 44，唯一相对 V11D 的新增 PASS
  是 `rob-slot-generation`；ledger SHA-256：
  `4d037e4577dc7596252db281cad730b7c018164bc20070d4cfff47ced64581db`。
- ARCH_STABLE 观测保持 51/53，V11E 新增失败为 0；两项既有
  current-workspace GAP 未被本轮局部证据覆盖。
- 首次 task-specific `npc-dev` run
  `2026-07-30-rob-slot-generation-semantic-revtag-v11e` 因 task slug
  生成的 recall terms 包含低召回 `semantic revtag` 而 fail closed，虽然
  五个 profile 节点均 PASS；原 blocked run 保留。
- 使用已独立验证可召回的硬件对象词组 `rob slot generation` 重跑后，
  `2026-07-30-rob-slot-generation` 为 completed 5/5；没有放宽 recall gate。
- 终审后的 active spec 页首同步改变 guard 绑定哈希；原 scoped guard
  因而正确返回 missing current evidence。继续使用相同可召回硬件对象
  `rob-slot-generation`，在独立目录
  `2026-07-30-rob-slot-generation-final` 生成 current-source
  `npc-dev` 5/5，不复写前一个 completed run。

## FINAL REVIEW DISPATCH

- 终审合同：
  `subagent-contracts/v11e-rob-slot-generation-final-review.json`
- 合同 SHA-256：
  `75fe8f31bbada20668b8da84d9085cf378b4e0ac7dad1dd6d752e48aa1d13aad`
- `create → validate → render` 均通过；reviewer 只读核对 current RTL/TB、
  三次 attempt、vvp/receipt、semantic ledger、normal regression、
  ARCH_STABLE 与 e2e 原始证据。

## FINAL REVIEW RESULT

- reviewer 已停止全部只读命令并归还唯一 WSL shell ownership。
- 终审结论为 bounded APPROVE、`blocker=0`，只批准
  `rob-slot-generation` 单元 PASS；global holder collision fence、
  global no-live-reuse、whole architecture、system、synthesis、STA、
  power 与 PPA 均未晋级。
- 终审核对：
  - `OooRob.v=bbb68a…c561`、`tb_ooo_rob.sv=6c5881…f4f5`；
  - 146-file pre/post snapshot 均为 `665b19…cca`；
  - baseline 4/4，17 个变体在两种 generation width 下均编译成功，
    34/34 由关闭 `OOO_ASSERT` 后仍生效的独立 oracle 拒绝；
  - attempt-1/2 的假绿原因与 attempt-3 混合 generation 纠偏可从原始
    cycle marker 复核；
  - V11D→V11E ledger 精确差分只新增
    `v11e-rob-slot-generation-current-closure`，只把
    `rob-slot-generation` 晋级为 PASS。
- reviewer 指出的两项记录层 GAP 已闭环：
  - active spec 页首已从 v11c 的 5/39 旧计数同步为 v11e 的 7/37；
  - `evidence/semantic-ledger-unit.log` 独立保存 13/13 ledger tests，
    与 attempt-3 已保存的 9/9 evidence-tool tests 合计 22/22。
- active spec 是终审后的 documentation-only publication 同步，当前 SHA-256
  为 `6f50d53e…008c4`；attempt-3 内原 SHA-256 `2bd1dac8…29ba`
  与 canonical summary 均保持原样。直接用当前工作树重建 attempt-3 时，
  builder 按设计拒绝该文档哈希漂移；没有通过放宽 currentness 或篡改
  历史证据来消除该拒绝。两者关系由
  `evidence/post-review-publication-receipt.json` 显式记录。
- `scope_extension_request=none`。有限 generation 回绕仍依赖外部 holder
  collision fence，不从本局部 PASS 外推。

## WORKFLOW CLOSURE

- post-review current-source `npc-dev`
  `2026-07-30-rob-slot-generation-final` completed 5/5。
- 7-path scoped strict guard PASS；全工作树 strict guard 的
  `agent-system`、`rv64-systemd-contract`、`npc-dev` PASS，唯一
  `rv64-linux` missing evidence 由共享
  `Linux/scripts/check-ubuntu-rootfs.sh` 触发，保持范围外 GAP。
- final identity PASS：146-file RTL、attempt-3 executable source、
  canonical summary、current 7/37 ledger、publication receipt 与
  22/22 tests 均核验。
- 609 个 raw evidence assets 已进入 `evidence_assets`；8 份技术
  Markdown 与 project/NPC memory 已用 `update-stored` 发布。
  `snapshot-stored`、DB-first、Markdown coverage 与 runtime-artifact
  audit 均 PASS。
- commit gate 观察 `ai@af027d1b…`、251 个 tracked 修改、1,611 个
  untracked 文件及一个无关 staged profile；保持 mixed-origin GAP，
  没有 stage/commit。

所有 Windows→WSL 工程命令保持 single-flight；预审与终审 reviewer 均已
明确归还执行权，无遗留工程进程。

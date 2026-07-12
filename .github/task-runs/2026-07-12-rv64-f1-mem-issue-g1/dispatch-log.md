# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-mem-issue-g1
- `task_slug`: rv64-f1-mem-issue-g1
- `graph_template`: regression-debug-loop + npc-sim-regression
- `log_policy`: append-only

---

### [2026-07-12 11:19 +0800] `source-to-sink-map` - PASS

- `owner_agent`: t3a_integration_map + root
- `action`: 对齐 issue1 can-fire、ready、request-valid/fire、request mux 与 MIQ push 条件。
- `outputs`: 锁定 exception-port-free 分歧；证明 WB-wait 第二怀疑不可达。
- `handoff_to`: red-owner-window。

### [2026-07-12 11:27 +0800] `red-owner-window` - PASS

- `owner_agent`: mem_lane1_red
- `action`: 构造 lane0 misaligned LR.D + lane1 aligned PMEM LW 合法双发。
- `outputs`: 唯一失败；issue1 已 fire/pop，但 request/MIQ owner 均不存在。
- `evidence`: `/tmp/lane1-owner-red-old-v5` 与 task-report 精确观测。
- `handoff_to`: freeze-contract, implement-owner。

### [2026-07-12 11:29 +0800] `freeze-contract` - PASS

- `owner_agent`: root
- `action`: 冻结六类合同、同拍优先级与唯一 `issue0_mem_port_free` 事实。
- `outputs`: `mem-lsq.md` 与 task-report。
- `handoff_to`: implement-owner。

### [2026-07-12 11:46 +0800] `implement-owner-v1` - REJECTED

- `owner_agent`: root + mem_issue_review
- `action`: 首版把 lane0 exception 直接视为 port-free，并跑正向 GREEN。
- `review`: reviewer 用更老 CLMUL 挡住 lane0 misaligned LR，发现 lane1 IQ 未 pop 却先发 bridge/MIQ。
- `outputs`: 精确 3 fail；`req_valid=1, fire=0, mem_req_valid=1, miq_count=1`。
- `evidence`: `evidence/reviewer-blocker-red/`。
- `handoff_to`: implement-owner-v2。

### [2026-07-12 11:49 +0800] `implement-owner-v2` - PASS

- `owner_agent`: root
- `action`: 抽不含 ready 的 `issue0_mem_issue_eligible`，收紧唯一 port-available 事实；
  `MEM-I2` 从 req-valid 握手前件核对 IQ/request/mux/MIQ 完整 owner。
- `outputs`: 正向 request/MIQ owner、blocked CLMUL guard、WB-wait guard 全 GREEN；focused 5/5、module 87/87。
- `evidence`: `evidence/focused-green-v3/`、`evidence/focused-suite-v2/`、`evidence/module-full-v2/`。
- `handoff_to`: full-regression, reviewer-rerun。

### [2026-07-12 11:53 +0800] `full-regression` - PASS

- `owner_agent`: root
- `action`: 主树跑最终 module；detached worktree 用逐字节相同 RTL 与 bundled Verilator 5.051
  跑 clean lint/build/AM/official，并在临时配置上跑 Difftest-ON AM。
- `outputs`: module 87/87；AM 59/59；official 177/177；overall_rc=0；Difftest ON/reference
  各 59、AM 59/59；style/lint/contract37/37。
- `evidence`: `evidence/core-regress-final-isolated-bundled/20260712-115028-1498028/`、
  `evidence/difftest-on-isolated/am-difftest-on-final.log`、`evidence/structural/`。
- `handoff_to`: reviewer-rerun, record-review。

### [2026-07-12 11:57 +0800] `record-review` - PASS

- `owner_agent`: root + mem_issue_review
- `action`: reviewer 二轮复核最终 eligible/available、断言与正反例；同步 active docs、DB-backed
  project/NPC memory、raw asset DB 与 bounded index；运行 fresh npc-dev。
- `outputs`: reviewer NO BLOCKER；MEM-ISSUE-G1 CLOSED；npc-dev PASS。
- `evidence`: 本 task-run、`2026-07-12-rv64-f1-mem-issue-g1-final/`。
- `guard`: strict mode PASS，required profile `npc-dev` 命中 fresh completed evidence。
- `next_step`: 精确提交，不纳入用户 dirty 文件。

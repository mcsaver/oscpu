# RV64 F1：MEM-ISSUE-G1 lane1 访存 owner 同源

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-mem-issue-g1
- `task_slug`: rv64-f1-mem-issue-g1
- `graph_template`: regression-debug-loop + npc-sim-regression
- `graph_mode`: static+dynamic
- `status`: completed
- `owner`: root + mem_lane1_red + t3a_integration_map
- `started_at`: 2026-07-12 11:19:00 +0800
- `updated_at`: 2026-07-12 11:58:00 +0800

## 任务目标与范围

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `goal`: 关闭 `MEM-ISSUE-G1`：lane0 访存异常释放主请求端口时，正常 lane1 访存的
  IQ dequeue、request mux、bridge fire 与 MIQ push 必须由同一 port-owner 判据授权，禁止丢事务。
- `scope`: `OooIntBackend` 双 lane memory issue；不改变页表异常、SQ forward、MMIO/AMO、
  bridge/MIQ response FSM 或 memory ordering 策略。

## Root cause

`issue1_mem_can_fire_w` 把 `issue0_mem_exception_w` 视为“lane0 已释放主请求端口”，因此
允许 lane1 ready/fire；但 `issue1_mem_request_fire_w` 与 `issue1_mem_req_valid_w` 仍严格要求
`!issue0_is_mem_w`。同拍 lane0 memory exception + lane1 normal load 时，lane1 从 IQ 删除，
却没有 bridge request、MIQ owner 或 EX completion，ROB 项永远不能完成。

## 接口合同冻结（RTL 阶段 0）

1. **握手**：先定义不依赖 `mem_req_ready` 的
   `issue0_mem_issue_eligible = issue0_is_mem && !mem_issue_block && mem_order_ready && amo_quiet`，
   再定义唯一 `issue1_mem_port_available = !issue0_is_mem ||
   (issue0_mem_exception && issue0_mem_issue_eligible)`；lane1 normal memory 的 can-fire、
   request-valid、request-fire 和 mux owner 必须机械复用该事实。
2. **stall**：port 不自由或 bridge/MIQ slot 不可用时，lane1 必须留在 IQ；禁止只撤 request
   而保留 dequeue。valid/ready 方向不新增组合环。
3. **flush/redirect/trap**：flush 继续禁止新 request/fire；lane0 exception 只完成 lane0 精确异常，
   不应占用 memory request port。branch kill/MIQ same-cycle squash 语义不变。
4. **异常序**：lane0 exception 与 lane1 normal request 可同拍各归其 owner；lane0 精确异常不能
   吞掉更年轻但合法发射的 lane1 memory transaction，后续 ROB 仍按年龄提交。
5. **访存序**：lane1 仍受既有 `mem_order_ready`、SQ block、AMO quiet、slot-open 与 bridge ready；
   本刀只统一端口 owner，不放宽 store/load、MMIO 或 atomic 排序。
6. **投机恢复/单一真源**：请求副作用只由 `mem_req_valid && mem_req_ready` 及匹配的
   `push_issue1` 产生；IQ fire 不能成为第二个独立 request owner。

### 同拍优先级

| lane0 | lane1 | 预期 |
| --- | --- | --- |
| normal memory request | normal memory | lane0 主端口，lane1 hold |
| memory exception | normal memory | lane0 exception completion + lane1 request/MIQ push |
| memory exception 但被 ROB/order/SQ 挡住 | normal memory | 两者 hold；lane1 无 request/MIQ side effect |
| SQ forward completion | normal memory | 维持现有 lane0-first 规则，本刀不改 |
| non-memory | normal memory | lane1 request/MIQ push |
| flush/block/slot closed | 任意 memory | 无 request，相关 IQ entry hold |

## RED 证据（旧 RTL）

- 常驻 `tb_ooo_int_backend` 场景先把 x1 写为 `0x301`，再同拍 dispatch misaligned LR.D
  （lane0，memory exception）与 aligned cacheable PMEM LW（lane1）。
- 旧 RTL 精确唯一失败：`lane1 owner A pop implies matching request fire`。
- 前沿观测：`issue1_fire=1, req_valid=0, req_fire=0, mem_req_valid=0`；后沿观测：
  `issue_count=0, rob_count=2, miq_count=0, commit0=1, commit1=0`，证明不是只看 timeout 的假 RED。
- 命令：`make -C npc/rv64/testbench TESTS=tb_ooo_int_backend RESULT_DIR=/tmp/lane1-owner-red-old-v5 run`。

## 已排除的第二怀疑

`mem_rsp_waiting_for_wb` 下“request 已 fire 但 IQ 不 pop”在合法接口不可达：该 waiting 只来自
LEGACY response，蕴含 legacy/request slot 都关闭，因此 `issue1_mem_req_valid=0`。动态 guard 已抵达
`rsp_wait=1, issue1_ready/fire=0, req_valid/fire=0` 并通过；保留为回归防未来分叉。

## 独立审查发现并关闭的假绿

首版修复把 port-free 过宽写成 `!issue0_is_mem || issue0_mem_exception`。独立 reviewer 构造：
更老 CLMUL 已离 IQ 但仍在执行，随后 lane0 misaligned LR.D 与 lane1 PMEM LW 入队。LR 尚非
ROB head，故 `issue0_mem_can_fire=0`，最终 cross-lane gate 令 `issue1_fire=0`；但过宽公式曾让
`issue1_mem_req_valid=1, mem_req_valid=1`，下一拍 MIQ 错入默认 DRAIN/rob0。该负探针精确 3 fail：
ownerless req-valid、ownerless bridge request、`miq_count=1`。

最终实现把公共 order/SQ/AMO 资格抽成不含 ready 的 `issue0_mem_issue_eligible`，并只允许
“lane0 非 memory”或“lane0 exception 且 eligible”交出 lane1 owner。反向 `MEM-I2` 断言以前件
`issue1_mem_req_valid && mem_req_ready` 检查 IQ fire、request fire、request mux、MIQ push 以及
ROB/pdest/kind 全匹配，不再用 request-fire 自身作前件掩蔽幽灵请求。

## 当前状态

- `red`: PASS（旧 RTL 精确 1 fail）。
- `contract`: PASS（六类合同与唯一 owner 已冻结）。
- `implementation`: PASS（共享 eligible/owner 事实 + 双向 `MEM-I1/I2` 断言）。
- `focused`: PASS（正向 exception+lane1 request、head-blocked 反例、WB-wait 不可达 guard；5/5）。
- `module`: PASS（87/87，最终 RTL/TB）。
- `structural`: PASS（RTL style、bundled Verilator 5.051 lint、contract `37/37`）。
- `core-regress`: PASS（detached 隔离树 clean build；AM 59/59、official 177/177、
  `overall_rc=0`；最终 RTL SHA-256 与主树逐字节一致）。
- `difftest`: PASS（隔离树 Difftest-ON AM 59/59；ON/reference marker 各 59）。
- `review`: PASS（独立 reviewer 先拦截首版假绿，修复后最终 NO BLOCKER）。
- `memory/evidence`: PASS（project-status、NPC memory、2130 raw asset DB index 与 bounded
  evidence index 已更新；fresh `npc-dev` profile 与 strict guard PASS）。
- `boundary`: 本 correctness slice 不作 CPI 或 5 ns 时序收益声明；T3 memory station 另刀处理。

## 验证与隔离说明

- 主工作区存在用户既有 dirty log/debug/frontend/sim 文件，本刀未暂存或修改其归属；authoritative
  core run 使用 detached `/tmp/ysyx-mem-issue-g1-core` 隔离这些改动。
- authoritative run 前，主树与隔离树 `OooIntBackend.v` SHA-256 均为
  `9e890f87ce22bafe13ced397af58e841a1841867ae84db00e297e3cf4dc1141f`。
- OFF 配置 SHA-256 `cb2cad6f...` 在主树前后不变；Difftest-ON 只改变临时 worktree。
- 首次未 source `scripts/agent-env.sh` 的 run 调到 system Verilator 5.020，因不识别
  `PROCASSINIT` lint code 失败；另一次 Difftest 隔离首跑缺 ignored SoftFloat archive。
  两者均作为环境诊断保留，不进入 GREEN；最终只采信 bundled 5.051 与补齐依赖后的 run。

## 最终裁决

- `final_result`: MEM-ISSUE-G1 CLOSED。
- `blockers`: 无。
- `next_step`: 独立删除已证明不可达的 issue0→issue1 current-result forward，再冻结 T3
  global-oldest-memory admission + non-fall-through prepared station 合同，做功能/CPI/5ns A/B。
- `parent_goal`: 仍 active；完整功能与物理 200 MHz 尚未完成，T0 5ns WNS 仍为 `-15.74ns`。

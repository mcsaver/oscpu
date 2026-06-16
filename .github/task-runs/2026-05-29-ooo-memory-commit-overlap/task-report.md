# OoO Memory Commit Overlap

## 目标

在已能跑通 AM `cpu-tests add` 的 OoO 实验核上，继续压低 memory/commit 串行损失，验证是否能向 `CPI=0.5` 靠近。

## RTL 推导摘要

- profile 基线：实验 OoO AM `add` 在保守 branch spec 后为 `cycles=1009/commits=839/CPI=1.203`；VCD 里 `iq_nonempty` 周期基本都能 issue，剩余主要来自 memory response、ROB head/control stop-pending 与 issue-to-commit latency。
- 已保留方向：让 memory pending 期间的无关 ALU 继续执行；ROB head/head1 支持写回同拍退休；给 memory issue 增加 1-entry buffer；放开 `issue0` 非 memory + `issue1` memory 的同包发射；当 ex0/ex1 两个写回口都忙时背压 memory response，等写回口空出后再接收。
- 关键修复：lane1 memory 初版暴露 writeback 端口冲突。`mem_rsp_fire` 与 `ex0_valid_q` 同拍时，旧 mux 会让 memory response 抢 wb0 并丢掉 lane0 ALU 写回，导致 ROB entry 永远 not done；现改为 ex0 走 wb0、memory response 走 wb1。
- 已否决方向：放宽 branch speculation 到非 drain 场景会变慢或卡住；lane1 branch + lane0 非 memory 的窄门 checkpoint spec 也让 AM `add` 从 `CPI=1.201` 退到 `1.278`；naive memory response/request 同拍续发会让 focused memory 程序 load 读 0 或无法到达 ebreak，已回退。

## 修改内容

- `OooRob`：增加 head/head1 写回同拍退休 bypass。
- `OooIntBackend`：支持 `mem_pending_q` 期间 issue0 非 memory overlap 到 ex1/wb1。
- `OooIntBackend`：新增 1-entry memory issue buffer。
- `OooIntBackend`：新增 issue1 LSU/request 通路，允许 lane0 ALU + lane1 load/store 同拍发射。
- `OooIntBackend`：修复 memory response 与 ex0 ALU 同拍 writeback 仲裁，避免 ROB done 丢失。
- `OooIntBackend`：允许 memory pending 下双 ALU 发射；当 memory response 等待且两个写回口都满时，只放行 issue0，保证下一拍能为 response 留出一个写回口。
- `tb_ooo_int_backend`：补 lane0 ALU + lane1 store 的同包回归，以及 store pending + 双 ALU + delayed memory response 的背压回归。

## 验证

- `make -B -C npc/single/testbench TESTS="tb_ooo_int_backend tb_ooo_alu_fetch_core tb_lsu" RESULT_DIR=/tmp/ysyx-ooo-dual-alu-mem-final-focused run`
  - 结果：`3/3` PASS。
- `make -B -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-dual-alu-mem-final-module run`
  - 结果：`38/38` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-dual-alu-mem-final-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-dual-alu-mem-final-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=1008/commits=839/CPI=1.201`。
- lane1 branch checkpoint spec 反证
  - 结果：focused `7/7` PASS、全量模块 `38/38` PASS，但 AM `add` GOOD TRAP 退化为 `cycles=1072/commits=839/CPI=1.278`，已回退。
- 默认非实验构建与 AM `add`
  - 结果：退出码 0，`cycles=1509/commits=838/CPI=1.801`。

## 结论

这轮增量正确性稳定，但 CPI 仍停在 `1.201`，说明当前安全 overlap 已接近单 outstanding memory 模型的收益上限；完整 AM `add` 的 `CPI=0.5` 尚未完成。VCD 显示 remaining stop 主要集中在 branch/control，且 full-snapshot checkpoint 继续放宽会因 commit 冻结而退化。下一步应优先做 ROB-age selective branch squash，或在 LSU 侧实现可证明的 request skid/response queue、多 outstanding/LSQ 与 commit-time store。

## 追加：dispatch-ready branch 同拍 redirect

### 目标

上一轮 profile 里 direct branch 仍占主要 stop-pending。已有后端 branch uop 能在源操作数 ready 后解析，但如果源在 dispatch 当拍已经 ready，仍会先进入 `stop_pending_q` 等下一拍 backend resolve，白白损失一个分支气泡。本追加尝试把这类 ready branch 在 dispatch 当拍直接送回前端 redirect。

### 修改内容

- `OooDispatchBackend` 暴露 dispatch fire 后的源物理寄存器号与 ready 状态。
- `OooPhysRegFile` 增加 read4/read5，供 `OooIntBackend` 在 dispatch 阶段读取 direct branch 两个源。
- `OooIntBackend` 组合计算 dispatch-ready branch 的 taken/next PC/misaligned，并通过 `dispatch_branch_resolve_*` 端口透传；同时保留下一拍 registered resolve pulse，供旧 pending 路径和观测使用。
- `OooAluDecodeBackend`、`OooAluCoreSlice` 透传新端口。
- `OooAluFetchCore` 在 direct branch fire 当拍若 `dispatch_branch_resolve_pc` 与当前 direct branch PC 匹配且 target 未 misalign，则跳过 `stop_pending_q`，清 FIFO/outstanding 并同拍发 redirect fetch 到 resolved next PC；普通 pending branch resolve 增加 PC match，避免旧 branch uop 的晚到脉冲误解锁新 pending branch。
- `tb_ooo_alu_fetch_core` 新增 `x0/x0` ready branch 场景，确认 dispatch-ready resolve 发生且 fallthrough 不执行。
- memory 侧保留安全小改动：已进入 1-entry buffer 的请求可在旧 response 同拍占用空槽；但新 issue load/store 的 response 同拍直发再次复现 load 读 0/无法到达 ebreak，已回退。

### 验证

- `make -B -C npc/single/testbench TESTS="tb_ooo_alu_fetch_core tb_ooo_alu_core_slice tb_ooo_alu_decode_backend tb_ooo_int_backend" RESULT_DIR=/tmp/ysyx-ooo-direct-branch-resolve-focused run`
  - 结果：`4/4` PASS。
- `make -B -C npc/single/testbench TESTS="tb_ooo_int_backend tb_ooo_alu_fetch_core tb_lsu" RESULT_DIR=/tmp/ysyx-ooo-mem-buffer-slot-focused run`
  - 结果：`3/3` PASS。
- `make -B -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-direct-branch-mem-buffer-module run`
  - 结果：`38/38` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-mem-buffer-slot-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-mem-buffer-slot-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=927/commits=839/CPI=1.105`。

### 新结论

dispatch-ready branch 同拍 redirect 对 AM `add` 有明确收益：`CPI 1.201 -> 1.105`，主要来自 `0x8000006a/0x8000007a` 这类源已 ready 的 loop branch。剩余 `0x8000000e` 等 forward branch 依赖刚计算的 x10，仍需要真实预测/rollback 才能继续削减；memory 侧若要继续推进，也不能再做无 skid 的同拍直发，必须引入 response queue/metadata queue 或更完整 LSQ。

## 追加：fetch control-stop 与 memory response/request 同拍续发

### 目标

dispatch-ready branch 后，AM `add` 的 fetch request 数仍偏高，且 memory side 仍有 response 后下一条 request 的单槽空泡。本追加分别验证两个更小的安全优化：控制包返回当拍不再发顺序 fallthrough fetch；旧 memory response fire 当拍允许新 issue load/store 直接占用空出的 pending 槽。

### 修改内容

- `OooAluFetchCore`：对刚解出的 fetch response packet 增加 `fetch_rsp_control_stop_w`，当 lane0/lane1 含 branch/JAL/JALR/SYSTEM 或 fetch fault 时，`can_issue_request_w` 不再同拍发顺序下一包 request。新增 `MODE_CONTROL_FETCH_GATE` 覆盖 `JAL` 跳过 fallthrough 的场景，确认不会额外请求 `0x80000008`。
- `OooIntBackend`：将 `mem_request_slot_open_w = !mem_pending_q || mem_rsp_fire_w` 用于新 issue memory request 的 ready/fire/valid 判断，允许旧 response 与新 request 同拍交接单 outstanding 槽；request metadata 在同拍写入下一条 load/store，避免复用旧请求上下文。
- `tb_ooo_alu_fetch_core`：新增 `saw_memory_rsp_req_overlap` 观测，要求 focused memory 程序出现 `mem_req_fire && mem_rsp_fire` 同拍，同时 store->load 和 dependent addi 结果保持正确。
- 反证：尝试过让 direct-return control commit 更早对前端可见，但 focused/module/AM 没有 CPI 收益，已撤回，避免保留无效复杂度。

### 验证

- `make -B -C npc/single/testbench TESTS="tb_ooo_int_backend tb_ooo_alu_fetch_core tb_lsu" RESULT_DIR=/tmp/ysyx-ooo-final-focused run`
  - 结果：`3/3` PASS。
- `make -B -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-final-module run`
  - 结果：`38/38` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-final-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-final-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=900/commits=839/CPI=1.073`。

### 最终结论

本追加把当前实验 OoO AM `add` 最好结果推进到 `CPI=1.073`，相对 dispatch-ready branch 基线 `1.105` 继续小幅改善。VCD 归因显示剩余主要是 `zero_issue=149`、`zero_stop_head=73`、`zero_mem=64`，其中 `0x8000000e` forward branch 仍是主要 unresolved branch 热点；当前非投机控制流与单槽 memory 模型已接近局部补丁收益上限。下一步若继续追 `CPI=0.5`，应优先设计 ROB-age selective branch squash/预测恢复、缩短 ALU issue-to-wakeup latency，并把 LSU 升级到 response queue、多 outstanding/LSQ 与 commit-time store。

## 追加：dispatch branch issue-result bypass 与 memory-aware issue1 selection

### 目标

`CPI=1.073` 的 VCD 里，`0x8000000e` 这类 forward branch 已不再是源已 ready 的普通 dispatch-ready branch，而是同拍 lane0 刚产生源值、lane1 分支立刻消费的短距离 RAW。另一个热点是 issue queue 在单 memory port 下会优先选择两个 ready memory uop，导致后面的 ready ALU uop 被压后一拍。本追加只保留两处可以用 focused 覆盖证明的结构性小改动。

### 修改内容

- `OooIntBackend`：dispatch-stage direct branch 比较加入当前 issue0/issue1 结果旁路。当分支源物理寄存器匹配同拍 fire 的非 memory uop 目的寄存器时，用当前 ALU/writeback 数据参与 branch compare，使 `addi x5,...; beq x5,...` 这类同拍 producer-consumer branch 可直接 resolve。
- `tb_ooo_int_backend`：新增同拍 issue producer + dispatch branch 的 focused 场景，检查 branch dispatch resolve 的 PC、next PC 与 not-taken 结果。
- `OooIntIssueQueue`：issue1 选择改为 memory-port-aware。若 issue0 已选中 load/store，issue1 会跳过其他 ready memory entry，优先选择后面的 ready non-memory uop；仍保持单 memory uop/cycle，避免两个 load/store 同拍争用 LSU。
- `tb_ooo_int_issue_queue`：新增两个 ready load 后跟一个 ready ALU 的场景，确认 issue0 发第一个 load、issue1 同拍发后面的 ALU，剩余 load 下一拍发出。
- 反证：direct branch predicted-match no-flush 在 AM `add` 上没有收益，已撤回；lane0 branch not-taken + lane1 RAS return 同拍 dispatch 尝试触发 Verilator `UNOPTFLAT` 组合 ready 环，也已撤回。

### 验证

- `make -B -C npc/single/testbench TESTS="tb_ooo_int_backend" RESULT_DIR=/tmp/ysyx-ooo-issue-branch-bypass-focused run`
  - 结果：`1/1` PASS。
- `make -B -C npc/single/testbench TESTS="tb_ooo_int_issue_queue" RESULT_DIR=/tmp/ysyx-ooo-mem-skip-iq-focused-2 run`
  - 结果：`1/1` PASS。
- `make -B -C npc/single/testbench TESTS="tb_ooo_alu_fetch_core tb_ooo_int_backend tb_ooo_int_issue_queue tb_lsu" RESULT_DIR=/tmp/ysyx-ooo-final-4focused run`
  - 结果：`4/4` PASS。
- `make -B -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-final-module run`
  - 结果：`38/38` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-final-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-final-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=835/commits=839/CPI=0.995`。

### 新结论

这轮把实验 OoO AM `add` 从 `CPI=1.073` 推进到 `1.006`（issue-result branch bypass），再到 `0.995`（memory-aware issue1 selection）。目标 `CPI=0.5` 仍未完成，但当前瓶颈已从单个 branch ready 气泡转向更结构性的控制流恢复、ALU issue-to-wakeup latency、单 outstanding memory/缺少 LSQ 以及 commit 带宽利用率。继续推进应优先做可证明的 branch prediction + ROB-age selective squash/rollback，或系统性升级 LSU，而不是继续堆单点旁路。

# RV64 CoreMark Regression and WSL Crash Follow-up Task Report

## 目标

接着用户对 WSL 崩溃的分析，确认当前 `npc/rv64` 是否仍存在 CoreMark no-progress，并把可复验的 RTL/benchmark 状态沉淀下来。

## 结论

原始 WSL 崩溃不应归因为 CoreMark 自身 BAD TRAP，也不像干净 OOM。代码侧主要触发点是 fault-trap 后 OoO memory response/flush ownership 曾经没有闭合，可能留下 orphan response；环境侧 WSL/vsock 不稳定会把长时间无进展放大为 `Wsl/Service/E_UNEXPECTED` 或 `0x8007274c`。

当前工作树已经不再复现 CoreMark no-progress：CoreMark10 能 PASS，memory request/response 平衡。但性能从历史 `CPI=0.783/0.779` 回退到 `CPI=0.828`，因此“CPI 低于 0.8”目标当前未达成。

## 最终代码状态

- `NpcCoreTop.v`/`NpcSimTop.sv`
  - 保持较小窗口基线：ROB index width 4、issue index width 3。
  - 未保留 ROB64/IQ32 实验，因为没有改善 CoreMark。

- `OooIntIssueQueue.v`
  - 保持 issue1 可独立发射，只在真实依赖 issue0 时等待 issue0 fire。
  - 未保留过度门控 issue1 的实验；该实验使 CoreMark 退化到 `CPI=0.831`。

- `OooAluFetchCore.v`
  - `branch_prefetch_dispatch_attempt_w`、`branch_prefetch_dispatch_fire_w`、`direct_branch_spec_start_w` 当前保持关闭。
  - branch prefetch same-cycle dispatch focused PASS，但 CoreMark无收益，因此未保留。

- `OooIntBackend.v`
  - `load_branch_fast_resolve_w` 当前保持 `1'b0`。
  - 带 load response bypass 的 fast resolve focused PASS，但 CoreMark 退化到 `CPI=0.907`，疑似过早 resolve 抢占 branch shadow prefetch。

- `OooRob.v`
  - dispatch free slots 仍只看当前已登记空位，不借用同拍 commit 释放槽。
  - 两版 same-cycle slot borrow 都触发 Verilator `UNOPTFLAT`，已撤回。

## 验证

- `make -C am-kernels/tests/cpu-tests AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ALL="branch-resolve-loop ooo-mem-order linux-mini-boot" run NPC_RUN_ARGS="--no-progress --max-cycles 1000000"`
  - 3/3 PASS。
  - `branch-resolve-loop cycles=55190/commits=35782/CPI=1.542`。
  - `ooo-mem-order cycles=22777/commits=14412/CPI=1.580`。
  - `linux-mini-boot cycles=31819/commits=10630/CPI=2.993`。

- `make -C am-kernels/benchmarks/coremark AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine ARCH=riscv64-npc NPC_SIM_BACKEND=rv64 ITERATIONS=10 run NPC_RUN_ARGS="--no-progress --max-cycles 20000000"`
  - PASS。
  - `cycles=2661725/commits=3216115/CPI=0.828`。
  - `mem req0/req1/rsp0/rsp1=696782/0/696782/0`。
  - branch accuracy `564652/590327`，branch miss `25675`。
  - control wait cycles `stop=814454/branch=795811/jump=18641`。
  - top branch wait PC: `0x80000b2c cycles=295809`。

## 负实验

- ROB64/IQ32: 无 CoreMark 改善，撤回。
- issue1 依赖 issue0 fire 过度门控: CoreMark 退化到 `cycles=2673739/CPI=0.831`，撤回。
- load-branch fast resolve + response bypass: focused PASS，但 CoreMark 退化到 `cycles=2916441/CPI=0.907`，撤回。
- ROB same-cycle free slot borrow: 直接借用和 registered-done 借用都触发 Verilator `UNOPTFLAT`，撤回。
- BPU local strong-only override: branch miss 增加到 `26467`，无周期收益，撤回。
- branch prefetch same-cycle dispatch: focused PASS，CoreMark周期无收益，保持关闭。

## 剩余限制

当前不是最终达标状态。CoreMark 已从卡死恢复为 PASS，但 `CPI=0.828` 仍高于目标；真实 Linux kernel 也仍未完整 boot。下一步应优先做历史好点后的差异审计，并围绕 load-dependent branch/control wait 设计不会破坏 shadow prefetch、不会形成 ready/valid 组合环、不会丢 memory response ownership 的优化。

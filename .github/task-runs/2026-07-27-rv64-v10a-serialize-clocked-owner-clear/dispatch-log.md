# V10A dispatch log

## 2026-07-27 root recall

- 读取工作区级规则、RTL 合同技能、RV64 interface/RTL/PPA 工作流、current memory、
  V9Z report/spec 与生产调用链。
- `npc/rv64/design/study/README.md` 当前不存在；按工作区稳定入口回退读取
  `npc/rv64/README.md`，并以 current spec/RTL 为本切片设计事实来源。
- 初步生产路径显示 pending architectural trap/system holder 在 C0 drain 边沿由
  `OooPendingDispatchArbiter` 发出 clear，`OooStopPendingSequencer` 同沿清 stop，
  `CsrFile` 同沿采样选中 request；尚待独立 reviewer 与 clocked TB 复核。

## Shell ownership

- root 保持 Windows→WSL 唯一工程命令 lane。
- 派发只读 RTL reviewer 时，lane 将显式移交；reviewer 归还前 root 不运行 WSL 工程命令。

## 2026-07-27 reviewer-v1 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/subagent-contracts/reviewer-v1.json`
- contract SHA-256:
  `3c784acda15aca26f102bd8bca212abfbdfde2de5ac29f812b91fe685378db5e`
- canonical pipeline: `create → validate → render` 全部 PASS。
- shell ownership：从本条开始移交给 `reviewer-v1`；root 在 reviewer 明确归还前不运行
  Windows→WSL 工程命令。

## 2026-07-27 reviewer-v1 bounded stop

- reviewer 未在有界等待内发布最终技术回复；主节点先请求仅基于已读材料收束，随后中止
  reviewer 回合。
- Windows 侧复核没有遗留指向本工作区的 `wsl.exe` 工程进程，唯一工程命令 lane 已回到 root。
- 本轮合同 JSON 与派发记录保留为诊断材料，但 reviewer-v1 不计 pre-review PASS；
  后续将用更窄的 versioned 合同重新执行独立复核，不放宽技术成功条件。

## 2026-07-27 reviewer-v2 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/subagent-contracts/reviewer-v2.json`
- contract SHA-256:
  `fcb958cfa8984ba7b075ab38317d22385722b8546033c27e3046f1e3a7525aaa`
- canonical pipeline: `create → validate → render` 全部 PASS。
- execution mode: `self-contained-no-tools`；只复核合同内冻结的本地 RV64 RTL
  equation，不读取工作区、不运行 shell、不修改文件，因此不占用 Windows→WSL
  唯一工程命令 lane。

## 2026-07-27 reviewer-v2 result

- reviewer 首行结论为 `GAP`，并给出
  `pending_arch_trap_fire` 未被更高优先 commit trap 接受条件约束的最强反例。
- reviewer 还要求动态覆盖 same-edge IRQ/arch birth、ECALL/IRQ/xRET/CSR/FENCE
  live-owner overlap、C0/C1/C2 owner/stop/no-repeat 与真实 `CsrFile` 采样。
- 主节点没有把该 GAP 降格为措辞问题；随后建立 pre-fix RED、实现最小 request
  priority 修复，并用 clocked TB 与 compile-success variants 杀死上述反例。
- reviewer 未使用 shell、未修改文件，Windows→WSL 唯一工程命令 lane 始终留在 root。
- 完整记录：`reviewer-report-v2.md`。

## 2026-07-27 final-reviewer-v1 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/subagent-contracts/final-reviewer-v1.json`
- contract SHA-256:
  `77074762c9f75b693fee68f89a166db2bc7b27887220dcd93ee041e7ae0b9a97`
- canonical pipeline: `create → validate → render` 全部 PASS。
- shell ownership：从本条开始移交给 `final-reviewer-v1`；root 在 reviewer
  明确归还前不运行 Windows→WSL 工程命令。reviewer 仅允许 `rg`、`sed`、
  `sha256sum` 读取合同列出的本地 RV64 RTL 与证据路径，不运行仿真/综合。

## 2026-07-27 final-reviewer-v1 result

- reviewer 明确停止全部 WSL 工程命令并归还唯一 shell ownership。
- verdict：V10A pending architectural-trap clocked exactly-once 子切片
  `PASS`；记录层在主节点更新前为 `GAP`；更宽 `SERIALIZE-G1`、八类
  pending SYSTEM post-fire、simulation exit/Linux、architecture-stable 与
  PPA 仍为 `GAP`/`UNQUALIFIED`。
- reviewer 独立核对 request priority、same-edge birth onehot、live-owner
  五类互斥、C0/C1/C2、assert-on/off、6/6 variants、113/113 module、
  functional/architecture 同 design-id 与关键 SHA。
- 保留覆盖洞：focused 日志无内嵌 design-id、pre-fix RED 无完整历史快照哈希、
  未独立 clocked 计数 predictor/最终 frontend redirect，且未运行综合/STA/Power。
- 完整记录：`final-reviewer-report-v1.md`。

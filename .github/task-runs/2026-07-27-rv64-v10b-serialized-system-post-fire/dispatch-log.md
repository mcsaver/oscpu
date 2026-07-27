# V10B dispatch log

## 2026-07-27 root start

- RTL object:
  `OooPendingSystemSequencer` eight canonical kinds through
  `OooPendingDrainResolveGate`, `OooCsrAccessRequestMux`,
  `OooCsrTrapRequestMux`, `CsrFile`, frontend redirect and MMU action.
- cycle/config:
  C0 accepted fire → C1 state/side effect → C2 no-repeat；
  CSR additionally spans enqueue → exact ProducerId/PC commit。
- evidence:
  V10A design-id
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`
  is the parent checkpoint.
- scope:
  `SERIALIZE-G1=OPEN`，simulation exit/Linux/PPA are not promoted by this node.

## 2026-07-27 pre-reviewer-v1 dispatch

- contract:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/subagent-contracts/pre-reviewer-v1.json`
- contract SHA-256:
  `fb88f47b1d59abf01ea637db7f3a57fee6e76fe58451946025ad40fdbcb84a5e`
- validation:
  canonical `create → validate → render` PASS。
- shell ownership:
  从本条开始移交给 `pre-reviewer-v1`。root 在 reviewer 返回前不运行
  Windows→WSL 工程命令；reviewer 只可执行合同列出的 `rg/sed/sha256sum`
  只读动作，结束后必须显式归还。
- expected output:
  八类 kind 的真实 signal/cycle/action 矩阵、最强 reachable counterexample、
  最小 clocked production-module TB 与 compile-success mutation 建议。

## 2026-07-27 pre-reviewer-v1 result

- RTL verdict:
  canonical kind、CSR exact PID/PC lease 与非 CSR holder/stop clear 的静态
  拓扑未发现已确认 production bug；八类 post-fire 总体为 `GAP`。
- blocking evidence gap:
  SATP/SFENCE/FENCEI MMU action、WFI/FENCE 零副作用和若干 C1/C2
  no-repeat 没有 production 顶层直接计数。
- strongest counterexample:
  切断 `OooMemoryAccess` 的 FENCEI MMU 输入可能仍保留既有 typed redirect
  绿灯；需要 compile-success mutation 动态确认。
- report:
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/reviewer-report-v1.md`
- shell ownership:
  reviewer 已停止全部 WSL 工程命令；唯一 Windows→WSL shell ownership
  已归还 root。

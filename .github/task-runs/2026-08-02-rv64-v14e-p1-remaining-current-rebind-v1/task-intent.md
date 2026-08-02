# RV64 V14E P1 remaining current rebind

- primary classification: `architecture`
- parent goal: active
- current design-id: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`（146 production RTL files）
- scope: `F0-G1`、`FENCE-G1`、`SERIALIZE-G1`、`VECTORED-TRAP-G1`
- hypothesis: 四门旧证据的主要缺口是 current source-set/provenance 绑定；实际 active cone 决定 replay 或定向 rerun。若 production RTL、实际 elaborated RTL、device model、simulator 语义或必要原始输入发生变化，则对应门必须动态重跑。
- competing hypothesis: memory/control 变更已进入某门的 elaborated source closure 或事务合同，旧正向/反例不能安全复用，必须以当前设计重新执行。
- required evidence per gate: current design-id、gate-specific positive RTL observation、compile-success RTL counterexample rejection、assertion-clean terminal marker、source pre/post identity。
- write boundary: 不修改 production RTL 或 canonical architecture/debt ledger；只写本 task-run 的脚本、结构化结果、bounded 日志和证据指针。
- PPA boundary: architecture gate、arch-stable 与 functional aggregate 尚未闭合，PPA 保持 `BLOCKED_BY_ARCHITECTURE`。
- workflow: 工程命令保持 Windows→WSL single-flight；确定性交付点再做 compact agent-flow、独立 reviewer 与最终审计，不运行无关 strict guard。

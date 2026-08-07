# Dispatch log

- Main RTL evidence objects: `OooDualMemAxiArbiter`,
  `OooLsuAxiLaneAdapter`, the six-case owner/B-response testbench, the frozen
  A2 workload receipt, and the optimization selector.
- Read-only causal-trace contract:
  `subagent-contracts/v15m-owner-timing-causal-trace-f7a.json`. The node was
  interrupted after two non-terminating attempts; no result from that node was
  used as engineering evidence.
- Independent review contract:
  `subagent-contracts/v15m-owner-timing-causal-review-f7a-v1.json`, SHA-256
  `8dd95519173f23ab4ed238ef007ce2bb9291f341bdef39c0b88c31ecbf9372f5`.
- Contract preparation and dispatch used the canonical
  `create -> validate -> render` path with isolated task context.
- The reviewer ran only the contract-listed read-only RTL/evidence commands
  while holding Windows-to-WSL single-flight ownership, then explicitly
  returned ownership to the main node.
- Review result: PASS for the L0 causal matrix, fail-closed sampling semantics,
  receipt reconstruction, negative mutations and selector transition.
- Review result path:
  `evidence/owner-timing-causal-independent-review.md`.
- Review boundary: H1 and H2 remain coupled; no production RTL candidate, PPA
  qualification or promotion is authorized.

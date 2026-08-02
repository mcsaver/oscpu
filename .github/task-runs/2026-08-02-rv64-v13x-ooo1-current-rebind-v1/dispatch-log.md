# V13X reviewer dispatch log

## Contract v1 — candidate only

- path: `subagent-contracts/v13x-ooo1-frozen-review.json`
- SHA-256: `101f4b99c9bde3759e198bcdcee1a6c25e402e8f8bfd6638fbaf34e486674483`
- disposition: not dispatched; Windows→WSL argument handling removed the literal SystemVerilog `$fatal`
  token from one supplied fact, so this contract was not used as final evidence.

## Contract v2 — stale candidate review

- path: `subagent-contracts/v13x-ooo1-frozen-review-v2.json`
- SHA-256: `7c941dceb83531094218797d0b34348b3446cdfe6a55d97808d2c07e1d61b57e`
- reviewer result: `APPROVED_FOR_CURRENT_SCOPE` for the then-frozen OOO-1 facts.
- disposition: candidate only. A new deterministic oracle test was added afterwards and the complete suite was
  rerun, changing the manifest, gate-log and proof hashes.

## Contract v3 — final frozen review

- path: `subagent-contracts/v13x-ooo1-frozen-review-v3.json`
- SHA-256: `fc9a7696d3f8237aea8cd5527ea6ee05e29a1e222fb8fde2885346586d51f35f`
- execution: `self-contained-no-tools`; only the contract's final RV64 RTL/TB/EDA facts were consumed.
- reviewer result: `APPROVED_FOR_CURRENT_SCOPE`.
- actionable next counterexamples: ROB index wrap/reuse with late response; flush/exception/kill/replay concurrent
  with long-latency completion; multiple long-latency owners; explicit retirement liveness/drain.
- preserved boundary: overall architecture RED; no full-system, CPI, synthesis, STA, area or power claim.


# v8n dispatch log

## Contract review

- Contract JSON: `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/subagent-contracts/v8n-true-ooo-contract-review.json`
- Contract JSON SHA-256: `ed6b867612939b83a34f929e6d5dddae316881657198d757281e9cccf0b4e8cd`
- Binding note: this SHA-256 binds only the JSON contract, not the design
  contract, RTL, tests, or evidence.
- Status: contract validated and rendered; reviewer dispatched.
- Mode required: native `self-contained-no-tools`; no shell, file access,
  network, accounts, credentials, external services, or writes.
- Review boundary: local RV64 Verilog/SystemVerilog architecture and
  verification only.
- Initial result: `contract-review-result.json`, strict verdict `gap`.
- Actioned blockers:
  - explicit accept/eligibility event binding and continuous owner-live checks;
  - four dual-issue accepts per class plus serial/MIQ/MulDiv freeze mutations;
  - non-zero ProducerId generations and three independent identity truncations;
  - activated non-head retirement mutation, nine-entry ROB identity census,
    holder drain/resource conservation, exact provenance, and atomic-merge
    fault injection.
- Revision contract JSON: `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/subagent-contracts/v8n-true-ooo-contract-review-r2.json`
- Revision contract JSON SHA-256: `967ff74240c2929d079c7d08d54ca0c2f542d508d997a28b618162b1e55b9607`
- Revision binding note: this SHA-256 binds only the revision JSON; the
  original contract JSON remains immutable and separately bound.
- Revision review status: validated, rendered, and dispatched in native
  self-contained no-tools mode.
- Revision result: `contract-review-r2-result.json`, strict verdict `pass`.
- Revision disposition: B1-B9 closed; promote scoped OOO-1 only, preserve
  same-design OOO-2, keep OOO-3/remaining architecture gates and PPA RED.

## Implementation review

- Contract JSON: `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/subagent-contracts/v8n-true-ooo-implementation-review.json`
- Contract JSON SHA-256: `f76bf979a12c1e0cb16c32c549b9e20bcfd0e10871c968041d855f37625bd590`
- Binding note: this SHA-256 binds only the implementation-review JSON,
  not the design contract, RTL, tests, or evidence.
- Status: contract validated and rendered; reviewer dispatched in native
  self-contained no-tools mode.
- Boundary: local RV64 RTL implementation/evidence review only; no shell,
  file access, network, accounts, credentials, external services, or writes.
- Result: `implementation-review-result.json`, strict verdict `pass`.
- Disposition: all seven executable false-green candidates were rejected;
  residual risks remain explicitly outside scoped OOO-1 and do not authorize
  OOO-3, overall architecture GREEN, or PPA work.

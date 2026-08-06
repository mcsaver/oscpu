# Evidence index

Classification: tooling/workflow. Retention is bounded to results, small logs, hashes and source-log pointers; no build product, waveform, simulator binary or copied A2/A3 console is stored here.

## Source-bound implementation

- `Linux/scripts/npc_systemd_transaction_evidence.py` — `8d15b93e9905e3719456d24ff9524c88212c229f4ca1d47efb723541aaadef6b`
- `Linux/scripts/check-npc-systemd-guest.sh` — `01a5198df6199a3bc620875914ca6fff8331b3a8c191b9d990257cf1103be113`
- `Linux/scripts/tests/test_npc_systemd_transaction_evidence.py` — `bbada7a8408096ed9bfd8e22fac3796f550d8da187478f51604ccbc1c9514e91`
- `Linux/scripts/tests/test_check_npc_systemd_guest_contract.py` — `e8dd06e8645de248ee5c2eff2b87b1f670812f605226cd157136cb6c5e05d736`

## Retained local logs

These `.log` files are intentionally retained under task-run for audit but remain ignored by Git.

- `logs/transaction-tests.log` — 2737 bytes — `487e5d3996bd131d37e9ebe2a7e4cad16435272e00888be86d0fd1833b27e41f`
- `logs/guest-contract-tests.log` — 3375 bytes — `c7bbad66940ec69413ada619055f70c85b76a30509971790b42f61ebe507d998`
- `logs/a2-verify.log` — 234 bytes — `6a586287ffbff219bafdf64e4b143749ebdde76d62210ac7bcb0d7f375145ce5`
- `logs/a3-verify.log` — 233 bytes — `045c1c737082cf9876648e1be4f644871737c3e47f39dfb3ade80fefb987d412`

## External immutable inputs/pointers

- A2 receipt: `.github/runtime-artifacts/npc-systemd-terminal-v2/a2-current.json` — `b8ad3c085c1f32664f2681f48f5a1972b93adae7b4a1964c61f2b993f3c6143c`
- A3 receipt: `.github/runtime-artifacts/npc-systemd-terminal-v2/a3-replay.json` — `38ed6763523a349262be577e756778eb1e3f2d9a48343cf8669990d0a2b130ed`
- A2 frozen console/NPC: `../2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/rootfs-093c2380-systemd-strict-6b-v14e-a2/guest/`
- A3 frozen console/NPC: `../2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3/guest/`
- Contracts: `subagent-contracts/terminal-collector-v2-review.json` and `subagent-contracts/terminal-collector-v2-review-v2.json`.

Evidence reuse boundary: valid only while the four source hashes and referenced frozen input hashes remain unchanged. A production RTL, simulator, device-model or elaborated-configuration change requires the corresponding system gate, not reuse of this tooling-only PASS.

Guard boundary: strict guard rc=1 is retained in `task-report.md`; no broad profile evidence was fabricated or inferred from this task-run.

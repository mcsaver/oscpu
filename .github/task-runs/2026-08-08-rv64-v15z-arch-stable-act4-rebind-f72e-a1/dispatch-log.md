# V15Z ACT4 upper-receipt rebind dispatch

- task: `v15z-v9p-act4-rebind-review-f72e-v2`
  - contract: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-v9p-act4-rebind-review-f72e-v2.json`
  - contract_sha256: `8c424abaebad436ce002ab85e4170316edbdc427c675b5b901feb8ea16e1e4d3`
  - mode: `read-only-review`
  - shell_ownership: `delegated-single-flight`
  - result_path: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-v9p-act4-rebind-review-f72e-v2.result.md`
  - state: `PASS_RETURNED`
  - conclusion: `V9P RTL semantics PASS; v1 layered/system exact hashes require versioned ACT4 rebind`
  - shell_ownership: `returned`

- task: `v15z-arch-stable-act4-rebind-review-f72e-v2`
  - contract: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-arch-stable-act4-rebind-review-f72e-v2.json`
  - contract_sha256: `e9eefb5e92d5d8ccec4b2b9ccc7e2652192f59f0adb48b1e37d4402531c9c0a9`
  - candidate_sha256: `697ec15673499dc7a2f8e6d07eece5b5020b0a4a5690e3885ff1646a55b6dade`
  - mode: `read-only-review`
  - predecessor: `v1 PASS retained; v1 review-receipt build rejected because the contract lacked the exact approval marker`
  - dispatch_exception: `fresh agent thread unavailable; reused the immediately preceding bounded reviewer`
  - result_path: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-arch-stable-act4-rebind-review-f72e-v2.result.md`
  - state: `PASS_RETURNED`
  - shell_ownership: `returned`

- task: `v15z-arch-stable-act4-rebind-review-f72e-v1`
  - contract: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-arch-stable-act4-rebind-review-f72e-v1.json`
  - contract_sha256: `dcb97c1c77f7814b381802a8e98c7a52ebcb8c59d8ad7fcfe07369f65e4d4b60`
  - candidate_sha256: `697ec15673499dc7a2f8e6d07eece5b5020b0a4a5690e3885ff1646a55b6dade`
  - mode: `read-only-review`
  - shell_ownership: `delegated-single-flight`
  - result_path: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-arch-stable-act4-rebind-review-f72e-v1.result.md`
  - state: `PASS_RETURNED`
  - dispatch_exception: `fresh agent thread unavailable; reused the immediately preceding fork-none V9P/ACT4 reviewer whose prior bounded evidence is included in this contract`
  - conclusion: `APPROVE_ARCH_STABLE candidate=697ec15673499dc7a2f8e6d07eece5b5020b0a4a5690e3885ff1646a55b6dade`
  - shell_ownership: `returned`

- task: `v15z-performance-baseline-act4-rebind-review-f72e-v1`
  - contract: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-performance-baseline-act4-rebind-review-f72e-v1.json`
  - contract_sha256: `53b640fc5d60ca8b03120fcbb22b1d5592d75195b5ef23be6eb0faf0594788c1`
  - result_sha256: `460fffbd42bd3824984c821120151f42a0062164475811725204d4582086ce32`
  - mode: `read-only-review`
  - shell_ownership: `delegated-single-flight`
  - result_path: `.github/task-runs/2026-08-08-rv64-v15z-arch-stable-act4-rebind-f72e-a1/subagent-contracts/v15z-performance-baseline-act4-rebind-review-f72e-v1.result.md`
  - state: `DISPATCHED`

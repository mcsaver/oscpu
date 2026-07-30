# V10G product-default queue-head=1 SYSTEM matrix

| case | test | compile | result | simulation | verdict |
| --- | --- | ---: | --- | --- | --- |
| `priv-system-assert` | `tb_ooo_priv_system` | 0 | FAIL | accepted | GAP |
| `priv-system-release` | `tb_ooo_priv_system` | 0 | FAIL | accepted | GAP |
| `csr-access-assert` | `tb_ooo_csr_access_request_mux` | 0 | PASS | accepted | PASS |
| `disconnect-satp-mmu` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `disconnect-sfence-mmu` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `disconnect-fencei-mmu` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `sfence-reason-to-serial` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `fencei-reason-to-serial` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `remove-fence-mem-idle` | `tb_ooo_pending_drain_resolve_gate` | 0 | FAIL | rejected | PASS |
| `retain-noncsr-holder-after-terminal` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `retain-stop-after-drain-terminal` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `remove-csr-producerid-match` | `tb_ooo_csr_access_request_mux` | 0 | FAIL | rejected | PASS |
| `remove-csr-pc-match` | `tb_ooo_csr_access_request_mux` | 0 | FAIL | rejected | PASS |
| `remove-wfi-control-commit` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `add-mmu-action-to-every-drain` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `drop-sfence-inval-ir-classification` | `tb_ooo_priv_system` | 0 | FAIL | rejected | PASS |
| `disconnect-fencei-fetch-cache-clear` | `tb_ooo_fetch_axi_bridge` | 0 | FAIL | rejected | PASS |

- all_pass: `false`
- design_id: `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`
- compile_success_mutations: `14`
- dynamically_rejected_mutations: `14`
- testbench_sha256_map:
  - `npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv`: `2ba8ddd9fdb8db655bf3754212a470f561a2200799be44546f74cad0e5d949a6`
  - `npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv`: `bab9479a2007900879bd8469ca992f9095dc6da2d597bf63ae3fb9b145338bd7`
  - `npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv`: `bdb8191629d7868e2150ef3f2d480a9d2767f26256133c8e6b12a386dd1e968d`
  - `npc/rv64/testbench/tests/tb_ooo_priv_system.sv`: `c92e591727b68bf1cea3321091e5000c2a95064a49255b9f25550a3e2fb4cfde`

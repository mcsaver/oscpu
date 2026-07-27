# Independent recovery/owner-birth review

RV64 RTL 结论｜对象=`OooPendingDispatchArbiter.pending_system_capture_*`、`OooPendingSystemSequencer.clear_i/producer_valid_q`、`OooStopPendingSequencer.stop_pending_o`、`OooFrontend.head0_csr_inflight_q`｜周期/配置=lane0/lane1 × `rob_walk_mode` 0/1 × empty/pre-ROB/exact-CSR-lease/queue-head-CSR｜TB/EDA 观测=未运行仿真/综合/STA；静态检查确认现有定向 TB 未覆盖 recovery-owner-birth 碰撞｜范围=GAP

## Contract binding

- JSON: `.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/reviewer-contract-v1.json`
- SHA-256: `f7d5a4ecf4cdc87b743c7e2cb322d148cd311fbbdce08e60e010d9d136f87047`
- Review mode: read-only; no workspace file was modified.

## Cycle-exact findings

1. Empty lane0 SYSTEM plus `branch_resolve_untracked_i`: pending holder
   clear wins, but the later raw `dispatch0_system_i` stop assignment creates
   an ownerless stop.
2. Empty lane1 SYSTEM barrier plus an accepted recovery: pending holder clear
   wins, but the later lane1 barrier assignment creates an ownerless stop.
3. Queue-head CSR visible while backend is not ready: there is no real
   `head0_csr_dispatch_fire_w` and no inflight owner, but raw SYSTEM can arm
   stop.
4. Queue-head CSR fire plus older branch/JALR kill: the inflight register
   rejects birth while stop accepts raw SYSTEM.
5. Existing queue-head CSR inflight plus older recovery: inflight dies but
   edge-old inflight rewrites stop to one.
6. Queue-head CSR C1 flush: inflight dies on C1 while edge-old inflight can
   recreate one cycle of orphan stop.

A post-dispatch exact CSR lease has the opposite phase rule: ordinary clear
must not kill the lease, so stop must remain asserted until exact
`producer_death_i` or the same C1 reset that clears the ROB and holder.

## Required correction

Use phase-aware accepted owner transition facts:

- pending birth only when the target holder accepts capture;
- queue-head birth only on real ready-qualified dispatch fire that survives
  same-edge older-control kill;
- pre-ROB death from accepted holder clear;
- exact lease death only from exact commit or C1 reset;
- queue-head death from exact commit, older-control kill or C1 reset.

Do not repair this by rearranging independent nonblocking assignments.

## Implementer evidence correction

The first directed simulation disproved one over-broad static statement:
`branch_resolve_untracked_i` and raw capture are already members of the same
`else-if` chain in `OooStopPendingSequencer`, so that particular pre-ROB
collision is clear-wins.  The independently placed
`branch_spec_resolve_valid_i` clear is the reproducible collision: its clear
is overwritten by the later raw lane0/lane1 SET.  The accepted implementation
scope therefore uses the demonstrated checkpoint-recovery RED and retains
`branch_resolve_untracked_i` only for exact lease/queue-head death analysis.

## Remaining scope

This review did not run simulation, synthesis or STA.  Memory-owner terminal
proof and seven-kind terminal exactly-once coverage remain outside this slice.
WSL engineering-command ownership was explicitly returned to the root node.

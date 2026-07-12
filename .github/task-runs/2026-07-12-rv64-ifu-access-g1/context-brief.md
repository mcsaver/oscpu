# IFU-ACCESS-G1 bounded context

- generated: 2026-07-12 23:40 +0800
- command: `python3 scripts/github_index_db.py brief IFU ACCESS ARSIZE PMP RRESP lane1 fetch fault device firewall --profile npc-dev --max-tokens 12000`
- result: live/stored DB brief completed; `npc-dev` selected. The generic brief was combined with the
  just-closed G2 task-run and a code-first read of the current bus/frontend/control path.
- base commit: `b1b1156db fix(rv64): preserve cross-page fetch fault provenance`
- dirty boundary retained from user: `build/linux-logs/npc-linux.log`, `OooAdUpdateChecker.sv`, the
  historical-path comment in `OooFrontend.v`, the active-spec comment in `NpcSimTop.sv`, and
  `.superpowers/`.

## Current dataflow facts

1. `OooFetchAxiBridge` fixes instruction reads to `ARSIZE=8B`, predicts page crossing with `PC+7`, and
   checks two fixed 4B PMP words before it knows the two RVC lengths.
2. `NpcAxiBus` already carries master ARSIZE/ARPROT into `AxiXbar`; `AxiXbar` stores ARPROT but drops
   ARSIZE at its AXI-Lite slave boundary. `AxiDpiSlave` therefore calls an unsized `npc_ifetch`, and
   `npc_paddr_read` validates/reads a full 8B word.
3. cache-hit eligibility uses `pmp_active ? grant : allow`; S/U no-match is actually default deny, and
   bare cache context does not compare privilege. M-mode fill followed by S-mode/pmpcfg=0 can bypass PMP.
4. `OooFetchHeadPairGate` suppresses every lane1 fetch fault after head0 branch; the dispatch gate then
   permits predicted-not-taken branch + sanitized NOP to pop. The arbiter separately filters real lane1
   instruction-access cause in ROB-walk mode.
5. page-table reads currently carry instruction ARPROT even though they are implicit data reads. A future
   execute firewall must distinguish PTW `data+8B` from instruction `exec+2B`.

## Scope boundary

- This task closes physical fetch footprint, PMP/RRESP owner, execute-device firewall, and downstream
  lane1 PF/AF capture/squash.
- IFU-TVAL-G1 remains separate: the first failing halfword frontier is retained, but `mtval/stval`
  faulting-portion semantics are not declared complete here.
- LSU/device lane, size, ordering and retired-store late-error policy remain separate platform contracts.
- 200MHz remains the parent goal; this correctness task must not claim timing closure.

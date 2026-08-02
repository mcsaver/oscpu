# V13P verification result

- classification: `architecture`
- secondary intent: `performance-cpi`
- implementation verdict: `DEVELOPMENT_PASS`
- promotion verdict: `NOT_ELIGIBLE_PPA_PENDING`
- production RTL SHA-256 (`OooMemAxiBridge.v`):
  `86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348`

## PASS scope

1. Bridge direct/fallback/drop contract under `OOO_ASSERT`:
   `[V13P-B-FUSION-CONTRACT][PASS] direct=3 fallback=1 killed-drop=1`.
2. Full bridge regression: `[PASS] tb_ooo_mem_axi_bridge` and
   `[RESULT] PASS`.
3. Real wrapper/backend direct lifecycle:
   `[V13P-BACKEND-B-FUSION] probe=1 aw=1 w=1 b=1 wb=1 sq_terminal=1 collector=0 registered_commit=1 sq_release=1 quiet=3 PASS`.
4. Compile-success source sensitivity:
   direct tie-off plus independent duplicate/fallback/killed variants are all
   rejected by their declared cycle marker; every mutation result JSON binds
   the current source SHA.
5. Same-config CoreMark pair: semantic/region/retired-instruction binding PASS;
   candidate is 3,123 cycles faster in this one pair.
6. Generic Yosys structural generation: PASS; candidate adds 9 generic cells
   and creates a selected four-stage B-to-response path.

## GAP scope

- Full-backend fallback under WB-slot saturation, two concurrent local SQ
  terminals and C0 barrier is not directed in this slice.
- CoreMark has no direct/fallback/drop event counter and only one A/B pair;
  causal attribution and repeatability are GAP.
- Yosys result is not mapped area/STA/power and was not fully re-audited by the
  independent reviewer.
- Qualified frequency, end-to-end B-to-backend timing, power, area and Pareto
  promotion remain GAP.

No assertion was removed or weakened, no duplicate terminal was hidden, and
AW/W acceptance remains nonterminal.

# V9J IFU-TVAL-G1 current-design closure

- `status`: complete
- `parent_goal`: active
- `canonical_command`: `make -C npc/rv64 check-ifu-tval`
- `architecture_debt`: `IFU-TVAL-G1=CLOSED`
- `ppa`: `UNQUALIFIED`
- `promotion_eligible`: `false`
- `design_id`: `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`

## Delivery evidence

- focused testbenches: `8/8`;
- current module inventory: `109/109`;
- compile-success RTL variants: `12/12` compiled and dynamically rejected;
- evidence validator tests: `12/12`;
- lifecycle joint manifest: `24/24` exact PF/AF, layout, frontier, lane-owner,
  `xEPC`, `tval`, capture, pending and drain rows;
- dispatch backpressure: one lane1 PF row proves no capture at `dispatch0_ready_i=0`
  and exact tuple capture/drain after READY acceptance;
- production RTL: unchanged before/after all variants;
- V2 independent bounded-material review: `PASS`;
- all CLOSED ledger artifacts: exact declared/actual SHA match;
- architecture audit: honest `GAP`, `37` remaining blockers; PPA remains unqualified.

The verification-only additions close exact instruction-fault `PC/cause/tval` ownership from the
first failing halfword through FIFO projection, lane acceptance, pending storage and CSR drain.
They do not claim fault-detection completeness, full-core architecture stability or physical PPA.

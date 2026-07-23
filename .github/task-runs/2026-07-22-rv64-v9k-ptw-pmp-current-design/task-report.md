# V9K PTW-PMP-G1 current-design closure

- `status`: complete
- `parent_goal`: active
- `canonical_command`: `make -C npc/rv64 check-ptw-pmp`
- `architecture_debt`: `PTW-PMP-G1=CLOSED`
- `ppa`: `UNQUALIFIED`
- `promotion_eligible`: `false`
- `design_id`: `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`

## Delivery evidence

- focused IFU/LSU bridge tests: `2/2`;
- current module inventory: `109/109`;
- compile-success RTL variants: `28/28` compiled and dynamically rejected;
- fail-closed evidence tests: `13/13`;
- IFU denied frontiers: `F=0/2/4/6`, with exact successful prefix and no younger
  instruction AR/AW/W;
- LSU denied rows: load-A readonly, store-D readonly and load-A partial8, each with
  response READY delays `0/1/2/3/5`, for `15` rows and `33` stalled-response cycles;
- LSU deny interval: owner kind/token/MMU epoch/original-VA `fault_tval` and access-fault
  class remain stable through response handshake while `AWREADY=WREADY=1`;
- arbitrary response-stall length: production AW/W VALID decoders contain only
  `S_WRITE_REQ`/`S_AD_UPDATE`; deny enters and holds `S_RESP` until response terminal;
- independent review sequence: V1/V2/V3/V4 found progressively narrower evidence gaps;
  V5 returned a design-ID-limited `PASS` after the unbounded state-decode certificate;
- production `.v` RTL: unchanged before/after every verification variant;
- architecture audit: `130/130` tests PASS, honest `GAP`, `36` remaining blockers;
  PPA remains unqualified.
- workflow closure: task-specific `npc-dev`, `agent-system` and `github-index` profiles all
  completed, followed by `scripts/agent-e2e.sh --guard --guard-mode strict` PASS for all three
  required profiles.

The closed claim is limited to local IFU/LSU PTW PTE 8B S-mode WRITE PMP decision,
checker-address-to-AW binding, independent AXI AW/W acceptance, access-fault ownership and the
deny-to-terminal quiet interval. It does not duplicate downstream IFU lane PC/`tval` claims,
does not invent an `AWPROT` port, and does not qualify full-core architecture stability or PPA.

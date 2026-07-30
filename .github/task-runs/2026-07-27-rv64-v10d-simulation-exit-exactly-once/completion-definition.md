# V10D completion definition

- current design-id:
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
- state: `APPROVED_FOR_CURRENT_SCOPE / RECORD_CLOSED`
- complete when:
  - [x] lane0 and lane1 accepted exit births are exact-one
  - [x] active older memory holder blocks the raw exit event
  - [x] exact memory-terminal eligibility produces one raw exit pulse
  - [x] C1 clears `pending_exit` and `stop_pending`
  - [x] C1 latches `exit_valid`, exit kind and `halted`
  - [x] C2+ has no second raw exit event without a new capture
  - [x] `core_local_flush` kills a pre-ROB exit owner without an exit pulse
  - [x] older trap priority is explicit at raw and latched boundaries
  - [x] focused assertion-on/off and compile-success negative variants pass
  - [x] required current-design layered evidence passes
  - [x] implementer/reviewer findings are reconciled
  - [x] memory, task-run index, e2e and strict guard are updated
- explicit non-completion:
  this slice alone does not close Linux/rootfs terminal evidence,
  architecture-stable freeze, synthesis/STA/power, PPA, or the long-term goal.

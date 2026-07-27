# RV64 V9S SERIALIZE-G1 default-configuration contract

## RTL design point

- design-id:
  `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`
- target configuration: `OOO_CSR_QUEUE_HEAD=1`
- diagnostic assertion configuration: `OOO_TERMINAL_HOLDER_ASSERT=1`

## Architecture scope

- Prove the implemented head0 non-FP CSR queue-head path on the current RTL:
  dispatch, ROB ownership, `mem_idle` retirement gate, typed C0/C1 application,
  `CsrFile` write, younger-state cancellation, and next-PC refetch.
- Preserve FP CSR and all non-CSR SYSTEM operations on their existing typed
  pending owners. This slice does not claim complete SYSTEM-uop ROB citizenship.
- Change the repository defaults only after the current-design flag-on rootfs
  gate reaches the strict guest marker and natural poweroff.

## Evidence boundary

- Existing focused/config, 110-test module inventory, compile-success variants,
  330-test full-state DiffTest, and functional aggregate remain supporting
  evidence only when their RTL design binding matches this design point.
- The old-design flag-on rootfs assertion and the current-design default-off
  bounded kernel run are diagnostic history; neither is a flag-on completion
  result for this design point.
- PPA remains `UNQUALIFIED` until the separate full-core arch-stable gate passes.

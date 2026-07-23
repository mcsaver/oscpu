# OOO-3 independent RTL review v1

- contract: `subagent-contracts/v8v-ooo3-final-review.json`
- contract SHA-256: `edcdf5c70224f8c6b360ff5ad8964bbfcecc0530d6b82fed238ac2aa8105834e`
- verdict: `GAP`

## Findings

1. `checkpoint_restore_i` cleared the two MIQs and retry holders but did not enter LQ recovery, so launched load
   ProducerIds could remain as live entries after checkpoint restore.
2. OOO-3 source checking only proved module/depth and SQ PA visibility; the directed record did not bind a fixed
   provenance inventory, and its source manifests were compared byte-for-byte without rehashing live files.
3. LQ release readiness was observed by assertions but did not actively gate ROB commit.
4. The OOO-3 backend profile did not execute `V8S_DUAL_MEMORY_FOCUSED`, so checkpoint, dual-bank retry and parent
   retirement internals were not directly present in the OOO-3 record.
5. Simultaneous final-PA queries carrying one ProducerId selected query0 implicitly rather than failing closed on
   both ports.

## Implemented closure

- Checkpoint restore drives LQ global recovery; launched incomplete loads become tombstones and exact collector
  terminal events drain them.
- ROB head load lookup and real commit are separate LQ inputs; `lq_retire*_permit_w` gates both commit lanes and
  only commit/fire frees normal entries.
- Both same-PID query ports close, with a dedicated dynamic scenario and compile-success mutation.
- OOO-3 runs default and V8S dual-backend profiles and binds checkpoint drain, retire authority and retry lifecycle.
- Architecture source checks cover every active LQ boundary; exact provenance and live source-manifest hashes are
  replay-checked, with negative unit tests.

The v1 GAP is not promoted to PASS.  A new versioned contract must review the final source/evidence closure.

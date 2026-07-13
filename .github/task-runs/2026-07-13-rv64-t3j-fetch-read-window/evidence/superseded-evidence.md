# Superseded / invalid intermediate evidence

- `evidence/focused-smoke/` is the first focused-run attempt. Its relative output
  path was interpreted below `npc/rv64/testbench`, so it is not a canonical task
  result. The valid replacement is `evidence/focused-window/`, followed by the
  complete `evidence/current-contract-final/` contract bundle.
- `evidence/negative-probes-root-rerun/` is an interrupted partial rerun and
  contains only the first negative case. The complete fail-closed verdict is in
  `evidence/negative-probes/`; both injected violations emit their exact contract
  marker and make exits nonzero.
- `evidence/negative-probes-relative-outdir-check/` is a runner path-hardening
  check, not the canonical negative-probe result. It verified that an absolute
  output directory avoids creating a nested task-run tree.
- `evidence/opensta-focused-fresh-t3j/` is the first focused current-netlist
  attempt. The checker incorrectly required a register `Q` startpoint even though
  OpenSTA reports the sequential launch pin `CK`; it therefore failed before the
  CK-to-same-cell-Q provenance check was added. The old-netlist smoke and all
  `*-hardening-smoke` directories are checker-development evidence only.
- Only `evidence/opensta-focused-old-t3i-final/`,
  `evidence/opensta-focused-fresh-t3j-final/`, and
  `evidence/opensta-fresh-t3j-final/` participate in the final STA verdict. The
  final global result remains a valid RED target verdict: WNS `-8.840 ns`, TNS
  `-199477.67 ns`, and `target_200mhz_met=false`.

# T3J fresh synthesis / OpenSTA provenance

period_ns=5.0
netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a

- Synthesis start: `2026-07-13T16:54:16+08:00`
- Recorded Git HEAD: `8532bad0794cb34199c8adf49b080e1773b1f16f`
- Yosys: `0.66+197`, delay target `5000.0ps`, strategy `DELAY-4`
- PDK/corner: `icsprout55`, H7CL typical `1.2V / 25C`
- Fresh netlist: `NpcTop-200MHz`, 110 modules, SHA shown above
- T3I comparison netlist SHA: `91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926`
- OpenSTA executable SHA: `50fb07e41cd448cbb6ee782cc552db9adff12ed5f98d02bcca97ea3d7c2dd788`
- H7CL standard-cell Liberty SHA: `55c129ca0f03a409622e6c309f7f2da3034a003323fc6f4e58ae2225ed416264`
- Macro Liberty SHA values: `Sram4096x199=8ab0ad9d...c8c6`,
  `Sram4096x113=ec50e7d4...0f67`, `OooFpArithGate=e151ba88...f703`,
  `OooBranchDirectionPredictor=ddbd7ba1...699c`.

The synthesis wrapper froze 110 synthesis RTL inputs, all 133 files below
`npc/rv64/vsrc`, and five explicitly listed flow inputs before/after the run.
The corresponding manifest digests are `9603a445...d563`,
`6adc06eb...e055`, and `dc30aae4...5828`; the hardened audit also recomputed
every listed current-file SHA and checked the exact Yosys configuration markers.

This is intentionally recorded as a **limited five-flow-input freeze**. The
wrapper did not pre-hash every Make/Tcl/PDK/Liberty/tool dependency, so this
intermediate T3J result must not be described as reproducible from the recorded
Git HEAD alone. In particular, the frozen source tree includes protected user
worktree content such as `OooFrontend.v` SHA `065738b9...c405a`. A future
200 MHz-closing run must use the expanded provenance manifest documented in the
T3J task report.

Final H7CL OpenSTA at 5.0ns reports 40/40 pending-trap endpoints, WNS
`-8.840ns`, TNS `-199477.67ns`, zero combinational loops, and total power
`0.117W`. The independent target checker therefore records expected RED
(`rc=1`); archive completeness does not mean that 200 MHz was met.

# R2.5 region A/B artifact

This directory freezes the two independently built simulation binaries, the identical host-only region probe, the A/B-only RTL delta, and the exact Dhrystone/CoreMark run scripts.

- `binaries/NpcSimTop-A-R2p4-region`: true R2.4 sandbox binary.
- `binaries/NpcSimTop-B-R2p5-region`: same source plus only the R2.5 `NpcCoreTop.v` ordinary-store/I-cache change.
- `region-probe.patch`: identical sim-only commit/cycle snapshot instrumentation applied to both.
- `r2p5-only-NpcCoreTop.patch`: final A-to-B RTL difference.
- `run-region-ab.sh`: Dhrystone A-B-B-A-A-B.
- `run-core-ab.sh`: CoreMark A-B-B-A-A-B.

The Dhrystone timed-region retired blocker is closed: both designs retire 4,250,000 instructions in-region.

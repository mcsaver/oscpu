# V9Y dispatch log

## Shell ownership

- Windows to WSL engineering commands remain single-flight.
- A contracted RTL reviewer may temporarily own the only WSL command lane.
- While that reviewer is active, the root node runs no WSL command.

## Current state

- Root mapped the production twelve-lane collector ingress order and preserved
  the pre-fix RED.
- V1 reviewer contract SHA
  `a22d03f2e49621db916e620ba0002f1341b4ab8cb7c7e6a6ccb844b254c80fa9`
  identified the active-holder GAP and specified the exact scalar boundary.
- Root implemented the scalar path and initial focused/mutation evidence.
- V2 reviewer contract SHA
  `a71208b4068eaead54cf4b95eb54f6803ebf0104ab889461249b2a821c5d8a12`
  found two blockers: production logic under `OOO_ASSERT` and raw ingress used
  as transfer authority.
- Root moved the production census outside the macro, exported exact
  collector acceptance, added assertion-on/off acceptance and SQ-release
  observations, and added three release-config mutations.
- V3 reviewer contract SHA
  `f355bb9b617bbd2786d284e07b6f7614c53aba25347237b7be24891b14c427f0`
  confirmed both RTL blockers closed but found stale mutation TB provenance.
- Root reran the acceptance mutations with the final TB.
- V4 reviewer contract SHA
  `7b5819ed8a4e0ff5bee89196250af6946b5425ae87032c064e738b58f3cb056e`
  matched live RTL/TB SHA, 3/3 release mutation oracles, and common
  functional/architecture design identity; verdict `PASS`.
- Every reviewer was read-only, stopped its commands, and explicitly returned
  the unique WSL command lane before root resumed.
- V9Y subrange is closed; broader `SERIALIZE-G1` remains OPEN.

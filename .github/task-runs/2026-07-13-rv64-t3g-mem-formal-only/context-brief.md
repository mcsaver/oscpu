# T3G bounded context brief

- profile: `npc-dev`
- query: `MEM completion fast wake PRF bypass load use`
- baseline commit: `c4a97fbda`
- fresh baseline: T3F 5 ns WNS `-12.838 ns`, loops `0`, top40 `40/40` DCache-started。
- root cause: MEM response 经 fast wake→IntIQ select→PRF bypass→integer execute/branch/kill
  继续形成约 16 ns 的真实同拍组合链。
- minimal cut: 只把 `OooIntBackend.fast_wb0/1` 收紧为 EX-only；formal WB、PRF write、
  IQ full-wakeup、ROB/commit、MEM response handshake 全部不动。
- rollback trigger: 任何正式 MEM completion/FP load/SC 语义回归，或 fresh STA 未消除
  DCache→integer fast consumer 的组合弧。

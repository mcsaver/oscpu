# v8h holder census delta（实现后）

| holder | v8g 状态 | v8h 目标 | 本地裁决 |
| --- | --- | --- | --- |
| `OooMulDivUnit` request/run/response | raw ROB idx AUTH RED | 单一 full PID + full-lifetime Q lease + exact-open sink | 本地 GREEN；唯一 `producer_id_q`，death-edge old-Q lease 已测 |
| `OooClmulUnit` run/response | raw ROB idx AUTH RED | 单一 full PID + full-lifetime Q lease + exact-open sink | 本地 GREEN；唯一 `producer_id_q`，death-edge old-Q lease 已测 |
| `OooIntBackend` long-op WB arbiter | raw idx可直接 side effect | transport/authority 分权 | 本地 GREEN；raw route/ready 与 actual exact-open/full-PID claim 分离 |
| dispatch collision fence | memory lease only | memory+MulDiv+CLMUL union | 本地 GREEN；三项 mask union、三处 indexed lookup、pair PID distinct |
| ROB completion authority | EX0/EX1/memory query | 再加 MulDiv/CLMUL同义 query | 本地 GREEN；query3/4 exact valid/generation/`!done`/kill |

本地 GREEN 的证据边界：focused assert/release 5/5、23/23 compile-success mutation、模块聚合
105/105、style/contract、strict lint 无新增 signature。真实 architecture inventory 仍 RED，故不把
本表解释为全核 holder census 完成。

明确仍 RED：FP IQ/arith/backend/done FIFO、branch resolve packet、pending-system/trap/control commit、
CsrFile/Q1、wrapper full identity、finite-generation 全核 last-reference/no-live-reuse。

# 派发日志

| worker | scope | status | result |
| --- | --- | --- | --- |
| `timing_baseline_audit` | 最新 NpcTop 网表、SDC、OpenSTA top40 与 200 MHz 可复现性 | completed | 10 ns WNS −5.35 ns；单点 buffer 不充分；正式 5 ns 需重综合；现有结果非物理 signoff。 |
| `functional_baseline_audit` | current 回归真实性、开放合同、Linux 层级与完整功能口径 | completed | official 177/177；AM 58/59；3 个 TB 假绿；8 个开放合同；推荐 Linux-capable 单 hart 口径。 |
| `root` | 依赖整合、路线裁决与设计规格 | review_pending | 采用双门槛交替路线，等待书面设计复核后进入 implementation plan。 |

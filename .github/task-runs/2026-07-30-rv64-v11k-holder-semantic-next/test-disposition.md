# V11K test disposition

- `tb_ooo_mem_inflight_queue`：KEEP；单实例精确 owner、flush/kill 与 FIFO
  行为继续 PASS。
- `tb_ooo_dual_mem_inflight_queue_semantic`：ADD；两个 MIQ lane 的
  capture/hold/cross-reject/flush/kill/exact-consume/occupancy matrix。
- `tb_ooo_int_backend`：KEEP；双访存后端普通回归继续 PASS。
- `run_v11k_miq_holder_semantic.py`：ADD；2 个 production profile、
  12 个 compile-success RTL 变体 × assertion/release、4 个
  push/pop X/Z interface probe × assertion/release、3 个带完整
  source/vvp/post-hash 的普通回归。
- `test_run_v11k_miq_holder_semantic.py`：ADD；7/7 runner 合同单测 PASS。
- `test_producer_holder_semantic_coverage.py`：EXTEND；当前 ledger、
  双产品实例、完整 evidence contract 与两态 elaborated-logic identity
  均 fail-closed。
- 全局 `test_arch_stable_freeze`：50/53；三项既有 V9R/control-event
  绑定漂移与全架构 GAP 保留，不属于 V11K 局部修复范围。
- 未启动完整系统 workload、综合、STA、功耗或 PPA 测试。

# 2026-06-04 RV64 PLIC bitmap/wstrb task report

## 结论

`AxiLitePlic` 已完成一轮 PPA/可读性收敛：byte strobe 写合并变成固定 lane mux，pending/enable bitmap 具备真实 byte-level `WSTRB` 语义，claim 仲裁由线性扫描改为平衡比较树，并保留原有优先级和低 ID tie-break 语义。

## 关键行为

- source0 继续强制无效。
- external level source 在非 in-service 时置 pending。
- claim read 清 pending 并置 in-service。
- complete 清 in-service，若 source level 仍有效则重新 pending。
- software pending 写保持原顺序：claim clear 后、complete re-pend 前。
- 64-bit priority beat 的 low/high word 映射保持原样。

## 覆盖

- focused PLIC TB 覆盖 reset、priority high lane、enable、threshold、level re-pend、software pending、multi-source higher-priority claim。
- 新增 source9 byte1 enable strobe 和 source9 software pending byte1 strobe，防止回退到只看 `WSTRB[0]`。
- 相关系统路径通过 `tb_ooo_priv_system`、`tb_axi_lite_to_uart`、lint、Verilator build 和 OpenSBI smoke。

## 后续建议

- 若继续平台设备 PPA，可检查 `AxiLiteXbar` 的 arbitration/owner loops 和 single-outstanding read/write ownership。
- 若继续 Linux 设备完整性，应补 virtio IRQ source 压力、PLIC gateway edge/level 行为和 DTB/driver 契约，而不是只依赖当前 mini PLIC smoke。

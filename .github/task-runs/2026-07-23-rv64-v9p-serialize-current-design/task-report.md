# RV64 V9P SERIALIZE-G1 current-design report

## 当前状态

`in_progress`（rootfs strict gate 正在运行）

## 已知基线

- parent RTL design-id:
  `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`
- `OOO_CSR_QUEUE_HEAD=1` 的 V9O focused/config 证据为 3/3 PASS；
- RTL、NPC Makefile 与 Linux Makefile 的默认值仍为 0；
- SERIALIZE-G1 ledger 状态仍为 OPEN；
- full-core 仍为 GAP，PPA 为 UNQUALIFIED。

## 当前 RTL 设计点

- design-id：
  `sha256:cf2e944622c422fbec52dcb1ddb439c52fb3f8e4a99d4cceb8cf562f88f2e325`
- `OOO_CSR_QUEUE_HEAD=1`；
- 更老 branch/JALR selective recovery 会释放被杀死的
  `head0_csr_inflight_q`；
- `CsrFile` 保存 `mstatus.VS[10:9]`，SD 汇总 FS/VS Dirty；
- IFU PTE.A 写响应完成会使双 D-cache 的潜在旧页表行失效。

## 措辞纠偏样本

V9O 第三轮 reviewer 已写出本地证据报告，但最终自然语言显示中止。v1/v2/v3 差分显示，v3
技术正文以泛化软件校验活动为主语，而非以 CONTROL-EVENT-G1 的具体 RTL/证据对象为主语。
平台内部分类原因不可观测，因此这里只记录为高置信措辞假设。

当前 canonical renderer 已改成精简硬件事实提示：只输出 RV64 RTL/证据对象、周期/配置、
TB/EDA 观测、合同绑定、工程动作和结论范围；协调元数据只留在 JSON/dispatch log。

## 已完成证据

- 独立只读架构复核正常返回，并定位真实 selective-recovery owner 缺口；
- branch/JALR 错误路径 CSR RED→GREEN；
- `tb_csr_file` 的 VS/SD 正反例 PASS；
- IFU A-update 与双 D-cache 维护定向 TB PASS；
- `OOO_CSR_QUEUE_HEAD=1` 模块集合 110/110 PASS；
- flag-on Verilator build PASS；
- full-state smoke 4/4 PASS；
- full-state riscv-tests 330/330 PASS（p=177，v=153，binding stable）。

## 待完成

- flag-on rootfs strict guest + natural poweroff；
- 默认配置变更与默认配置 current-design 验证；
- evidence/ledger/full-core 边界更新；
- memory/e2e/strict guard。

# Rerun1 rootfs provenance classification

- status:
  `FAIL rc=143 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0 signal=TERM`
- classification:
  `writable_rootfs_template_reused`
- functional conclusion:
  `INCONCLUSIVE`
- promotion eligibility:
  `false`

本轮 binding 阶段发现 strict ext4 的 SHA-256 为
`d5126bd00f49a7a00d90efc32d522e89ac7d2082e49a4a85ddb4f596ad087594`，
而原始 strict 模板证据为
`d4cda519bef51088b320c3a50486f24c678313eadce0b3905a9c439d91d71b06`。
对应 CPIO 仍保持
`ec6a1baad2c65abd22a67a9bc73c3064d2e06761278901e7ea723665e459be79`。

进程树显示 `NpcSimTop --block=` 仍指向共享 strict ext4，说明上一轮 guest 的合法可写
block transaction 已改变模板输入。为避免用不同 rootfs 状态比较同一 RTL 设计点，本轮在 OpenSBI
早期阶段对精确 detached session 发送 `TERM`。新的 fail-closed runner 正确记录 stage、signal 和
cleanup rc；没有把本轮写成 PASS。

后续 `rerun2` 在启动前重建并校验原始模板，将 block backend 指向
`.github/runtime-artifacts/rv64-systemd-strict/<run-label>/rootfs.ext4` 独立副本，并要求模板前后
SHA-256 不变。

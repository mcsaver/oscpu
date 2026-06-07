# nemu E2E Contract

- **范围**: ISA reference、AM target、SOC_SIM reference、设备模型、Linux/rootfs NEMU gate。
- **上游**: abstract-machine 镜像、Linux rootfs/image。
- **下游**: DiffTest、NPC target 对比、RV64 Linux evidence。
- **L0 gate**: `nemu-config-probe` 记录当前 `.config` ISA/target。
- **L1 gate**: `nemu-add-smoke` 在 AM-compatible 配置下跑 `cpu-tests add`，否则 SKIP。
- **L2 gate**: `nemu-ubuntu` 做 NEMU Ubuntu rootfs 切片静态生产守门，覆盖脚本语法、DTS 生成器、performance config 和近期设备/性能切片 guest marker/device hook（virtio-rng、goldfish-rtc、virtio-blk topology/CONFIG_WCE/event idx、DISCARD/WRITE_ZEROES、pread/pwrite 后端、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache、TB 边界中断 fast flag 等）。
- **L3 gate**: `nemu-ubuntu-gate` 在显式 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 时运行真实 `check-nemu-systemd-guest`，默认 SKIP 以避免日常小改都触发十几分钟长跑。
- **证据**: NEMU config summary、GOOD/BAD TRAP、guest marker、Linux focused gate。
- **升级路线**: 增加 config-preserving smoke：临时 O=build/e2e 配置，不污染用户 `.config`；把长期稳定的设备切片 gate 继续提升为 `nemu-ubuntu` 必检 marker。

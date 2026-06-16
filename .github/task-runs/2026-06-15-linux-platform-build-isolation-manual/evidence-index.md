# Evidence Index

| Evidence | Status | Notes |
| --- | --- | --- |
| `bash -n` changed scripts | PASS | Shell syntax for Linux scripts and e2e modules. |
| `make -C Linux ARCH=riscv64-nemu paths` | PASS | Shows `PLATFORM_ROOT=Linux/env/platforms/nemu`. |
| `make -C Linux ARCH=riscv64-npc paths` | PASS | Shows `PLATFORM_ROOT=Linux/env/platforms/npc`. |
| `make -C Linux ARCH=riscv64-nemu rootfs-dtb` | PASS | Outputs `Linux/build/riscv64-nemu/npc-rv64-nemu-rootfs.dtb`. |
| `make -C Linux ARCH=riscv64-npc rootfs-dtb` | PASS | Outputs `Linux/build/riscv64-npc/npc-rv64-rootfs.dtb`. |
| `make -C Linux ARCH=riscv64-nemu opensbi-rootfs` | PASS | Outputs NEMU no-PMU firmware under `env/platforms/nemu/build/opensbi/rootfs`. |
| `make -C Linux ARCH=riscv64-npc opensbi-rootfs` | PASS | Outputs NPC firmware under `env/platforms/npc/build/opensbi/rootfs`. |
| `make -C Linux ARCH=riscv64-{nemu,npc} linux-image` | PASS | Both platform `O=` kernel builds available. |
| `make -C Linux ARCH=riscv64-nemu check-nemu-kernel-config` | PASS | Reads platform `.config`. |
| Linux source tree clean check | PASS | No `env/src/linux/.config`, `include/generated`, or `include/config/auto.conf`. |
| `make -C Linux ARCH=riscv64-nemu -n run` | PASS | Firmware/rootfs/overlay/log all expand under `env/platforms/nemu`. |
| `scripts/agent-e2e.sh --validate-profile --profile contracts` | PASS | Profile binding validation only. |
| `scripts/agent-e2e.sh --validate-profile --profile rv64-linux` | PASS | Profile binding validation only. |
| direct `e2e_rv64_linux_contract` | PASS | Checks `Linux/scripts/platform/{nemu,npc}.mk`. |
| full `contracts` dispatch | BLOCKED | Existing untracked agent/e2e source hygiene, not Linux build isolation. |

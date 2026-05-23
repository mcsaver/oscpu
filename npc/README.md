# NPC 顶层入口

`npc/` 保留为兼容入口，真正的平台无关仿真顶层在 `npc/sim/`。外部模块应优先和 `npc/sim` 交互；从 `npc/` 执行的常用目标会继续代理过去。

- `single`: 默认后端，面向 AM / `riscv32-npc` / `NpcSimTop` 自仿真，不接入 ysyxSoCFull。
- `soc`: 从 `single` 复制出的 ysyxSoC 接入版本，保留 `ysyx_26010035`、`NpcSoCAxiBridge` 和 `soc/soc-lint`。

常用命令：

```sh
make -C npc lint
make -C npc run IMG=/path/to/image.bin RUN_ARGS='--no-progress -m 0'
make -C npc BACKEND=soc lint
make -C npc soc-lint
make -C npc soc
```

如果希望持久切换默认后端，推荐走 `npc/sim` 自己的 Kconfig 配置：

```sh
make -C npc/sim menuconfig
make -C npc/sim single_defconfig
make -C npc/sim soc_defconfig
make -C npc switch BACKEND=soc
make -C npc status
make -C npc switch BACKEND=single
```

`BACKEND=am` 是 `single` 的别名，`BACKEND=ysyx-soc` 是 `soc` 的别名。`abstract-machine` 的 `riscv32-npc run` 入口会直接调用 `npc/sim`；默认跟随 `npc/sim/.config`，仓库默认配置为 `single`，需要临时切到 SoC 复制版时可传 `NPC_SIM_BACKEND=soc`。旧的 `NPC_PLATFORM=soc` 仍保留兼容。若要配置当前真实后端自身的 Kconfig，可从顶层使用 `make -C npc backend-menuconfig` 或 `make -C npc backend-perf_defconfig`。

# NPC 仿真顶层

`npc/sim` 是平台无关的仿真入口，职责类似 AM 的 `scripts/platform/*.mk` 分层：外部模块只和这一层交互，这一层再选择真实后端。

当前后端：

- `single`: 默认后端，运行未接入 ysyxSoCFull 的 `NpcSimTop` 自仿真版本。
- `soc`: ysyxSoC 接入复制版，同时也保留普通 `NpcSimTop` 后端用于 AM 镜像 smoke。

常用命令：

```sh
make -C npc/sim run IMG=/path/to/image.bin RUN_ARGS='--no-progress -m 0'
make -C npc/sim BACKEND=soc run IMG=/path/to/image.bin
make -C npc/sim lint
make -C npc/sim BACKEND=soc lint
make -C npc/sim soc-lint
make -C npc/sim soc
```

推荐使用 Kconfig 风格管理默认后端：

```sh
make -C npc/sim menuconfig
make -C npc/sim default_defconfig
make -C npc/sim single_defconfig
make -C npc/sim soc_defconfig
```

也可以用快捷目标持久切换默认后端，它会更新 `npc/sim/.config`：

```sh
make -C npc/sim switch BACKEND=soc
make -C npc/sim status
make -C npc/sim switch BACKEND=single
```

AM 侧默认调用本目录。保持默认时无需传参；如果要让 AM 镜像跑在 `soc` 复制版普通后端上，传：

```sh
NPC_SIM_BACKEND=soc
```

临时覆盖仍然可以直接传 `BACKEND=soc`，不会改写 `.config`。兼容别名：`BACKEND=am` 等价于 `single`，`BACKEND=ysyx-soc` 等价于 `soc`。

如果要配置当前真实后端自身的 Kconfig，使用 `backend-` 前缀代理，例如：

```sh
make -C npc/sim backend-menuconfig
make -C npc/sim backend-perf_defconfig
```

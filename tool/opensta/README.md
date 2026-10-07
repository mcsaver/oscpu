# OpenSTA

从 `tmp/rv64-opensta/build/sta` 迁出的本地工具入口。运行：

```sh
tool/opensta/bin/sta -version
```

本地保留版本为 `3.1.0`。`bin/` 中的可执行文件由 Git 忽略，新克隆不包含该二进制。
上游许可证见 [LICENSE](LICENSE)，源码来源及构建步骤见
[UPSTREAM-README.md](UPSTREAM-README.md#build-from-source)。

按上游说明构建后，将可执行文件放到 `tool/opensta/bin/sta` 并保留执行权限；
也可通过 `make -C npc/rv64 sta OPENSTA=/absolute/path/to/sta` 指定已有工具。
版本检查只确认工具可用，不代表已经运行或通过工程 STA。

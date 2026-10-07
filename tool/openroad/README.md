# OpenROAD

从 `tmp/rv64-openroad` 迁出的本地运行时入口。运行：

```sh
tool/openroad/openroad -version
```

启动器按自身位置加载 `runtime/` 内的库，不再依赖 `tmp`。本地保留版本为
`v2.0-17598-ga008522d8`；运行时和共享库由 Git 忽略，新克隆需要自行部署。

恢复时按 [package.json](package.json) 与 [dependencies.json](dependencies.json) 中的
URL 下载主包及依赖，逐个核对记录的 SHA-256，再将这些 `.deb` 包用
`dpkg-deb -x <package.deb> tool/openroad/runtime/` 解包到同一目录。
该方式只解包文件，不执行系统包安装。完成后运行上述版本命令检查启动器和动态库。

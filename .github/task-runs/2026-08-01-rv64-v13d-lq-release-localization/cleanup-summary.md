# V13D runtime cleanup

- 已解析并核对删除目标：
  `/home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13d-lq-release-localization`。
- 删除前：`260,235,414` bytes，38 个可再生 Yosys/OpenSTA 文件。
- 保留：candidate/baseline RTL/TB/spec 快照、功能日志、coarse/mapped statistic/check、OpenSTA
  top-40/setup/console 及压缩 Yosys console。
- 删除后：目标不存在；四个 raw-Q 和所有 focused/integration `.vvp` 亦在各次运行后删除。
- 可恢复性：已删除网表和工具中间文件不可直接恢复，但可由冻结源码、配置和工具版本重新生成。

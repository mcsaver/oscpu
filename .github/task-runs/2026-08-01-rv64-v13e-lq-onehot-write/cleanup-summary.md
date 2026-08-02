# V13E runtime cleanup

- 删除前先独立解析目标：
  `/home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13e-lq-onehot-write`。
- 删除量：`113,782,010` bytes、15 个可再生文件。
- 删除对象：candidate coarse/mapped netlist、Yosys runtime logs 及临时 focused/raw-Q/rollback
  compile images；所有 `.vvp` 在各层运行后先行删除。
- 保留对象：candidate/parent source snapshots、functional logs、coarse/mapped statistic/check、
  OpenSTA top-40/setup/console、压缩 Yosys console及配置。
- 删除后目标不存在。已删除对象不可直接恢复，但可由冻结源码、配置及工具版本重建。

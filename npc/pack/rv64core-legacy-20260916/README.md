# rv64core 旧核归档 · 2026-09-16

此目录保存承岳64正式化时的 **旧 rv64core**。它保留归档时工作区中的实际内容，包含未提交修改，
不是从 Git HEAD 重建的旧版本。正式主线位于 [../../rv64](../../rv64/README.md)。

## 内容

- `rv64/vsrc/`：旧核完整 RTL、共享 IP、原有仿真壳与源文件清单。
- `rv64/csrc/`、`include/`、`configs/`：旧仿真器、配置及生成头文件。
- `rv64/testbench/`、`testsuites/`：旧测试与软件测试源。
- `rv64/design/`、`eval/`、`perf/`、`syn/`、`vivado/`、`scripts/`：原有设计资料与工具。
- `rv64/Makefile`、`vsrc/filelist.mk`、`testbench/Makefile` 和架构/README 主入口使用归档前的 legacy 版本。
- `MANIFEST.json` 记录每个文件的原路径和内容校验值；`SHA256SUMS` 可直接核验。
- `rv64core-legacy-20260916.tar.gz` 是可搬运的源码压缩包；对应校验值在 `PACKAGE.sha256`。

归档未收录新核 `rebuild/chengyue64`、多 GB 的构建产物、历史运行输出、波形和日志。
共享外设的归档副本固定为封存时内容；正式主线保留自己的活动副本。

## 使用

从工作区根运行：

```sh
make -C npc/pack/rv64core-legacy-20260916 verify
make -C npc/pack/rv64core-legacy-20260916 lint
make -C npc/pack/rv64core-legacy-20260916 all
```

根目录 Makefile 给旧构建明确传入 NEMU、通用工具、综合工具的工作区位置。
源码包依赖宿主 Verilator / C++ 工具链及工作区依赖，不包含工具链和 NEMU 仓库。
搬到其他位置时，传 `WORKSPACE=/absolute/ysyx-workbench`。
部分历史评估脚本仍假定原工作区相对布局；复现这些脚本需按原布局使用独立工作区，
或显式调整它们的工作目录与参数。

## 归档状态

这是源码保存和构建兼容包。旧报告只代表各自当时测量的版本，
不能作为承岳64的 CPI、Linux、NPU 或 PPA 验收结果。
当前 `npc/rv64/vsrc` 中旧核独有目录以相对链接指回本包；新核产品清单不包含旧 OoO 核。

## 本次归档核验

源码逐文件核验通过；归档 filelist 的全部 RTL 都位于本包内部。
新位置的旧核严格 lint 与原位置得到相同的 5 条既有告警，返回失败：
NpcTop 的 timer_wait_o / machine_irq_o / supervisor_irq_o 未连接，
AxiPlic 的 GENUNNAMED 与 BLKSEQ。
归档保留原始 RTL 和严格判定，未屏蔽这些告警；因此上面的 lint 命令可用于复现，当前结果不为 PASS。

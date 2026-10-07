# 保留结果与正式依赖路径

2026-09-21 按用户要求清理旧构建、旧运行结果与临时依赖。

- 当前 RV64 结果从仓库 `tmp/<任务名>` 迁入本目录，任务名保持不变。
- `rv64-cpi-timing-20260916` 保存当前 v1.0.0 采用的 held-ready 网表、STA 与 CPI 报告；比较报告仍保留，旧候选大网表和编译目录已清理。
- `rv64-replacement-20260915` 保存最近一套系统接入验证记录；其他目录保存发布迁移和 9 月 17 日模型验证结果。
- OpenSTA 已迁至 `tool/opensta/bin/sta`，OpenROAD 迁至 `tool/openroad/openroad`。
- NPU 的长期 llama.cpp 库位于 `npu/version_0820/tools/llama.cpp/bin`；CMake 安装位于 `tools/cmake-python` 和 `tools/cmake-3.31.12`。
- 历史 JSON/日志中实际执行过的命令和原始路径未伪装成重新执行记录。查询原 `tmp/<任务名>/<文件>` 时，在本目录下使用 `<任务名>/<文件>`；未保留的中间产物需重建。
- 这次仅清理和迁移产物，没有重新运行完整 RTL/NPU/Linux 回归，也没有改变已有 PASS/FAIL 结论。


## Git 保存范围

Git 保存本说明、`path-relocations.json`，以及
`rv64-cpi-timing-20260916/` 中的 `REPORT.md`、`comparison.json`、
`verification.json`，以及报告引用的 `split-hint` / `held-ready` 两份
`critical-path.json`，供发布说明引用并保留历史结论。
网表、原始日志、波形和其他运行目录保留在本机，由 Git 忽略；新克隆不包含完整证据包。

这些文件记录的是当时的测试结果，本次整理未重跑仿真、综合或 STA。
历史报告及 JSON 中的原始命令、绝对路径和产物链接按原记录保留；
访问未纳管的原始产物需要本地保留目录，缺失的中间产物需要重新生成。

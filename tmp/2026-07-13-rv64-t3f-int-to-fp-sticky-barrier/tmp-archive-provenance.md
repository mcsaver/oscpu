# T3B–T3F `/tmp` 归档说明

用户要求把 `/tmp` 中与本轮架构/时序调试相关的内容收回工作区。
`archive-related-tmp.sh` 只选择 T3B–T3F 前缀的顶层路径，包含：

- RED/GREEN/focused/negative 的 Icarus build 与日志；
- T3B–T3F DB brief/path-review 文本；
- T3F full Verilator build；
- CoreMark 首次缺环境变量的失败日志与最终成功日志；
- 用户 `npc-linux.log` 的原始 `/tmp` 快照。

无关的 F0、AXI-DPI 和早期任务 `/tmp` 目录不在本轮范围。归档完成后，
`tmp-archive/` 内保留压缩包、顶层路径清单、tar inventory 和 SHA-256。

## 归档结果

- 顶层相关路径：44 个；tar inventory：435 项。
- 压缩包：`tmp-archive/t3b-t3f-related-tmp.tar.zst`，`30,930,919` bytes。
- 压缩包 SHA256：
  `667c533b70ee382e356457301679c307697f226ab9bc6d17cd4d90dd5cd2ad57`。
- `zstd --test`、`tar --list` 和 `sha256sum -c SHA256SUMS` 全部 PASS。

# T3G `/tmp` 归档说明

用户要求把 `/tmp` 中与当前工作相关的内容收回工作区。`archive-related-tmp.sh`
只选择 T3G 前缀的顶层路径，覆盖 RED/GREEN/negative、94-module Icarus build 与
full Verilator build；功能/STA 的可读日志本身已直接写入 task-run 或本工作区 `tmp/`。

## 归档结果

- 顶层相关路径：7 个；tar inventory：225 项。
- 压缩包：`tmp-archive/t3g-related-tmp.tar.zst`，`27,019,588` bytes。
- 压缩包 SHA256：
  `bf93d515a8293378b1e20fddcfd913c1ca3ea5518dda5ff623bde3f9b66a112f`。
- `zstd --test`、`tar --list` 与 `sha256sum -c SHA256SUMS` 全部 PASS。

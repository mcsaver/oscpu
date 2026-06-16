# Legacy AI Dev Environment Archive Pointers

tracked source 只保留本 pointer 文件、`ARCHIVE_MANIFEST.md` 和
`CHECKSUMS.txt`。

外置 payload 位置：

| Payload | Location | Notes |
| --- | --- | --- |
| 旧手工输出 | `dist/archive/` 或 release artifact | 不要把生成包重新放回 `.github/archive/`。 |
| 大体积 e2e 证据 | 对象存储或 release artifact | Git 只保留 bounded task-run summary 和 evidence index。 |

# T3B–T3H `/tmp` 增量归档说明

用户要求把 `/tmp` 中与当前目标相关的内容收回工作区。此前的
`tmp/2026-07-13-goal-tmp-snapshot.tar.zst` 已覆盖 2026-07-13 01:27 前的
B2/F0/XRET/IFU/AXI 等 134 个顶层对象；本增量只补齐之后产生的 T3B–T3H
RED/GREEN/negative/build/review/OpenSTA 证据，以及 `/tmp/OooIntBackend-A.v`
架构基线。

`archive-related-tmp.sh` 在归档时动态枚举 `/tmp` 顶层，保存 NUL source list、
可读 source list、tar inventory 和 SHA-256；每个阶段单独压缩，避免单个 Git blob
过大。所有八个 archive 均完成 `zstd --test`、`tar --list` 与
`sha256sum -c`。

| group | top-level paths | tar entries | archive bytes | SHA-256 |
| --- | ---: | ---: | ---: | --- |
| T3B | 16 | 132 | 4,175,977 | `fd751bed294a606129052304a0bb9d182fd61bd4f4a116489c636725dde1f578` |
| T3C | 2 | 3 | 199,778 | `2ec013b5ae106326a7d0e9c6e6714c3a69a338a8c3cad985865e92a6e3b10c0f` |
| T3D | 3 | 7 | 29,211 | `dee3421e625c8c8f9ad279c2909fdd8fa9de684bc709409a61849f8a52f65ec6` |
| T3E | 4 | 6 | 13,255 | `1c31e9478fb5399cfa08982fcc639250c1cdbf9b8462636603e5fc14fa14a860` |
| T3F | 22 | 288 | 26,569,412 | `203cec5511f31956d5702f40fa80ff15b711b30aa0bbcca0496652cc8134f9c7` |
| T3G | 7 | 225 | 27,019,588 | `bf93d515a8293378b1e20fddcfd913c1ca3ea5518dda5ff623bde3f9b66a112f` |
| T3H | 15 | 92 | 138,724 | `bd13d2a4fc3786f654b536cb5452c922c63bf32aec9f413d8a380e49b3f997cd` |
| baseline | 1 | 1 | 30,185 | `7f561d8ed965cfb3f276e8b0d956d41e425d6cb8f9929aa5aa26612f4ed8d9c4` |

T3B archive 内的用户日志保持原始字节，抽取后 SHA-256 为
`3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15`，
与 `build/linux-logs/npc-linux.log` 和 `/tmp/ysyx-t3b-user-npc-linux.log`
完全相同。

`/tmp/ysyx-bpu-static-a` 是约 790 MB 的干净重复 worktree，HEAD 与旧快照记录一致；
旧归档已保存其 metadata，因此本增量不重复打包。归档内容含项目内部状态和
`/home/lyg/...` 绝对路径，仅作为本仓库内部证据使用。

# Evidence Index

- `run.rc`：最终退出码，值为 `0`。
- `run-npc-systemd-guest.sh`：本轮复现脚本。
- `evidence/npc-systemd-guest/console.log`：NPC 串口/host 合并日志，含 wrapper guest marker、root prompt marker、systemd/Ubuntu banner 与 guest-watch 命中。
- `evidence/npc-systemd-guest/npc.log`：NPC 内部日志与统计。
- `evidence/npc-systemd-guest/npc-guest-check.cmd`：autocheck 模式说明文件；本轮未注入 UART payload。

# Dispatch Log

- 搜索仓库，确认当前没有真实 OpenSBI/Linux/DTB 镜像。
- 检查本机工具，确认 `dtc`、`fdtget` 和 RV64 交叉 GCC 可用。
- 根据 `define.v` 与 `NpcSimTop.sv` 的地址图，整理 memory、CLINT、PLIC、UART、CPU interrupt controller 节点。
- 新增 `npc-rv64.dts`，先描述当前已经实现并验证过的设备，避免把 virtio/blk 等尚未实现设备写进 DTB。
- 扩展 `npc/rv64/tools/Makefile`，新增 DTB 生成、host 侧 `fdtget` 检查和三镜像 smoke。
- 新增 `linux-dtb-smoke.c`，让 guest 从 `a1` 指向的真实 DTB 中检查 FDT header 与关键字符串。
- 首次 `check-dtb` 因 `/chosen` 路径写成两个参数失败，修正 Makefile。
- 首次 payload 高地址链接因默认 medlow 报 relocation truncated，改用 `-mcmodel=medany`。
- 首次 payload 运行跳入 C 函数序言时栈未初始化，定位为 raw binary 最低地址不是 `_start`，把 `_start` 放入普通 `.text` 并设置 ELF entry。
- 第二次 payload 运行跳到 NOBITS 空洞后的 helper，定位为 `.bss.stack` 造成 raw binary 未装载代码间隙，改用固定 PMEM 栈。
- 最终 `check-dtb`、`smoke-dtb` 和 rv64 build 均 PASS。

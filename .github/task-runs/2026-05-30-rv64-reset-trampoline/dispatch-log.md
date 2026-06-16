# Dispatch Log

- 复核已有多镜像 loader 与 `linux-handoff`，确认缺口在 reset PC 到 payload 入口之间的 host 启动胶水。
- 新增 `linux-boot-trampoline.S`，从 `0x80000000` 设置 `a0/a1` 后跳到 `NEXT_ADDR`。
- 新增 `npc/rv64/tools/Makefile`，生成 trampoline ELF 和 raw binary。
- 初版验证暴露 payload 编译为 RVC 压缩指令，raw handoff trace 混入半字取指，无法干净区分 trampoline 与测试 payload 问题。
- 将临时验证 payload 改成 `.option norvc` 和 `rv64ima_zicsr_zifencei`，只覆盖 `a0/a1` 与 fake DTB magic 读取。
- 三镜像启动 `trampoline@0x80000000 + payload@0x80001000 + fake_dtb@0x80002000`，确认 GOOD TRAP。
- 更新 project status、NPC 模块笔记、known issue [39] 和本 task-run，明确记录这仍不是完整 OpenSBI/Linux。

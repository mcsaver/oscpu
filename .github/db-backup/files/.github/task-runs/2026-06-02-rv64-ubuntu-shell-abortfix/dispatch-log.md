# Dispatch Log

## 2026-06-02

- 读取并沿用项目规则、RV64 Linux bring-up 说明和既有 memory，确认本轮不能通过跳过 SRET/Sv39/RVC 或关闭 direct RAS 来换取 Ubuntu 表面跑通。
- 保留 direct RAS return fast path，复核 SRET/Sv39/RAS focused smoke 作为回归门槛。
- 定位 Ubuntu shell gate 卡点到 LSU bridge 与 xbar read abort 契约：flush 后读/page-walk response owner 已取消，但 bridge 仍等待可能不存在的 R。
- 修改 `OooMemAxiBridge`：读/page-walk状态在 `flush_i` 下本地释放；写路径仍 drain AW/W/B 并维护 D-cache store update。
- 更新 `tb_ooo_mem_axi_bridge`：in-flight read flush case 断言 abort 后 bridge ready 恢复，后续新读可正常完成。
- 复验 rv64 build、focused 5/5、SRET/Sv39/RAS smokes。
- 跑干净 Ubuntu shell gate，命中 `[ysyx-sh] /bin/sh -c marker` 并 `GUEST EXPECT MATCH`。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md`。

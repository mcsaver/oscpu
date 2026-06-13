# Dispatch Log

## 2026-06-03

- 复核 `NpcSimTop -> NpcTop -> NpcCoreTop -> OooAluFetchCore` 前端模块拓扑，确认本轮只动 `OooBranchTargetCache` 与后端验证源列表/testbench。
- 对 `OooBranchTargetCache` 做 RTL 推导：
  - lookup hit 被 valid 门控。
  - clear/invalidate_all 只需清 valid。
  - data/tag 在 invalid entry 中为 don't-care。
  - store target invalidation 因 target-word CAM 语义保留 16-entry 扫描。
- 实现 packed valid vector、vector clear、nonblocking store invalidation，删除 `BLKSEQ` waiver。
- 发现 `OooMulDivUnit` 后端模块引入后，多个 module testbench source list 未纳入该文件，导致依赖 `OooIntBackend` 的 tb 编译失败；抽出 `TB_OOO_INT_BACKEND_SRCS` 统一修复。
- 发现 `tb_ooo_int_backend` 初次编译后失败集中在 lane1 store、LR/SC、AMOADD 的固定拍点假设；按用户要求允许 testbench 跟随新模块协议更新。
- 将 `tb_ooo_int_backend` 的相关场景改为等待 mem0 request、mem0 response ready 与 commit 事件；补齐 `recover_gprs_i` 连接。
- 验证：
  - focused module testbench 3/3 PASS。
  - rv64 lint PASS。
  - rv64 build PASS。
  - Linux tools `smoke-jal-link/smoke-branch-raw/smoke-muldiv` GOOD TRAP。
  - `git diff --check` PASS。

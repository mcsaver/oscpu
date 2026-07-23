# Dispatch log

- 2026-07-22：工作对象声明为本地 RV64 Verilog/SystemVerilog 处理器 RTL、规格、TB、EDA
  与证据；root 持有唯一 WSL 工程 shell。
- 2026-07-22：当前源码探针 tb_ooo_fetch_axi_bridge 与
  tb_ooo_fetch_axi_bridge_xbar 为 2/2 PASS；生产 RTL 未修改。
- 2026-07-22：限定材料 reviewer 合同路径
  .github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/subagent-contracts/v9g-ifu-axi-coverage-review-v1.json，
  JSON SHA-256 0e476c47a4a3d6d12a3c8f44584f08a490e95111a5e979933a49e6bede81adef；
  canonical create、validate、render 已通过；节点不执行命令或仓库读取。
- reviewer 可操作反例将在返回后转成 TB、compile-success RTL verification mutation 或
  fail-closed 静态审计；文本意见本身不授予 GREEN。
- 初审结论为证据完备性 GAP、未发现 P0 生产 RTL 缺陷。P1-1..P1-7 已分别落实为
  flush+last-AW+B、AW+W+B 全同拍、both-done+flush+B-error、flush+first AW/W、
  两拍 BREADY 背压 owner 保持、AW-first/W-first xbar 场景及对应 branch-local
  compile-success RTL verification variants。
- P1-8 以 owner 边界收敛：IFU-AXI-G1 write owner 只从寄存后的
  `state_q==S_AD_UPDATE` 开始；旧状态仍为 `S_WALK_R` 的 flush 属于 PTW read-owner
  取消/排水，不能同拍建立 write owner。该边界已写入 `contract.md`/`rtl-derivation.md`，
  不把相邻读事务合同扩写为写 owner 证据。
- P2 边界保留：quiet window 是有界动态观测；合法 slave 合同要求 BVALID 在 AW/W
  已接受后返回；reset 与非法 BVALID 激励不属于本切片。18 个变体是关键分支反例集，
  不宣称形式穷尽。
- canonical `make -C npc/rv64 check-ifu-axi-flush-drain` 已取得 focused 3/3、module
  109/109、compile-success variants 18/18、evidence tests 8/8，生产 `.v` 前后不变。
- architecture provenance 仅两个实际漂移路径；旧哈希精确重建、9 个 record 的非
  provenance 语义投影不变，directed architecture gates 9/9 GREEN。冻结工作流变更后，
  FDG/XRET/INSTRET/MEM/MIQ 规范入口已重放并更新账本结果哈希。
- 终审限定材料合同路径
  `.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/subagent-contracts/v9g-ifu-axi-final-evidence-review-v1.json`，
  JSON SHA-256 `e9cff492b1b02b789c20fc2d13e1b459c6f33374403fa2dbd8f5a3230b0a0b2d`；
  canonical create、validate、render 已通过并原样派发，节点无命令、无写路径。
- 终审返回限定材料 PASS，未发现合法 AXI slave 合同、当前 design-id、非 reset 路径内的
  推翻性周期反例；`scope_extension_request=无`，置信度约 0.94。残余风险限定为非形式
  穷尽、非法提前 BVALID、reset、更广公平性/配置与 reviewer no-tools 审计方式，不影响本轮
  限域 CLOSED。完整摘要见 `review-summary.md`。

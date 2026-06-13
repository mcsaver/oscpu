# Dispatch Log

## 调用链

当前 RV64/OoO/Linux 活动路径：

```text
NpcSimTop
  -> NpcCoreTop
    -> OooFetchAxiBridge
    -> OooMemAxiBridge
    -> OooAluFetchCore
      -> OooRvcDecompressor
      -> OooFpDecode
      -> OooAluCoreSlice
        -> OooAluDecodeBackend
        -> OooIntBackend
          -> OooDispatchBackend
          -> OooIntIssueQueue
          -> OooRob
          -> OooRenameMap/OooFreeList/OooBusyTable
          -> OooPhysRegFile/OooArchRegFile
```

旧 `NpcCore/IfStage/ICache/DCache/PipelineControl/*PipeReg` 不在默认 `RTL_CORE_SRCS` 活动路径。

## RTL 推导

### 需求

- 不改变 `NpcCoreTop` 和 `OooAluFetchCore` 对外接口。
- 不改变 fetch request/response ready-valid、FIFO、flush、ROB/IQ/LSU 提交协议。
- 让 OoO 文件布局反映职责边界。
- 把不在默认 RV64/OoO 构建中的旧模块集中管理。

### 协议

- RVC 解压是 fetch response 解包后的组合转换：输入半字，输出标准 32-bit 指令。
- FP decode 是 head packet 阶段的组合分类：输入 `decode_valid` 与 instruction，输出分类位和聚合 `fp`/`double`/`gpr_write`。
- legacy 文件不进入 `RTL_CORE_SRCS`，但 filelist 仍保留旧变量，避免历史 testbench 入口立即失效。

### 状态机

- `OooRvcDecompressor` 无寄存器和状态机。
- `OooFpDecode` 无寄存器和状态机。
- `OooAluFetchCore` 的已有 fetch FIFO、pending stop、branch/jump/fp drain、CSR/trap flush 状态机未改。

### 不变量

- `fetch_dec*_inst_w` 的选择点不变：压缩指令选择 RVC 解压输出，非压缩选择原始 32-bit 指令。
- FP 指令的 lane0/lane1 分类条件与原重复 wire 表保持一致。
- `pending_fp_gpr_write_q` 的含义不变，由原 OR 表达式收敛为 `OooFpDecode.fp_gpr_write_o`。
- `rv32_imm_j()` 留在 `OooAluFetchCore`，因为 commit-time JAL redirect 仍需要从原始 32-bit 指令恢复架构 next PC。

## 验证摘要

- Verilator lint/build 通过，证明新 filelist、目录和模块层级可 elaboration。
- `tb_ooo_fetch_trap_gate` 与 `tb_ooo_priv_system` 通过，覆盖当前可靠的 fetch trap/privilege focused 路径。
- 旧 `tb_ooo_alu_fetch_core` 失败被归入 known issue [33]，不是本轮结构整理的回退依据。

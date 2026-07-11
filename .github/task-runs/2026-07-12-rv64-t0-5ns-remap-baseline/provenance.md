# Provenance

## Git / working tree

```text
branch: ai
HEAD: ee422740d75bd8ff042575cf515d8dd04d926749
```

目标驱动重映射开始时存在且由用户所有的未提交文件：

```text
build/linux-logs/npc-linux.log
npc/rv64/vsrc/debug/OooAdUpdateChecker.sv
npc/rv64/vsrc/frontend/OooFrontend.v
npc/rv64/vsrc/sim/NpcSimTop.sv
.superpowers/
```

本 task-run 不暂存这些路径。三份 RTL 的输入身份：

```text
combined git diff sha256:
ba53023545091ab611f5d05d2a1afe2ed709ba797811c06baa6a4f0b8740a391

OooAdUpdateChecker.sv:
3863f022cddf2f72818a0fddfe424be9308735d5bc9575d8b2703a8346cacb42
OooFrontend.v:
8be9ca5b0759d4a509b7d20a2024fda3a1779e0953b6d738afb68e32513c4ccc
NpcSimTop.sv:
6e1947fa9afeb6e0a17d82c5c670fc11d644f1be3f5ada3f406577579192f0aa
```

## Flow identity

HEAD `ee422740d75bd8ff042575cf515d8dd04d926749` 包含 ABC delay target 合约修复。41 字节的 `abc.sdc` 只有通用 drive/load 约束，不含 `5000 ps`；5 ns 映射目标的唯一直接证据是综合日志中 105 个实际执行的 `ABC: + &nf -D 5000.0`。修复前 HEAD `aa5f6c66f` 生成的映射产物已重命名为 `*.pre-target-contract.*`，只保留作失效诊断。

## Flow configuration

```text
STA_CLK_FREQ_MHZ=200
STA_PDK=icsprout55
STA_SYNTH_FLATTEN=0
STA_SYNTH_SHARE=0
STA_SYNTH_STOP_AFTER_COARSE=0
STA_SYNTH_PUBLIC_AUTONAME=0
STA_SYNTH_DFF_AUTONAME=0
STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor"
STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
```

`.config` SHA-256：`cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`。

## Reproduction note

同一网表目录名不等于同一映射目标，也不等于同一 RTL。重跑必须同时确认：

1. HEAD 含 delay target 合约修复；
2. 综合日志的最终 ABC cone 实际收到 `-D 5000.0`；
3. combined dirty diff 与 `.config` 哈希匹配；
4. OpenSTA 使用修复后的 `NpcTop.netlist.v`，而不是 `*.pre-target-contract.v`；
5. iEDA 若未产生报告，不得借用 OpenSTA 文件名或旧报告宣称 iEDA 完成。

若用户修改三份未提交 RTL 中任一文件，本报告即成为历史基线，不能作为新 RTL 的直接时序证明。

# IFU-ACCESS-G1 限定材料复核 V2

- contract: `subagent-contracts/v9i-ifu-access-coverage-review-v2.json`
- contract SHA-256: `00a2e4db3475a6dec764404aca44095eaac88a8289dc2fae0268066b7de09991`
- mode: `self-contained-no-tools`
- result: PASS
- confidence: high within the supplied IFU-ACCESS-G1 evidence

审查者逐项核对 exact halfword 序列、2B EXEC PMP、RRESP transaction owner、
`ARVALID && !ARREADY` 周期内的 `ARADDR/ARSIZE/ARPROT`、`ARPROT[2]` default-slave
选择、PMEM 尾界 2B 读取和 decoder→capture→pending→drain 的 lane fault owner。

矩阵与 19 个编译成功负向 RTL 变体未暴露共同覆盖缺口，也未形成能同时绕过所有周期级 oracle 的反例。
保留项是冻结材料没有逐项附上 19 个 variant patch 与 marker 全文；若需要逐变体独立复核，应生成新版
合同并显式提供这些材料。该保留项不扩展本轮结论，也不影响当前 `IFU-ACCESS-G1` 的关闭资格。

结论不覆盖 `IFU-TVAL-G1`、`PTW-PMP-G1`、LSU split transaction、full-core freeze 或 PPA。

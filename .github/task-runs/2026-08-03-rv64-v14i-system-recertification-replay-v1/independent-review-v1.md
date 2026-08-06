# V14I independent review v1

RV64 RTL 结论｜对象=NpcTop V14E system receipt、V14H ProducerId 聚合账本与 SoC delivery gate｜周期/配置=design-id sha256:093c2380…a7488，5,055,252,337 cycles/1,231,323,780 commits｜TB/EDA 观测=17/17 strict、7/7 terminal、0 RTL assertions、45 checker tests；V14G 4/4 baseline+22/22 mutation｜范围=GAP

收据与聚合账本边界通过：A2 保持 PASS、A1 保持原始 FAIL；V14H global receipt 保持
`system_recertification=REQUIRED`，聚合账本分别验证 global/system receipt 后才提升为
`PASS_CURRENT_CONFIG`；`whole_architecture=RED`、`ppa=UNPROMOTED` 未越级。`agent-flow reclassify`
保留 paths/evidence/decisions、递增 generation，已有测试覆盖旧 candidate 不复用。

阻塞反例：`scripts/check-rv64-soc-delivery-gates.sh` v1 只检查九列非空与 marker 全局存在，未逐 tier
绑定字段。`candidate.promotion_authority` 改为 `none` 或跨 tier 交换 reuse/waiver marker 仍可能通过；
八个负例也未覆盖 eligible classes、execution、retention、promotion authority 与跨 tier 交换。

结论：delivery gate 必须逐 tier/逐字段 exact 或 enum 校验并补齐上述反例后复核。合同
SHA-256=`92a42783e096e9e58a8720e08fcf35d9da133f19e6788e228fba262888073d57`；
`scope_extension_request=none`；置信度高；WSL ownership returned。

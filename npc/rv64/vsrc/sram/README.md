# vsrc/sram — SRAM 宏行为模型（独立管理，勿与其他 RTL 杂糅）

本目录只放 **SRAM 宏的行为模型**：每个规格一个具体模块名的 `.v` 文件
（`Sram<深度>x<宽度>.v`），与真实工艺 SRAM 宏"一 cell 一规格"的形态对齐。

## 管理约定

1. **一规格一文件一模块**，禁止参数化实例（iEDA parser 对 parameterized
   blackbox instance 会 abort——见 `2026-07-08-ieda-netlist-compat` 教训）。
   需要新规格时新增文件，不给现有模块加 parameter override。
2. **仿真真源**：本目录的行为模型即仿真语义——1RW 单口、同步读
   （en 且非写时读地址打拍，次拍 `rdata_o` 有效）、write-first 不保证
   （读写同拍同址视为使用方违约，使用方必须保证读写状态互斥）。
3. **综合边界**：NpcTop 综合时本目录模块经 `SYNTH_BLACKBOX_MODULES`
   黑盒化，由工艺 SRAM 宏 / bsg_fakeram 生成的 lib/lef 提供实现；
   本目录行为模型**不得**进入标准单元综合展开（4096 深阵列会重现
   memory_map FF 海卡死 ABC 的老路）。
4. **使用方契约**：读发射拍与数据判决拍分离（+1 拍）；复位/全清语义
   由使用方的 valid FF 承担，宏内容不清零、上电内容未定义——使用方
   必须保证 valid=1 的 entry 一定被真实 fill 写过。

## 当前规格清单

| 模块 | 规格 | 使用方 | 用途 |
| --- | --- | --- | --- |
| `Sram4096x199` | 4096×199, 1RW | `OooFetchPacketCache` | 取指包 payload（paging/priv/satp/pc/inst0/inst1/resp0/resp1 拼宽） |
| `Sram4096x113` | 4096×113, 1RW | `OooDataWordCache` | d-cache tag+data 拼宽 |

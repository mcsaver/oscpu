# V9M FENCE-G1 completion definition

- 工作对象：本地 RV64 Verilog/SystemVerilog 双发射 OoO 处理器的普通
  `FENCE` 退休顺序与 memory-owner 排空条件。
- parent design-id：
  `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。
- production RTL：保持当前实现不变；本轮只增加 testbench marker、证据生成器、
  fail-closed 审计与当前设计绑定。
- 完整设计点条件：
  1. store→FENCE→device-read 定向程序精确 PASS；
  2. `OooPendingDrainResolveGate` 完整 memory-idle 条件与
     `OooCoreTopGlue`→`OooControlPlane` 直连各有一个可编译负向 RTL 版本，
     且分别被独立 gate oracle 与全核程序精确检出；
  3. 当前模块清单全部 PASS，每个日志含编译时注入的当前 RTL design-id，
     且逐项绑定；
  4. `FENCE-G1` debt-specific validator 对 result、raw log、RTL SHA、源文件、
     testbench 日志、运行时 design-id 和负向版本进行独立重算；
  5. 架构账本与 ROADMAP 更新到同一 design-id。
- 声明边界：这是 architecture closure；综合、STA、Power 与 PPA promotion 均保持
  `UNQUALIFIED` / `promotion_eligible=false`。

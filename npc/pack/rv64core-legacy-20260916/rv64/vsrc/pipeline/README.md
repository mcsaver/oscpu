# vsrc/pipeline — 级间边界原语（独立管理，勿与功能 RTL 杂糅）

本目录只放**流水线级间边界的标准原语**，与 `vsrc/sram/` 同一管理哲学：
结构显式化、让工具看得见边界。

## 当前原语

| 模块 | 用途 |
| --- | --- |
| `PipeStageReg` | 标准级间寄存器：valid/ready 握手 + payload 打拍 + flush/kill 清 valid。参数化 WIDTH（普通模块参数化合法——iEDA 只对参数化 *blackbox* 报错，本模块不是黑盒）。自带 `(* keep_hierarchy *)`，综合时保留边界让 ABC 沿寄存器切 cone。 |

## 管理约定

1. 原语只承载**边界语义**（握手/冻结/清空），不解析 payload 内容；rob_idx
   年龄比较等 kill 判定必须留在使用方（kill 窗口覆盖是使用方契约——
   F2 kill 窗口逃逸家族教训）。
2. 每个原语自带 OOO_ASSERT 立即断言（PSR-HOLD/PSR-FLUSH-EMPTY），进
   `check-contract` 计数；新增原语必须同步给 focused TB。
3. 治理路线与边界清单见 `design/arch/pipeline-stage-boundary.md`（spec 先行）。
4. skid-buffer 变体（up_ready 打拍切断 ready 组合链）按需另立模块，不改本原语语义。

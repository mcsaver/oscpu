# RV64 producer identity P0 holder census 合同

## 目的

本目录只建立 v8c P0 的机器化入口：凡 `npc/rv64/vsrc` source tree 中显式使用
`ROB_INDEX_W` / `OOO_ROB_INDEX_W` 的 file/module 单元，都必须在 manifest 中分类为
`AUTH`、`TOMBSTONE`、`DETACHED` 或 `EXEMPT`，并逐项记录 capture、kill、terminal、
side effect、proxy 与 full-identity 状态。

此外，ROB index 文本扫描天然看不到的 pending-system/Q1/CsrFile 派生 owner，以及现有
local memory-token owner/tombstone，也由 checker 内置 seed 强制进入 manifest。

## 分类

- `AUTH`：可保存或消费 producer/owner 身份，并可直接或间接授权 WB、commit 或 memory
  side effect。
- `TOMBSTONE`：取消后只允许为晚到 terminal 核销而保留；不得授权新的 ROB incarnation。
- `DETACHED`：保存派生 owner payload，却没有 generation-safe ROB full identity 绑定。
- `EXEMPT`：宽度定义、组合年龄比较或 wrapper/proxy；本地没有 holder，不表示路径已支持
  full identity。

本版是一行一个 file/module 的单标签账本，因此采用
`classification_policy=strongest-live-authority`：只要模块任一正常子态可以授权或派生副作用，
整模块必须标 `AUTH`；`TOMBSTONE` 只能描述完全静默核销的单元。MIQ、memory bridge 与 terminal
collector 均含正常 AUTH 和取消后 drain 子态，所以保守标 `AUTH`，并在 notes 记录内部 tombstone，
禁止用单一 `TOMBSTONE` 把 live 权限说窄。

机器门把上述三个混合单元的 id 冻结在 `scope.strongest_live_authority_ids`，并要求其
`classification` 始终为 `AUTH`；把它们降为 `TOMBSTONE`、`EXEMPT` 或 `DETACHED` 都必须
失败。另有通用交叉字段约束：`EXEMPT.capture` 只能是 `NONE/PASS_THROUGH`，且不得是
`STATEFUL_HOLDER`。这些规则只锁 manifest 内部一致性；`semantic_complete=false` 仍表示
checker 不能从 lexical RTL 自动还原全部真实 owner 语义。

## 强制状态账本

| 项 | 当前状态 | 本 census 能否提升 |
| --- | --- | --- |
| global no-live-reuse | RED | 否 |
| generation-safe full identity | RED | 否 |
| WB authorization | RED | 否 |
| live Q1/Csr owner | RED | 否 |
| `{kind,token,epoch}` memory token domain | LOCAL_GREEN | 只保持局部结论 |

checker 拒绝把前四项改成 GREEN，也拒绝把 `LOCAL_GREEN` 擦成无范围的 `GREEN`。

## 覆盖边界

当前机器能力明确是 `file-module`，不是 field-level：

1. checker 对 `.v/.sv/.vh/.svh` 做 comment/string stripping，再用 lexical
   `module ... endmodule` 范围归属显式 `ROB_INDEX_W` token；
2. 不展开 include、generate 或 parameter elaboration；
3. 不解析 packed payload 中已失去 `rob_idx` 名称的 slice；
4. 不建立 production instance graph，也不证明 module 当前 live instantiate；
5. 无 ROB index 的 derived owner 使用 bounded seed 加 declaration heuristic，不能声称开放世界
   的 owner discovery 完备；
6. manifest 的 `field_level_complete`、`instance_graph_complete`、`semantic_complete` 必须保持
   `false`。

因此 PASS 只证明“当前扫描规则看到的 file/module carrier 与规定的 derived-owner seed 均有一行
可审计分类”，不证明字段数完整、不证明 stale completion 已消失，更不证明 full identity 已接通。

## Fail-closed 规则

- 新增或移动任何显式 `ROB_INDEX_W` carrier，未同步 manifest 即失败；
- manifest 的 path/module 必须真实存在、位于 source root、不是 symlink；
- carrier/derived-owner 不可漏标，entry id 和 file/module key 不可重复；
- `LOCAL_GREEN` 只允许用于 memory-local token 身份；
- 越级修改 coverage 或 status ledger 必须失败；
- runner 内置 9 个 mutation：漏 ROB、漏 Q1 derived owner、伪字段完备、伪 global full-ID
  GREEN、擦除 memory-local 边界、伪称 derived-owner 开放世界完备，以及把含 live side effect 的
  混合模块分别降格成 `TOMBSTONE`、`EXEMPT`、`DETACHED`。

## 后续退出条件

本 P0 骨架只有在后续阶段完成下列项目后，才允许扩展状态，而不是直接改 ledger 文本：

1. 定义独立的 generation-safe `ProducerId`，从 ROB allocation 传播到所有 carrier；
2. WB/kill/recovery 只以 exact full identity 授权，并覆盖同 idx 错 generation 反例；
3. variable-latency transport 使用 tagged tombstone/drain 或可证明的 reuse fence；
4. live Q1 owner 具备 mismatch-cycle `kill_now`、随后 shared registered abort、CsrFile 同事件
   reservation clear/apply；
5. 把 file/module census 提升到字段/实例图时，新增独立 parser/checker 与 mutation，不能只把
   `field_level_complete` 改成 `true`。

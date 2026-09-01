# Qwen canonical F32 ALU families production-owner RTL contract

> **QWEN-F32-ALU-FAMILIES compile-v8 / destination terminal-stride overflow
> admission freeze。** compile-v7 的唯一 O3/no-assert/no-trace/j1 collect 已完成
> CMake configure/build（均 rc0），但实际 warning census 比冻结 25 行多出唯一一行：
> `TensorNpuVectorF32Adapter.v` 的 `dst_nb3_ext_w[127:64]` 未被使用。根因是
> 128-bit destination `nb3` 中间值仅以 `[63:0]` 送入 64-bit child port，upper half
> 未进入真实 admission，存在 future/corrupted profile 静默截断洞。compile-v8 合同 JSON
> 为 `npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v8.json`，SHA-256 为
> `bc2b3378affd5c85d42d37968e74db6494822763a5c79d5063f8ec2deecf8de3`；该哈希只绑定
> JSON，不绑定本文、RTL、runner 或编译证据。下列阶段 1、2a--2e 与九项 topology
> 是本次单项 RTL 修改的前置冻结；既有 v4/v3 owner 合同继续生效。

## V8.1 阶段 1：需求冻结

1. `dst_nb1_ext_w`、`dst_nb2_ext_w`、`dst_nb3_ext_w` 继续使用 128-bit 组合中间值。
   每个送入 64-bit child descriptor port 的 profile-derived destination stride 都必须精确
   可表示为 64 bit；特别是 `dst_nb3_ext_w[127:64] != 0` 时必须在任何 child start 或
   GMEM request 前 fail-closed。
2. 唯一 production RTL 语义变化是在既有 `iova_reject_w` OR 中加入
   `(dst_nb3_ext_w[127:64] != 64'd0)`。端口、时钟域、同步复位、六态 adapter FSM、
   error owner、counter、permission、span、resident descriptor 与 held completion 均不变。
3. 有限 P00--P18 的所有 destination stride 均小于 `2^64`，因此其 admission、child
   descriptor、GMEM byte accounting 和 completion 行为必须逐 bit 等价。新增条件只拒绝
   无法由 64-bit child port无损表达的 future/corrupted row。
4. 本切片的 compile evidence 仅为 absolute CMake 3.31.12、Release/O3、no-assert、
   no-trace、j1；生成 binary 不运行，model/Qwen/synthesis/STA/PPA 全部为 out-of-scope。

## V8.2a 阶段 2a：协议规则

1. `start_valid_i && start_ready_o` 仍只捕获一次 resident command；`AD_CHECK` 仍按
   ABI -> capability -> layout -> IOVA 的顺序决定唯一 admission。
2. destination terminal-stride upper half 非零时，`iova_reject_w` 在 `AD_CHECK` 命中
   既有 IOVA error path；`f32_start_pulse_o=0`、public GMEM request valid=0，且不得发布
   success completion。
3. upper half 为零时，child 继续接收 `dst_nb3_ext_w[63:0]`；不增加重试、旁路、
   backpressure 或新的 completion handshake 规则。

## V8.2b 阶段 2b：状态机

- 六态 `AD_IDLE -> AD_CHECK -> AD_ENGINE_START -> AD_ENGINE_RUN -> AD_DONE/AD_ERROR`
  的编码、复位值、输出和正常转移不变。
- 唯一新增转移条件属于既有 `AD_CHECK -> AD_ERROR` 的 `iova_reject_w` 合取；不新增状态、
  profile-specific FSM、寄存器或 terminal phase。

## V8.2c 阶段 2c：不变量

| ID | 表达式 | 违反后果 |
|---|---|---|
| V8-I1 | child `dst_nb3_i == dst_nb3_ext_w[63:0]` 仅在 `dst_nb3_ext_w[127:64]==0` 的 admission 后可启动 | terminal stride 静默截断 |
| V8-I2 | overflow reject 后 child start=0、GMEM valid=0、success completion=0 | 越界 descriptor 获得事务资格 |
| V8-I3 | P00--P18 的 admission/counter/permission/span/descriptor 行为不变 | 既有 canonical profile 回归 |
| V8-I4 | resident command、held request/completion 与单 GMEM owner不变量不变 | payload 漂移或 owner 串单 |
| V8-I5 | 冻结 warning oracle仍为 25 行，禁止新增第 26 行 waiver | lint 假绿或基线漂移 |

## V8.2d 阶段 2d：数据通路约束

- `profile_src0_ne[0:2] -> dst_nb1_ext_w -> dst_nb2_ext_w -> dst_nb3_ext_w` 的
  128-bit 组合乘法链保持不变；low 64 bit继续直连唯一 `TensorNpuF32TensorAlu.dst_nb3_i`。
- 新增唯一 64-bit upper-half nonzero comparator，其单 bit结果 OR 入既有
  `iova_reject_w`。不新增寄存器、数据 mux、shadow descriptor、GMEM owner或算术单元。
- comparator只影响 `AD_CHECK` 的 fail-closed decision，不串入运行态 GMEM/FPU numerical
  path；本轮不作 STA/PPA 外推。

## V8.2e 阶段 2e：RTL 级 topology（九项冻结）

1. **module/interface**：`TensorNpuVectorF32Adapter` 全部 port、位宽、单时钟同步 reset、
   start/GMEM/terminal handshake不变。
2. **state registers**：既有 resident、terminal、accounting 与 `state_q` 保持唯一 owner；
   不新增任何 state register，复位值不变。
3. **combinational blocks**：唯一新增组合块语义是
   `dst_nb3_ext_w[127:64] != 64'd0`，直接作为既有 `iova_reject_w` OR member。
4. **FSM**：六态 FSM 不复制；overflow沿现有 IOVA rejection从 `AD_CHECK` 进入
   `AD_ERROR`，illegal/default行为不变。
5. **pipeline/valid-ready**：resident capture -> CHECK -> child start -> RUN -> terminal
   流向和所有 backpressure 边界不变；overflow在 child start边界前终止。
6. **priority**：reset > 既有 ABI/capability/layout/IOVA rejection > child terminal/
   accounting priority保持不变；新条件只是现有 IOVA OR 的同级 member。
7. **资源共享**：19 profiles继续共享一个 adapter、一个 F32 child与一个 public GMEM owner；
   不复制乘法器、mux、port或 owner。
8. **critical path**：新增路径仅为 upper-half OR-reduction/equality到 CHECK reject；运行态
   GMEM/FPU critical path不变，STA/PPA仍为 GAP。
9. **function/显式硬件**：用显式组合比较实现真实 admission；禁止用 function、assertion、
   dummy reduction、lint waiver、缩窄中间值或 comment-only decoy代替。

Topology 自审：64-bit child interface、128-bit producer、CHECK error path和零 GMEM/child
side effect闭合，且没有端口/FSM/owner变化；允许进入阶段 3。compile-v8 preflight 必须以
同一 checker 定向拒绝删除该 term、移出 live admission、错误 slice/value、comment-only decoy
与新增 waiver；expected warning census仍精确为冻结 25 行，不得更新为 26。

> **QWEN-F32-ALU-FAMILIES-v4 / identity-and-publication freeze。** v4 在 v3
> descriptor/profile 数据路不变的前提下，根修 synthetic representative 对
> canonical required 计数的污染、host 自填 profile、completion emitted/accepted/raw
> commit 事件坍缩，以及 367 canonical identity 未由 raw graph 重生的问题。合同 JSON
> 是 `npu/version_0820/tmp/contracts/qwen-f32-alu-families-v4.json`，SHA-256 为
> `ca00a021c6c1e17fdd7774990c07f2672b68600c5ce47d0c5a7f3afc91d69bc0`；该哈希
> 只绑定 JSON，不绑定本文、RTL、runtime、manifest 或 runner evidence。
>
> 下列 v4 阶段 1、2a--2e 与九项 topology 是后续 RTL/runtime 落盘的前置冻结；
> 本文后半部保留 v3 descriptor/span/numeric 基线，二者冲突时以 v4 为准。

## V4.1 阶段 1：需求冻结

### V4.1.1 representative 与 canonical 严格分域

1. P00--P18 是 19 个 synthetic representative transaction，不是 canonical graph
   node。其 command flags 精确为 `32'h00000010`（仅 PROFILE，REQUIRED bit0=0）；
   future canonical transaction 仍可精确使用 `32'h00000011`，adapter 只接受这两个值，
   其它任一 bit pattern 在 F32 start/GMEM 前 fail-closed。
2. 对 profile `p in [0,18]` 冻结唯一 representative namespace：

   ```text
   textual namespace = rep:qwen-f32-alu:v4:P%02u
   context_id         = 0x52500000 | p
   sequence_id        = 0x5250524550000000 | p
   producer_id        = 0x5250524f44000000 | p
   user_tag           = 0x5250544147000000 | p
   node_hash_lo       = 0x9e3779b97f4a7c15 ^ p
   node_hash_hi       = 0xd1b54a32d192ed03 ^ ((uint64(p) << 32) | p)
   covered_node_count = 1
   ```

   `rep:` 前缀使其不可能等于 64-lower-hex canonical ID；硬件实际回显的六个字段与
   `vector_flags` 必须全部逐 bit 匹配，不能只比较 profile 或 node hash。
3. 19 次 representative 正向序列的 top-level
   `npu_required_issued_o`/`npu_required_completed_o` pre/post delta 必须均为 0。
   `representative_transactions_passed=19` 只在后续 execute 全部闭合后成立；历史 v11
   单代表事务单独记为 `predecessor_representative_transactions_passed=1`。
4. verified canonical set 在本 v4 slice 中为空：

   ```text
   canonical_f32_alu_identities_eligible        = 367
   verified_canonical_node_identities_completed = 0
   remaining_nonmetadata_gap                    = 1079
   ```

   static 367 census 与 synthetic 19 set 均不得插入 verified canonical set。

### V4.1.2 RTL-returned profile 与 128-byte completion framing

1. `TensorNpuCoprocessor` 新增 held output
   `completion_macro_vector_flags_o[31:0]`，直接选择 admission 时捕获且贯穿 adapter
   transaction 的 resident `macro_vector_flags_q`。禁止由 runner function argument、host loop
   label 或 node-hash lookup 代填该 output。
2. `completion_valid_o && !completion_ready_i` 时，该 output 与 status、command flags、
   context/sequence/producer/user-tag/node-hash/counters 一起逐 bit stable；在真实
   `valid&&ready` 前，completion-accepted、raw-commit、coverage 三类事件都保持 0。
3. generic v1.0 completion framing 保持 128 bytes、minor=0、offset `0x0a` 为 0，保证
   predecessor compatibility。v4 representative evidence 使用同样 128-byte record 的 local
   minor=1：offset `0x0a` 的既有 16-bit reserved word 编码 RTL-returned
   `observed_profile_id`；只有完整 `vector_flags[31:5]==0` 且 `[4:0]<=18` 才可编码。
   `0x3c state_epoch_out` 与其余 v1 字段不变，严禁仅在 host 扩大 record size。
4. runtime/result 同时保存 `submitted_profile_id` 与 `observed_profile_id`。成功要求
   observed 值由 RTL port 获取、恰好映射一个 P00--P18 row、等于 submitted profile，且
   128-byte minor=1 serialize/parse 往返一致。

### V4.1.3 事件集合与 canonical 来源

1. 每个 representative identity 分别进入且只进入一次：command accepted、completion emitted、
   completion accepted、raw destination committed、representative coverage closed。五个集合的
   exact profile mask 都必须为 `19'h7ffff`，returned identity ordered list 与 set 都必须等于
   V4.1.1 冻结集合；重复、缺失、extra、wrong-profile、reorder collision 或 identity
   substitution 均非零拒绝。
2. raw commit 只可发生在 matching SUCCESS、full returned identity/profile、counter/framing、
   completion accepted 全部闭合后；一个 accepted completion 最多产生一次 raw commit 与一次
   representative coverage insertion。
3. canonical 来源只接受
   `tmp/logs/qwen-graph-manifest-v5/dispatch.raw.jsonl`，raw SHA-256 为
   `5b7356312f1e97adaa22ce101793588afaa7192a576d46b68ae68d9949890635`。
   preflight 必须用 `qwen_graph_manifest.py validate` exclusive 生成 fresh JSON/JSONL，复核
   payload SHA `49138fb4...f474`、frozen file SHA `f10572d0...d804` /
   `a8e334b3...4610`、1711/959/120/632 census、model/source/profile identity。
4. `qwen_f32_alu_profiles.py` 对 fresh envelope 独立重算 canonical manifest payload hash、
   每个 eligible node 的 `canonical_id=sha256(canonical(semantic_key))` 与
   `descriptor_sha256=sha256(canonical({descriptor,sources}))`，并要求 sorted 367-set digest
   精确为 `d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385`。
5. v4 preflight receipt 必须 hash-bind raw/frozen/fresh JSON+JSONL、validator source/test/log、
   graph `final.receipt`/`final.binding.sha256`、profile tool/test/log/census/mutations，以及 fixed
   identity-set digest 字段；build count=0 且 fresh build root 不存在。

### V4.1.4 性能/范围边界

- v3 19-row descriptor、allocation-relative span、private contiguous shadow、SCALE empty-src1、
  64-bit counter/cycle bound 与 P18 262144 元素语义保持不变。
- 首次授权只允许 source、一次 `bash -n` 与一次 `--preflight`；禁止 Verilator、make、backend
  binary、`--execute`、综合、STA、PPA 或 Qwen replay。
- matching child terminal 与 200000000-cycle child timeout 的同边沿优先级未动态覆盖，仍为
  显式 GAP；本 slice 不修改 `TensorNpuF32TensorAlu` timeout 语义。

## V4.2a 阶段 2a：协议规则

1. **Admission**：legacy 保持同拍优先；macro fire 时 top 原子捕获 flags/profile 与完整
   representative/canonical identity。adapter 只在自己的 start fire 再捕获一次同一 snapshot。
2. **Namespace/required**：adapter capability predicate 精确接受 `0x10 || 0x11`；top required issued
   只看 admission-resident bit0，required completed 只在 matching success terminal 看相同 resident
   bit0，禁止由 profile/node_count 推断 required。
3. **Profile echo**：completion profile 数据源只能是 `macro_vector_flags_q`；held completion 期间
   组合 output 只由 resident q 驱动，不从 pin-level `macro_vector_flags_i` 或 host result 驱动。
4. **Event ordering**：`accepted-command < emitted < accepted-completion < raw-commit < covered`。
   emitted 是首次观察 held valid；accepted 只在唯一 `valid&&ready` edge；raw/covered 不允许同拍越过
   尚未接受的 completion。
5. **Backpressure**：至少四拍 ready=0 的检查周期内 full snapshot/profile/identity stable，五类 stage
   set 除 emitted 外均不增；ready fire 后 valid 必须撤销且 accepted 恰增一。
6. **Failure**：wrong returned profile/identity、duplicate replay、framing/counter failure、missing/extra
   set、nonzero required delta 均不 commit、不 cover、不改变 canonical set。
7. **Manifest**：fresh canonical outputs 使用 exclusive create；profile census 只能消费 fresh JSON，
   不能消费历史 envelope 字段作为信任根。

## V4.2b 阶段 2b：状态机

- top 八态、adapter 六态与 child 十四态保持 v3 编码，不新增 profile-specific FSM。
- `ST_IDLE` macro fire 捕获 identity/flags；`ST_MACRO_START/RUN` 完成单 adapter owner；terminal捕获后
  进入 `ST_COMPLETE` holder。profile output 在 `ST_COMPLETE` 只读 resident q，唯一 ready fire 后才
  回 IDLE/ERROR_HOLD。
- host evidence FSM 独立为 `EMPTY -> COMMAND_ACCEPTED -> COMPLETION_EMITTED ->
  COMPLETION_ACCEPTED -> RAW_COMMITTED -> COVERED`；任一 skip/replay/不同 identity transition
  进入 FAIL，不能用最终 scalar cardinality补偿。
- graph preflight 为 `raw validate -> fresh publish -> frozen hash compare -> independent profile audit ->
  mutation -> receipt`；任一阶段失败不写 PASS/evidence-complete。

## V4.2c 阶段 2c：不变量

| ID | 表达式 | 违反后果 |
|---|---|---|
| V4-I1 | synthetic flags=`0x10`；canonical flags=`0x11`；其它值拒绝 | required 污染/ABI 漂移 |
| V4-I2 | 19 synthetic 后 top required issued/completed delta=`0/0` | false canonical hardware claim |
| V4-I3 | completion profile=`macro_vector_flags_q` 且 held 全宽 stable | host self-asserted profile |
| V4-I4 | submitted profile=observed profile=identity formula中的 p | profile/identity substitution |
| V4-I5 | emitted/accepted/commit/covered 每 identity 基数至多1且依次蕴含前级 | replay/提前发布 |
| V4-I6 | 五个 exact masks=`0x7ffff` 才可关闭 representative coverage | missing/extra 假绿 |
| V4-I7 | representative set 与 64-hex canonical set 不相交 | synthetic alias canonical |
| V4-I8 | verified canonical completed=0、remaining=1079 | 历史常量冒充查询 |
| V4-I9 | fresh payload/per-node hash/367-set digest逐项重算相等 | stale envelope/fake IDs |
| V4-I10 | valid&&!ready 时 accepted/commit/covered=0且snapshot stable | backpressure 观测坍缩 |
| V4-I11 | one accepted completion -> at most one raw commit/coverage | duplicate publication |
| V4-I12 | preflight build_count=0且build root absent | 未授权 dynamic build |

## V4.2d 阶段 2d：数据通路约束

- **RTL identity path**：macro input pins -> top resident identity/vector_flags q -> adapter resident row ->
  child transaction -> top completion holder -> `completion_macro_vector_flags_o`；无 host 回注 mux。
- **required counters**：command flag bit0 是唯一 enable；0x10 synthetic 结构性隔离，0x11 canonical
  语义保持。
- **completion record**：v1.0 与 v4-minor1 共享 128-byte serializer；minor/profile word由显式 mux
  选择，全部 counters/identity/profile先写，status最后发布。
- **host stage ledger**：每级保存 profile mask、returned hash pair与插入计数；next-stage insert 必须
  命中同一 identity 的 previous-stage member。ordered array 只接收 profile 递增序列，set 独立去重。
- **canonical audit**：canonical JSON serialization 固定 UTF-8、sorted keys、compact separators；
  semantic key、descriptor+sources 与 manifest payload 各自独立 SHA-256，不把 envelope 字段当 oracle。
- numerical GMEM/FP critical path保持 v3；新增硬件路径仅为 32-bit resident q 到 completion output，
  不串入 GMEM ready/FPU path。本轮不做 STA/PPA。

## V4.2e 阶段 2e：RTL 级 topology（九项冻结）

1. **module/interface**：`TensorNpuCoprocessor` 仅新增 32-bit held completion profile output；macro
   command、GMEM 与 child ports不变。adapter command flags predicate精确覆盖0x10/0x11。
2. **state registers**：top 继续以唯一 `macro_vector_flags_q` 保存 profile；不新增影子 host profile
   register。host audit stage/mask在 C++ context，不进入综合网表。
3. **combinational blocks**：completion profile assign由 `macro_completion_active_w` 与 resident q
   组成；adapter flags comparator为两个全32-bit equality；default均为0/fail-closed。
4. **FSM**：top八态、adapter六态、child十四态均不复制；host stage ledger为单向六态。
5. **pipeline/valid-ready**：admission -> top resident -> adapter/child -> terminal capture -> held
   completion -> accepted -> raw commit -> coverage，寄存/事件边界不得折叠。
6. **priority**：reset > protocol/identity/profile failure > matching completion fire > timeout > normal；
   holder内 ready=0 只保持，不授予 commit。
7. **资源共享**：唯一 public GMEM、adapter、F32 child与top completion holder保持共享；新增 profile
   output是 resident q fanout，不复制数值单元或 owner。
8. **critical path**：新增路径为32-bit q到output/host comparison；原 CHECK 128-bit span与 FPU path保持。
9. **function/显式硬件**：RTL holder/flags compare用显式 assign/always；C++ identity formula、128-byte
   raw serialization与 Python canonical helper仅是纯整数/byte helper，不隐藏 FSM/handshake。

Topology 自审：0x10/0x11 分域、resident profile 回显、128-byte predecessor compatibility、五级
publication ledger、raw-to-canonical重生和固定 367 digest均有单一数据源；允许进入阶段3。

## V4.3 阶段 3 落盘与验证边界

定向 mutation 必须拒绝 raw byte tamper、stale payload hash、semantic-key tamper、descriptor/source
tamper、stale descriptor hash、367 fake distinct IDs、identity duplicate/missing/extra、wrong profile、
duplicate replay与profile-to-identity substitution。首次只以 source audit、Python unit/mutation、唯一
preflight receipt给出证据；未执行的 RTL completion backpressure、P18、deadline-edge、Verilator link/
simulation、综合/STA/PPA 全部保留 GAP。

---

> **QWEN-F32-ALU-FAMILIES-v3 / retained descriptor baseline。** 本合同冻结本地
> `TensorNpuCoprocessor -> TensorNpuVectorF32Adapter ->
> TensorNpuF32TensorAlu -> TensorNpuFp32AddMul` 的单 macro transaction owner，
> 以 `macro_vector_flags_i[4:0]` 的有限表实现 canonical F32
> ADD/MUL/SUB/SCALE 的 P00--P18。本文先冻结阶段 1、2a--2e 与九项 RTL
> topology，随后阶段 3 才允许修改 RTL/runtime/evidence。
>
> 合同 JSON 是
> `npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3.json`，SHA-256 为
> `3d2820f3c2be87891421c804f523e88c880358fe1915b310267d58585dc023d2`；
> 该哈希只绑定 JSON，不绑定本文、RTL、runtime、profile oracle 或 runner evidence。

## 0. 冻结前提与判定层级

- canonical manifest 固定为
  `npu/version_0820/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json`，
  内部 `manifest_sha256` 必须为
  `49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474`；
  census 为 `1711 = 959 compute + 120 mover + 632 metadata`。
- F32 ALU 的精确静态集合是
  `84 ADD + 211 MUL + 18 SUB + 54 SCALE = 367` 个互异 `canonical_id`。
  P00--P18 的 profile row count 总和必须恰为 367，不能用算术常量替代 manifest join。
- v11 predecessor 只证明 P00 descriptor class 的 18 个 node 静态 eligible，并动态执行
  一个代表事务。因此三种基数永久分离：

  ```text
  canonical_f32_alu_identities_eligible = 367
  representative_transactions_passed  = 19   // 仅在后续 execute 全部通过后
  canonical_node_identities_completed  = 1
  remaining_gap                        = 1078
  ```

- metadata-only `supports_op` 可以在 `tensor->data == nullptr` 时判断 descriptor；
  `graph_compute` 必须另外要求所有实际 source 与 destination raw storage 存在。
  host 只允许 checked raw-byte copy、地址/shape 控制和 completion framing，禁止 float、
  `ggml_compute_forward_*`、BLAS、host tensor arithmetic 或 CPU fallback。
- `QWEN_NPU_COMMAND_ABI.md` 是 DRAFT。本 capability 对公共 `vector_op` 冻结局部精确映射
  `1=ADD, 2=MUL, 3=SUB, 4=SCALE`；3 只在 P15 被接受，不实现 FMA。profile/op
  任一不匹配均在 F32 start 与 GMEM traffic 前 fail-closed。

## 1. 阶段 1：需求冻结

### 1.1 功能目标

1. 保持 `TensorNpuCoprocessor` 既有 public macro port list、legacy 优先 admission、
   state-driven DMA/macro GMEM mux、完整 64-bit producer/sequence/context/node identity 和
   held 128-byte completion payload；不新增第二个 public GMEM owner。
2. `vector_flags_i[4:0]` 精确编码 P00--P18，`vector_flags_i[31:5]` 必须为零。
   adapter 只能从有限表生成完整 child `opcode/ne[4]/nb[4]/view_off`，禁止 generic
   descriptor 或 shape-only acceptance。
3. binary P00--P15 的权限必须逐 2-bit 全等于 `01/01/10`；SCALE P16--P18 必须
   全等于 `01/00/10`。SCALE source1 的 IOVA/base/size/stride/permission 全零，不参与
   overlap、GMEM floor/limit、byte accounting，也不被 child 读取。
4. source descriptor 保持 allocation-relative `region_base + view_off`。runtime 只复制
   profile 证明的 aligned beat span，不做 broadcast expansion；destination 一律映射到
   disjoint private contiguous shadow，child `view_off=0`，matching SUCCESS 后才 raw commit
   完整 shadow 到 `dst->data`。
5. ADD/MUL/SUB/SCALE 的唯一 numerical path 是 clocked F32 child。SUB 只把 RHS sign
   翻转一次并发 ADD child；SCALE 每元素只发一次 MUL child，`op_params_i` 固定为
   `{scalar1, scalar0}`。
6. binary 的 64-byte GGML `op_params` 与两路 scalar 必须全零。SCALE bytes 0--3 作为
   little-endian raw `uint32_t scalar0` 原样传输，bytes 4--63、`scalar1` 和其它 tail 全零：
   P16=`32'h3db504f3`，P17/P18=`32'h00000000`。
7. completion accounting 动态按 profile 计算：binary read=`16*N`，SCALE read=`8*N`，
   write=`4*N`，vector elements=`N`。所有乘法、地址 end、cycle bound 与 receipt counter
   采用 checked unsigned 64-bit；失败或 incomplete counter 没有 raw commit/coverage 资格。
8. 新机器 profile/oracle 必须从 canonical manifest 独立重建 19 row/367 identity，拒绝
   missing、extra、duplicate canonical ID、profile collision、op、type、shape、stride、
   view presence、view offset、op_params 或 permission mutation。
9. 后续唯一 execute 才允许一个 fresh O3/no-assert/no-trace elaborated binary 跑 19 个
   正向代表事务与负向矩阵；P18 必须真实执行 262144 个元素。当前 preflight 只能证明
   build_count=0、静态 census/identity/comparator/status/cleanup 边界，不能宣称 dynamic PASS。

### 1.2 Profile table 与 public summary fields

每个 `dst/src` 元组写作 `ne / nb / view_off / view-present`。destination 的 view metadata
只用于 runtime predicate；child destination 始终 private contiguous shadow。

| ID | count | op / vector_op | dst | src0 | src1 | scalar0 |
|---|---:|---|---|---|---|---:|
| P00 | 18 | ADD / 1 | `16,1,1,1 / 4,64,64,64 / 0 / 0` | same / `0 / 1` | same / `0 / 0` | `00000000` |
| P01 | 30 | ADD / 1 | `1024,1,1,1 / 4,4096,4096,4096 / 0 / 0` | same / `0 / 0` | same / `0 / 0` | `00000000` |
| P02 | 18 | ADD / 1 | P01 | P01 / `0 / 1` | P01 / `0 / 0` | `00000000` |
| P03 | 18 | ADD / 1 | `128,128,16,1 / 4,512,65536,1048576 / 0 / 0` | same / `0 / 0` | same / `0 / 0` | `00000000` |
| P04 | 18 | MUL / 2 | P00 with dst view0 | same / `0 / 0` | same / `0 / 0` | `00000000` |
| P05 | 49 | MUL / 2 | P01 | same / `0 / 0` | same / `0 / 0` | `00000000` |
| P06 | 36 | MUL / 2 | P03 | same / `0 / 0` | `128,1,16,1 / 4,8192,512,8192 / 0 / 1` | `00000000` |
| P07 | 18 | MUL / 2 | `128,1,16,1 / 4,512,512,8192 / 0 / 0` | same / `0 / 0` | `1,1,16,1 / 4,4,4,64 / 0 / 1` | `00000000` |
| P08 | 18 | MUL / 2 | P03 | same / `0 / 0` | `1,128,16,1 / 512,4,512,8192 / 0 / 1` | `00000000` |
| P09 | 18 | MUL / 2 | P03 | same / `0 / 1` | `1,1,16,1 / 4,4,4,64 / 0 / 0` | `00000000` |
| P10 | 18 | MUL / 2 | `128,16,1,1 / 4,512,8192,8192 / 0 / 0` | same / `0 / 0` | `128,1,1,1 / 4,512,512,512 / 0 / 0` | `00000000` |
| P11 | 18 | MUL / 2 | P10 | same / `0 / 0` | same / `0 / 0` | `00000000` |
| P12 | 6 | MUL / 2 | `2048,1,1,1 / 4,8192,8192,8192 / 0 / 0` | same / `0 / 0` | same / `0 / 0` | `00000000` |
| P13 | 6 | MUL / 2 | `256,2,1,1 / 4,1024,2048,2048 / 0 / 0` | same / `0 / 0` | `256,1,1,1 / 4,1024,1024,1024 / 0 / 0` | `00000000` |
| P14 | 6 | MUL / 2 | `256,8,1,1 / 4,1024,8192,8192 / 0 / 0` | same / `0 / 0` | P13 src1 | `00000000` |
| P15 | 18 | SUB / 3 | `128,1,16,1 / 4,512,512,8192 / 0 / 0` | `128,1,16,1 / 4,24576,512,24576 / 16384 / 1` | `128,1,16,1 / 4,4,512,8192 / 0 / 1` | `00000000` |
| P16 | 18 | SCALE / 4 | P10 | same / `0 / 0` | absent | `3db504f3` |
| P17 | 18 | SCALE / 4 | `18432,1,1,1 / 4,73728,73728,73728 / 0 / 1` | same / `0 / 1` | absent | `00000000` |
| P18 | 18 | SCALE / 4 | `262144,1,1,1 / 4,1048576,1048576,1048576 / 0 / 1` | same / `0 / 1` | absent | `00000000` |

Public summary fields 也属于 exact predicate：

```text
element_count = dst.ne[0]
outer_count   = dst.ne[1] * dst.ne[2] * dst.ne[3]
src0_stride   = src0.nb[1]
src1_stride   = binary ? src1.nb[1] : 0
src2_iova/src2_stride/scratch_iova/scratch_bytes/rope_position = 0
dst_stride    = dst.nb[1]
```

### 1.3 Span、window 与私有 shadow

对每个实际 source 使用 128-bit/overflow-detecting 算术：

```text
logical_hi = view_off + sum((ne[d]-1)*nb[d], d=0..3) + 4
beat_lo    = view_off & ~7
beat_hi    = (logical_hi + 7) & ~7
```

- public `src_iova == src_window_base + view_off`；window base 是 mapped allocation
  base，window size 精确等于 `beat_hi`，但 runtime 只从 allocation raw-copy
  `[beat_lo, beat_hi)`，不读取未证明 prefix。
- child `region_base=window_base`、`region_size=beat_hi`、`view_off` 取 profile 表；
  GMEM floor/limit 与 overlap 只使用实际 beat interval
  `[base+beat_lo, base+beat_hi)`。
- SCALE source1 的 tuple 精确全零，并从上述 floor/limit/overlap/accounting 集合移除。
- destination shadow base 8-byte aligned、size=`4*N`、view_off=0、contiguous
  `nb=[4,4*ne0,4*ne0*ne1,4*ne0*ne1*ne2]`，与每个实际 source beat interval disjoint。

### 1.4 Numeric serial cycle bound

functional GMEM model 冻结 `B_rsp=16`（request fire 后 1--16 cycles 首次 valid，随后
held-until-ready）；F32 child phase bound 使用既有 `B_child=512`。以固定 admission/tail
裕量 `B_fixed=32`，保守 serial upper bound 为：

```text
B_binary(N) = 32 + N * (1 + 2*(1+16) + (1+512) + (1+16))
            = 32 + 565*N
B_scale(N)  = 32 + N * (1 +   (1+16) + (1+512) + (1+16))
            = 32 + 548*N
```

最大 binary profile P03/P06/P08/P09 的 `N=262144`，上界为 `148111392`；P18
上界为 `143654944`。adapter 实例的 child `COMMAND_TIMEOUT_CYCLES=200000000`，
64-bit harness limit=`220000000`，两者都严格大于上界且小于 32-bit counter 极限；
Python/C++/receipt 中仍以 64-bit 保存和比较。matching response/fire 在 deadline
比较中优先于 timeout；valid environment 的 16/512 bound 又保证正常事务不会到达 deadline。

### 1.5 明确 out-of-scope

- 不修改 `TensorNpuF32TensorAlu`/`TensorNpuFp32AddMul` 数值数据路、legacy DMA/MM2、
  third-party FPU-SP 或 public macro port list；不新增 generic F32/FMA capability。
- 本轮首次只允许运行 `bash -n` 与唯一 `--preflight`。不执行 Verilator generation、make、
  binary、19 个代表事务、canonical node rollout、综合、STA 或 PPA。
- 即使后续 19-profile execute PASS，也不证明 367 个 canonical identity 已逐个按真实依赖执行，
  更不证明完整 Qwen、shell chat、tokens/s 或 full-graph anti-fallback。

## 2. 阶段 2a：协议规则

1. **Admission/resident**：legacy 与 macro 同拍仍由 legacy 优先；macro payload 只在
   `macro_cmd_valid_i && macro_cmd_ready_o` 捕获。top resident 到 held completion handshake
   全程稳定；adapter 再以一次 start handshake 捕获 profile/window/scalar snapshot。
2. **Finite preflight**：`ABI -> kernel/capability/identity/deadline -> profile/op/summary/
   scalar/tail -> generation/permission/span/alignment/overlap`。任一 reject 在 child reset asserted、
   F32 start=0、GMEM=0、raw commit=0 时 terminal。
3. **GMEM owner**：top `ST_DMA_RUN` 只选 DMA，`ST_MACRO_RUN` 只选 adapter；non-owner
   ready/response 全零。adapter 与 child 各自最多一个 outstanding，离开 RUN 前必须为零。
4. **SCALE empty source1**：public tuple必须 `iova/base/size/stride=0,perm=00`；adapter child
   固定 port驱动 inert zero descriptor，但 `opcode=SCALE` 结构上跳过 src1 request。
5. **Request/response**：request `valid&&!ready` 时 payload held；accepted request 恰好一个
   held response。response error、wrong owner、timeout 先 fail-closed并完成既有 drain，不能把
   partial shadow 计为成功。
6. **Completion**：adapter terminal 只被 top 锁存一次。top 不再比较固定 `256/64/16`，而以
   profile 导出的 expected read/write/elements 与 observed counter 全等后发布 SUCCESS；
   `completion_valid_o&&!completion_ready_i` 时全部 identity/status/counter逐 bit稳定。
7. **Runtime publication**：matching status、producer/sequence/context/kernel/node count/hash、
   framing、counter 与 profile identity 全部通过后才 raw-copy完整 shadow。失败、completion
   backpressure未accept、identity mismatch或counter incomplete不修改 `dst->data`。
8. **Coverage sets**：`required_seen`、`eligible_exact_signature`、`assigned_profile`、
   `enqueued_command_fire`、`adapter_started`、`completion_emitted`、`completion_accepted`、
   `raw_dst_committed`、`required_successfully_covered` 分别计数/去重，禁止用19或367覆盖
   canonical-completed set。

## 3. 阶段 2b：状态机

top 继续使用八态：

```text
IDLE -> DECODE -> TIU_RUN/DMA_RUN -> COMPLETE -> IDLE/ERROR_HOLD
IDLE -> MACRO_START -> MACRO_RUN -> COMPLETE -> IDLE/ERROR_HOLD
```

adapter 继续使用六态，不新增 profile-specific state：

| state | owner / output | transition |
|---|---|---|
| `AD_IDLE` | start ready，child reset | start fire -> `AD_CHECK` |
| `AD_CHECK` | finite-table/span preflight，零 GMEM | reject -> `AD_ERROR`; pass -> `AD_ENGINE_START` |
| `AD_ENGINE_START` | child reset释放，held start | child start fire -> `AD_ENGINE_RUN` |
| `AD_ENGINE_RUN` | child是唯一 adapter GMEM owner | child done -> `AD_DONE`; error -> `AD_ERROR` |
| `AD_DONE` | 一整拍 success terminal | -> `AD_IDLE` |
| `AD_ERROR` | 一整拍 fail terminal | -> `AD_IDLE` |

accepted GMEM/FP child 的 drain 仍在 `TensorNpuF32TensorAlu.ST_DRAIN`，adapter 不得提前
terminal。profile 只选择 resident combinational table，不建立 19 套 FSM。

## 4. 阶段 2c：不变量

| ID | 表达式 | 违反后果 |
|---|---|---|
| A1 | `legacy_fire + macro_fire <= 1`；DMA/macro GMEM owner互斥 | 双 owner/response串单 |
| A2 | profile只接受0..18且upper flags为0；profile/op/table row一一对应 | descriptor collision |
| A3 | binary permission=`01/01/10`；SCALE=`01/00/10`，全2-bit相等 | 越权或 dummy source |
| A4 | SCALE empty source1 tuple全零且不进入floor/limit/overlap/accounting | absent operand被访问 |
| A5 | 每个source的ne/nb/view/off/logical/beat span与profile逐字段相等 | canonical view归一化或越界 |
| A6 | destination child永远private/contiguous/view_off0，SUCCESS前active dst不变 | partial publish/alias corruption |
| A7 | binary op_params全零；SCALE raw scalar/tail逐bit精确 | host FP或ABI漂移 |
| A8 | SUB child=ADD且RHS sign翻转一次；SCALE child=MUL且每元素一次 | numerical operation漂移 |
| A9 | `observed read/write/elements == profile expected` 才可done | dynamic completion假绿 |
| A10 | GMEM/child outstanding各∈{0,1}且总和≤1；terminal时为0 | orphan response |
| A11 | held request与held completion在backpressure期间payload稳定 | address/identity corruption |
| A12 | checked64 products/end/cycle limit无overflow；timeout/harness均大于upper bound | P18截断/漏最后元素 |
| A13 | 367 eligible、19 representatives、1 canonical completed为独立集合 | coverage基数坍缩 |
| A14 | failure/identity mismatch/incomplete counters不raw commit、不增加completed set | false canonical completion |
| A15 | reset清空resident/owner/terminal；error-clear后clean retry无stale credit | ghost transaction |

A1--A12 由结构 RTL、profile source audit、negative mutation 与后续 single-binary suite组合
覆盖；A13--A14 由 manifest oracle、runtime audit schema与receipt闭合。文本本身不是 PASS。

## 5. 阶段 2d：数据通路约束

- **profile ROM**：一个 bounded `case(profile_id)` 同时生成 expected macro op/summary、child
  opcode、三组 `ne/nb/view_off/span`、scalar、permission class和expected counters；所有 default
  先零化并令 `profile_valid=0`，防 latch/partial row。
- **widened checks**：source logical/beat span、`base+beat_hi`、destination `4*N`、floor/limit、
  overlap与accounting全部使用 65/128-bit组合中间值；64-bit输出只在overflow bit为0后采纳。
- **child lowering**：table row寄存后直驱唯一 `TensorNpuF32TensorAlu`；binary src1取table，
  SCALE src1固定全零；destination使用private shadow descriptor。没有 host result注入口。
- **accounting**：adapter request fire寄存 direction/strobe，matching non-error response分别加
  read8或write popcount4；terminal以64-bit expected值比较。top只冻结adapter observed值与
  profile-checked terminal，不再含 profile0 magic constant。
- **runtime raw path**：allocation/view root raw bytes -> disjoint simulated GMEM source span ->
  child reads/FP operation/private writes -> completion matcher -> full shadow raw commit。broadcast
  始终由 child modulo walker寻址，不在 host展开。
- **critical path**：最重新增路径是 profile ROM -> 128-bit span/end/overlap -> CHECK next-state；
  它独占 `AD_CHECK`，不串入 public GMEM ready。运行 numerical critical path仍位于既有 F32 child。

## 6. 阶段 2e：RTL 级 topology（九项冻结）

1. **module边界与接口协议**：public `TensorNpuCoprocessor` macro/GMEM/completion ports逐字保持；
   adapter内部增加expected-counter输出供top动态复核，不改变backend public port；全部单时钟同步reset。
2. **状态寄存器**：top macro resident/identity/completion/cycle/counter q保持唯一时序块；adapter
   保存profile ID、public fields、三路完整permission-equality结果、terminal/accounting q；child
   保存既有descriptor/walker/owner。reset均为0/IDLE。
3. **组合逻辑**：top admission/GMEM mux/completion decode；adapter profile ROM、ABI/layout、
   128-bit span/window/overlap、floor/limit、fixed lowering、error map与accounting decode；每块先默认赋值。
4. **FSM**：top八态、adapter六态、child既有14态；profile不复制状态机，illegal/default均
   fail-closed。accepted owner只经child DRAIN收口。
5. **pipeline与valid/ready**：public macro accept -> top resident -> adapter resident/CHECK ->
   child resident -> serial GMEM/FP/write -> adapter terminal -> top held completion -> runtime raw commit。
   所有backpressure点在对应resident边界held。
6. **reset/stall/kill优先级**：无独立flush/kill；`reset > illegal/wrong-owner/response error >
   matching deadline fire > timeout > predicate reject > normal`。completion stall只由top holder处理。
7. **资源共享**：DMA与adapter共享唯一public GMEM 2:1 state mux；19 profiles共享一个adapter、一个
   F32 tensor ALU和一个Fp32AddMul。显式profile mux/op mux/enable来自resident `state_q/profile_q`。
8. **critical path**：CHECK周期的ROM+128-bit bounds/overlap和child运行时4D modulo/stride为候选；
   FPU unpack/align/normalize/round保持既有路径。本轮不执行STA/PPA。
9. **function与显式硬件划分**：FSM、owner、valid/ready、permission、span、accounting、completion
   全部用显式 `always @(posedge)`/`always @(*)`/assign；只允许小型纯组合min/max/helper。
   Python/C++ profile table和raw byte helper不进入综合网表，且不得含host FP arithmetic。

Topology 自审：public ABI、单 GMEM owner、SCALE absent source1、allocation-relative source span、
private shadow、动态counter、held completion与64-bit bounded cycle路径在结构上闭合；允许进入阶段3。

## 7. 后续 evidence boundary、反例与 unknowns

preflight 必须生成并绑定：19-row machine profile、367 canonical IDs与row counts、permission 64-row/
SCALE empty-row truth table、view/span/cycle oracle、missing/extra/duplicate/collision/op/shape/nb/view/off/
op_params mutations、source/tool/DSO identity、warning/membership comparator mutation、task-status
HUP/INT/TERM/early-exit/cleanup probes、active-process audit和`build_count=0`/build-root absent receipt。

后续 execute 的负向矩阵至少包含 unknown kernel、invalid profile、op/profile collision、shape/stride/
view/off mismatch、nonzero binary params、unsupported SCALE bits、4mod8/out-of-window、overlap、
overpermission、request-ready timeout、completion backpressure/identity mismatch与clean retry。

- 反例：把 P17/P18 的 canonical destination view直接交给child会允许active alias写入，违反private
  shadow；把 SCALE source1伪装为readable dummy window会使read/floor/accounting错误增加。
- 替代实现“根据shape自动识别profile”会在P01/P02、P03/P06/P08/P09及多个MUL row产生collision，
  不采用；profile ID仍必须与完整runtime metadata双向相等。
- unknowns：本轮不执行binary，故19代表事务、P18最后元素、warning/membership actual rows、host
  runtime动态zero-fallback仍是GAP；FPU-SP独立数值正确性、完整canonical依赖rollout、综合/STA/PPA
  也未证明。
- `scope_extension_request`：无；当前 v3 合同的write paths足以实现本slice。若后续真实deadline-edge
  test证明既有 `TensorNpuF32TensorAlu` 的内部timeout优先级违反本合同，则需新版本合同把该RTL与
  对应TB加入write paths，当前slice不得以adapter补丁掩盖child owner根因。

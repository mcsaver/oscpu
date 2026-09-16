# OoO Branch Prefetch Buffer

> ⚠️ **状态(2026-07-03 RTL 重读)**:活文件中的死存储——`OOO_ROB_WALK_MODE=1` 下 `req_fire_i` 恒 0(branch prefetch req 需 pending_branch 恒 0、JALR req 需 JALR-BTB hit 而表恒空,见 `OooBranchPrefetchRequestGate.v:40-52`),影子包永不建立,全链死路;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. 需求

`OooBranchPrefetchBuffer` 承接 `OooFrontend` 中 branch prefetch 影子包状态：

- 记录已经发出的 branch prefetch request PC。
- 在匹配的 fetch response 返回时保存两条 slot 的 decoded packet。
- 向父模块暴露 active、buffer valid、request PC 和 packet payload。
- 接受父模块给出的 clear 动作，在 redirect/trap/recovery 边界丢弃影子包。

本模块只持有前端局部影子包状态，不发起 fetch request，不判断 branch resolve，不决定 FIFO seed，不修改 `next_fetch_pc`、outstanding、trap、commit 或 pending 状态。

## 2. 协议

输入：

- `clear_i`：父模块已经仲裁好的清理动作。
- `req_fire_i`：branch prefetch request 被接受，`req_pc_i` 是请求 PC。
- `rsp_capture_i`：当前 fetch response 应被保存到影子包。
- `rsp_*_i`：当前 response decode 后的 packet payload。

输出：

- `active_o`：有一个 branch prefetch request/影子包仍属于当前控制流。
- `buffer_valid_o`：影子 packet payload 有效。
- `pc_o`：已发出 request 的 PC，用于 pending/response match。
- `buf_*_o`：被捕获的 packet payload。

父模块仍负责：

- 生成 `branch_prefetch_req_fire_w`、`branch_prefetch_rsp_capture_w` 和 `branch_prefetch_clear_w`。
- 判断 `branch_prefetch_buffer_match_w`、`branch_prefetch_rsp_raw_match_w`、`branch_prefetch_hit_available_w`。
- 把命中的影子包转正为 FIFO seed 或 redirect target。

## 3. 状态机

每个时钟沿：

1. `rst`：清 active、buffer valid、request PC 和 payload，保证仿真确定性。
2. `clear_i`：清 active、buffer valid 和 request PC；payload 不要求清零，沿用旧父模块非 reset clear 行为。
3. `req_fire_i`：置 `active=1`、清 `buffer_valid`、记录 `req_pc_i`。
4. `rsp_capture_i`：置 `buffer_valid=1` 并保存 `rsp_*_i` payload。

当 `req_fire_i` 与 `rsp_capture_i` 同拍且未被 clear 覆盖时，保持旧 nonblocking 赋值顺序：request 先清 `buffer_valid`，随后 response capture 将 `buffer_valid` 置 1 并写入 payload。

## 4. 不变量

- `clear_i` 优先级高于 request/capture，匹配旧父模块中清理分支位于 request/capture 赋值之后的非阻塞覆盖语义。
- 非 reset clear 不修改 payload，避免把无效 payload 清零行为误当成协议语义。
- `buffer_valid_o` 为 1 时，`buf_*_o` 是最近一次 `rsp_capture_i` 保存的 packet。
- 新模块不观察 CSR/ROB/branch resolve/flush cause，只执行父模块给出的动作。
- 新模块不改变 branch prefetch direct dispatch 当前被显式门掉的事实。

## 5. 数据通路

1. request path：`req_fire_i + req_pc_i -> active_o/pc_o`。
2. capture path：`rsp_capture_i + rsp packet -> buffer_valid_o/buf_*_o`。
3. clear path：`clear_i -> active_o=0, buffer_valid_o=0, pc_o=0`。
4. match、hit、FIFO seed、redirect PC 选择全部留在父模块。

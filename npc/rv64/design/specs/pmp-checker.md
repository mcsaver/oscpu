# 规范：PMP 检查器 PmpChecker

> 模块：`vsrc/memory/PmpChecker.v`。取指桥/访存桥各例化若干份做逐访问权限检查。
> 模板见 `../arch/SPEC-TEMPLATE.md`。状态：**已实现并验证（ACT4 PMP gate 通过）**。

## 1. 目的与范围
对单次物理访问按 RISC-V PMP 规范判定是否产生 access fault。纯组合：输入物理地址+访问
属性+pmpcfg/pmpaddr，输出 `fault_o`。不负责 fault 的 trap 形成(由桥/控制面处理)。

## 2. 接口
| 信号 | 含义 |
| --- | --- |
| `paddr_i` / `access_size_i` | 访问起始物理地址 / 字节数 |
| `priv_mode_i` | 当前特权级(M/S/U) |
| `access_read_i/write_i/exec_i` | 访问类型 |
| `pmpcfg_i` / `pmpaddr_i` | 全部 PMP 配置/地址寄存器(packed bus，16 entry) |
| `fault_o` | 1=该访问应触发 access fault |

## 3. 判定逻辑（组合，规范对齐）
对地址区间 `[paddr, paddr+size-1]`：
1. **越界回绕**(`access_last < paddr`)→ fault。
2. 自 entry0 起找**第一个 overlap** 的已激活 entry(A=TOR/NA4/NAPOT)，记其 cfg 与是否 full-cover。
3. 若有匹配 entry：
   - `enforce = (priv != M) || cfg.L`（M 模式仅锁定 entry 才受限）。
   - `fault = enforce && (!full_cover || (read&&!R) || (write&&!W) || (exec&&!X))`。
   - 注：访问跨越但未被单条 entry **完整覆盖** 也算 fault（部分覆盖不放行）。
4. **若无任何 entry 匹配**：
   - `fault = (priv != M) && (read||write||exec)` ——
     **M 模式放行；S/U 模式拒绝**。

## 4. 关键不变量
- **PMP-I1（默认拒绝 S/U）**：PMP 已实现(本核 16 entry)且无匹配条目时，M 通过、S/U 失败。
  这是 RISC-V 规范行为，也是 iter0 回归的根因：AM S-mode 测试未配 PMP→进 S 即 access fault。
  **教训**：任何运行于 S/U 的裸代码必须先配 PMP(真实固件 OpenSBI 即如此)；不要把此默认拒绝误判为 core bug。
- **PMP-I2（M 模式默认放行）**：无匹配 entry 时 M 访问恒通过(除非匹配到 locked entry)。
- **PMP-I3（完整覆盖）**：访问区间必须被单条匹配 entry 完整覆盖才按其权限放行；跨 entry 部分覆盖→fault。
- **PMP-I4（地址匹配）**：TOR 用 `[pmpaddr[i-1], pmpaddr[i])<<2`；NA4=4B；NAPOT 按编码前导 1 推区间，
  全 1 编码=全地址空间。

## 5. 关键路径
纯组合，16 entry × (overlap+full-cover+match) 比较 + 优先级选择。是潜在长组合链；
NAPOT 的前导 1 计数(`napot_ones`)含循环。时序阶段(待 STA)若成关键路径，可考虑流水化 PMP 检查
或减少 entry 数；当前功能正确优先。

## 6. 验证
- riscv-arch-test ACT4 PMP gate（`PMPSm 51/51`、`PMPS,PMPU 18/18`）。
- riscv-tests `rv64mi-p-pmpaddr`。
- iter0 经验：AM S-mode 测试经 `trm.c` 配 NAPOT 全空间 RWX 后全部恢复(56/56)。

## 7. 变更记录
- 2026-06-28：逆向文档化(含 iter0 回归根因与教训)。

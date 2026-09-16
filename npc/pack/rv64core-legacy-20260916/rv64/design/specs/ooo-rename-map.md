# 规范：寄存器重命名映射 OooRenameMap

> 模块：`vsrc/rename_allocate/OooRenameMap.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
维护架构寄存器→物理寄存器映射(speculative map)。每拍最多 2 条 uop 同拍重命名:读 src 的当前 phys 映射、
把 dest 的 arch→new phys 写入映射;返回每条 uop 的 src phys 与被覆盖的 old phys(供 ROB 提交时释放)。
误预测恢复走 ROB-walk 反向恢复端口(restore0/1,每拍 2 条,把 squashed uop 的 arch_rd 还原为 old_pdest);
checkpoint 影子在 `OOO_ROB_WALK_MODE=1` 下 capture/restore 恒被 gate,为死硅(2026-07-03 RTL 重读确认)。
flush 时恒等复位(map[i]=preg_i)。

## 2. 同拍双重命名
- lane0/lane1 同拍:lane1 的 src 若等于 lane0 的 dest(同拍 RAW),src phys 取 lane0 的 new phys(同拍前递);
  两条都写 dest 时 lane1 覆盖 lane0(同 arch dest 的 WAW,lane1 较新胜)。
- old phys:每条写 dest 的 uop 返回该 arch reg 之前的 phys(ROB 提交该 uop 时回收到 free list)。

## 3. 不变量
- **RM-I1 同拍前递**:lane1.src == lane0.dest → 用 lane0.new_phys(读到同拍较老 uop 的结果映射)。
- **RM-I2 同拍 WAW**:lane0/lane1 同 arch dest → 最终映射为 lane1.new_phys。
- **RM-I3 x0**:arch x0 映射恒为 preg0(不分配/不释放)。
- **RM-I4 精确恢复**:误预测由 ROB 反向 walk 逐拍把 squashed uop 的 map[arch_rd] 还原为 old_pdest
  (walk lane1 程序序更老,同拍 WAW 后写胜→最老映射留存),保证 redirect 后映射正确;flush 则恒等复位。

## 4. 关键路径
Vivado OOC:RenameMap 单独仅 1 逻辑级/logic 0.77ns(极浅,健康)。深度在 DispatchBackend 把它与
free-list/busy/IQ 合一时(见 `ooo-rename-alloc.md`),非本模块本身。

## 5. 验证
- 模块 TB `tb_ooo_rename_map`;集成 riscv-tests/AM(同拍 RAW/WAW、分支恢复后映射正确、old-phys 释放)。

## 6. 变更记录
- 2026-06-28：逆向文档化(同拍双重命名前递/WAW、old-phys、checkpoint/restore)。

# T4D dispatch log

- `/root/t4d_plic_netlist_map`：只读映射 T4C fresh PLIC cell→RTL，确认 threshold→winner→claim side-effect 公共锥；核对 TB/Linux/DTS 后推荐默认 `PRIORITY_BITS=3`。未修改文件。
- `/root`：冻结接口契约、实现、变异、回归、fresh synthesis/STA 与记录。

[V9P-CURRENT-PATH-PROJECTION][APPROVE] design_id=sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af contract_sha256=71b0d1619d4af6349eeb195d71a9e494ca03c434bfd700f5bf343c0394f54c89

RV64 RTL 结论｜对象=`OooLsuAxiLaneAdapter`、`OooMemOwnerTerminalCollector` 旧 L0 → full-core L0 收据投影｜周期/配置=d3f3、`-DOOO_ASSERT`、114/114｜TB/EDA 观测=目标日志字节同一，layered/system 已绑定新 current 路径；未重启仿真/综合/STA｜范围=PASS（projected aggregate）

## Projected aggregate 边界

- 旧 module result `88c098ab4d7a17155e6d1d1b237c1d95a50af8ea9a32c361a0ebcd019aabc202` 是原 independent review 直接审阅的 PASS、d3f3、114/114 收据。
- 新 full-core module result `9b03a5e7c93ca769598c69b603fa34f6892b84d1c9df3cbce8f9c069c64fb4dc` 是 PASS、d3f3、114/114；路径、文件 SHA、输入收据 SHA 和记录命令并行度不同，必须显式标成 projected aggregate。
- 四个生产 RTL SHA 保持原 d3f3 身份：`OooIntBackend.v=bf07ac64…f6a07e`、`OooMemAxiBridge.v=86299fad…f870348`、`OooLsuAxiLaneAdapter.v=6d81b143…3a0e22`、`OooMemOwnerTerminalCollector.v=d904f13a…b185`。
- 旧新 summary 均为 `75496cf1…903cc3`，module make log 均为 `4c429530…d584b`。

## 目标日志字节同一

- adapter 旧新日志均为 `99034f370c90fabfacf25d00e544b5f5677778aea1f5d3dad7310b3b776e6072`、851 B，含 `[PASS] tb_ooo_lsu_axi_lane_adapter`、d3f3 `[RTL-DESIGN-ID]`、`[RESULT] PASS`。
- collector 旧新日志均为 `4cb905abb2130cd1ac0acd7176e1a5eab4853bc43b98e586b27129b7e52be3d1`、1278 B，保留 `[V12A-TCOLL-LANE-PAIR-MATRIX] duplicate=66 distinct=66 PASS`、`[V8P-TCOLL-12INGRESS-CAPTURE]`、`[V8P-TCOLL-12INGRESS-DRAIN]`、`[PASS] tb_ooo_mem_owner_terminal_collector`、d3f3 `[RTL-DESIGN-ID]` 与 `[RESULT] PASS`。
- live collector 仍阻断同 token 的全部 `ingress_accept_o`，并在 `OOO_ASSERT` 下以 `[S2-G1-TCOLL-INGRESS-DUP]`、`$fatal` fail-loud；不存在择一路、合并或去重后继续 PASS。

## Layered/system current 指针

- live layered SHA 为 `735f313b29104be7fb52ffafcd51ca684190bbfb69b15ed7439a541ea957406d`；L0 `result`、L1 `module_result` 及 `source_directories.l0_module` 均精确引用新 full-core module 路径和 SHA `9b03a5e7…fb4dc`。
- live system SHA 为 `ab79d6122d15e0baa6bda65ae993b55fe3227615e22f37d31f294ed11b75d165`；其 `layered_signoff_receipt` 精确绑定 live layered，并投影 L0 114/114。
- `reuse_boundary.dut_rerun_performed=false`、`sealed_layered_evidence_recomputed=true`，所以只需重绑定现有证据，不需要再次启动 RTL 仿真。
- `historical_defect_current.py` 必须分离旧 review provenance 与新 canonical current，并 fail-closed 校验旧新 design-id、114 inventory、目标日志 SHA/size/marker、layered 直连和 system 传递指针。

## 反例与边界

adapter/collector 新日志单字节漂移、114 inventory 漂移、四个生产 RTL SHA 或 design-id 漂移、layered 回指旧 module、system 的 layered SHA/size 漂移，以及修改原 independent review 把 projected aggregate 冒充直接审阅，均必须拒绝并输出 GAP。

Unknowns：immutable V9P instance bank 与 kind/token/epoch owner tuple 未保留；未执行 fresh d3f3 collector fatal-removal RTL mutation；mapped PPA 为 `UNMEASURED_UNPROMOTED`；本 review 未运行新的 RTL 仿真、L2/L3 guest、Ubuntu、综合或 STA；除完整 summary 与两个目标日志外未逐字比较其余 112 个单项日志。

`scope_extension_request=null`。WSL single-flight 工程 shell ownership 已归还主节点。

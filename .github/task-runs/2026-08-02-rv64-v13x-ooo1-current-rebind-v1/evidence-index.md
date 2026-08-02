# V13X evidence index

- current design-id: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
- scoped manifest: `evidence/architecture-current.json`, SHA-256
  `ed757ec21d717f74be9b857deba2d37edc8c91f9308d153766d92d2f113c5689`
- OOO-1 gate log: `evidence/true-ooo-long-latency.log`, SHA-256
  `6a7635c930f7e7dab097451c146939fd85ee05276463e401ff007281a3c87434`
- architecture result: `evidence/ooo1-current/static/architecture-result.json`, SHA-256
  `fb9e3f7c2ab3e86d645f0bc889adc0e42c13bf71f97dbb182978c6643dcd789d`
- release log: `evidence/ooo1-current/baseline-release/logs/tb_ooo_int_backend.log`, SHA-256
  `5b3735755eae042d7af82b478b935f065c4184a5fda0959fa2b760f1d5097c73`
- assert log: `evidence/ooo1-current/baseline-assert/logs/tb_ooo_int_backend.log`, SHA-256
  `2971d53e0eb4d453a3ef5ca0fd66736a6d6a91cc3de8a186ea15623c38f54705`
- 7/7 negative RTL records: `evidence/ooo1-current/mutation-summary.log`, SHA-256
  `23b41e49c6c82be9a8330be4eb3185059e2bcc4a1bbe692663ae3c5d3a4e79f0`
- checker unit log: `evidence/ooo1-current/static/checker-unit.log`, SHA-256
  `5066db0c934dd4ea6de75ec7752cf76e90c07415c568892606042169c62715c4`
- simulator config: `evidence/ooo1-current/static/simulator-config.txt`, SHA-256
  `0e552aea72a37596b3c81d8c3f1bd1437d4a43924a1deac3314ff9a056cc8f54`
- final runner summary: `evidence/ooo1-current/runner-summary.log`, SHA-256
  `7f555a8387fed7105cfe6c3c7e9d371411058a17e641597a966eec03832f3aae`
- final review: `evidence/pre-delivery-review.md`
- final contract: `subagent-contracts/v13x-ooo1-frozen-review-v3.json`, SHA-256
  `fc9a7696d3f8237aea8cd5527ea6ee05e29a1e222fb8fde2885346586d51f35f`

Markers:

- `[V8N-TRUE-OOO-METRICS] load_miss=8 mul=8 div=8 rob_peak=9 retire_order_violations=0`
- `[V8N-TRUE-OOO-BINDING] ... load_dual=4 mul_dual=4 div_dual=4 ... rob_valid_peak=9`
- `[V8N-RUNNER][PASS] refresh=1 baselines=6/6 mutations=7/7 OOO-1=GREEN overall=RED`


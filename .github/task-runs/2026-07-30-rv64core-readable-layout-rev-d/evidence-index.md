# Evidence index

| Evidence | Observation | Result |
|---|---|---|
| `tools/generate_elaboration_xml.sh` | Product `OOO_CSR_QUEUE_HEAD=1`, `OOO_TERMINAL_HOLDER_ASSERT=1`; regenerated current `NpcTop` and `NpcSimTop` XML | PASS |
| `build_interactive_datasheet.py` | 150 files, 136 modules, 195 instances, 9 transactions, 38 WaveDrom, 1,073,714 bytes | PASS |
| Node syntax check | Bundled Node accepted `interactive_datasheet.js` | PASS |
| `audit_interactive_datasheet.py --self-test` | Baseline passed; injected 9 px, undefined variable and hidden font control were all rejected | PASS |
| `audit_interactive_datasheet.py` | 58 phases, 2 side paths, 240 fields, 975 answers, 1,219 sequential targets, 0 external resources; default large 16/12; undefined variables 0 | PASS |
| `audit_vsrc_coverage.py` | 14 Markdown files, 150 vsrc files, 150 atlas rows, 150 covered files, 38 WaveDrom blocks | PASS |
| Independent static review | Initial P2 found for hidden narrow-screen scale control; fixed and re-reviewed with P0/P1/P2 all zero | PASS |
| Scoped strict guard | Four scoped path groups, `required_profiles=0` | PASS |
| Full-worktree strict guard | 42 changed path groups; unrelated concurrent V11I paths require missing `npc-dev` evidence | GAP |
| Browser dynamic visual check | Not run under the local-site skill boundary | GAP |

## Artifact hashes

```text
80ed008e3e00ac512d00962acbd7ad35448745f98417f67e114f9f488f8d7331  docs/rv64core/study/index.html
c6d8c09a02c1aa4a50ac718e436f1dcb6425ce456eff0d12877da99d0aad51aa  docs/rv64core/study/tools/interactive_datasheet.css
27c6810ace2124844abe2d3f749ba44c45342bc9f461d15b9feb2ceaf004e9d9  docs/rv64core/study/tools/interactive_datasheet.js
c350601521d1645c1d657df0a4cf7cd4ada61e27ab3ac18166f769be7191ecee  docs/rv64core/study/tools/build_interactive_datasheet.py
fe90fa110b6c604cf7f934cff58fa85a8ccfacb58cc1b176ca7fcd13d22f837b  docs/rv64core/study/tools/audit_interactive_datasheet.py
21345d233087bc36a8275cde7f88ea19e64113f585e983e340944cf1ea993a6f  docs/rv64core/study/README.md
9eced7569f815ebf763de2a1647d1ccc264ea340f28826f72f600aff4cb79695  /tmp/rv64-study-npctop.xml
922c23d0687a4b7ce11f4620e97f509058544af9510b35b810837b4022894a7a  /tmp/rv64-study-simtop.xml
```

The XML files are reproducible temporary elaboration inputs and are not
delivered as repository artifacts.

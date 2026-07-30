# Evidence index

| Evidence | Observation | Result |
|---|---|---|
| `tools/generate_elaboration_xml.sh` | Product `OOO_CSR_QUEUE_HEAD=1`, `OOO_TERMINAL_HOLDER_ASSERT=1`; generated `/tmp/rv64-study-npctop.xml` and `/tmp/rv64-study-simtop.xml` | PASS |
| `normalize_wavedrom_levels.py` | `files=0 fields=0 mode=check` | PASS |
| `audit_vsrc_coverage.py` | 14 Markdown files, 150 vsrc files, 150 atlas rows, 150 covered files, 38 WaveDrom blocks | PASS |
| `build_interactive_datasheet.py` | 150 files, 136 modules, 195 instances, 9 transactions, 38 WaveDrom, 1,066,834 bytes | PASS |
| `audit_interactive_datasheet.py` | 58 phases, 2 side paths, 240 fields, 975 answers, 1218 sequential targets, 0 external resources | PASS |
| Stale XML negative | XML mtime forced to 2000; builder rejected it and created no output | PASS |
| CSR side-path parent negative | In-memory mutation moved side path from `CsrFile` to phase 7; audit emitted the required parent error | PASS |
| Independent static review | One P1 found, fixed and re-reviewed; final CSR parent/owner/count closure | PASS |
| Scoped strict guard | `--path docs/rv64core/study`, `required_profiles=0` | PASS |
| Full-worktree strict guard | Large unrelated dirty scope; missing `rv64-linux` and `npc-dev` evidence | GAP |

## Artifact hashes

```text
73e6975aa440160c61531ce4a3cea236457d58ac2e7592e2ba0a5f8e63752002  docs/rv64core/study/index.html
6cf2f322655e8a49cae0a57aa58bcbb25ba432a6e7804809d985c32057829ead  /tmp/rv64-study-npctop.xml
2b8d76a16863b5e0c98d159f3e3f0833271c3a630e56093c3000d15ea36eb6d4  /tmp/rv64-study-simtop.xml
945ea5a76e0e4b428e17ede3b1adfcdf6752f9d9b7a744dd9c3720a1db8fab0c  docs/rv64core/study/tools/generate_elaboration_xml.sh
429bdb5eee68c2506ff0b3d35a9c74916951d011b854f0095faf1170f5ef061f  docs/rv64core/study/tools/build_interactive_datasheet.py
7e0699928f344925a396b3da26fe477b8c2d7e4c16293cc09c082fcd25b501e1  docs/rv64core/study/tools/audit_interactive_datasheet.py
```

The XML files are reproducible temporary elaboration inputs and are not
delivered as repository artifacts.

# Evidence index

Canonical command: `make -C npc/rv64 check-ifu-tval`.

- `npc/rv64/eval/ppa/evidence/ifu-tval-current.json`
  - SHA-256: `5455dcf154a59765abcb0862f0e4e39cd43eea59907cea3b906d8da3e4312834`
  - schema: `npc-rv64-ifu-tval-evidence-v2`
- `npc/rv64/eval/ppa/evidence/ifu-tval.log`
  - SHA-256: `7f6c32a09a86388636de3346942cd72a60e0fdc8fa9370b033b03ce03dc5192f`
- `evidence/focused/summary.txt`
  - SHA-256: `539255718d9dfa1884595032198d1a9b16ac236cc9c843915b1ef044fe5b20ac`
  - result: `8/8`
- `evidence/module-aggregate/summary.txt`
  - SHA-256: `ecd2a55da8c96f3844715068f8f4b8471d5f45f2b30fa833bfb65c0fc624ff33`
  - result: `109/109`
- `evidence/mutations/summary.json`
  - SHA-256: `fbfd1f141870874a867a29eebf6ba36d1c393ea6965982bd512ccd0f419f9f53`
  - result: `12/12` compile-success and dynamically rejected; source unchanged
- V1 review contract SHA-256:
  `a6fc02e6627523b4a9c7a75c705266ace3a3657a948cb4f8f954c2367aa78c1a`
- V2 review contract SHA-256:
  `ccc091eaa009c44e934e2ed310f1527312ad9083b8adde505a31f1741e04378b`
- `npc/rv64/eval/ppa/evidence/arch-stable-current.json`
  - SHA-256: `917dd988178c0e0f237d8ed1e3f4e4440989c45acb7fb8509a1a0107398613cb`
  - status: `GAP`, blockers=`37`, PPA=`UNQUALIFIED`

The nested artifact list in `ifu-tval-current.json` binds all focused logs, the exact module
aggregate and every variant log. The ledger binds the result and raw-log hashes shown above.

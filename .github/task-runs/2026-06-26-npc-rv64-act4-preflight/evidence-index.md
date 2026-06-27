# Evidence Index

## Commands

```sh
npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --probe-elfs --extensions I
make -C npc/rv64/testsuites/core-tests/src/riscv-arch-test elfs CONFIG_FILES=/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/act4-config/sail-rv64-max-linux-gnu/test_config.yaml EXTENSIONS=I EXCLUDE_EXTENSIONS=Sm WORKDIR=/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/act4-npc-final-work JOBS=1
npc/rv64/build/NpcSimTop -b --no-diff --max-cycles 20000000 --tohost=0x0000000080039300 npc/rv64/perf/results/act4-probe/20260626-final-elf/I-add-00.bin
```

## Observed Results

- Testsuite asset relocation: PASS, assets now live under `npc/rv64/testsuites/core-tests/`.
- ACT4 FAST ELF probe: PASS, `204 succeeded`.
- ACT4 final ELF generation: PASS, `255 succeeded`.
- ACT4 final ELF NPC smoke: PASS, `I-add-00.elf` exits with `TOHOST PASS`.
- Root cause note: `build/.../*.sig.elf` is a Sail/reference signature-generation intermediate. Running it on NPC exits on HTIF newline value `0x0a`; this is not a DUT ISA failure. Use `elfs/.../*.elf` for NPC.

## Runtime Artifacts

- `riscv-arch-test`: `npc/rv64/testsuites/core-tests/src/riscv-arch-test/`
- `riscv-tests`: `npc/rv64/testsuites/core-tests/src/riscv-tests/`
- ACT4 venv: `npc/rv64/testsuites/core-tests/act4-venv/`
- Bundler install: `npc/rv64/testsuites/core-tests/gems/`
- Sail 0.12: `npc/rv64/testsuites/core-tests/sail-riscv-0.12/`
- xPack GCC 15.2.0-1: `npc/rv64/testsuites/core-tests/xpack-riscv-none-elf-gcc-15.2.0-1/`
- Probe config: `npc/rv64/testsuites/core-tests/act4-config/sail-rv64-max-linux-gnu/`
- Final ELF workdir: `npc/rv64/testsuites/core-tests/act4-npc-final-work-script/`
- NPC smoke log: `npc/rv64/perf/results/act4-probe/20260626-testsuites-final/I-add-00.log`

## Current Gap

- Need replace/adapt broad `sail-rv64-max` config with an NPC-accurate UDB profile before treating failures as RTL issues.
- Need automate ACT4 final ELF execution over a batch, including per-test `tohost` discovery, objcopy, NPC run, and PASS/FAIL summary.
- Need expand from `I-add-00` smoke to RV64I and then supported RV64GC/Zb subsets.

# Evidence Index

## Commands

```sh
bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --list-suites
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --filter "I-(add|addi|sub)-00" --limit 3 --timeout-sec 60 --max-cycles 20000000
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --timeout-sec 60 --max-cycles 20000000
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --build-final --extensions M --workdir /home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/act4-npc-final-work-m --suites rv64i/M --timeout-sec 60 --max-cycles 20000000
npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --workdir /home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/act4-npc-final-work-m --suites rv64i/M --timeout-sec 60 --max-cycles 20000000
```

## Passing Runs

- RV64I ACT4 final ELFs:
  - Run dir: `npc/rv64/perf/results/act4-run/20260626-185425-396823/`
  - Summary: `attempted=51 pass=51 fail=0 skip=0`
  - Status: `npc/rv64/perf/results/act4-run/20260626-185425-396823/status.txt`
- RV64M ACT4 final ELFs:
  - Run dir: `npc/rv64/perf/results/act4-run/20260626-185521-398710/`
  - Summary: `attempted=13 pass=13 fail=0 skip=0`
  - Status: `npc/rv64/perf/results/act4-run/20260626-185521-398710/status.txt`

## Exploratory Notes

- `--extensions M` final build generated suite `rv64i/M`, not `rv64m/M`; runner now offers `--list-suites` to avoid guessing.
- `--extensions A` did not generate a normal A final ELF suite in this checkout. This is a test availability/configuration observation, not an NPC RTL failure.

## Current Gap

- Build an NPC-accurate ACT4/UDB profile instead of relying on a broad `sail-rv64-max` derived probe config.
- Determine the correct ACT4 extension filters for A/F/D/C/Zb/privileged suites in the current ACT4 checkout, or import/update test definitions if needed.
- Add a higher-level ACT4 sweep command once supported suite names and NPC feature profile are pinned down.

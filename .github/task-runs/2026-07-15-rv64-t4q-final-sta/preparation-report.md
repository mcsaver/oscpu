# T4Q STA preparation report

Status: **prepared; heavy synthesis/OpenSTA not run by this preparation task**.

Lightweight checks completed on 2026-07-15:

- `bash -n` on both runners: PASS;
- in-memory compile of all 7 Python files: PASS;
- `test-t4q-evidence-hardening.py`: PASS for all required positive and negative
  controls;
- `git diff --check` for this task directory: PASS;
- no `__pycache__` left in this task directory;
- setup-manifest derivation replayed against T4I evidence: PASS with warning
  counts `303 / 1873 / 1875` and scalar port counts `304 input / 1900 output`;
- corrected top-stat parser replayed against T4I `synth_stat.txt`: selected
  `NpcTop area=1622701.08`, `sequential_area=445478.88`, reported `27.45%`
  (derived `27.452923%`).

The final implementation owner must still run `run-fresh-synthesis.sh` followed
by `run-global-opensta.sh` after the RTL and functional evidence are frozen.

# Dispatch Log

## graph

- `node_id`: recall
  - `owner_agent`: codex
  - `status`: done
  - `evidence`: live docs and current gate script inspected
- `node_id`: run-systemctl-lite-default-heavy
  - `owner_agent`: nemu
  - `status`: done
  - `evidence`: `evidence/python-int-systemctl-lite-default/python-int-preflight-summary.tsv`

## events

- 2026-06-16: created NEMU-only systemctl-lite PyLong staged gate runner.
- 2026-06-16: first runner attempt aborted before analysis because relative `NEMU_PYTHON_INT_CHECK_LOG_DIR` was interpreted under `Linux/` by `make -C Linux`; fixed runner to pass absolute log/overlay paths and removed the mistaken temporary `Linux/.github/...` output.
- 2026-06-16: rerun PASS; `boot_seconds=75`, `total_seconds=204`, `stage_count=8`, all `stage_rc.*=0`, runtime fast paths all enabled.

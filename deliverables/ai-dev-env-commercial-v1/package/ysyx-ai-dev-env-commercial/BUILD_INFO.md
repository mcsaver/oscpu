# Build Info

- package_root: deliverables/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial
- generated_by: scripts/package-ai-dev-env.sh
- generated_at: reproducible

## Validation

Run from the source workspace before shipping:

```bash
python3 scripts/github_index_db.py delivery-audit
scripts/agent-maintain.sh --mode check
```

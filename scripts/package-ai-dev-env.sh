#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DELIVERY_ROOT="$REPO_ROOT/deliverables/ai-dev-env-commercial-v1"
DIST_ROOT="$REPO_ROOT/dist/ai-dev-env-commercial-v1"
PACKAGE_ROOT="$DIST_ROOT/package/ysyx-ai-dev-env-commercial"
GENERATED_AT="${AI_DEV_ENV_PACKAGE_GENERATED_AT:-reproducible}"

case "$PACKAGE_ROOT" in
  "$REPO_ROOT"/dist/ai-dev-env-commercial-v1/package/*) ;;
  *)
    echo "refuse package root outside dist directory: $PACKAGE_ROOT" >&2
    exit 2
    ;;
esac

rm -rf "$PACKAGE_ROOT"
mkdir -p "$PACKAGE_ROOT"

copy_file() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$PACKAGE_ROOT/$dst")"
  cp -a "$REPO_ROOT/$src" "$PACKAGE_ROOT/$dst"
}

copy_dir() {
  local src=$1 dst=$2
  rm -rf "$PACKAGE_ROOT/$dst"
  mkdir -p "$PACKAGE_ROOT/$dst"
  cp -a "$REPO_ROOT/$src"/. "$PACKAGE_ROOT/$dst"/
}

copy_file AGENTS.md AGENTS.md
copy_file AI_ENVIRONMENT.md AI_ENVIRONMENT.md
copy_file CLAUDE.md CLAUDE.md
copy_file GEMINI.md GEMINI.md
copy_file CONVENTIONS.md CONVENTIONS.md
copy_file .windsurfrules .windsurfrules
copy_file .cursor/rules/agents.mdc .cursor/rules/agents.mdc

copy_file .github/AGENTS.md .github/AGENTS.md
copy_file .github/copilot-instructions.md .github/copilot-instructions.md
copy_file .github/agentic-hardware-blueprint.md .github/agentic-hardware-blueprint.md
copy_dir .github/instructions .github/instructions
copy_file .github/e2e/README.md .github/e2e/README.md
copy_dir .github/agents .github/agents
copy_file .github/ai-env/README.md .github/ai-env/README.md
copy_dir .github/skills .github/skills
copy_dir .github/e2e/modules .github/e2e/modules
copy_dir .github/e2e/profiles .github/e2e/profiles
copy_dir .github/task-runs/templates .github/task-runs/templates
copy_file .github/agent-env-policy.json .github/agent-env-policy.json
copy_file .github/agent-env-schema-contract.json .github/agent-env-schema-contract.json
copy_file .github/agent-env-observability.json .github/agent-env-observability.json
copy_file .github/agent-env-runtime-artifacts.json .github/agent-env-runtime-artifacts.json
copy_file .github/agent-env-state-traceability.json .github/agent-env-state-traceability.json
copy_file .github/agent-env-review-routing.json .github/agent-env-review-routing.json
copy_file .github/agent-env-branch-health.json .github/agent-env-branch-health.json
copy_file .github/agent-env-rebuild-matrix.json .github/agent-env-rebuild-matrix.json
copy_file .github/agent-env-delivery.json .github/agent-env-delivery.json
copy_file .github/ai-env/contracts/agent-env-policy.json .github/ai-env/contracts/agent-env-policy.json
copy_file .github/ai-env/contracts/agent-env-schema-contract.json .github/ai-env/contracts/agent-env-schema-contract.json
copy_file .github/ai-env/contracts/agent-env-observability.json .github/ai-env/contracts/agent-env-observability.json
copy_file .github/ai-env/contracts/agent-env-runtime-artifacts.json .github/ai-env/contracts/agent-env-runtime-artifacts.json
copy_file .github/ai-env/contracts/agent-env-state-traceability.json .github/ai-env/contracts/agent-env-state-traceability.json
copy_file .github/ai-env/contracts/agent-env-review-routing.json .github/ai-env/contracts/agent-env-review-routing.json
copy_file .github/ai-env/contracts/agent-env-branch-health.json .github/ai-env/contracts/agent-env-branch-health.json
copy_file .github/ai-env/contracts/agent-env-rebuild-matrix.json .github/ai-env/contracts/agent-env-rebuild-matrix.json
copy_file .github/ai-env/contracts/agent-env-delivery.json .github/ai-env/contracts/agent-env-delivery.json
copy_file .github/ai-env/contracts/agent-env-rtl-task-contract.json .github/ai-env/contracts/agent-env-rtl-task-contract.json

copy_file scripts/github_index_db.py scripts/github_index_db.py
copy_file scripts/README.md scripts/README.md
copy_file scripts/agent-env.sh scripts/agent-env.sh
copy_file scripts/agent-run.sh scripts/agent-run.sh
copy_file scripts/agent-flow.c scripts/agent-flow.c
copy_file scripts/agent-flow.sh scripts/agent-flow.sh
copy_file scripts/agent-e2e.sh scripts/agent-e2e.sh
copy_file scripts/agent-maintain.sh scripts/agent-maintain.sh
copy_file scripts/task-run-status.sh scripts/task-run-status.sh
copy_dir scripts/tests scripts/tests
copy_dir scripts/dev_memory scripts/dev_memory
copy_dir scripts/e2e scripts/e2e

copy_file deliverables/ai-dev-env-commercial-v1/README.md README.md
copy_file deliverables/ai-dev-env-commercial-v1/PACKAGING_MANIFEST.md PACKAGING_MANIFEST.md
copy_file deliverables/ai-dev-env-commercial-v1/COMMERCIAL_READINESS.md COMMERCIAL_READINESS.md
copy_dir deliverables/ai-dev-env-commercial-v1/docs docs
copy_dir deliverables/ai-dev-env-commercial-v1/templates templates

cat > "$PACKAGE_ROOT/BUILD_INFO.md" <<EOF
# Build Info

- package_root: dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial
- generated_by: scripts/package-ai-dev-env.sh
- generated_at: $GENERATED_AT

## Validation

Run from the source workspace before shipping:

\`\`\`bash
scripts/agent-maintain.sh --mode release
\`\`\`
EOF

sanitize_package_text() {
  local file
  while IFS= read -r -d '' file; do
    sed -i \
      -e "s#${REPO_ROOT}#<repo-root>#g" \
      -e 's#ysyx_[0-9]\{8\}#<ysyx-id>#g' \
      "$file"
  done < <(
    find "$PACKAGE_ROOT" -type f \
      \( -name '*.md' -o -name '*.txt' -o -name '*.sh' -o -name '*.py' -o -name '*.json' -o -name '*.tsv' -o -name '*.yml' -o -name '*.yaml' \) \
      -print0
  )
}

find "$PACKAGE_ROOT" -type d \( -name __pycache__ -o -name .pytest_cache \) -prune -exec rm -rf {} +
find "$PACKAGE_ROOT" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete
sanitize_package_text
(cd "$PACKAGE_ROOT" && find . -type f | sed 's#^\./##' | sort > PACKAGE_FILELIST.txt)
echo "PASS package-ai-dev-env package_root=${PACKAGE_ROOT#$REPO_ROOT/} files=$(wc -l < "$PACKAGE_ROOT/PACKAGE_FILELIST.txt")"

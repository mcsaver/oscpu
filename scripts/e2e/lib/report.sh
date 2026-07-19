#!/usr/bin/env bash

# task-run 记录层：所有 e2e profile 都通过这里生成统一证据包。

e2e_validate_run_dir() {
  local task_root task_root_real run_real
  [[ -n ${E2E_RUN_DIR:-} ]] || return 1
  task_root="$E2E_ROOT_DIR/.github/task-runs"
  task_root_real=$(realpath -e -- "$task_root" 2>/dev/null) || return 1
  run_real=$(realpath -e -- "$E2E_RUN_DIR" 2>/dev/null) || return 1
  [[ $E2E_RUN_DIR = "$run_real" && -d $E2E_RUN_DIR && ! -L $E2E_RUN_DIR ]] || return 1
  case "$run_real" in
    "$task_root_real"/*) return 0 ;;
    *) return 1 ;;
  esac
}

e2e_allocate_run_dir() {
  local date_stamp base candidate idx task_root task_root_real requested parent parent_real first_entry artifact
  date_stamp=$(date '+%Y-%m-%d')
  task_root="$E2E_ROOT_DIR/.github/task-runs"
  mkdir -p -- "$task_root" || return 1
  task_root_real=$(realpath -e -- "$task_root") || return 1

  if [[ -z ${E2E_RUN_DIR:-} ]]; then
    base="$task_root_real/${date_stamp}-${E2E_TASK_SLUG}"
    candidate=$base
    idx=2
    while [[ -e $candidate || -L $candidate ]]; do
      candidate="${base}-${idx}"
      idx=$((idx + 1))
    done
    E2E_RUN_DIR=$candidate
  else
    requested=$(e2e_abspath_from_root "$E2E_RUN_DIR")
    [[ $requested = "$(realpath -m -- "$requested")" ]] || return 1
    case "$requested" in
      "$task_root_real"/*) ;;
      *) return 1 ;;
    esac
    if [[ -e $requested || -L $requested ]]; then
      [[ -d $requested && ! -L $requested ]] || return 1
      [[ $requested = "$(realpath -e -- "$requested")" ]] || return 1
      first_entry=$(find "$requested" -mindepth 1 -maxdepth 1 -print -quit) || return 1
      [[ -z $first_entry ]] || return 1
    else
      parent=$(dirname -- "$requested")
      parent_real=$(realpath -e -- "$parent" 2>/dev/null) || return 1
      [[ $parent = "$parent_real" ]] || return 1
      case "$parent_real" in
        "$task_root_real"|"$task_root_real"/*) ;;
        *) return 1 ;;
      esac
    fi
    E2E_RUN_DIR=$requested
  fi

  E2E_EVIDENCE_DIR="$E2E_RUN_DIR/evidence"
  E2E_REPORT_FILE="$E2E_RUN_DIR/task-report.md"
  E2E_DISPATCH_FILE="$E2E_RUN_DIR/dispatch-log.md"
  E2E_CONTEXT_BRIEF_FILE="$E2E_RUN_DIR/context-brief.md"
  E2E_PROFILE_RESOLVE_FILE="$E2E_RUN_DIR/profile-resolve.md"
  E2E_EVIDENCE_INDEX_FILE="$E2E_RUN_DIR/evidence-index.md"
  E2E_RUN_MANIFEST_FILE="$E2E_RUN_DIR/run-manifest.json"
  E2E_COMPLETE_MARKER_FILE="$E2E_RUN_DIR/complete.marker"
  E2E_PUBLICATION_FILE="$E2E_RUN_DIR/completion-publication.md"
  E2E_NODES_FILE="$E2E_RUN_DIR/nodes.tsv"
  if [[ ! -e $E2E_RUN_DIR && ! -L $E2E_RUN_DIR ]]; then
    mkdir -- "$E2E_RUN_DIR" || return 1
  fi
  e2e_validate_run_dir || return 1
  for artifact in \
      "$E2E_EVIDENCE_DIR" \
      "$E2E_REPORT_FILE" \
      "$E2E_DISPATCH_FILE" \
      "$E2E_CONTEXT_BRIEF_FILE" \
      "$E2E_PROFILE_RESOLVE_FILE" \
      "$E2E_EVIDENCE_INDEX_FILE" \
      "$E2E_RUN_MANIFEST_FILE" \
      "$E2E_COMPLETE_MARKER_FILE" \
      "$E2E_PUBLICATION_FILE" \
      "$E2E_NODES_FILE"; do
    [[ ! -e $artifact && ! -L $artifact ]] || return 1
  done
  mkdir -- "$E2E_EVIDENCE_DIR" || return 1
  : > "$E2E_NODES_FILE"
}

e2e_sanitize_task_run_text_artifacts() {
  local file list_file last_line
  e2e_validate_run_dir || return 1

  # 统一清理 e2e 证据包中的行尾空白、CR 和文件尾空行，避免生成物过不了 git diff --check。
  list_file=$(mktemp "$E2E_RUN_DIR/.sanitize-files.XXXXXX") || return 1
  if ! find "$E2E_RUN_DIR" -type f \
      \( -name '*.md' -o -name '*.tsv' -o -name '*.log' -o -name '*.cmd' -o -name '*.txt' \) \
      -print0 > "$list_file"; then
    rm -f -- "$list_file"
    return 1
  fi
  while IFS= read -r -d '' file; do
    LC_ALL=C sed -i 's/[ \t\r]*$//' "$file" || { rm -f -- "$list_file"; return 1; }
    while [[ -s $file ]]; do
      last_line=$(tail -n 1 "$file") || { rm -f -- "$list_file"; return 1; }
      [[ -z $last_line ]] || break
      sed -i '$d' "$file" || { rm -f -- "$list_file"; return 1; }
    done
  done < "$list_file"
  rm -f -- "$list_file" || return 1
}

e2e_render_run_manifest() {
  local status=$1 final_result=$2 updated=$3
  [[ -n ${E2E_RUN_DIR:-} && -d $E2E_RUN_DIR ]] || return 1

  python3 - "$E2E_ROOT_DIR" "$E2E_RUN_DIR" "$E2E_PROFILE" "$E2E_TASK_SLUG" "$status" "$final_result" "$E2E_STARTED_AT" "$updated" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
run_dir = Path(sys.argv[2]).resolve()
profile = sys.argv[3]
task_slug = sys.argv[4]
status = sys.argv[5]
final_result = sys.argv[6]
started_at = sys.argv[7]
updated_at = sys.argv[8]
run_id = run_dir.name

def rel(path: Path) -> str:
    return path.resolve().relative_to(repo_root).as_posix()

def git_out(*args: str) -> str:
    proc = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    return proc.stdout.strip() if proc.returncode == 0 else ""

nodes_path = run_dir / "nodes.tsv"
nodes = []
by_status = {}
if nodes_path.exists():
    for raw in nodes_path.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        parts = raw.split("\t")
        while len(parts) < 9:
            parts.append("")
        node = {
            "node_id": parts[0],
            "owner_agent": parts[1],
            "module": parts[2],
            "status": parts[3],
            "inputs": parts[4],
            "outputs": parts[5],
            "evidence": parts[6],
            "source_profile": parts[7],
            "function": parts[8],
        }
        nodes.append(node)
        by_status[node["status"]] = by_status.get(node["status"], 0) + 1

evidence_by_kind = {}
total_size = 0
asset_count = 0
evidence_dir = run_dir / "evidence"
if evidence_dir.exists():
    for path in sorted(p for p in evidence_dir.rglob("*") if p.is_file()):
        kind = path.suffix.lower().lstrip(".") or "file"
        evidence_by_kind[kind] = evidence_by_kind.get(kind, 0) + 1
        total_size += path.stat().st_size
        asset_count += 1

manifest = {
    "schema_version": 1,
    "trace_id": f"e2e:{run_id}",
    "run_id": run_id,
    "task_slug": task_slug,
    "profile": profile,
    "graph_template": "modular-agent-e2e",
    "graph_mode": "static",
    "publication_contract": "db-marker-v1",
    "status": status,
    "started_at": started_at,
    "updated_at": updated_at,
    "final_result": final_result,
    "state_traceback": {
        "state_sequence": [
            "recall_context",
            "classify_layer",
            "plan_graph",
            "implement",
            "verify",
            "inspect",
            "persist",
        ],
        "current_state": "persist" if status == "completed" else "verify",
        "failure_state": "" if status == "completed" else "verify",
        "rollback_target": "" if status == "completed" else "implement",
        "failure_reason": "" if status == "completed" else final_result,
        "reviewer": "ysyx-coordinator",
        "inspector": "agent-system",
        "evidence_policy": "task-report + dispatch-log + run-manifest + evidence-index",
    },
    "git": {
        "branch": git_out("rev-parse", "--abbrev-ref", "HEAD") or "<unknown>",
        "head": git_out("rev-parse", "--short", "HEAD") or "<unknown>",
        "upstream": git_out("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}") or "<none>",
    },
    "artifacts": {
        "run_dir": rel(run_dir),
        "task_report": rel(run_dir / "task-report.md"),
        "dispatch_log": rel(run_dir / "dispatch-log.md"),
        "context_brief": rel(run_dir / "context-brief.md"),
        "profile_resolve": rel(run_dir / "profile-resolve.md"),
        "evidence_index": rel(run_dir / "evidence-index.md"),
        "nodes": rel(nodes_path),
        "evidence_dir": rel(run_dir / "evidence"),
        "run_manifest": rel(run_dir / "run-manifest.json"),
    },
    "node_counts": {
        "total": len(nodes),
        "by_status": dict(sorted(by_status.items())),
    },
    "nodes": nodes,
    "evidence": {
        "asset_count": asset_count,
        "by_kind": dict(sorted(evidence_by_kind.items())),
        "total_size_bytes": total_size,
    },
    "db": {
        "markdown_archive": True,
        "raw_evidence_index_only": True,
    },
}

(run_dir / "run-manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
}

e2e_archive_task_run_markdown_to_db() {
  [[ ${E2E_ARCHIVE_TASK_RUN_MARKDOWN_TO_DB:-1} = 1 ]] || return 1
  [[ -n ${E2E_RUN_DIR:-} && -d $E2E_RUN_DIR ]] || return 1
  [[ -f "$E2E_ROOT_DIR/scripts/github_index_db.py" ]] || return 1

  local run_rel backup_dir db_path
  run_rel=$(e2e_relpath "$E2E_RUN_DIR")
  backup_dir=${E2E_TASK_RUN_DB_BACKUP_DIR:-.github/db-backup/task-runs}
  db_path=${E2E_GITHUB_INDEX_DB:-.github/cache/github-index.sqlite}
  if ! python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown "$run_rel" \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$db_path" \
      --backup-dir "$backup_dir" \
      --sync-task-run \
      --yes >/dev/null; then
    printf '[e2e] WARN task-run Markdown archive failed for %s\n' "$run_rel" >&2
    return 1
  fi
}

e2e_archive_task_run_publication_to_db() {
  [[ ${E2E_ARCHIVE_TASK_RUN_MARKDOWN_TO_DB:-1} = 1 ]] || return 1
  [[ -f ${E2E_PUBLICATION_FILE:-} && ! -L ${E2E_PUBLICATION_FILE:-} ]] || return 1
  local run_rel db_path
  e2e_validate_task_run_bundle "$E2E_RUN_DIR" "$E2E_PROFILE" || return 1
  e2e_validate_evidence_index "$E2E_ROOT_DIR" "$E2E_RUN_DIR" "$E2E_PROFILE" || return 1
  e2e_validate_completion_marker "$E2E_RUN_DIR" "$E2E_PROFILE" || return 1
  e2e_validate_completion_publication "$E2E_RUN_DIR" "$E2E_PROFILE" "$E2E_PUBLICATION_FILE" || return 1
  run_rel=$(e2e_relpath "$E2E_RUN_DIR")
  db_path=${E2E_GITHUB_INDEX_DB:-.github/cache/github-index.sqlite}
  if ! python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" publish-task-run "$run_rel" \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$db_path" \
      --yes >/dev/null; then
    printf '[e2e] WARN task-run completion publication failed for %s\n' "$run_rel" >&2
    return 1
  fi
}

e2e_index_task_run_evidence_assets() {
  [[ ${E2E_INDEX_TASK_RUN_EVIDENCE_ASSETS:-1} = 1 ]] || return 1
  [[ -n ${E2E_RUN_DIR:-} && -d $E2E_RUN_DIR ]] || return 1
  [[ -f "$E2E_ROOT_DIR/scripts/github_index_db.py" ]] || return 1

  local run_rel backup_dir db_path
  run_rel=$(e2e_relpath "$E2E_RUN_DIR")
  backup_dir=${E2E_TASK_RUN_DB_BACKUP_DIR:-.github/db-backup/task-runs}
  db_path=${E2E_GITHUB_INDEX_DB:-.github/cache/github-index.sqlite}
  if ! python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence "$run_rel" \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$db_path" \
      --write-index \
      --backup-dir "$backup_dir" \
      --yes >/dev/null; then
    printf '[e2e] WARN task-run evidence asset index failed for %s\n' "$run_rel" >&2
    return 1
  fi
}

e2e_validate_task_run_db_archive() {
  local repo_root=$1 run_dir=$2 db_path=${3:-.github/cache/github-index.sqlite} expected_state=${4:-published}
  python3 - "$repo_root" "$run_dir" "$db_path" "$expected_state" <<'PY'
import hashlib
import json
import re
import sqlite3
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
run_dir = Path(sys.argv[2]).resolve()
db_path = Path(sys.argv[3])
expected_state = sys.argv[4]
if expected_state not in {"staged", "published"}:
    raise SystemExit(2)
if not db_path.is_absolute():
    db_path = repo_root / db_path
try:
    run_rel = run_dir.relative_to(repo_root).as_posix()
    publication_path = run_dir / "completion-publication.md"
    if expected_state == "staged" and (publication_path.exists() or publication_path.is_symlink()):
        raise ValueError("staged run unexpectedly has a publication record")
    if expected_state == "published" and (publication_path.is_symlink() or not publication_path.is_file()):
        raise ValueError("published run lacks an ordinary publication record")
    live: dict[str, str] = {}
    for path in sorted(run_dir.rglob("*.md")):
        relative = path.relative_to(run_dir)
        if relative.parts and relative.parts[0] == "evidence":
            continue
        if path.is_symlink() or not path.is_file():
            raise ValueError("non-ordinary retained Markdown")
        rel_path = f"{run_rel}/{relative.as_posix()}"
        live[rel_path] = path.read_text(encoding="utf-8")
    required_names = {
        "task-report.md",
        "context-brief.md",
        "profile-resolve.md",
        "evidence-index.md",
        "dispatch-log.md",
    }
    if not required_names.issubset({Path(path).name for path in live}):
        raise ValueError("required retained Markdown is incomplete")
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    try:
        prefix = run_rel + "/"
        rows = conn.execute(
            "SELECT path, content FROM db_documents WHERE substr(path, 1, ?) = ? ORDER BY path",
            (len(prefix), prefix),
        ).fetchall()
        stored = {str(path): str(content) for path, content in rows if str(path).endswith(".md")}
        if stored != live:
            raise ValueError("DB/live retained Markdown set or content mismatch")
    finally:
        conn.close()
    if expected_state == "published":
        marker_path = run_dir / "complete.marker"
        manifest_path = run_dir / "run-manifest.json"
        if marker_path.is_symlink() or not marker_path.is_file() or manifest_path.is_symlink() or not manifest_path.is_file():
            raise ValueError("published run marker/manifest is not ordinary")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        marker_fields: dict[str, str] = {}
        for line in marker_path.read_text(encoding="utf-8").splitlines():
            key, separator, value = line.partition("=")
            if separator != "=" or not key or key in marker_fields:
                raise ValueError("invalid marker")
            marker_fields[key] = value
        publication_lines = publication_path.read_text(encoding="utf-8").splitlines()
        if publication_lines[:4] != ["# Task Run Publication", "", "## 基本信息", ""]:
            raise ValueError("invalid publication heading")
        publication_fields: dict[str, str] = {}
        field_re = re.compile(r"^- `([A-Za-z0-9_.-]+)`:\s*(.*?)\s*$")
        for line in publication_lines[4:]:
            match = field_re.fullmatch(line)
            if match is None or match.group(1) in publication_fields:
                raise ValueError("invalid publication field")
            publication_fields[match.group(1)] = match.group(2)
        expected = {
            "task_id": run_dir.name,
            "trace_id": f"e2e:{run_dir.name}",
            "task_slug": str(manifest.get("task_slug", "")),
            "profile": str(manifest.get("profile", "")),
            "status": "completed",
            "publication_contract": "db-marker-v1",
            "marker_sha256": hashlib.sha256(marker_path.read_bytes()).hexdigest(),
        }
        for key, value in marker_fields.items():
            if key not in {"status", "profile"}:
                expected[key] = value
        if publication_fields != expected:
            raise ValueError("publication/marker/manifest binding mismatch")
except (OSError, sqlite3.Error, UnicodeError, ValueError):
    raise SystemExit(1)
PY
}

e2e_validate_recall_header() {
  local artifact_kind=$1 artifact_path=$2 expected_profile=$3 expected_node_count=${4:-}
  python3 - "$artifact_kind" "$artifact_path" "$expected_profile" "$expected_node_count" <<'PY'
import re
import sys
from pathlib import Path

artifact_kind, raw_path, expected_profile, expected_node_count = sys.argv[1:]
specs = {
    "context": (
        "# Agent Brief",
        {"ok": "true", "recall_status": "complete", "profile": expected_profile},
    ),
    "resolve": (
        "# E2E Resolved Profile",
        {"ok": "True", "profile": expected_profile},
    ),
}
if artifact_kind not in specs:
    raise SystemExit(2)

path = Path(raw_path)
if path.is_symlink() or not path.is_file():
    raise SystemExit(1)
try:
    lines = path.read_text(encoding="utf-8").splitlines()
except (OSError, UnicodeError):
    raise SystemExit(1)

heading, expected = specs[artifact_kind]
if len(lines) < 3 or lines[0] != heading or lines[1] != "":
    raise SystemExit(1)
field_re = re.compile(r"^- `([A-Za-z0-9_.-]+)`:\s*(.*?)\s*$")
fields: dict[str, list[str]] = {}
index = 2
while index < len(lines) and lines[index] != "":
    match = field_re.fullmatch(lines[index])
    if match is None:
        raise SystemExit(1)
    fields.setdefault(match.group(1), []).append(match.group(2))
    index += 1
if index == 2 or any(len(values) != 1 for values in fields.values()):
    raise SystemExit(1)
if any(fields.get(name) != [value] for name, value in expected.items()):
    raise SystemExit(1)

if artifact_kind == "context":
    if (
        fields.get("source") != ["live-or-stored"]
        or fields.get("focus_scope") != ["non-history"]
        or not fields.get("terms")
    ):
        raise SystemExit(1)
    budget_match = re.fullmatch(r"([0-9]+)\s*/\s*([0-9]+)", fields.get("token_estimate", [""])[0])
    if budget_match is None:
        raise SystemExit(1)
    used, budget = map(int, budget_match.groups())
    if used <= 0 or budget <= 0 or used > budget:
        raise SystemExit(1)
    try:
        chunks_index = lines.index("## Chunks")
    except ValueError:
        raise SystemExit(1)
    chunk_heading_re = re.compile(r"^### (.+#chunk-[0-9]+)$")
    chunk_starts = [
        (line_index, match.group(1))
        for line_index, line in enumerate(lines[chunks_index + 1:], start=chunks_index + 1)
        if (match := chunk_heading_re.fullmatch(line)) is not None
    ]
    chunk_headings = [heading for _, heading in chunk_starts]
    canonical_prefix = ".github/AGENTS.md#"
    profile_prefix = f".github/e2e/profiles/{expected_profile}.tsv#"
    if len(chunk_headings) < 3 or len(set(chunk_headings)) != len(chunk_headings):
        raise SystemExit(1)
    if not chunk_headings[0].startswith(canonical_prefix) or not chunk_headings[1].startswith(profile_prefix):
        raise SystemExit(1)
    if not any(
        not chunk.startswith(canonical_prefix) and not chunk.startswith(profile_prefix)
        for chunk in chunk_headings[2:]
    ):
        raise SystemExit(1)
    required_chunk_fields = {"kind", "lines", "tokens", "heading", "summary"}
    history_kinds = {"task-report", "dispatch-log", "task-run", "task-evidence"}
    for chunk_index, (start, chunk_heading) in enumerate(chunk_starts):
        end = chunk_starts[chunk_index + 1][0] if chunk_index + 1 < len(chunk_starts) else len(lines)
        body = lines[start + 1:end]
        if not body or body[0] != "":
            raise SystemExit(1)
        metadata: dict[str, str] = {}
        body_index = 1
        while body_index < len(body) and body[body_index] != "":
            match = field_re.fullmatch(body[body_index])
            if match is None or match.group(1) in metadata:
                raise SystemExit(1)
            metadata[match.group(1)] = match.group(2)
            body_index += 1
        if set(metadata) != required_chunk_fields or any(not value for value in metadata.values()):
            raise SystemExit(1)
        if chunk_index == 2 and (
            chunk_heading.startswith(".github/task-runs/")
            or metadata["kind"] in history_kinds
        ):
            raise SystemExit(1)
        if re.fullmatch(r"[0-9]+-[0-9]+", metadata["lines"]) is None:
            raise SystemExit(1)
        if re.fullmatch(r"[1-9][0-9]*", metadata["tokens"]) is None:
            raise SystemExit(1)
        if body_index >= len(body) or not any(line.strip() for line in body[body_index + 1:]):
            raise SystemExit(1)
else:
    required_fields = {
        "source": "live-or-stored",
        "command": f"scripts/agent-e2e.sh --profile {expected_profile}",
        "validate_command": f"scripts/agent-e2e.sh --validate-profile --profile {expected_profile}",
    }
    if any(fields.get(name) != [value] for name, value in required_fields.items()):
        raise SystemExit(1)
    try:
        expanded = int(fields.get("expanded_node_count", [""])[0])
    except (ValueError, TypeError):
        raise SystemExit(1)
    if expanded <= 0:
        raise SystemExit(1)
    if expected_node_count and expanded != int(expected_node_count):
        raise SystemExit(1)
    profile_order = [part.strip() for part in fields.get("profile_order", [""])[0].split(",")]
    if not profile_order or profile_order[0] != expected_profile or len(set(profile_order)) != len(profile_order):
        raise SystemExit(1)
    if not fields.get("modules") or not fields.get("owners"):
        raise SystemExit(1)
    try:
        nodes_index = lines.index("## Nodes")
    except ValueError:
        raise SystemExit(1)
    node_re = re.compile(
        r"^([0-9]+)\. `([^`]+)` source=`([^`]+)` module=`([^`]+)` "
        r"owner=`([^`]+)` function=`([^`]+)`$"
    )
    node_matches = []
    for line in lines[nodes_index + 1:]:
        if not line:
            continue
        match = node_re.fullmatch(line)
        if match is None:
            raise SystemExit(1)
        node_matches.append(match.groups())
    node_numbers = [int(item[0]) for item in node_matches]
    node_ids = [item[1] for item in node_matches]
    node_sources = [item[2] for item in node_matches]
    node_modules = [item[3] for item in node_matches]
    node_owners = [item[4] for item in node_matches]
    if len(node_matches) != expanded or node_numbers != list(range(1, expanded + 1)):
        raise SystemExit(1)
    if len(set(node_ids)) != expanded:
        raise SystemExit(1)
    if not set(node_sources).issubset(set(profile_order)):
        raise SystemExit(1)
    header_modules = {part.strip() for part in fields["modules"][0].split(",") if part.strip()}
    header_owners = {part.strip() for part in fields["owners"][0].split(",") if part.strip()}
    if header_modules != set(node_modules) or header_owners != set(node_owners):
        raise SystemExit(1)
PY
}

e2e_validate_evidence_index() {
  local repo_root=$1 run_dir=$2 expected_profile=$3
  python3 - "$repo_root" "$run_dir" "$expected_profile" <<'PY'
import hashlib
import os
import re
import stat
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
run_dir = Path(sys.argv[2]).resolve()
expected_profile = sys.argv[3]
index_path = run_dir / "evidence-index.md"
evidence_dir = run_dir / "evidence"
if index_path.is_symlink() or not index_path.is_file() or evidence_dir.is_symlink() or not evidence_dir.is_dir():
    raise SystemExit(1)
try:
    lines = index_path.read_text(encoding="utf-8").splitlines()
except (OSError, UnicodeError):
    raise SystemExit(1)
if len(lines) < 7 or lines[:4] != ["# Evidence Index", "", "## 基本信息", ""]:
    raise SystemExit(1)

field_re = re.compile(r"^- `([A-Za-z0-9_.-]+)`:\s*(.*?)\s*$")
header: dict[str, str] = {}
index = 4
while index < len(lines) and lines[index] != "":
    match = field_re.fullmatch(lines[index])
    if match is None or match.group(1) in header:
        raise SystemExit(1)
    header[match.group(1)] = match.group(2)
    index += 1
try:
    asset_count = int(header.get("asset_count", ""))
    total_size = int(header.get("total_size_bytes", ""))
except ValueError:
    raise SystemExit(1)
if header.get("task_id") != run_dir.name or header.get("profile") != expected_profile:
    raise SystemExit(1)
if not header.get("task_slug") or asset_count <= 0 or total_size < 0:
    raise SystemExit(1)
try:
    assets_heading = lines.index("## 证据资产", index)
except ValueError:
    raise SystemExit(1)

sections: list[tuple[str, dict[str, str]]] = []
cursor = assets_heading + 1
while cursor < len(lines):
    if not lines[cursor].startswith("### "):
        cursor += 1
        continue
    asset_name = lines[cursor][4:]
    cursor += 1
    fields: dict[str, str] = {}
    while cursor < len(lines) and not lines[cursor].startswith("### "):
        match = field_re.fullmatch(lines[cursor])
        if match:
            if match.group(1) in fields:
                raise SystemExit(1)
            fields[match.group(1)] = match.group(2)
        cursor += 1
    sections.append((asset_name, fields))
if len(sections) != asset_count:
    raise SystemExit(1)

indexed: set[Path] = set()
indexed_size = 0
for asset_name, fields in sections:
    relative = Path(asset_name)
    if relative.is_absolute() or ".." in relative.parts:
        raise SystemExit(1)
    absolute = repo_root / relative
    try:
        resolved = absolute.resolve(strict=True)
        evidence_resolved = evidence_dir.resolve(strict=True)
        mode = os.lstat(absolute).st_mode
    except OSError:
        raise SystemExit(1)
    if not stat.S_ISREG(mode) or absolute.is_symlink():
        raise SystemExit(1)
    try:
        resolved.relative_to(evidence_resolved)
    except ValueError:
        raise SystemExit(1)
    if resolved in indexed:
        raise SystemExit(1)
    try:
        declared_size = int(fields.get("size_bytes", ""))
    except ValueError:
        raise SystemExit(1)
    digest = hashlib.sha256(resolved.read_bytes()).hexdigest()
    if declared_size != resolved.stat().st_size or fields.get("sha256") != digest:
        raise SystemExit(1)
    indexed.add(resolved)
    indexed_size += declared_size

actual: set[Path] = set()
for path in evidence_dir.rglob("*"):
    if path.is_symlink():
        raise SystemExit(1)
    if path.is_file():
        actual.add(path.resolve(strict=True))
if indexed != actual or indexed_size != total_size:
    raise SystemExit(1)
PY
}

e2e_write_completion_marker_for_dir() {
  local run_dir=$1 expected_profile=$2 marker temp artifact digest marker_write_rc=0
  local artifacts=(task-report.md run-manifest.json context-brief.md profile-resolve.md evidence-index.md dispatch-log.md nodes.tsv)
  marker="$run_dir/complete.marker"
  for artifact in "${artifacts[@]}"; do
    [[ -f $run_dir/$artifact && ! -L $run_dir/$artifact ]] || return 1
  done
  temp=$(mktemp "$run_dir/.complete-marker.XXXXXX") || return 1
  if ! {
    printf 'status=complete\n'
    printf 'profile=%s\n' "$expected_profile"
    for artifact in "${artifacts[@]}"; do
      if ! digest=$(sha256sum "$run_dir/$artifact" | awk '{print $1}'); then
        marker_write_rc=1
        break
      fi
      printf '%s_sha256=%s\n' "${artifact//[-.]/_}" "$digest"
    done
    [[ $marker_write_rc -eq 0 ]]
  } > "$temp"; then
    rm -f -- "$temp"
    return 1
  fi
  if ! mv -T -- "$temp" "$marker"; then
    rm -f -- "$temp"
    return 1
  fi
}

e2e_validate_completion_marker() {
  local run_dir=$1 expected_profile=$2
  python3 - "$run_dir" "$expected_profile" <<'PY'
import hashlib
import re
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
expected_profile = sys.argv[2]
marker = run_dir / "complete.marker"
artifacts = [
    "task-report.md",
    "run-manifest.json",
    "context-brief.md",
    "profile-resolve.md",
    "evidence-index.md",
    "dispatch-log.md",
    "nodes.tsv",
]
if marker.is_symlink() or not marker.is_file():
    raise SystemExit(1)
fields: dict[str, str] = {}
field_re = re.compile(r"^([a-z0-9_]+)=(.*?)$")
try:
    lines = marker.read_text(encoding="utf-8").splitlines()
except (OSError, UnicodeError):
    raise SystemExit(1)
for line in lines:
    match = field_re.fullmatch(line)
    if match is None or match.group(1) in fields:
        raise SystemExit(1)
    fields[match.group(1)] = match.group(2)
expected_keys = {"status", "profile"}
for artifact in artifacts:
    expected_keys.add(artifact.replace("-", "_").replace(".", "_") + "_sha256")
if set(fields) != expected_keys or fields.get("status") != "complete" or fields.get("profile") != expected_profile:
    raise SystemExit(1)
for artifact in artifacts:
    path = run_dir / artifact
    if path.is_symlink() or not path.is_file():
        raise SystemExit(1)
    key = artifact.replace("-", "_").replace(".", "_") + "_sha256"
    if fields[key] != hashlib.sha256(path.read_bytes()).hexdigest():
        raise SystemExit(1)
PY
}

e2e_write_completion_publication_for_dir() {
  local run_dir=$1 expected_profile=$2 publication
  publication=${3:-$run_dir/completion-publication.md}
  e2e_validate_completion_marker "$run_dir" "$expected_profile" || return 1
  python3 - "$run_dir" "$expected_profile" "$publication" <<'PY'
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path

run_dir = Path(sys.argv[1]).resolve()
expected_profile = sys.argv[2]
publication = Path(sys.argv[3])
marker = run_dir / "complete.marker"
manifest_path = run_dir / "run-manifest.json"
if publication.parent.resolve() != run_dir or publication.is_symlink():
    raise SystemExit(1)
try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    marker_fields: dict[str, str] = {}
    marker_lines = marker.read_text(encoding="utf-8").splitlines()
    for line in marker_lines:
        key, separator, value = line.partition("=")
        if separator != "=" or not key or key in marker_fields:
            raise ValueError("invalid marker")
        marker_fields[key] = value
    if marker_fields.get("status") != "complete" or marker_fields.get("profile") != expected_profile:
        raise ValueError("marker identity mismatch")
    if (
        manifest.get("run_id") != run_dir.name
        or manifest.get("trace_id") != f"e2e:{run_dir.name}"
        or manifest.get("profile") != expected_profile
        or manifest.get("status") != "completed"
        or manifest.get("publication_contract") != "db-marker-v1"
    ):
        raise ValueError("manifest is not publishable")
    fields = [
        ("task_id", run_dir.name),
        ("trace_id", f"e2e:{run_dir.name}"),
        ("task_slug", str(manifest.get("task_slug", ""))),
        ("profile", expected_profile),
        ("status", "completed"),
        ("publication_contract", "db-marker-v1"),
        ("marker_sha256", hashlib.sha256(marker.read_bytes()).hexdigest()),
    ]
    fields.extend((key, value) for key, value in marker_fields.items() if key not in {"status", "profile"})
    if not fields[2][1]:
        raise ValueError("task slug missing")
    content = "# Task Run Publication\n\n## 基本信息\n\n" + "".join(
        f"- `{key}`: {value}\n" for key, value in fields
    )
    fd, temp_name = tempfile.mkstemp(prefix=".completion-publication.", dir=run_dir)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, publication)
    except BaseException:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise
except (OSError, TypeError, UnicodeError, ValueError, json.JSONDecodeError):
    raise SystemExit(1)
PY
}

e2e_validate_completion_publication() {
  local run_dir=$1 expected_profile=$2 publication
  publication=${3:-$run_dir/completion-publication.md}
  e2e_validate_completion_marker "$run_dir" "$expected_profile" || return 1
  python3 - "$run_dir" "$expected_profile" "$publication" <<'PY'
import hashlib
import json
import re
import sys
from pathlib import Path

run_dir = Path(sys.argv[1]).resolve()
expected_profile = sys.argv[2]
publication = Path(sys.argv[3])
marker = run_dir / "complete.marker"
manifest_path = run_dir / "run-manifest.json"
try:
    if publication.is_symlink() or not publication.is_file() or marker.is_symlink() or not marker.is_file():
        raise ValueError("publication or marker is not ordinary")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    marker_fields: dict[str, str] = {}
    for line in marker.read_text(encoding="utf-8").splitlines():
        key, separator, value = line.partition("=")
        if separator != "=" or not key or key in marker_fields:
            raise ValueError("invalid marker")
        marker_fields[key] = value
    lines = publication.read_text(encoding="utf-8").splitlines()
    if lines[:4] != ["# Task Run Publication", "", "## 基本信息", ""]:
        raise ValueError("invalid publication heading")
    fields: dict[str, str] = {}
    field_re = re.compile(r"^- `([A-Za-z0-9_.-]+)`:\s*(.*?)\s*$")
    for line in lines[4:]:
        match = field_re.fullmatch(line)
        if match is None or match.group(1) in fields:
            raise ValueError("invalid publication field")
        fields[match.group(1)] = match.group(2)
    expected = {
        "task_id": run_dir.name,
        "trace_id": f"e2e:{run_dir.name}",
        "task_slug": str(manifest.get("task_slug", "")),
        "profile": expected_profile,
        "status": "completed",
        "publication_contract": "db-marker-v1",
        "marker_sha256": hashlib.sha256(marker.read_bytes()).hexdigest(),
    }
    for key, value in marker_fields.items():
        if key not in {"status", "profile"}:
            expected[key] = value
    if fields != expected:
        raise ValueError("publication binding mismatch")
except (OSError, TypeError, UnicodeError, ValueError, json.JSONDecodeError):
    raise SystemExit(1)
PY
}

e2e_validate_task_run_bundle() {
  local run_dir=$1 expected_profile=$2
  python3 - "$run_dir" "$expected_profile" <<'PY'
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

run_dir = Path(sys.argv[1]).resolve()
expected_profile = sys.argv[2]
run_id = run_dir.name
if len(run_dir.parents) < 3 or run_dir.parent.name != "task-runs" or run_dir.parent.parent.name != ".github":
    raise SystemExit(1)
repo_root = run_dir.parents[2]
run_rel = run_dir.relative_to(repo_root).as_posix()
field_re = re.compile(r"^- `([A-Za-z0-9_.-]+)`:\s*(.*?)\s*$")
node_re = re.compile(
    r"^([0-9]+)\. `([^`]+)` source=`([^`]+)` module=`([^`]+)` "
    r"owner=`([^`]+)` function=`([^`]+)`$"
)


def read_lines(name: str) -> list[str]:
    path = run_dir / name
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"missing ordinary artifact: {name}")
    return path.read_text(encoding="utf-8").splitlines()


def parse_header(lines: list[str], prefix: list[str]) -> dict[str, str]:
    if lines[: len(prefix)] != prefix:
        raise ValueError("noncanonical heading")
    fields: dict[str, str] = {}
    index = len(prefix)
    while index < len(lines) and lines[index] != "":
        match = field_re.fullmatch(lines[index])
        if match is None or match.group(1) in fields:
            raise ValueError("noncanonical or duplicate header field")
        fields[match.group(1)] = match.group(2).strip()
        index += 1
    return fields


def parse_time(raw: str) -> datetime:
    parsed = datetime.fromisoformat(raw)
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ValueError("timezone is required")
    parsed = parsed.astimezone(timezone.utc)
    if parsed.timestamp() > time.time() + 300:
        raise ValueError("implausibly future timestamp")
    return parsed


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def reject_constant(value: str) -> object:
    raise ValueError(f"non-standard JSON constant: {value}")


try:
    report_lines = read_lines("task-report.md")
    report = parse_header(report_lines, ["# 任务报告", "", "## 基本信息", ""])
    required_report = {
        "task_id": run_id,
        "trace_id": f"e2e:{run_id}",
        "graph_template": "modular-agent-e2e",
        "profile": expected_profile,
        "graph_mode": "static",
        "publication_contract": "db-marker-v1",
        "status": "completed",
    }
    if any(report.get(key) != value for key, value in required_report.items()):
        raise ValueError("report identity mismatch")
    task_slug = report.get("task_slug", "")
    started_at = report.get("started_at", "")
    updated_at = report.get("updated_at", "")
    started_dt = parse_time(started_at)
    updated_dt = parse_time(updated_at)
    if not task_slug or not started_at or not updated_at or started_dt > updated_dt:
        raise ValueError("invalid report task or time fields")

    manifest_path = run_dir / "run-manifest.json"
    if manifest_path.is_symlink() or not manifest_path.is_file():
        raise ValueError("missing ordinary manifest")
    manifest = json.loads(
        manifest_path.read_text(encoding="utf-8"),
        object_pairs_hook=unique_object,
        parse_constant=reject_constant,
    )
    if not isinstance(manifest, dict):
        raise ValueError("manifest must be an object")
    required_manifest = {
        "run_id": run_id,
        "trace_id": f"e2e:{run_id}",
        "task_slug": task_slug,
        "profile": expected_profile,
        "graph_template": "modular-agent-e2e",
        "graph_mode": "static",
        "publication_contract": "db-marker-v1",
        "status": "completed",
        "started_at": started_at,
        "updated_at": updated_at,
    }
    if any(manifest.get(key) != value for key, value in required_manifest.items()):
        raise ValueError("manifest/report identity or time mismatch")

    expected_artifacts = {
        "run_dir": run_rel,
        "task_report": f"{run_rel}/task-report.md",
        "dispatch_log": f"{run_rel}/dispatch-log.md",
        "context_brief": f"{run_rel}/context-brief.md",
        "profile_resolve": f"{run_rel}/profile-resolve.md",
        "evidence_index": f"{run_rel}/evidence-index.md",
        "nodes": f"{run_rel}/nodes.tsv",
        "evidence_dir": f"{run_rel}/evidence",
        "run_manifest": f"{run_rel}/run-manifest.json",
    }
    if manifest.get("artifacts") != expected_artifacts:
        raise ValueError("manifest artifact pointers are not canonical")
    if manifest.get("db") != {"markdown_archive": True, "raw_evidence_index_only": True}:
        raise ValueError("manifest DB policy mismatch")

    manifest_nodes = manifest.get("nodes")
    if not isinstance(manifest_nodes, list) or not manifest_nodes:
        raise ValueError("manifest node list missing")
    node_ids: list[str] = []
    node_full: list[tuple[str, str, str, str, str, str, str, str, str]] = []
    for node in manifest_nodes:
        if not isinstance(node, dict):
            raise ValueError("non-object manifest node")
        full = tuple(
            node.get(key)
            for key in (
                "node_id",
                "source_profile",
                "module",
                "owner_agent",
                "function",
                "status",
                "inputs",
                "outputs",
                "evidence",
            )
        )
        if (
            not all(isinstance(full[index], str) and full[index] for index in (0, 1, 2, 3, 4, 5, 8))
            or not all(isinstance(full[index], str) for index in (6, 7))
            or full[5] != "PASS"
        ):
            raise ValueError("completed bundle contains non-PASS or malformed node")
        node_ids.append(full[0])
        node_full.append(full)
    if len(set(node_ids)) != len(node_ids):
        raise ValueError("duplicate manifest node ID")
    node_counts = manifest.get("node_counts")
    if not isinstance(node_counts, dict) or node_counts != {
        "total": len(node_ids),
        "by_status": {"PASS": len(node_ids)},
    }:
        raise ValueError("manifest node counts mismatch")

    profile_root = repo_root / ".github" / "e2e" / "profiles"
    profile_name_re = re.compile(r"^[A-Za-z0-9_.-]+$")
    live_nodes: list[tuple[str, str, str, str, str, str, str, str]] = []

    def visit_live_profile(profile: str, stack: list[str]) -> None:
        if not profile_name_re.fullmatch(profile) or profile in stack or len(stack) >= 64:
            raise ValueError("invalid live profile include closure")
        path = profile_root / f"{profile}.tsv"
        if path.is_symlink() or not path.is_file():
            raise ValueError("missing ordinary live profile")
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            if not raw_line or raw_line.startswith("#"):
                continue
            parts = raw_line.split("|", 5)
            if len(parts) != 6:
                raise ValueError("malformed live profile row")
            node_id, module, function, owner, inputs, outputs = parts
            if node_id == "@include":
                if not module or any((function, owner, inputs, outputs)):
                    raise ValueError("malformed live profile include")
                visit_live_profile(module, [*stack, profile])
                continue
            if not all((node_id, module, function, owner)):
                raise ValueError("incomplete live profile node")
            live_nodes.append(
                (node_id, profile, module, owner, function, "PASS", inputs, outputs)
            )

    visit_live_profile(expected_profile, [])
    if [row[:8] for row in node_full] != live_nodes:
        raise ValueError("bundle node tuples do not match live profile closure")

    evidence_dir = run_dir / "evidence"
    if evidence_dir.is_symlink() or not evidence_dir.is_dir():
        raise ValueError("evidence directory is not ordinary")
    evidence_count = 0
    evidence_size = 0
    evidence_by_kind: dict[str, int] = {}
    evidence_assets: set[str] = set()
    for path in sorted(evidence_dir.rglob("*")):
        if path.is_symlink():
            raise ValueError("symlink evidence is not accepted")
        if not path.is_file():
            continue
        kind = path.suffix.lower().lstrip(".") or "file"
        evidence_count += 1
        evidence_size += path.stat().st_size
        evidence_by_kind[kind] = evidence_by_kind.get(kind, 0) + 1
        evidence_assets.add(path.relative_to(repo_root).as_posix())
    expected_evidence = {
        "asset_count": evidence_count,
        "by_kind": dict(sorted(evidence_by_kind.items())),
        "total_size_bytes": evidence_size,
    }
    if manifest.get("evidence") != expected_evidence:
        raise ValueError("manifest evidence summary mismatch")
    for row in node_full:
        node_evidence = [part.strip() for part in row[8].split(",")]
        canonical_node_evidence = f"{run_rel}/evidence/{row[0]}.log"
        if (
            not node_evidence
            or any(not pointer for pointer in node_evidence)
            or len(set(node_evidence)) != len(node_evidence)
            or node_evidence[0] != canonical_node_evidence
            or any(pointer not in evidence_assets for pointer in node_evidence)
        ):
            raise ValueError("node evidence does not bind its canonical indexed log")

    resolve_lines = read_lines("profile-resolve.md")
    resolve_fields = parse_header(resolve_lines, ["# E2E Resolved Profile", ""])
    if resolve_fields.get("profile") != expected_profile or resolve_fields.get("ok") != "True":
        raise ValueError("resolve identity mismatch")
    if int(resolve_fields.get("expanded_node_count", "")) != len(node_ids):
        raise ValueError("resolve node count mismatch")
    nodes_heading = resolve_lines.index("## Nodes")
    resolved_full: list[tuple[str, str, str, str, str]] = []
    resolved_numbers: list[int] = []
    for line in resolve_lines[nodes_heading + 1 :]:
        if not line:
            continue
        match = node_re.fullmatch(line)
        if match is None:
            raise ValueError("noncanonical resolve node")
        resolved_numbers.append(int(match.group(1)))
        resolved_full.append(
            (match.group(2), match.group(3), match.group(4), match.group(5), match.group(6))
        )
    expected_resolved = [(row[0], row[1], row[2], row[3], row[4]) for row in node_full]
    if resolved_numbers != list(range(1, len(node_ids) + 1)) or resolved_full != expected_resolved:
        raise ValueError("resolve/manifest full node tuple mismatch")

    nodes_lines = read_lines("nodes.tsv")
    tsv_full: list[tuple[str, str, str, str, str, str, str, str, str]] = []
    for line in nodes_lines:
        parts = line.split("\t")
        if len(parts) != 9:
            raise ValueError("noncanonical nodes.tsv row")
        tsv_full.append(
            (parts[0], parts[7], parts[2], parts[1], parts[8], parts[3], parts[4], parts[5], parts[6])
        )
    if tsv_full != node_full:
        raise ValueError("nodes.tsv/manifest full node tuple mismatch")

    try:
        table_heading = report_lines.index("## 节点概览")
    except ValueError as exc:
        raise ValueError("report node table missing") from exc
    report_full: list[tuple[str, str, str, str, str, str, str]] = []
    for line in report_lines[table_heading + 1 :]:
        if line.startswith("## "):
            break
        if not line.startswith("| `"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 7:
            raise ValueError("noncanonical report node row")
        code_values: list[str] = []
        for cell in cells[:4]:
            match = re.fullmatch(r"`([^`]*)`", cell)
            if match is None:
                raise ValueError("noncanonical report node code cell")
            code_values.append(match.group(1))
        report_full.append(tuple([*code_values, *cells[4:]]))
    expected_report = [
        (row[0], row[3], row[2], row[5], row[6], row[7], row[8])
        for row in node_full
    ]
    if report_full != expected_report:
        raise ValueError("report/manifest full node row mismatch")

    index_lines = read_lines("evidence-index.md")
    index_fields = parse_header(index_lines, ["# Evidence Index", "", "## 基本信息", ""])
    if any(
        index_fields.get(key) != value
        for key, value in {
            "task_id": run_id,
            "task_slug": task_slug,
            "profile": expected_profile,
        }.items()
    ):
        raise ValueError("evidence-index identity mismatch")
    if (
        int(index_fields.get("asset_count", "")) != evidence_count
        or int(index_fields.get("total_size_bytes", "")) != evidence_size
    ):
        raise ValueError("evidence-index/manifest evidence summary mismatch")

    dispatch_lines = read_lines("dispatch-log.md")
    dispatch = parse_header(dispatch_lines, ["# 派发日志", "", "## 基本信息", ""])
    required_dispatch = {
        "task_id": run_id,
        "trace_id": f"e2e:{run_id}",
        "task_slug": task_slug,
        "graph_template": "modular-agent-e2e",
        "profile": expected_profile,
        "log_policy": "append-only",
    }
    if any(dispatch.get(key) != value for key, value in required_dispatch.items()):
        raise ValueError("dispatch identity mismatch")
    event_re = re.compile(r"^### \[([^\]]+)\] `([^`]+)` - `([^`]+)`$")
    event_starts: list[tuple[int, re.Match[str]]] = []
    for line_index, line in enumerate(dispatch_lines):
        if line.startswith("### "):
            match = event_re.fullmatch(line)
            if match is None:
                raise ValueError("noncanonical dispatch event heading")
            event_starts.append((line_index, match))
    if not event_starts:
        raise ValueError("dispatch has no events")
    events: dict[str, list[tuple[str, dict[str, str]]]] = {}
    event_sequence: list[tuple[str, str]] = []
    previous_event_time: datetime | None = None
    required_event_fields = {
        "owner_agent",
        "module",
        "trigger",
        "depends_on",
        "inputs",
        "action",
        "outputs",
        "evidence",
        "handoff_to",
        "next_step",
        "notes",
    }
    allowed_statuses = {"in-progress", "PASS", "FAIL", "SKIP", "WARN"}
    for event_index, (start, match) in enumerate(event_starts):
        end = event_starts[event_index + 1][0] if event_index + 1 < len(event_starts) else len(dispatch_lines)
        event_time = parse_time(match.group(1))
        if event_time < started_dt or event_time > updated_dt:
            raise ValueError("dispatch event lies outside report time envelope")
        if previous_event_time is not None and event_time < previous_event_time:
            raise ValueError("dispatch event time moved backwards")
        previous_event_time = event_time
        node_id, status = match.group(2), match.group(3)
        if status not in allowed_statuses:
            raise ValueError("unknown dispatch status")
        event_fields: dict[str, str] = {}
        for line in dispatch_lines[start + 1 : end]:
            if not line:
                continue
            field_match = field_re.fullmatch(line)
            if field_match is None or field_match.group(1) in event_fields:
                raise ValueError("noncanonical or duplicate dispatch event field")
            event_fields[field_match.group(1)] = field_match.group(2)
        if set(event_fields) != required_event_fields:
            raise ValueError("dispatch event field set mismatch")
        events.setdefault(node_id, []).append((status, event_fields))
        event_sequence.append((node_id, status))

    expected_event_ids = {"context-brief", "profile-resolve", *node_ids}
    if set(events) != expected_event_ids:
        raise ValueError("dispatch contains missing or orphan node events")
    expected_sequence = [("context-brief", "PASS"), ("profile-resolve", "PASS")]
    for node_id in node_ids:
        expected_sequence.extend(((node_id, "in-progress"), (node_id, "PASS")))
    if event_sequence != expected_sequence:
        raise ValueError("dispatch event order is not canonical")
    startup_expectations = {
        "context-brief": {
            "owner_agent": "agent-system",
            "module": "github-index",
            "trigger": f"e2e:{expected_profile}",
            "depends_on": "",
            "inputs": ".github live index + retained memory/log",
            "action": "github-index brief",
            "outputs": f"{run_rel}/context-brief.md",
            "evidence": f"{run_rel}/context-brief.md",
            "handoff_to": "",
            "next_step": "DB-indexed startup context generated before dispatch",
            "notes": "",
        },
        "profile-resolve": {
            "owner_agent": "agent-system",
            "module": "github-index",
            "trigger": f"e2e:{expected_profile}",
            "depends_on": "",
            "inputs": f".github/e2e/profiles/{expected_profile}.tsv",
            "action": "github-index resolve-profile",
            "outputs": f"{run_rel}/profile-resolve.md",
            "evidence": f"{run_rel}/profile-resolve.md",
            "handoff_to": "",
            "next_step": "live/indexed e2e profile include closure generated before dispatch",
            "notes": "",
        },
    }
    for node_id, expected_payload in startup_expectations.items():
        entries = events[node_id]
        if len(entries) != 1 or entries[0][0] != "PASS":
            raise ValueError("startup dispatch event is not exactly one PASS")
        values = entries[0][1]
        if values != expected_payload:
            raise ValueError("startup dispatch payload mismatch")
    manifest_by_id = {row[0]: row for row in node_full}
    for node_id in node_ids:
        entries = events[node_id]
        if [status for status, _ in entries] != ["in-progress", "PASS"]:
            raise ValueError("profile dispatch is not exactly in-progress then PASS")
        row = manifest_by_id[node_id]
        expected_payload = {
            "owner_agent": row[3],
            "module": row[2],
            "trigger": f"e2e:{expected_profile}",
            "depends_on": "",
            "inputs": row[6],
            "action": row[4],
            "outputs": row[7],
            "evidence": row[8],
            "handoff_to": "",
            "notes": "",
        }
        for status, values in entries:
            status_payload = dict(expected_payload)
            status_payload["next_step"] = "等待节点结果" if status == "in-progress" else "进入下一节点"
            if values != status_payload:
                raise ValueError("dispatch/manifest full node payload mismatch")
except (
    IndexError,
    OSError,
    OverflowError,
    TypeError,
    UnicodeError,
    ValueError,
    json.JSONDecodeError,
) as exc:
    if os.environ.get("E2E_VALIDATE_DEBUG") == "1":
        print(f"[e2e-bundle] {exc}", file=sys.stderr)
    raise SystemExit(1)
PY
}

e2e_context_brief_terms() {
  [[ $# -eq 1 ]] || return 2
  # task slug 是路径/身份字段，不应整串当作一个检索短语，也不应把 profile
  # 名重复塞进 focus query。拆出至多八个非泛化语义词，让独立 focus 仍按
  # AND 语义 fail-closed，同时过滤日期/序号和 run/final 等生命周期噪声。
  python3 - "$1" <<'PY'
import re
import sys

slug = sys.argv[1].casefold()
stopwords = {
    "agent", "e2e", "run", "rerun", "retry", "final", "latest",
    "task", "test", "tests", "check", "verify", "verification",
    "profile", "fix", "fixed", "update", "updated", "pass", "green",
}
terms = []
for term in re.findall(r"[0-9a-z\u3400-\u9fff]+", slug):
    if term.isdigit() or term in stopwords or term in terms:
        continue
    terms.append(term)
    if len(terms) == 8:
        break
if not terms:
    raise SystemExit(1)
print("\n".join(terms))
PY
}

e2e_generate_context_brief() {
  [[ -n ${E2E_RUN_DIR:-} && -d $E2E_RUN_DIR ]] || return 1

  local max_tokens temp_brief generation_ok brief_term_text
  local -a brief_terms=()
  max_tokens=${E2E_CONTEXT_BRIEF_MAX_TOKENS:-2400}
  temp_brief="${E2E_CONTEXT_BRIEF_FILE}.tmp"
  generation_ok=0
  rm -f -- "$temp_brief"
  if brief_term_text=$(e2e_context_brief_terms "$E2E_TASK_SLUG") &&
     [[ -n $brief_term_text ]]; then
    mapfile -t brief_terms <<< "$brief_term_text"
  fi
  if [[ ${#brief_terms[@]} -gt 0 ]] &&
     [[ ${E2E_GENERATE_CONTEXT_BRIEF:-1} = 1 ]] &&
     [[ -f "$E2E_ROOT_DIR/scripts/github_index_db.py" ]] &&
     python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" brief "${brief_terms[@]}" \
      --repo-root "$E2E_ROOT_DIR" \
      --profile "$E2E_PROFILE" \
      --focus-scope non-history \
      --max-tokens "$max_tokens" > "$temp_brief" 2>&1; then
    if e2e_validate_recall_header context "$temp_brief" "$E2E_PROFILE"; then
      generation_ok=1
    fi
  fi
  if [[ $generation_ok -eq 1 ]] &&
     mv -T -- "$temp_brief" "$E2E_CONTEXT_BRIEF_FILE"; then
    e2e_append_dispatch \
      "context-brief" \
      "PASS" \
      "agent-system" \
      "github-index" \
      "github-index brief" \
      ".github live index + retained memory/log" \
      "$(e2e_relpath "$E2E_CONTEXT_BRIEF_FILE")" \
      "$(e2e_relpath "$E2E_CONTEXT_BRIEF_FILE")" \
      "DB-indexed startup context generated before dispatch"
  else
    {
      printf '# Agent Brief\n\n'
      printf -- '- `recall_status`: failed\n'
      printf -- '- `profile`: %s\n' "$E2E_PROFILE"
      printf '\nWARN context brief generation failed; profile dispatch is not green.\n\n'
      printf '## Diagnostic\n\n```text\n'
      sed -n '1,160p' "$temp_brief"
      printf '```\n'
    } > "$E2E_CONTEXT_BRIEF_FILE"
    rm -f -- "$temp_brief"
    e2e_append_dispatch \
      "context-brief" \
      "WARN" \
      "agent-system" \
      "github-index" \
      "github-index brief" \
      ".github live index + retained memory/log" \
      "context brief unavailable" \
      "$(e2e_relpath "$E2E_CONTEXT_BRIEF_FILE")" \
      "继续采集诊断，但本轮 overall status 保持 FAIL"
    return 1
  fi
}

e2e_generate_profile_resolve() {
  [[ -n ${E2E_RUN_DIR:-} && -d $E2E_RUN_DIR ]] || return 1

  local temp_resolve generation_ok
  temp_resolve="${E2E_PROFILE_RESOLVE_FILE}.tmp"
  generation_ok=0
  rm -f -- "$temp_resolve"
  if [[ ${E2E_GENERATE_PROFILE_RESOLVE:-1} = 1 ]] &&
     [[ -f "$E2E_ROOT_DIR/scripts/github_index_db.py" ]] &&
     python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" resolve-profile "$E2E_PROFILE" \
       --repo-root "$E2E_ROOT_DIR" > "$temp_resolve" 2>&1; then
    if e2e_validate_recall_header resolve "$temp_resolve" "$E2E_PROFILE" "${#PROFILE_NODE_IDS[@]}"; then
      generation_ok=1
    fi
  fi
  if [[ $generation_ok -eq 1 ]] &&
     mv -T -- "$temp_resolve" "$E2E_PROFILE_RESOLVE_FILE"; then
    e2e_append_dispatch \
      "profile-resolve" \
      "PASS" \
      "agent-system" \
      "github-index" \
      "github-index resolve-profile" \
      ".github/e2e/profiles/$E2E_PROFILE.tsv" \
      "$(e2e_relpath "$E2E_PROFILE_RESOLVE_FILE")" \
      "$(e2e_relpath "$E2E_PROFILE_RESOLVE_FILE")" \
      "live/indexed e2e profile include closure generated before dispatch"
  else
    {
      printf '# E2E Resolved Profile\n\n'
      printf -- '- `ok`: False\n'
      printf -- '- `profile`: %s\n' "$E2E_PROFILE"
      printf '\nWARN profile resolve generation failed; profile dispatch is not green.\n\n'
      printf '## Diagnostic\n\n```text\n'
      sed -n '1,160p' "$temp_resolve"
      printf '```\n'
    } > "$E2E_PROFILE_RESOLVE_FILE"
    rm -f -- "$temp_resolve"
    e2e_append_dispatch \
      "profile-resolve" \
      "WARN" \
      "agent-system" \
      "github-index" \
      "github-index resolve-profile" \
      ".github/e2e/profiles/$E2E_PROFILE.tsv" \
      "profile resolve unavailable" \
      "$(e2e_relpath "$E2E_PROFILE_RESOLVE_FILE")" \
      "继续采集诊断，但本轮 overall status 保持 FAIL"
    return 1
  fi
}

e2e_init_dispatch_log() {
  cat > "$E2E_DISPATCH_FILE" <<EOF
# 派发日志

## 基本信息

- \`task_id\`: $(basename "$E2E_RUN_DIR")
- \`trace_id\`: e2e:$(basename "$E2E_RUN_DIR")
- \`task_slug\`: $E2E_TASK_SLUG
- \`graph_template\`: modular-agent-e2e
- \`profile\`: $E2E_PROFILE
- \`log_policy\`: append-only

---
EOF
}

e2e_append_dispatch() {
  local node_id=$1 status=$2 owner=$3 module=$4 action=$5 inputs=$6 outputs=$7 evidence=$8 next_step=$9 notes=${10:-}
  cat >> "$E2E_DISPATCH_FILE" <<EOF

### [$(e2e_now)] \`$node_id\` - \`$status\`

- \`owner_agent\`: $owner
- \`module\`: $module
- \`trigger\`: e2e:$E2E_PROFILE
- \`depends_on\`: ${E2E_NODE_DEPENDS_ON:-}
- \`inputs\`: $inputs
- \`action\`: $action
- \`outputs\`: $outputs
- \`evidence\`: $evidence
- \`handoff_to\`: ${E2E_NODE_HANDOFF_TO:-}
- \`next_step\`: $next_step
- \`notes\`: $notes
EOF
}

e2e_record_node() {
  local node_id=$1 owner=$2 module=$3 status=$4 inputs=$5 outputs=$6 evidence=$7
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$node_id" "$owner" "$module" "$status" "$inputs" "$outputs" "$evidence" \
    "${E2E_CURRENT_SOURCE_PROFILE:-}" "${E2E_CURRENT_FUNCTION:-}" >> "$E2E_NODES_FILE"
}

e2e_record_skip() {
  local node_id=$1 owner=$2 module=$3 inputs=$4 reason=$5 next_step=$6
  local log_file="$E2E_EVIDENCE_DIR/${node_id}.log"
  local evidence
  evidence=$(e2e_relpath "$log_file")
  if ! {
    printf 'SKIP %s\n' "$node_id"
    printf 'reason=%s\n' "$reason"
    printf 'next_step=%s\n' "$next_step"
  } > "$log_file"; then
    E2E_OVERALL_RC=1
    return 1
  fi
  if ! e2e_record_node "$node_id" "$owner" "$module" "SKIP" "$inputs" "$reason" "$evidence" ||
     ! e2e_append_dispatch "$node_id" "SKIP" "$owner" "$module" "skip" "$inputs" "$reason" "$evidence" "$next_step"; then
    E2E_OVERALL_RC=1
    return 1
  fi
  E2E_SKIP_COUNT=$((E2E_SKIP_COUNT + 1))
}

e2e_run_function_node() {
  local node_id=$1 owner=$2 module=$3 function_name=$4 inputs=$5 outputs=$6
  local log_file="$E2E_EVIDENCE_DIR/${node_id}.log"
  local evidence
  evidence=$(e2e_relpath "$log_file")

  if ! e2e_append_dispatch "$node_id" "in-progress" "$owner" "$module" "$function_name" "$inputs" "$outputs" "$evidence" "等待节点结果"; then
    E2E_OVERALL_RC=1
    return 1
  fi
  local rc=0
  "$function_name" > "$log_file" 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then
    if ! e2e_record_node "$node_id" "$owner" "$module" "PASS" "$inputs" "$outputs" "$evidence" ||
       ! e2e_append_dispatch "$node_id" "PASS" "$owner" "$module" "$function_name" "$inputs" "$outputs" "$evidence" "进入下一节点"; then
      E2E_OVERALL_RC=1
      return 1
    fi
    return 0
  fi

  if [[ $rc -eq 77 ]]; then
    if ! e2e_record_node "$node_id" "$owner" "$module" "SKIP" "$inputs" "$outputs" "$evidence" ||
       ! e2e_append_dispatch "$node_id" "SKIP" "$owner" "$module" "$function_name" "$inputs" "$outputs" "$evidence" "查看 SKIP 原因后切换配置或补依赖"; then
      E2E_OVERALL_RC=1
      return 1
    fi
    E2E_SKIP_COUNT=$((E2E_SKIP_COUNT + 1))
    return 0
  fi

  E2E_OVERALL_RC=1
  local evidence_write_rc=0
  e2e_record_node "$node_id" "$owner" "$module" "FAIL" "$inputs" "exit=$rc" "$evidence" || evidence_write_rc=1
  e2e_append_dispatch "$node_id" "FAIL" "$owner" "$module" "$function_name" "$inputs" "exit=$rc" "$evidence" "检查日志并按 regression-debug-loop 扩图" || evidence_write_rc=1
  if [[ ${E2E_KEEP_GOING:-1} -eq 0 ]]; then
    e2e_render_report || true
    exit "$rc"
  fi
  [[ $evidence_write_rc -eq 0 ]] || return 1
  return 0
}

e2e_run_shell_node() {
  local node_id=$1 owner=$2 module=$3 inputs=$4 outputs=$5 cmd=$6 timeout_note=${7:-} validator=${8:-}
  local log_file="$E2E_EVIDENCE_DIR/${node_id}.log"
  local cmd_file="$E2E_EVIDENCE_DIR/${node_id}.cmd"
  local evidence
  evidence="$(e2e_relpath "$log_file"), $(e2e_relpath "$cmd_file")"
  if ! printf '%s\n' "$cmd" > "$cmd_file"; then
    E2E_OVERALL_RC=1
    return 1
  fi

  if ! e2e_append_dispatch "$node_id" "in-progress" "$owner" "$module" "$(e2e_relpath "$cmd_file")" "$inputs" "$outputs" "$evidence" "等待命令完成" "$timeout_note"; then
    E2E_OVERALL_RC=1
    return 1
  fi
  local rc=0
  (cd "$E2E_ROOT_DIR" && bash -lc "$cmd") > "$log_file" 2>&1 || rc=$?
  if [[ $rc -eq 0 && -n $validator ]]; then
    "$validator" "$log_file" || rc=99
  fi

  if [[ $rc -eq 0 ]]; then
    if ! e2e_record_node "$node_id" "$owner" "$module" "PASS" "$inputs" "$outputs" "$evidence" ||
       ! e2e_append_dispatch "$node_id" "PASS" "$owner" "$module" "$(e2e_relpath "$cmd_file")" "$inputs" "$outputs" "$evidence" "进入下一节点" "$timeout_note"; then
      E2E_OVERALL_RC=1
      return 1
    fi
    return 0
  fi

  E2E_OVERALL_RC=1
  local evidence_write_rc=0
  e2e_record_node "$node_id" "$owner" "$module" "FAIL" "$inputs" "exit=$rc" "$evidence" || evidence_write_rc=1
  e2e_append_dispatch "$node_id" "FAIL" "$owner" "$module" "$(e2e_relpath "$cmd_file")" "$inputs" "exit=$rc" "$evidence" "检查日志并按 regression-debug-loop 扩图" "$timeout_note" || evidence_write_rc=1
  if [[ ${E2E_KEEP_GOING:-1} -eq 0 ]]; then
    e2e_render_report || true
    exit "$rc"
  fi
  [[ $evidence_write_rc -eq 0 ]] || return 1
  return 0
}

e2e_render_report() {
  local status updated final_result risk next_step nodes_fd nodes_inode path_inode render_nodes_rc=0
  local completion_marker=${E2E_COMPLETE_MARKER_FILE:-$E2E_RUN_DIR/complete.marker}
  local publication_file=${E2E_PUBLICATION_FILE:-$E2E_RUN_DIR/completion-publication.md}
  rm -f -- "$completion_marker" "$publication_file" || return 1
  [[ ! -e $completion_marker && ! -L $completion_marker ]] || return 1
  [[ ! -e $publication_file && ! -L $publication_file ]] || return 1
  [[ -f ${E2E_NODES_FILE:-} && ! -L ${E2E_NODES_FILE:-} && -r ${E2E_NODES_FILE:-} ]] || return 1
  exec {nodes_fd}< "$E2E_NODES_FILE" || return 1
  nodes_inode=$(stat -Lc '%d:%i' "/proc/$$/fd/$nodes_fd" 2>/dev/null) || {
    exec {nodes_fd}<&-
    return 1
  }
  path_inode=$(stat -Lc '%d:%i' "$E2E_NODES_FILE" 2>/dev/null) || {
    exec {nodes_fd}<&-
    return 1
  }
  if [[ $nodes_inode != "$path_inode" || ! -f /proc/$$/fd/$nodes_fd ]]; then
    exec {nodes_fd}<&-
    return 1
  fi
  updated=$(e2e_now)
  if [[ ${E2E_SKIP_COUNT:-0} -gt 0 ]]; then
    E2E_OVERALL_RC=1
  fi
  if [[ $E2E_OVERALL_RC -eq 0 ]]; then
    status=completed
    final_result="profile=$E2E_PROFILE 通过，当前 modular e2e 证据链可复用。"
    risk="无 hard fail；optional tool 缺失只作为后续节点风险。"
    next_step="按模块或跨模块目标选择更深 profile，或进入具体静态图。"
  else
    status=blocked
    if [[ ${E2E_SKIP_COUNT:-0} -gt 0 ]]; then
      final_result="profile=$E2E_PROFILE 有 ${E2E_SKIP_COUNT} 个 required 节点被 SKIP，验证闭包不完整；不能把 SKIP 当作 PASS。"
      risk="required 节点未全部执行，当前 task-run 不能作为 strict guard 的完成证据。"
      next_step="补齐依赖或切换到能执行全部 required 节点的配置后重跑。"
    else
      final_result="profile=$E2E_PROFILE 存在失败节点；不能把后续工程判断建立在该节点上。"
      risk="需要先查看 evidence 日志，按 regression-debug-loop 补 reproduce/collect/localize。"
      next_step="修复失败节点或切换到更小 profile。"
    fi
  fi

  local state_current state_failure state_rollback state_failure_reason
  if [[ $status = completed ]]; then
    state_current=persist
    state_failure=无
    state_rollback=无
    state_failure_reason=无
  else
    state_current=verify
    state_failure=verify
    state_rollback=implement
    state_failure_reason=$final_result
  fi

  cat > "$E2E_REPORT_FILE" <<EOF
# 任务报告

## 基本信息

- \`task_id\`: $(basename "$E2E_RUN_DIR")
- \`trace_id\`: e2e:$(basename "$E2E_RUN_DIR")
- \`task_slug\`: $E2E_TASK_SLUG
- \`graph_template\`: modular-agent-e2e
- \`profile\`: $E2E_PROFILE
- \`graph_mode\`: static
- \`publication_contract\`: db-marker-v1
- \`status\`: $status
- \`owner\`: agent-system + hardware-flow + module agents
- \`started_at\`: $E2E_STARTED_AT
- \`updated_at\`: $updated

## 任务目标

- \`source_request\`: 将 agent 系统从纯语言提示升级为分层、分模块、可闭环和可优化的 e2e 流水线
- \`goal\`: 依据 profile 执行模块化 e2e 节点，生成可复核证据包
- \`scope\`: profile=$E2E_PROFILE；不越级声明未执行模块或业务 gate 已完成

## 选图说明

- \`selected_template\`: modular-agent-e2e
- \`why_this_graph\`: 本 profile 从 \`.github/e2e/profiles/\` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- \`dynamic_nodes_added\`: 无
- \`why_dynamic_nodes_were_needed\`: 无

## 状态回溯

- \`state_sequence\`: recall_context -> classify_layer -> plan_graph -> implement -> verify -> inspect -> persist
- \`current_state\`: $state_current
- \`failure_state\`: $state_failure
- \`rollback_target\`: $state_rollback
- \`failure_reason\`: $state_failure_reason
- \`reviewer\`: ysyx-coordinator
- \`inspector\`: agent-system
- \`evidence_policy\`: task-report + dispatch-log + run-manifest + evidence-index

## 节点概览

| 节点ID (\`node_id\`) | 负责 Agent (\`owner_agent\`) | 模块 (\`module\`) | 状态 (\`status\`) | 输入 (\`inputs\`) | 输出 (\`outputs\`) | 证据 (\`evidence\`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- | ----------------- |
EOF
  [[ $? -eq 0 ]] || return 1

  python3 - "/proc/$$/fd/$nodes_fd" "$E2E_REPORT_FILE" <<'PY' || render_nodes_rc=1
import sys
from pathlib import Path

nodes_path = Path(sys.argv[1])
report_path = Path(sys.argv[2])
rows: list[str] = []
for line in nodes_path.read_text(encoding="utf-8").splitlines():
    fields = line.split("\t")
    if len(fields) != 9:
        raise SystemExit(1)
    node, owner, module, status, inputs, outputs, evidence, _source, _function = fields
    rows.append(
        f"| `{node}` | `{owner}` | `{module}` | `{status}` | "
        f"{inputs} | {outputs} | {evidence} |\n"
    )
with report_path.open("a", encoding="utf-8", newline="\n") as handle:
    handle.writelines(rows)
PY
  exec {nodes_fd}<&-
  [[ $render_nodes_rc -eq 0 ]] || return 1

  cat >> "$E2E_REPORT_FILE" <<EOF

## 关键产物

- \`artifacts\`: $(e2e_relpath "$E2E_RUN_DIR")
- \`logs_or_traces\`: $(e2e_relpath "$E2E_EVIDENCE_DIR")
- \`context_brief\`: $(e2e_relpath "$E2E_CONTEXT_BRIEF_FILE")
- \`profile_resolve\`: $(e2e_relpath "$E2E_PROFILE_RESOLVE_FILE")
- \`evidence_index\`: $(e2e_relpath "$E2E_EVIDENCE_INDEX_FILE")
- \`run_manifest\`: $(e2e_relpath "$E2E_RUN_MANIFEST_FILE")
- \`profile_manifest\`: .github/e2e/profiles/$E2E_PROFILE.tsv
- \`linked_memory_updates\`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 当前阻塞点

- \`blockers\`: $([[ $E2E_OVERALL_RC -eq 0 ]] && printf '无' || printf '存在失败节点，详见 evidence 日志')
- \`missing_dependencies\`: 见对应 tool/env 节点日志
- \`risk_assessment\`: $risk

## 下一步建议

1. $next_step
2. 对含 \`SKIP\` 的模块，先补依赖或切换到合适配置，再把该模块提升到 PASS 证据。

## 模板升级候选

- \`repeated_dynamic_subgraph\`: 无
- \`should_promote_to_static_template\`: 已作为 modular-agent-e2e profile 固化
- \`reason\`: profile + module library + task-run 证据包能把 agent 提示转为可执行流水线

## 收尾结论

- \`final_result\`: $final_result
- \`evidence_summary\`: 详见节点表与 \`evidence/\`
- \`notes\`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。
EOF
  [[ $? -eq 0 ]] || return 1
  e2e_sanitize_task_run_text_artifacts || {
    printf '[e2e] WARN report finalization failed at stage=sanitize\n' >&2
    return 1
  }
  e2e_render_run_manifest "$status" "$final_result" "$updated" || {
    printf '[e2e] WARN report finalization failed at stage=render-manifest\n' >&2
    return 1
  }
  e2e_index_task_run_evidence_assets || {
    printf '[e2e] WARN report finalization failed at stage=index-evidence\n' >&2
    return 1
  }
  e2e_validate_evidence_index "$E2E_ROOT_DIR" "$E2E_RUN_DIR" "$E2E_PROFILE" || {
    printf '[e2e] WARN report finalization failed at stage=validate-evidence-index\n' >&2
    return 1
  }
  if [[ $status = completed ]]; then
    e2e_validate_recall_header context "$E2E_CONTEXT_BRIEF_FILE" "$E2E_PROFILE" || {
      printf '[e2e] WARN report finalization failed at stage=validate-context\n' >&2
      return 1
    }
    e2e_validate_recall_header resolve "$E2E_PROFILE_RESOLVE_FILE" "$E2E_PROFILE" || {
      printf '[e2e] WARN report finalization failed at stage=validate-resolve\n' >&2
      return 1
    }
    e2e_validate_task_run_bundle "$E2E_RUN_DIR" "$E2E_PROFILE" || {
      printf '[e2e] WARN report finalization failed at stage=validate-bundle\n' >&2
      return 1
    }
    e2e_write_completion_marker_for_dir "$E2E_RUN_DIR" "$E2E_PROFILE" || {
      printf '[e2e] WARN report finalization failed at stage=write-marker\n' >&2
      return 1
    }
    if ! e2e_archive_task_run_markdown_to_db; then
      printf '[e2e] WARN completion publication failed at stage=archive-staged\n' >&2
      rm -f -- "$completion_marker" "$publication_file"
      return 1
    fi
    if ! e2e_validate_task_run_db_archive \
        "$E2E_ROOT_DIR" \
        "$E2E_RUN_DIR" \
        "${E2E_GITHUB_INDEX_DB:-.github/cache/github-index.sqlite}" \
        staged; then
      printf '[e2e] WARN completion publication failed at stage=validate-staged\n' >&2
      rm -f -- "$completion_marker" "$publication_file"
      return 1
    fi
    if ! e2e_write_completion_publication_for_dir \
        "$E2E_RUN_DIR" "$E2E_PROFILE" "$publication_file"; then
      printf '[e2e] WARN completion publication failed at stage=write-publication\n' >&2
      rm -f -- "$completion_marker" "$publication_file"
      return 1
    fi
    if ! e2e_validate_completion_publication \
        "$E2E_RUN_DIR" "$E2E_PROFILE" "$publication_file"; then
      printf '[e2e] WARN completion publication failed at stage=validate-publication\n' >&2
      rm -f -- "$completion_marker" "$publication_file"
      return 1
    fi
    if ! e2e_archive_task_run_publication_to_db; then
      printf '[e2e] WARN completion publication failed at stage=archive-publication\n' >&2
      rm -f -- "$completion_marker" "$publication_file"
      return 1
    fi
  else
    e2e_archive_task_run_markdown_to_db || return 1
  fi
}

# Strict Guard Semantic Freshness Design

## Problem

The strict agent-e2e guard currently compares the filesystem modification time
of task-report.md with the maximum filesystem modification time of the changed
paths that require a profile.

That makes evidence freshness depend on mutable presentation metadata. On
2026-07-11, an npc-dev run completed at 21:57:13 +0800, then a mechanical
Markdown cleanup changed task-report.md mtime to 22:07:30 +0800. The guard
therefore accepted that old run for a design document changed at 22:07:30,
even though the run manifest proved that execution finished earlier.

## Goals

- Strict mode must use the semantic completion time recorded by the run.
- Touching, copying, restoring, or formatting task-report.md must not make an
  old run fresh.
- A valid legacy run without run-manifest.json remains usable when its report
  contains a timezone-qualified updated_at value.
- Legacy profile, status, and updated_at fields must each occur exactly once
  and match their complete values; prefixes and conflicting duplicates fail.
- When several candidates are supplied, the newest semantically valid
  candidate is selected with microsecond precision.
- Manifest profile and status must agree with the requested profile and the
  completed report.

## Non-goals

- This change does not redesign how changed-path timestamps are obtained.
- This change does not add content hashes or bind a run to an exact Git tree.
- This change does not modify any RV64 RTL or functional/timing gate.

## Considered approaches

### 1. Semantic timestamp with legacy report fallback

Read updated_at from run-manifest.json when present. If a manifest is absent,
read updated_at from task-report.md. Reject malformed, timezone-less, profile-
mismatched, or incomplete evidence. Compare that epoch with the changed-path
threshold and return the newest qualifying candidate.

This is selected because it fixes the observed false pass while preserving
well-formed legacy evidence.

### 2. Manifest-only strict evidence

Require run-manifest.json for every candidate. This is simpler and strongest
for new runs, but hundreds of retained historical reports predate the
manifest, so it creates an unnecessary migration cliff.

### 3. Content-addressed evidence binding

Record hashes of every relevant changed file and require exact hash agreement.
This is stronger than timestamps, but it expands the evidence schema and run
generator substantially. It remains a possible future hardening step.

## Selected contract

scripts/agent-e2e.sh gains one focused helper:

- e2e_guard_evidence_updated_epoch(root, profile)
  - Parse the report's profile, status, and updated_at as unique structured
    fields and require exact profile/completed values.
  - If run-manifest.json exists, require JSON profile equal to profile,
    status equal to completed, a timezone-qualified updated_at, an object
    top-level value, no duplicate JSON keys, no NaN/Infinity constants, and
    a regular non-symlink manifest path.
  - If no manifest exists, require a timezone-qualified updated_at in
    task-report.md.
  - Print an integer UTC Unix epoch in microseconds on success; return
    non-zero without traceback otherwise.

e2e_guard_find_evidence_for_profile evaluates every explicit and automatically
discovered evidence directory. A candidate qualifies only when:

1. task-report.md says the requested profile completed;
2. context-brief.md, profile-resolve.md, and evidence-index.md exist;
3. the semantic timestamp helper succeeds;
4. the semantic timestamp is not older than the changed-path threshold.

The candidate with the greatest semantic epoch is returned. Input order breaks
ties, so results remain stable without adding another ordering policy.

## Verification

The existing agent-system self-test receives four focused cases:

- stale manifest time plus freshly touched report is rejected;
- fresh manifest time plus deliberately old report mtime is accepted;
- a manifest whose profile disagrees with the report is rejected;
- two qualifying candidates select the one with the newer semantic time.
- malformed/non-object manifests, missing fields, non-completed status,
  timezone-less timestamps, non-finite JSON constants, duplicate JSON keys,
  dangling manifest symlinks, legacy prefix collisions, and duplicate report
  fields are rejected without traceback;
- two timestamps within the same second retain fractional ordering.

The RED run must fail against the current mtime implementation. The GREEN run,
the complete agent-system profile, the strict guard, shell syntax checks, DB
audit, and whitespace checks must then pass before commit.

## Compatibility and failure behavior

An existing manifest is authoritative: malformed or contradictory manifest
data is not silently replaced by report data. Legacy fallback applies only
when the manifest is absent. Evidence without any semantic updated_at is
unprovable and is rejected by strict mode.

# Raw Markdown Evidence Index-only Design

## Problem

The runtime-artifact contract says every file below
.github/task-runs/*/evidence and .github/runtime-artifacts is raw execution
payload. Raw payload may be summarized in evidence_assets, but its complete
content must not be retained in db_documents or file_text.

The implementation violates that boundary for Markdown:

- infer_kind classifies evidence/*.md as task-evidence;
- task-evidence is currently a DB-retained kind;
- archive-markdown therefore copies raw Markdown into db_documents;
- the general .github rebuild also copies ignored raw evidence into file_text;
- index-evidence excludes the .md suffix, so the intended bounded asset index
  does not receive the same file.

The current database consequently contains nine raw Markdown documents, and
the agent-system artifact audit fails before strict guard self-tests run.

## Selected architecture

Runtime location, not file extension, owns the retention decision.

1. Add a shared is_raw_evidence_path predicate for both runtime roots.
2. Exclude raw evidence from the general files/file_text index and prune
   historical rows during rebuild.
3. Remove task-evidence from DB_RETAINED_KINDS and from the schema contract's
   db_owned_kinds.
4. Make archive-markdown reject raw evidence paths even if a future kind list
   accidentally includes them again.
5. Add .md to the bounded index-evidence text suffixes.
6. Count Markdown below the run's evidence directory as manifest assets while
   continuing to exclude task-report and other top-level Markdown documents.
7. Extend artifact-audit to reject raw paths in both db_documents and
   file_text.

The current nine files will be indexed into evidence_assets, removed from Git
tracking while remaining available as ignored local runtime payload, and
pruned from db_documents/file_text. Their hashes and bounded excerpts remain
available through evidence-index.md and the evidence query.

## Alternatives rejected

- Renaming .md files to .log hides the symptom and leaves the location policy
  unenforced.
- Allowing small Markdown in db_documents contradicts raw_evidence_fulltext_in_db
  and lets payload type determine retention.
- Deleting the nine files without indexing them loses useful evidence and does
  not prevent recurrence.

## Verification

The github-index contract test creates evidence/note.md and must prove:

- index-evidence reports three assets instead of two;
- evidence_assets contains note.md;
- a general rebuild leaves no raw path in file_text;
- archive-markdown leaves no raw path in db_documents;
- the bounded evidence query can recall the Markdown marker.

Repository integration then requires github-index PASS, artifact-audit PASS,
markdown coverage PASS, agent-system PASS, DB-first audit PASS, and strict
guard PASS before the lifecycle fix is committed.

# S2 exact-owner `/tmp` archive

This directory preserves every top-level `/tmp/s2-g1*` object that existed at
the S2-G1 checkpoint closeout on 2026-07-17.

- `system-tmp/` is the unmodified `cp -a` copy of the source objects.
- `inventory.tsv` records object type, byte size, SHA-256 or symlink target,
  and archive-relative path.
- `SHA256SUMS` covers every regular file below `system-tmp/`.
- `archive-summary.txt` records the verified object counts and byte total.
- `system-tmp.tar.zst` is the durable Git archive of the verified `cp -a`
  tree (16,228,885 bytes); `system-tmp.tar.zst.sha256` binds it.
- Failed/diagnostic attempts are intentionally retained beside the final green
  runs; no source object was deleted from `/tmp`.

Verification at archive creation compared source and copy path-for-path,
including type, file size, SHA-256, and symlink target.  Result:

```text
[S2-G1-TMP-ARCHIVE][PASS] top=64 files=788 dirs=214 links=0 bytes=303240349
```

Recheck while the original `/tmp` objects still exist with:

```sh
python3 .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/check-s2-g1-tmp-archive.py
```

Compressed archive SHA-256:

```text
aa52f2d41c60af37e2bb4b836b6f5ec7ff391eec0e9b06756716f3954c02c196
```

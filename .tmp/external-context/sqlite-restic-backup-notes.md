---
source: official docs
topic: sqlite-restic-backup-best-practice
fetched: 2026-05-05T00:00:00Z
---

## Actionable notes

- **Portable logical backup:** Prefer `VACUUM INTO` when you want a compact, portable snapshot of a live SQLite DB; SQLite says it is an alternative to the backup API and produces a fully vacuumed copy.
- **`sqlite3 .backup` / backup API:** Also valid for live DBs and usually cheaper on CPU; it is the classic online-backup path and yields a consistent snapshot.
- **Raw file backup of a live DB:** Not safe as a generic method. SQLite warns plain file copy has corruption risk if power/OS failure occurs during copy. For WAL mode, the `-wal` file is part of the database state and must be backed up with the main DB.
- **Recommended restic pairing:** Use restic for the raw on-disk state (`db.sqlite`, plus `db.sqlite-wal` and `db.sqlite-shm` when present), and separately keep a logical export (`.backup` or `VACUUM INTO`) for portability/repair.
- **Restore rule of thumb:**
  - For fastest exact restore, restore the raw DB set together (`main` + WAL/SHM if WAL was active).
  - For portable or offline restore, restore the logical export into a fresh database.
  - Don’t mix a restored main DB with missing WAL/SHM from a WAL-era backup.

## Practical recommendation

1. Run a logical export on a schedule (`VACUUM INTO` if you want a compact portable copy; otherwise `.backup`).
2. Back up the live database files with restic as an exact-state capture.
3. For restore, prefer logical export when moving between hosts/versions; prefer raw files when recreating the same host state.

## Source URLs

- https://www.sqlite.org/backup.html
- https://www.sqlite.org/lang_vacuum.html
- https://www.sqlite.org/wal.html
- https://restic.readthedocs.io/en/stable/040_backup.html

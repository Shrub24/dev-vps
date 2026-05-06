---
source: Context7 API + official docs
library: Vaultwarden
package: vaultwarden
topic: backup restore sqlite
fetched: 2026-05-05T15:40:00Z
official_docs: https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
---

## Recommended backup strategy
- Back up the whole `data` directory regularly (cron/automated job preferred).
- Store at least one copy off-host/off-site.
- For SQLite, use `sqlite3 .backup`, `VACUUM INTO`, or Vaultwarden’s built-in `/vaultwarden backup`.
- Also back up `attachments/`.
- Back up `config.json` and `rsa_key*` if you need admin config and to avoid forcing re-logins.
- `sends/` and `icon_cache/` are optional.

## App-level export vs full backup
- Vaultwarden’s app/export features are for user vault data export, not a complete server backup.
- A full restore needs the database plus filesystem state (attachments, keys, config, etc.).

## SQLite consistency
- Prefer `.backup` for a live database.
- `VACUUM INTO` is also valid and produces a compact copy.
- If copying raw SQLite files, include the matching `db.sqlite3-wal` with `db.sqlite3`.
- Do not rely on `db.sqlite3-shm`.
- When restoring a `.backup`/`VACUUM INTO` copy, remove any stale `db.sqlite3-wal` first.

## Restore workflow
1. Stop Vaultwarden.
2. Replace files/directories in the data dir with the backup contents.
3. For `.backup`/`VACUUM INTO`, rename the backup DB to `db.sqlite3`.
4. Delete any existing `db.sqlite3-wal` before starting.
5. Start Vaultwarden and verify login/admin access.

## Cautions
- Restoring only the DB may drop attachments if they were not backed up.
- Restoring a backup without renaming the DB file can make Vaultwarden create a fresh empty database.
- Admin token / SMTP data may be in `config.json`; encrypt backups.
- Test restores periodically.

## Source URLs
- https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
- https://github.com/dani-garcia/vaultwarden/discussions/6104
- https://sqlite.org/backup.html
- https://sqlite.org/wal.html
- https://sqlite.org/lang_vacuum.html

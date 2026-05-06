---
source: mixed web/docs
library: Kanidm
package: kanidm
topic: backup-restore
fetched: 2026-05-05T00:00:00Z
official_docs: https://kanidm.github.io/kanidm/
---

## Concise notes

- I could verify the Kanidm docs site and admin docs, but the specific backup/restore pages surfaced by site navigation currently return 404 on the published site.
- I did **not** find a verified CLI export command in the accessible docs I could fetch.
- Treat Kanidm as needing an **offline, application-consistent backup** of its persisted server state rather than a hot-copy of live files.

## Actionable guidance

1. Prefer a maintenance window: stop Kanidm or otherwise ensure quiescence before copying state.
2. Back up the full persisted data directory/database used by the deployment.
3. Keep the backup alongside the server config/secrets needed to recreate the instance.
4. For restore, provision a fresh instance, restore the saved state into the same data location, then start Kanidm.

## Cautions

- Avoid hot-copying live state unless the storage layer provides a consistent snapshot.
- Do not assume a CLI export/import workflow exists without checking the versioned docs for your release.

## Source URLs

- https://kanidm.github.io/kanidm/
- https://kanidm.github.io/kanidm/backup_and_restore.html
- https://kanidm.github.io/kanidm/database_maintenance.html
- https://kanidm.github.io/kanidm/administration.html

# Spec: Beets Automation

## Capability ID

`beets-automation`

## Summary

Beets automation provides transfer‑safe, idempotent inbox processing for music files deposited under `/srv/media/inbox`. The automation includes `.tmp` lockout detection, settle/debounce delays, per‑file album‑import promotion to `/srv/media/library`, demotion of unresolved files to `/srv/media/quarantine/untagged`, and structured reporting under `/srv/data/beets`. Automation triggers (systemd path watchers and timer backstops) are currently disabled pending completion of MEDI‑05 and MEDI‑06 requirements.

## Behaviors

### Automation Triggers

- **BA‑1**: The system shall provide a `systemd.path` unit (`beets-inbox-watch.path`) that triggers `beets-inbox-run.service` on modification of `/srv/media/inbox`.
- **BA‑2**: The system shall provide a `systemd.path` unit (`beets-quarantine-promote-watch.path`) that triggers `beets-quarantine-promote-run.service` on modification of `/srv/media/quarantine/approved`.
- **BA‑3**: The system shall provide a `systemd.timer` unit (`beets-inbox-backstop.timer`) that runs `beets-inbox-run.service` on boot and every 15 minutes as a safety backstop.
- **BA‑4**: The system shall provide a `systemd.timer` unit (`beets-quarantine-promote-backstop.timer`) that runs `beets-quarantine-promote-run.service` on boot and every 20 minutes as a safety backstop.
- **BA‑5**: All path watchers and timer backstops shall be **disabled by default** (`enable = false`) until MEDI‑05 and MEDI‑06 are fully satisfied.

### Transfer Safety

- **BA‑6**: The Beets runner shall detect the presence of any `.tmp` file under the target path and **skip execution** immediately.
- **BA‑7**: After the initial `.tmp` check, the runner shall wait a configurable settle delay (`BEETS_SETTLE_SECONDS`, default 10 seconds) before proceeding.
- **BA‑8**: After the settle delay, the runner shall re‑check for `.tmp` files and skip execution if any remain.
- **BA‑9**: The runner shall process only audio files with extensions `.mp3`, `.flac`, `.m4a`, `.aac`, `.ogg`, `.opus`, `.wav`.
- **BA‑10**: For targets under `/srv/media/inbox`, the runner shall demote leftover audio files (those not successfully imported) to `/srv/media/quarantine/untagged`, preserving relative subdirectory structure.
- **BA‑11**: For targets under `/srv/media/quarantine/approved`, the runner shall **not** demote leftovers (promotion is the only allowed outcome).

### Idempotency and Single‑Instance Behavior

- **BA‑12**: The Beets runner shall exit immediately with success if no eligible audio files are found under the target path (empty‑inbox fast exit).
- **BA‑13**: The runner shall guarantee **zero‑state cleanup** for eligible inbox audio: after a successful run, `/srv/media/inbox` shall contain no remaining audio files that match the processed extensions.
- **BA‑14**: The systemd service units shall be configured with `Type = oneshot` and appropriate resource restrictions (`PrivateTmp`, `ProtectSystem`, etc.) but do not yet enforce native systemd single‑instance behavior (pending MEDI‑06).

### Processing Flow

- **BA‑15**: The runner shall invoke `beet import` with flags `-q` (quiet), `-C` (auto‑import candidates), and `-l <logfile>` to capture Beets import output.
- **BA‑16**: The import shall use Beets configuration that sets `directory: /srv/media/library`, `library: /srv/data/beets/state/library.db`, and `singletons: no`, `group_albums: yes`.
- **BA‑17**: The import shall preserve original filenames via Beets `paths:` mapping `$source_stem`.
- **BA‑18**: Successful imports shall place files under `/srv/media/library` according to the Beets path template (e.g., `$albumartist/$album%aunique{}/$source_stem`).
- **BA‑19**: The runner shall record each import session with a UTC timestamp (`%Y%m%dT%H%M%SZ`) and write two logs:
  - `import_log`: Beets import output (`<timestamp>-import.log`)
  - `runner_log`: Runner stdout/stderr (`<timestamp>-runner.log`)
- **BA‑20**: The runner shall output a summary line with counts of candidates, estimated imports, leftovers, and demoted files.

### Reporting and Operator Interaction

- **BA‑21**: All logs and Beets database shall reside under `/srv/data/beets`, with `beets` user ownership and group read access for `dev`.
- **BA‑22**: The runner shall support a dry‑run mode (`BEETS_DRY_RUN=1`) that performs Beets import with `-p` (pretend) and exits without moving or demoting files.
- **BA‑23**: The runner shall accept an optional target path argument, allowing manual processing of a subdirectory of `/srv/media/inbox` or `/srv/media/quarantine/approved`.
- **BA‑24**: The runner shall validate that the target path is within the allowed boundaries (`/srv/media/inbox` or `/srv/media/quarantine/approved`).

### Integration with Media Services

- **BA‑25**: The Beets automation shall be composed via `modules/applications/music.nix` and depend on the same mount points (`/srv/media`, `/srv/data`) as Syncthing and Navidrome.
- **BA‑26**: The Beets system user (`beets`) shall belong to groups `music-ingest` and `media` to permit read/write access to the relevant media directories.
- **BA‑27**: Permission reconciliation (`beets-permission-reconcile`) shall run after each Beets execution to ensure ACLs and group ownership match the declared `systemd.tmpfiles.rules`.

## Constraints

- Automation triggers (path watchers, timers) are **disabled** (`enable = false`) in the current implementation.
- MEDI‑05 (transfer‑safe inbox automation) is partially satisfied by `.tmp` lockout and settle delay in the runner, but not yet integrated with enabled systemd triggers.
- MEDI‑06 (Beets worker idempotency with native systemd single‑instance behavior) is pending.
- Beets automation assumes the presence of `/srv/media/inbox` and `/srv/media/quarantine/approved` directories created by `music.nix` tmpfiles rules.
- External Beatport plugin requires one‑time interactive authorization on the target host before non‑interactive runs can succeed.

## Verification

- `tests/phase-04.2-beets-promotion-contract.sh` validates promotion behavior, demotion rules, log outputs, and forbidden drift.
- `just verify-phase-04.2` runs the promotion contract test.
- Manual execution: `beets-inbox-runner /srv/media/inbox` (or subdirectory) processes files immediately.
- Dry‑run: `BEETS_DRY_RUN=1 beets-inbox-runner /srv/media/inbox` simulates import without moving files.
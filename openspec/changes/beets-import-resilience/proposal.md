## Why

Beets import runners currently fail silently when import crashes mid-batch — the runner exits non-zero, systemd sees a failed unit, but no notification alerts the operator and no automatic retry re-attempts the remaining files. This leaves the inbox stalled until manual intervention, breaking the hands-off automation promise.

## What Changes

- **Add OnFailure-triggered retry**: When a beets runner exits non-zero, a systemd timer fires after a 10-minute cooldown and re-starts the same runner. The inbox still holds unseen files (demotion only runs on success), so the retry picks up where it left off. `StartLimitBurst` caps retry loops at 3 failures per 30 minutes.
- **Add ntfy.sh failure notification**: A `beets-notify-failure@.service` template unit curls ntfy.sh with the runner name and last 20 journal lines. Wired via `OnFailure=` on every generated runner unit.
- **No runner code changes**: The existing `set -euo pipefail` behavior is already correct — on beets crash, the script dies before demotion, leaving unseen files in the inbox. This change only adds systemd-level recovery and alerting around that behavior.
- **New SOPS secret for ntfy token**: An optional `beets.notify.tokenFile` points to a SOPS-managed ntfy.sh access token (or user:pass). Notifications are silent if the token is absent.

## Capabilities

### New Capabilities
- `beets-runner-retry`: Automatic retry of failed beets imports via OnFailure-triggered systemd timers with cooldown and burst-limiting.
- `beets-failure-notify`: ntfy.sh push notification on runner failure via systemd OnFailure template unit.

### Modified Capabilities
- `beets-automation`: Runner processing outcome spec SHALL be updated to include automatic retry semantics and failure notification. The existing "Processing outcome is deterministic" requirement is extended to cover crash recovery.

## Impact

- **modules/services/beets/default.nix**: Generate OnFailure= lines on all runner service units; generate retry timer units; include notify-failure template unit.
- **modules/services/beets/types.nix**: Add optional `notify` submodule (enable, ntfyUrl, tokenFile).
- **modules/applications/music.nix**: Add notify config block (tokenFile pointing to SOPS secret, ntfy topic).
- **secrets**: New `beets.ntfy_token` SOPS key (optional — graceful no-op if absent).

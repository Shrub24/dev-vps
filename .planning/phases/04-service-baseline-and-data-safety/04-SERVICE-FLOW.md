# Phase 04 Service Flow Runbook

## Direct media flow contract

Syncthing /srv/media (authoritative) -> Navidrome MusicFolder /srv/media

## No duplicate staging rule

Navidrome must not read /srv/media/inbox.

/srv/media/inbox is the app-owned generic ingest boundary from `modules/applications/music.nix` via `music-ingest`.

slskd is confined to `/srv/media/inbox/slskd` for completed downloads and `/srv/media/slskd/incomplete` for partial data.

`/srv/media` is the dedicated media mount and remains the authoritative library path for Syncthing, Navidrome, and slskd ingest paths.

## Verification commands

```bash
bash tests/phase-04-syncthing-contract.sh
bash tests/phase-04-service-flow-contract.sh
just verify-phase-04
```

## Operator routine

1. `just verify-phase-04`
2. `just redeploy`
3. `just status`
4. `just tailscale-status`

# Phase 04 Service Flow Runbook

## Direct media flow contract

Syncthing /srv/data/media (authoritative) -> Navidrome MusicFolder /srv/data/media

## No duplicate staging rule

Navidrome must not read /srv/data/inbox.

/srv/data/inbox is the app-owned generic ingest boundary from `modules/applications/music.nix` via `music-ingest`.

slskd is confined to `/srv/data/inbox/slskd/{complete,incomplete}`.

/srv/data/media remains the authoritative library path for Syncthing and Navidrome.

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

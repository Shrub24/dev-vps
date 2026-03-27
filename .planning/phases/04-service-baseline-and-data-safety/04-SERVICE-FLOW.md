# Phase 04 Service Flow Runbook

## Direct media flow contract

Syncthing /srv/data/media (authoritative) -> Navidrome MusicFolder /srv/data/media

## No duplicate staging rule

Navidrome must not read /srv/data/inbox.

/srv/data/inbox remains slskd-only staging (`/srv/data/inbox/complete` and `/srv/data/inbox/incomplete`).

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

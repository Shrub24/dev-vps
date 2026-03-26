# Phase 02 Service Readiness

This document defines the canonical readiness checks for `oci-melb-1` after bootstrap (`deploy.sh`) and updates (`just redeploy`).

## Mandatory Process-Level Checks (D-10)

Run on the target host:

```bash
sudo systemctl is-enabled tailscaled syncthing navidrome slskd
sudo systemctl is-active tailscaled syncthing navidrome slskd
```

Expected result: all units return `enabled` and `active`.

## Local Structural Contract Checks

Run from the operator machine:

```bash
just verify-oci-contract
```

This verifies:

- Flake checks evaluate cleanly.
- Host identity resolves to `oci-melb-1`.
- `tailscale`, `syncthing`, and `navidrome` module enable flags evaluate to `true`.

## Deferred Secret-Dependent Functional Probes

The checks below are intentionally deferred to later phases because they require host-scoped secret material and deeper runtime setup:

- Authenticated Tailscale enrollment and reachability probes beyond process health.
- End-to-end sync and media indexing assertions requiring real content flow.

Deferrals remain explicit for:

- **D-19**: deployment orchestration (`deploy-rs`/Colmena-class rollout tooling)
- **D-20**: backup automation and retention workflows

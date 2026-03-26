---
status: complete
phase: 02-oci-bootstrap-and-service-readiness
source:
  - 02-oci-bootstrap-and-service-readiness-01-SUMMARY.md
  - 02-oci-bootstrap-and-service-readiness-02-SUMMARY.md
  - 02-oci-bootstrap-and-service-readiness-03-SUMMARY.md
started: 2026-03-26T15:38:53Z
updated: 2026-03-26T16:28:05Z
---

## Current Test

[testing complete]

## Tests

### 1. Host-scoped secrets split is visible
expected: In repo files, `.sops.yaml` scopes common vs host secrets separately and `hosts/oci-melb-1/secrets.template.yaml` only defines `tailscale.auth_key`.
result: pass

### 2. Bootstrap-safe evaluation works without host secret requirement
expected: Running `just verify-oci-contract` succeeds without needing `hosts/oci-melb-1/secrets.yaml` present.
result: pass

### 3. Canonical data mount contract is present
expected: `nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.fileSystems."/srv/data".mountPoint` returns `/srv/data`.
result: pass

### 4. Service/private network contract is preserved
expected: Host config imports syncthing/navidrome/slskd modules and keeps private posture with `networking.firewall.trustedInterfaces = [ "tailscale0" ]`.
result: pass

### 5. Operator command contract is canonical
expected: `deploy.sh` still uses nixos-anywhere with `--build-on-remote` and `--flake "path:.#oci-melb-1"`, and `justfile` includes `redeploy` plus `verify-oci-contract`.
result: pass

### 6. Readiness guidance is tiered and explicit
expected: `.planning/phases/02-oci-bootstrap-and-service-readiness/02-SERVICE-READINESS.md` includes process-level checks for tailscaled/syncthing/navidrome/slskd and separately marks secret-dependent probes as deferred.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]

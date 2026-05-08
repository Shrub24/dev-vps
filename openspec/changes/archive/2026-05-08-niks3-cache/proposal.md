## Why

The fleet currently relies on nixbuild.net as the sole shared binary cache, which is a dependency with no sovereignty — builds that expire, were never built on nixbuild, or were built locally have no durable cache. A self-hosted, S3-backed sovereign binary cache gives the fleet persistence, non-CI build coverage, and long-term rollback safety without adding a public-facing homelab HTTP cache endpoint.

**Core Value:** Give the fleet a durable, owned binary cache that works alongside nixbuild.net — first for immediate freshness, second for long-term persistence — while preserving the existing private-first network posture.

## What Changes

- Deploy a `niks3` server on `oci-melb-1` with R2 S3 backend, Postgres for reference-tracking GC, and server-side Ed25519 signing.
- Add host-scoped API tokens and a signing key so hosts can push verified closure artifacts after successful deployment activation.
- Configure active fleet hosts to consume the sovereign cache as a secondary substituter (nixbuild.net first, sovereign S3 cache second, cache.nixos.org third).
- Add a post-deploy push hook on both hosts so deployed generations land in the cache without manual CLI steps.
- Keep CI out of the cache push path — hosts own push authority; CI only builds via nixbuild.net.

## Capabilities

### New Capabilities
- `sovereign-binary-cache`: The niks3 server, Postgres, S3 backing, signing, GC, and token-based auth surface for a self-hosted Nix binary cache that does not require a public HTTP cache endpoint.
- `cache-push-workflow`: Host-side post-deploy push of verified closures into the sovereign cache using host-scoped API tokens.

### Modified Capabilities
- `nixbuild-build-plane`: Substituter priority now includes the sovereign S3 cache as a durable secondary tier; the primary CI build plane contract is unchanged.
- `fleet-infrastructure`: `oci-melb-1` gains new infrastructure components (niks3 service, shared PostgreSQL) that other hosts do not replicate.
- `secrets-management`: Host-scoped secrets now include niks3 API tokens and server-side signing key material scoped to the cache host.

## Impact

- Affected code paths:
  - `hosts/oci-melb-1/default.nix` — new niks3 service module, shared PostgreSQL enablement
  - `policy/globals.nix` — substituter lists and trusted public keys updated
  - `modules/profiles/base-server.nix` — inherits updated policy values (no structural change)
  - `secrets/hosts/oci-melb-1/system.yaml` — signing key, niks3 server API token
  - `secrets/hosts/do-admin-1/system.yaml` — host-scoped niks3 push API token
  - `.sops.yaml` — updated with `secrets/services/niks3.yaml` service scope rule
  - New: `modules/services/niks3.nix` — NixOS service module for niks3 server
- Affected specs:
  - New: `sovereign-binary-cache/spec.md`
  - New: `cache-push-workflow/spec.md`
  - Modified: `nixbuild-build-plane/spec.md`
  - Modified: `fleet-infrastructure/spec.md`
  - Modified: `secrets-management/spec.md`
- Operational impact:
  - Fleet gains a sovereign durable cache layer without adding public HTTP endpoints.
  - Hosts gain an automated post-deploy push path for cache warming.
  - Postgres is introduced as a shared platform service on `oci-melb-1` only; other hosts are not affected.
  - CI and local operator workflows are unchanged beyond the new substituter order.

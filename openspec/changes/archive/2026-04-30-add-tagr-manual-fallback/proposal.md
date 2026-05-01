## Why

SoulSync and beets cover automated ingest plus rescue, but we still lack a focused manual web UI for correcting bad covers, unknown artists/albums, and metadata drift after import. We need a lightweight Tagr path now so operators can quickly repair problematic tracks without changing the current primary ingest architecture.

**Core Value:** Add a clear manual tagging fallback while preserving the existing SoulSync-primary flow, canonical media paths, and private-first edge posture.

## What Changes

- Add a new Tagr service module on `oci-melb-1` using the upstream container image and explicit media/data path wiring.
- Wire Tagr into `modules/applications/music.nix` as an optional host-secret-gated fallback service.
- Add host-scoped Tagr secrets/templates for auth/session configuration.
- Expose Tagr through canonical `do-admin-1` edge routing using `tailscale-upstream` with Cloudflare Access and AOP.
- Add Tagr into admin homepage navigation as an operator-facing fallback tool link.
- Update architecture/docs language to reflect Tagr as manual fallback for metadata and cover repair.

## Capabilities

### New Capabilities
- `tagr-manual-fallback`: Provide a host-run Tagr web UI fallback for manual metadata and artwork correction on existing media paths.

### Modified Capabilities
- `media-services`: Extend music composition contracts to include Tagr as a manual fallback service that operates on canonical media paths.
- `edge-proxy-ingress`: Add canonical policy/route support for `tagr` as an Access-gated `tailscale-upstream` service.
- `admin-services`: Add Tagr to admin homepage service navigation for operator workflow visibility.
- `secrets-management`: Add host-scoped secret requirements for Tagr auth/session values on `oci-melb-1`.

## Impact

- **Affected code**: `modules/services/`, `modules/applications/music.nix`, `hosts/oci-melb-1/default.nix`, `hosts/oci-melb-1/secrets.template.yaml`, `policy/web-services.nix`, `modules/services/admin/homepage/data.nix`, `docs/architecture.md`.
- **Operational impact**: Operators gain a dedicated manual fallback editor for bad metadata/album-art outcomes without replacing SoulSync/beets role boundaries.
- **Security impact**: Tagr credentials remain host-scoped and route exposure follows existing Access + AOP + private-upstream policy.
- **Risk boundary**: No change to canonical ingest/promotion path ownership; Tagr is fallback tooling only.

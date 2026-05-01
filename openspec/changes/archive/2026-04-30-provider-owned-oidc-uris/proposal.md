## Why

OIDC URI derivation (issuer, well-known, authorization, token, userinfo endpoints) was duplicated across host configs and module consumers instead of being owned and emitted by the identity provider module as a single source of truth. This change eliminates that duplication by having the Pocket ID module derive canonical OIDC URIs from its own `appUrl` and emit them as read-only outputs that consumers reference directly.

**Core Value:** Move OIDC URI ownership into the provider module so consumers stay DRY and operators update exactly one `appUrl` when the identity provider changes.

## What Changes

- Add `mkOidcEndpoints` helper to `lib/policy.nix` that derives the five canonical OIDC endpoints from an issuer base URL.
- Extend `modules/services/admin/pocket-id.nix` to emit read-only `oidc.*` outputs (issuerUrl, wellknownUrl, authorizationUrl, tokenUrl, userinfoUrl) derived from its own `appUrl`.
- Switch `modules/applications/admin/default.nix` Termix and Quantum OIDC wiring to consume `config.services.admin.pocket-id.oidc.issuerUrl` instead of calculating from `pocketIdBaseUrl` in-place.
- Switch `hosts/do-admin-1/secrets.nix` termix-oidc.env template to use `config.services.admin.pocket-id.oidc.*` for all endpoint values.
- Switch `hosts/oci-melb-1/default.nix` Karakeep OIDC `wellknownUrl` to use `pocketIdOidc` derived from policy services via `mkOidcEndpoints`.

## Capabilities

### New Capabilities
- `provider-owned-oidc-uris`: Pocket ID module SHALL own and emit its OIDC endpoint URIs as a read-only single source of truth, and consumer services SHALL reference those outputs rather than independently constructing OIDC URIs.

### Modified Capabilities
- `secrets-management`: OIDC-related env template assembly in host configs SHALL consume provider-owned endpoint outputs rather than independently reconstructing OIDC URIs.
- `admin-service-consolidation`: Admin application composition SHALL source OIDC issuer configuration from the Pocket ID module's read-only outputs rather than deriving from `policyServices` in-place.

## Impact

- **Affected code**: `lib/policy.nix`, `modules/services/admin/pocket-id.nix`, `modules/applications/admin/default.nix`, `hosts/do-admin-1/secrets.nix`, `hosts/oci-melb-1/default.nix`.
- **Operational impact**: Changing the Pocket ID public URL now updates all consumer OIDC endpoints through a single `appUrl` value — no more chasing host-local copies.
- **Security impact**: No blast-radius change; OIDC endpoints were already the same read-only URIs, just centralized now.
- **Risk boundary**: Pocket ID module's `oidc.*` outputs are read-only and derived deterministically from `appUrl`; no new side-effects.

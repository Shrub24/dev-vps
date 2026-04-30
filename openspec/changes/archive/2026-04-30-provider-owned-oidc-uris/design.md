## Context

Before this change, OIDC endpoint URIs (issuer, well-known, authorization, token, userinfo) were independently reconstructed in multiple places from the Pocket ID `publicUrl`. This created drift risk and made the identity provider's public URL a multi-site change.

The Pocket ID module already owns its `appUrl` as the external reachable URL. It should also own the derived OIDC endpoints since those are mechanically determined by the issuer URL.

## Goals / Non-Goals

**Goals:**
- Pocket ID module emits read-only `oidc.*` outputs (issuerUrl, wellknownUrl, authorizationUrl, tokenUrl, userinfoUrl) derived from `appUrl`.
- All existing OIDC consumers (Termix, Quantum, Karakeep, admin env templates) pull from the provider-owned outputs rather than rebuilding URIs locally.
- Provide a reusable `mkOidcEndpoints` helper in `lib/policy.nix` for consistent derivation.

**Non-Goals:**
- Do not change the Pocket ID OIDC protocol or endpoint paths.
- Do not introduce new OIDC consumers or providers in this change.

## Decisions

- **PROV-1 (Emission model):** Pocket ID module emits `oidc.*` as read-only `mkOption` values computed from `appUrl` via `mkOidcEndpoints`.
  - **Rationale:** Read-only options prevent accidental overrides while making the values inspectable through Nix's option system.
  - **Alternative considered:** Emitting as a plain attrset on `config.services.admin.pocket-id` without `mkOption` wrapping; rejected because it hides the values from `nixos-option`/eval inspection.

- **PROV-2 (Helper location):** Place `mkOidcEndpoints` in `lib/policy.nix`, not inline in the Pocket ID module.
  - **Rationale:** `lib/policy.nix` already hosts shared derivation functions and is importable by any module that needs OIDC endpoint construction. Karakeep's host config uses it to derive from policy service URLs.
  - **Alternative considered:** Inline in `pocket-id.nix` only; rejected because Karakeep needs endpoint derivation from a policy-resolved URL, not the module's own `appUrl`.

- **PROV-3 (Consumer migration):** Switch all consumers simultaneously — no gradual rollout.
  - **Rationale:** The derived values are mechanically identical (same appUrl → same endpoints). No behavioral change, so a single atomic switch is safe.
  - **Alternative considered:** Staged migration per consumer; rejected as unnecessary given the deterministic derivation.

## Risks / Trade-offs

- **[R1] Pocket ID appUrl misconfiguration now affects all OIDC consumers silently** → **Mitigation:** Already true before the change; the SSOT pattern makes misconfiguration more visible by centralizing the derivation point.
- **[R2] `mkOidcEndpoints` encodes Pocket ID-specific paths** → **Mitigation:** The helper's name is generic but its paths are Pocket ID-specific. If a second IdP is added, a more generic or parameterized helper should replace or extend this one.

## Migration Plan

All changes were applied together in a single atomic refactor:
1. Added `mkOidcEndpoints` to `lib/policy.nix`.
2. Updated `pocket-id.nix` to emit `oidc.*` read-only outputs.
3. Switched `modules/applications/admin/default.nix` Termix/Quantum to use `config.services.admin.pocket-id.oidc.issuerUrl`.
4. Updated `hosts/do-admin-1/secrets.nix` termix-oidc.env to use `config.services.admin.pocket-id.oidc.*`.
5. Switched `hosts/oci-melb-1/default.nix` Karakeep to derive `pocketIdOidc` via `mkOidcEndpoints` from policy.

Rollback: Revert each consumer to its previous inline `pocketIdBaseUrl` derivation and remove the `mkOidcEndpoints` helper if no consumers remain.

## Open Questions

None remaining — change is implemented and validated.

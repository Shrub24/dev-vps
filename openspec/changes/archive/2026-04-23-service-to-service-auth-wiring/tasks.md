## 1. Caller-owned Homepage auth wiring

- [x] 1.1 Add host-scoped Homepage integration secret definitions and placeholders in `hosts/do-admin-1/secrets.nix` and `hosts/do-admin-1/secrets.template.yaml` (Tailscale, Navidrome, slskd, Beszel).
- [x] 1.2 Add a dedicated Homepage SOPS template env file and wire it to `services.homepage-dashboard.environmentFiles` in `modules/services/admin/homepage/default.nix`.
- [x] 1.3 Add declarative assertions for required Homepage auth template inputs when authenticated widgets are enabled.

## 2. Homepage integration behavior updates

- [x] 2.1 Update `modules/services/admin/homepage/data.nix` to wire Beszel widget username/password placeholders and retain existing Tailscale/Navidrome/slskd placeholders.
- [x] 2.2 Preserve explicit auth exceptions for Caddy (local no-auth) and keep Gatus URL-only/read-only posture.
- [x] 2.3 Keep Filebrowser widget auth out of scope for this wave and ensure no new Filebrowser machine-auth contract is introduced.

## 3. Beszel bootstrap and operational checks

- [x] 3.1 Document one-time Beszel manual bootstrap steps (dedicated read-only Homepage account + explicit system sharing scope).
- [x] 3.2 Validate evaluation and contracts with `nix flake check` and targeted `nix eval` checks for Homepage env-file wiring and required placeholders.
- [x] 3.3 Verify no new shared secrets were introduced in `secrets/common.yaml` and all new caller credentials remain host-scoped.

## 4. Beszel agent host-scoped auth wiring

- [x] 4.1 Add host-scoped Beszel agent secret placeholders to `hosts/oci-melb-1/secrets.template.yaml` (KEY/TOKEN) and wire matching `sops.secrets` + `sops.templates` in `hosts/oci-melb-1/default.nix`.
- [x] 4.2 Enable and configure `services.beszel.agent` on `oci-melb-1` using the rendered environment file; keep credentials out of shared/common secret scope.
- [x] 4.3 Add declarative assertions on `oci-melb-1` so Beszel agent env wiring is required when the agent is enabled.
- [x] 4.4 Validate with targeted `nix eval` for agent enablement + environmentFile path and verify no Beszel agent credentials were added to `secrets/common.yaml`.

## 5. Beszel agent module modularization (per-host configurable)

- [x] 5.1 Extract Beszel agent auth/secrets wiring into a reusable service module under `modules/services/` with host-configurable enable + secret-source paths.
- [x] 5.2 Replace `hosts/oci-melb-1/default.nix` bespoke Beszel agent block with module options (preserve current behavior for `oci-melb-1`).
- [x] 5.3 Validate targeted `nix eval` for `oci-melb-1` agent enablement + environment file path and ensure host-scoped secret posture remains unchanged.

## 6. do-admin-1 enrollment + template cleanup

- [x] 6.1 Enable reusable Beszel agent auth module on `do-admin-1` with host-scoped secret source.
- [x] 6.2 Add Beszel agent placeholders to `hosts/do-admin-1/secrets.template.yaml`.
- [x] 6.3 Remove unused Cloudflare Access OIDC placeholders from `hosts/do-admin-1/secrets.template.yaml` while retaining required Cloudflare DNS token placeholders.

## 7. Beszel universal token flow

- [x] 7.1 Move Beszel agent KEY/TOKEN placeholders to `secrets/common.template.yaml` and remove per-host Beszel agent placeholders from host templates.
- [x] 7.2 Update `modules/services/beszel-agent-auth.nix` to source Beszel agent secrets from common scope by default (no host-specific `sopsFile` requirement).
- [x] 7.3 Update host configs (`do-admin-1`, `oci-melb-1`) to consume universal-token module wiring without host-specific Beszel token source configuration.
- [x] 7.4 Validate with targeted `nix eval` for both hosts (`services.beszel.agent.enable` and `environmentFile`) and confirm no remaining Beszel agent token keys in host templates.

## 8. Beszel SSH-first per-host token transition

- [x] 8.1 Move Beszel `KEY` placeholder to `secrets/common.template.yaml` and reintroduce host-scoped Beszel `TOKEN` placeholders in `hosts/do-admin-1/secrets.template.yaml` and `hosts/oci-melb-1/secrets.template.yaml`.
- [x] 8.2 Update `modules/services/beszel-agent-auth.nix` so `KEY` sources from common scope while `TOKEN` sources from configurable host-scoped `sopsFile`.
- [x] 8.3 Update host configs (`do-admin-1`, `oci-melb-1`) to provide host token `sopsFile` for the shared Beszel agent module.
- [x] 8.4 Validate with targeted `nix eval` for both hosts and confirm templates/spec texts align with shared KEY + per-host TOKEN model.

## 9. Homepage authenticated Gatus integration

- [x] 9.1 Add dedicated Homepage->Gatus machine auth placeholders in `hosts/do-admin-1/secrets.template.yaml` and wire matching host-scoped secrets/template vars in `hosts/do-admin-1/secrets.nix`.
- [x] 9.2 Replace Homepage URL-only Gatus widget in `modules/services/admin/homepage/data.nix` with authenticated request-capable widget config against Gatus API status endpoint.
- [x] 9.3 Ensure Gatus service security wiring supports Homepage machine credentials without disabling existing OIDC posture.
- [x] 9.4 Validate with targeted `nix eval` for Homepage config render + Gatus service config and confirm no unauthenticated Homepage Gatus API path remains.

## 10. Homepage-Gatus single-secret derivation

- [x] 10.1 Remove stored `gatus/homepage/password_bcrypt_base64` secret wiring and template placeholder, keeping only one stored Homepage-Gatus plaintext password secret.
- [x] 10.2 Update `hosts/do-admin-1/secrets.nix` template wiring to derive `GATUS_HOMEPAGE_BASIC_PASSWORD_BCRYPT_BASE64` from `homepage_gatus_password` at render time.
- [x] 10.3 Validate with targeted `nix eval` that Gatus security basic auth remains configured and Homepage still receives plaintext machine credentials from the same secret source.

## 11. do-admin-1 Cloudflare Access secret cleanup

- [x] 11.1 Remove unused `cloudflare_access/upstream_oidc/*` secret declarations from `hosts/do-admin-1/secrets.nix` while preserving required Cloudflare DNS token wiring for edge ingress.

## 12. Homepage Gatus bearer-token auth alignment

- [x] 12.1 Add host-scoped Homepage Gatus API token placeholder in `hosts/do-admin-1/secrets.template.yaml` and wire matching secret/template var in `hosts/do-admin-1/secrets.nix`.
- [x] 12.2 Update Homepage Gatus `customapi` widget in `modules/services/admin/homepage/data.nix` to send `Authorization: Bearer ...` header and remove username/password auth fields.
- [x] 12.3 Remove Gatus homepage basic-auth derivation/wiring in `modules/services/admin/gatus/default.nix` and admin identity linkage where no longer needed.
- [x] 12.4 Validate with targeted `nix eval` that Homepage renders bearer header config, Gatus security remains valid, and no stale Homepage Gatus basic-auth secret keys remain referenced.

## 13. Gatus auth simplification (Cloudflare for humans, local no-auth API)

- [x] 13.1 Remove app-native Gatus OIDC credential wiring from host/admin identity paths and drop unused Gatus OIDC secret/template inputs.
- [x] 13.2 Update Gatus service wiring to explicit loopback bind (`127.0.0.1`) with no app-level OIDC/basic/bearer auth block for local API use.
- [x] 13.3 Replace Homepage Gatus widget config to use no-auth local API/widget path and remove bearer token header usage.
- [x] 13.4 Validate rendered config (`nix eval`) for loopback bind + endpoint presence + Homepage Gatus config and confirm stale Gatus bearer/OIDC secret references are removed.

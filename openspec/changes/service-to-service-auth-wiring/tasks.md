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

- [x] 4.1 Add host-scoped Beszel agent secret placeholders to `hosts/oci-melb-1/secrets.template.yaml` (KEY/TOKEN/HUB_URL) and wire matching `sops.secrets` + `sops.templates` in `hosts/oci-melb-1/default.nix`.
- [x] 4.2 Enable and configure `services.beszel.agent` on `oci-melb-1` using the rendered environment file; keep credentials out of shared/common secret scope.
- [x] 4.3 Add declarative assertions on `oci-melb-1` so Beszel agent env wiring is required when the agent is enabled.
- [ ] 4.4 Validate with targeted `nix eval` for agent enablement + environmentFile path and verify no Beszel agent credentials were added to `secrets/common.yaml`.

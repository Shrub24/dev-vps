## 1. Baseline and module skeleton

- [x] 1.1 Confirm `migrate-nixpkgs-unstable-default` is complete and branch baseline is current before starting this refactor.
- [x] 1.2 Create `modules/applications/admin/` entrypoint structure (`default.nix` plus composition helpers) while preserving the `applications.admin.enable` and `applications.admin.dataRoot` contract.
- [x] 1.3 Create `modules/services/admin/` namespace with initial per-service module files and subdirectories for complex services.

## 2. Move admin service ownership to service-level modules

- [x] 2.1 Move service wiring for Cockpit, Webhook, Ntfy, Vaultwarden, Filebrowser, Homepage Dashboard, and Beszel hub from monolithic admin module to service-owned admin modules.
- [x] 2.2 Keep custom service modules (`termix`, `pocket-id`) integrated via the new admin composition layer without changing functional behavior.
- [x] 2.3 Move shared runtime glue (tmpfiles/systemd/environment wiring) to the owning service module or clearly scoped composition helper.
- [x] 2.4 Keep cockpit module migrated but set host-level cockpit enable to false as a documented temporary upstream exception.

## 3. Implement policy-derived Gatus monitoring

- [x] 3.1 Add Gatus endpoint generation from resolved host services in `policy/web-services.nix` using `lib/policy.nix` helpers.
- [x] 3.2 Ensure generated checks apply policy health defaults when explicit per-service health overrides are absent.
- [x] 3.3 Preserve monitor-all behavior for resolved services in this phase (no policy monitor toggle in this change).

## 4. Consolidate SSOT for domain/routes/ports

- [x] 4.1 Define and consume the primary domain (`shrublab.xyz`) from one canonical policy/config location instead of repeating literals across modules.
- [x] 4.2 Ensure subdomain and route path metadata remain authoritative in `policy/web-services.nix` and are consumed by edge and monitoring outputs.
- [x] 4.3 Ensure service origin ports are authored once in canonical policy metadata and consumed via policy projections in module wiring.
- [x] 4.4 Extend `lib/policy.nix` helper projections as needed so downstream modules do not need ad-hoc duplicated transforms.

## 5. Split Homepage payload and preserve presentation ownership

- [x] 5.1 Move large Homepage layout/services/bookmarks payloads into homepage-owned adjacent data files under the Homepage service subdirectory.
- [x] 5.2 Keep Homepage presentation metadata independent from `policy/web-services.nix` derivation.
- [x] 5.3 Drive app-level OIDC enablement from `policyServices.<service>.access.oidc.enabled` gated by `services.admin.<service>.enable` and required secret template presence.

## 6. Light split of do-admin-1 host glue

- [x] 6.1 Split `hosts/do-admin-1/default.nix` into focused imports for `secrets.nix`, `edge.nix`, and `networking.nix`.
- [x] 6.2 Keep `default.nix` as host assembly entrypoint and preserve existing edge route resolution behavior.
- [x] 6.3 Preserve host-scoped secret/template ownership and current private-first networking posture after the split.

## 7. Validation and documentation alignment

- [x] 7.1 Run `nix fmt` and evaluate the target host configuration to verify the refactor does not change intended behavior.
- [x] 7.2 Run `nix flake check` and resolve any failures introduced by module moves/splits.
- [x] 7.3 Run `openspec validate --strict` and ensure this change remains apply/validate clean.
- [x] 7.4 Update relevant docs (`docs/architecture.md`, `docs/decisions.md`, or related references) if module/layout navigation guidance changed.

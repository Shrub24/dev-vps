## 1. Topology and helper foundations

- [x] 1.1 Finalize the canonical feature namespace and enablement rules for applications and standalone services, and remove mixed or hidden activation paths that conflict with the new topology.
- [x] 1.2 Add a light helper library for reusable secret-contract option declarations, assertions, and `sops.secrets` / `sops.templates` registration patterns.
- [x] 1.3 Add or normalize a canonical non-secret defaults source for shared feature defaults, and wire applications/services to consume it with host-overridable semantics.

## 2. Secret scope and recipient-policy migration

- [x] 2.1 Create the new secrets bucket structure for application scopes, standalone service scopes, and host exception scopes.
- [x] 2.2 Update `.sops.yaml` path rules to match the new bucket model and preserve explicit blast-radius boundaries.
- [x] 2.3 Implement or wire validation for normal feature-derived reader sets plus explicit exception-reader handling.
- [x] 2.4 Move existing secret material out of monolithic host buckets into the new application/service/host-exception scopes without preserving dual-path compatibility.

## 3. Migrate the music application as the first full pilot

- [x] 3.1 Refactor `applications.music` into the canonical composition-root pattern with shared paths, assertions, and explicit secret contract inputs.
- [x] 3.2 Move music-stack secret/template ownership from host files into the owning music application and leaf service modules.
- [x] 3.3 Re-home music-related secret data into `secrets/applications/music.yaml` and any required host exception scopes.
- [x] 3.4 Thin the `oci-melb-1` host layer so music wiring is expressed through feature enables, secret bindings, and narrow host-only overrides.

## 4. Migrate admin and remaining composed feature stacks

- [x] 4.1 Refactor `applications.admin` to the same composition-root pattern, including shared admin defaults and composition-owned secret inputs.
- [x] 4.2 Move admin secret/template ownership from host files into owning application/service modules.
- [x] 4.3 Re-home admin secret data into `secrets/applications/admin.yaml` and any required host OIDC/system exception scopes.
- [x] 4.4 Thin the `do-admin-1` host layer so admin wiring is expressed through feature enables, secret bindings, and narrow host-only overrides.

## 5. Migrate singleton services and remaining leaf contracts

- [x] 5.1 Convert singleton services that still depend on host-owned secret/template wiring to leaf-owned contracts using explicit `secretFiles.*` / `secretKeys.*` inputs.
- [x] 5.2 Keep Karakeep as a standalone leaf service and move its runtime secret ownership to service-scoped secret files/contracts.
- [x] 5.3 Re-home true standalone secret data into `secrets/services/*.yaml` only where no application scope is the correct owner.

## 6. Remove legacy patterns and finish repository cleanup

- [x] 6.1 Remove legacy monolithic host secret files as the primary canonical secret buckets.
- [x] 6.2 Remove host-owned application-internal `sops.secrets`, `sops.templates`, tmpfiles, ACL glue, and mixed composition patterns that are superseded by the new topology.
- [x] 6.3 Remove any compatibility aliases, duplicate option paths, or transitional imports that would preserve the old model.

## 7. Validation and documentation alignment

- [x] 7.1 Run `nix fmt` and fix formatting across all moved or rewritten Nix files.
- [x] 7.2 Run `nix flake check` and targeted host evaluations for `oci-melb-1` and `do-admin-1` to verify the refactor preserves intended behavior.
- [x] 7.3 Run or update relevant contract tests and secret-policy checks for feature enablement, secret placement, and host thinning.
- [x] 7.4 Update canonical docs (`docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, and related navigation guidance) to reflect the new feature-oriented topology and secret structure.
- [x] 7.5 Run `openspec validate --strict` and ensure the change is fully valid before implementation closeout.

## 8. OIDC follow-up after secret-topology refactor

- [x] 8.1 Extend the change artifacts to capture the provider-owned OIDC URI follow-up and the requirement to preserve composition-layer env-file handoff for leaf-owned OIDC templates.
- [x] 8.2 Restore admin composition wiring so Termix and Quantum receive their resolved OIDC environment-file paths while leaf modules keep ownership of OIDC secrets/templates sourced from host `oidc.yaml` scopes.
- [x] 8.3 Extract `mkOidcEndpoints` into `lib/policy.nix` and update Pocket ID plus Karakeep wiring to reuse the shared helper-derived OIDC endpoints.
- [x] 8.4 Re-run strict OpenSpec validation plus targeted Nix validation to confirm the OIDC regression is closed without violating the secret-topology refactor.
- [x] 8.5 Restore `do-admin-1` Beszel agent auth enablement so the host-scoped token from `secrets/hosts/do-admin-1/system.yaml` is wired back into the leaf-owned `beszel-agent.env` contract after host thinning.
- [x] 8.6 Clean up Karakeep and Beszel follow-up fixes so they use canonical helper-based secret contracts, self-describing code, and no leftover inline implementation comments or legacy-shaped option defaults.

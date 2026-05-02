## Context

The current repository already has the right high-level layers (`hosts/`, `modules/applications/`, `modules/services/`, `policy/`, `lib/`), but the boundaries are still uneven in practice. Hosts still carry a meaningful amount of feature wiring, tmpfiles/ACL glue, and large `sops.secrets` / `sops.templates` blocks. Secret storage is also biased toward monolithic host buckets, which makes feature ownership harder to follow and keeps host files as the de facto integration point for application internals.

The desired end state is a clean feature-oriented topology:
- hosts are thin assembly entrypoints,
- applications are the canonical composition roots for multi-service stacks,
- singleton workloads remain leaf services,
- leaf modules own secret/runtime contracts,
- secret scope follows actual feature topology rather than a second manually curated consumer model.

This is a cross-cutting architectural refactor affecting both active hosts, multiple application stacks (`music`, `admin`), singleton services such as Karakeep, `.sops.yaml` policy structure, and repository navigation/documentation. It also needs to preserve the repo’s operational constraints: plain flake architecture, explicit blast-radius control, Tailscale-first private access, and clean reproducibility across `aarch64-linux` and `x86_64-linux` hosts.

## Goals / Non-Goals

**Goals:**
- Normalize feature enablement so every application entrypoint exposes `applications.<name>.enable` and standalone workloads expose `services.<domain>.<name>.enable` (or a finalized equivalent namespace chosen in this change).
- Make `hosts/<host>/default.nix` and any host-adjacent split files thin, focused assembly layers.
- Move service/application integration logic out of hosts and into owning application/service modules.
- Introduce topology-aligned secret buckets:
  - `secrets/applications/<name>.yaml`
  - `secrets/services/<name>.yaml`
  - `secrets/hosts/<host>/system.yaml`
  - `secrets/hosts/<host>/oidc.yaml`
- Standardize leaf secret contracts around explicit `secretFiles.*` and `secretKeys.*` inputs with a light helper library for common SOPS patterns.
- Derive normal secret recipient scope from normalized feature enablement, while keeping explicit exception handling for cross-host readers.
- Preserve public repo/operator interfaces (`nixosConfigurations.<host>`, `deploy.nodes.<host>`, `checks.<system>.*`, `devShells.<system>.default`, `formatter.<system>`, `just` workflows) while removing internal legacy patterns.
- Use `music` as the first full end-to-end migration slice, then complete the same pattern across the rest of the repo in this change.

**Non-Goals:**
- Adopting `flake-parts`, Dendritic Nix, or changing the plain flake entrypoint architecture.
- Replacing host recipients with application-owned runtime identities or introducing Vault/ESO-style runtime secret infrastructure.
- Changing provider/storage/bootstrap strategy beyond what is required to thin hosts and relocate secret/feature ownership.
- Preserving backward-compatibility aliases, dual secret bucket models, or long-lived migration shims.
- Forcing singleton services into application wrappers when no real composition value exists.

## Decisions

### Decision FT-1: Keep the plain explicit flake architecture
- **Chosen:** keep `flake.nix` explicit and unchanged in architectural role.
- **Why:** the problem being solved is feature ownership and host/secret topology, not flake-output composition.
- **Alternatives considered:**
  - Adopt `flake-parts` during the same change: rejected as scope inflation and a second architectural migration.
  - Dendritic/aspect-oriented rewrite: rejected for this change because the user explicitly reset scope to feature topology without `flake-parts`.

### Decision FT-2: Applications are composition roots; singleton workloads remain leaf services
- **Chosen:** `modules/applications/*` are used only when they add real composition value (shared paths, assertions, secrets, tmpfiles, multi-service wiring, one operator-facing stack toggle). Singleton services stay leaf services.
- **Why:** this keeps the application layer meaningful instead of turning it into taxonomy-only indirection.
- **Alternatives considered:**
  - Wrap every service in an application module: rejected as unnecessary ceremony.
  - Keep the current mixed approach with hidden leaf imports and ad hoc host glue: rejected because it prevents enablement from being a clean topology SSOT.

### Decision FT-3: Hosts become thin assembly layers
- **Chosen:** hosts primarily declare identity, facts, provider/storage/profile imports, feature enables, secret source bindings, and narrow host-only overrides.
- **Why:** hosts should express “what this machine is” rather than “how every internal stack is wired.”
- **Alternatives considered:**
  - Keep heavy host files but split them cosmetically: rejected because it preserves the wrong ownership boundary.
  - Push all customization into global defaults: rejected because host-specific overrides still need an explicit home.

### Decision FT-4: Secret scope follows topology with explicit exception buckets
- **Chosen:** replace the default `common + host monolith` model with application-scoped, standalone-service-scoped, and narrow host-exception-scoped secret files.
- **Why:** this aligns secret ownership with real feature ownership while still encrypting directly to host/admin recipients.
- **Alternatives considered:**
  - Keep monolithic `hosts/<host>/secrets.yaml`: rejected because it leaves secret ownership host-centric even when runtime ownership is feature-centric.
  - Introduce app-specific private keys or non-host principals: rejected because hosts are the actual decryption/runtime principals in this repo.

### Decision FT-5: Leaf modules own secret contracts; applications satisfy them through explicit contract inputs
- **Chosen:** leaves own semantic secret registration, templates, assertions, path/mode/owner behavior, and runtime wiring. Applications may provide `secretFiles.*` / `secretKeys.*` values but do not override raw `sops.secrets.<name>` internals as the primary pattern.
- **Why:** this preserves encapsulation and keeps secret schema changes local to the owning module.
- **Alternatives considered:**
  - Application modules directly mutate leaf `sops.secrets` internals: rejected as brittle coupling.
  - Hosts continue owning rendered templates and secret registration: rejected because it keeps application internals in host files.

### Decision FT-6: Use a light helper library for repeated secret-contract patterns
- **Chosen:** add a small reusable helper layer for common option declarations, assertions, and secret/template registration patterns.
- **Why:** many services will need the same contract shape, and repeating boilerplate in every module increases drift risk.
- **Alternatives considered:**
  - No helper library: rejected because the repo will repeat the same SOPS contract patterns many times.
  - Heavy DSL/framework: rejected as too magical for this repo’s simplicity goals.

### Decision FT-7: Derive normal secret readers from feature enablement
- **Chosen:** normal application/service secret recipient membership derives from normalized host enablement, with only a small explicit exception map for cross-host readers such as OIDC handshake material.
- **Why:** host composition should remain the SSOT rather than introducing a second broad inventory of secret consumers.
- **Alternatives considered:**
  - Manual `.sops.yaml` maintenance only: rejected because it is easy to drift from real topology.
  - Full explicit secret-consumer inventory for every feature: rejected as redundant state.

### Decision FT-8: Keep host exception scopes narrow and explicit
- **Chosen:** `secrets/hosts/<host>/system.yaml` is reserved for host/bootstrap/system-only material; `secrets/hosts/<host>/oidc.yaml` is reserved for host exception identity handshakes that may need explicit extra readers.
- **Why:** this preserves explicit blast-radius control for the few cases that should not derive purely from feature enablement.
- **Alternatives considered:**
  - Put all OIDC material in application scopes: rejected because cross-host identity handshakes sometimes need a distinct reader set from normal feature enablement.
  - Keep all exception material in broad host monoliths: rejected because it recreates the structure this change is trying to remove.

### Decision FT-8a: Preserve composition-layer OIDC env-file handoff while leaves own OIDC templates and secrets
- **Chosen:** when a leaf service owns its OIDC template/secrets contract but requires a resolved env-file path as input, the owning application composition layer passes that resolved `sops.templates.*.path` into the leaf rather than pushing that handoff back into hosts or duplicating template ownership in the application.
- **Why:** this preserves the FT-5 leaf-owned secret-contract rule while keeping application composition responsible for multi-service wiring and preventing host-local OIDC glue from reappearing.
- **Alternatives considered:**
  - Have hosts wire leaf OIDC env files directly: rejected because it violates the thin-host boundary.
  - Have applications own leaf `sops.templates` internals directly: rejected because it breaks leaf encapsulation and repeats brittle coupling.

### Decision FT-8b: Centralize provider-owned OIDC endpoint derivation in shared policy helpers
- **Chosen:** derive canonical OIDC endpoints through a shared `mkOidcEndpoints` helper in `lib/policy.nix`, with Pocket ID exposing those endpoints as read-only outputs and downstream consumers reusing the same derivation.
- **Why:** the refactor must not reintroduce duplicated URL interpolation or drift between Pocket ID, admin consumers, and Karakeep.
- **Alternatives considered:**
  - Keep private per-module OIDC endpoint builders: rejected because it invites divergence and caused ambiguity during regression analysis.
  - Hardcode consumer-specific well-known URLs: rejected because it violates provider-owned OIDC URI requirements.

### Decision FT-9: Perform a clean cutover without compatibility layers
- **Chosen:** remove old enablement paths, legacy host secret buckets as primary storage, and compatibility aliases/shims in the same change.
- **Why:** the repo is not a live production system, and carrying both models would prolong confusion.
- **Alternatives considered:**
  - Preserve dual paths or aliases temporarily: rejected because it undermines the point of a canonical topology reset.

## Risks / Trade-offs

- **[Risk] Large structural churn can hide behavior regressions** → **Mitigation:** migrate in deliberate slices (`music` first), keep validations running after each slice, and preserve top-level host/deploy/check interfaces throughout.
- **[Risk] Derived recipient logic can become opaque** → **Mitigation:** keep derivation inputs explicit (`applications.*.enable`, `services.*.enable`), keep exception maps small, and add validation/linting that explains computed readers.
- **[Risk] Namespace cleanup could create unnecessary churn** → **Mitigation:** define the target namespace up front, but restrict renames to paths/options that materially improve topology clarity.
- **[Risk] Application/service ownership boundaries remain fuzzy in edge cases** → **Mitigation:** encode the rule in specs and tasks: applications compose; leaves implement; singleton services do not get wrappers without composition value.
- **[Risk] Secret-file reorganization could broaden access accidentally** → **Mitigation:** update `.sops.yaml` and secret file moves together, verify reader sets explicitly, and preserve host exception scopes for any non-derived readers.
- **[Risk] Host thinning could over-centralize defaults and hide necessary host differences** → **Mitigation:** use a global defaults attrset only for non-secret defaults and keep narrow host-level overrides first-class.
- **[Risk] Both hosts may diverge during the migration** → **Mitigation:** treat `music` as the first pattern-establishing slice, then finish admin/standalone migrations in the same change before closing it.

## Migration Plan

1. Normalize the target topology and namespace rules in specs before implementation.
2. Add the helper library and canonical contract shapes for `secretFiles.*` / `secretKeys.*`.
3. Introduce the new secrets directory structure and update `.sops.yaml` to support application/service/host-exception scopes.
4. Migrate `music` end-to-end first: secret buckets, application composition, leaf secret ownership, host thinning, and validation.
5. Apply the same pattern across `admin` and any remaining feature stacks that still depend on host-owned secret/template glue.
6. Migrate true singleton workloads (for example Karakeep and other standalone services) to leaf-owned contracts with service-scoped secret files where appropriate.
7. Remove legacy host secret buckets, legacy host-owned template/secret wiring, and mixed enablement/import-only activation paths.
8. Update docs and contract tests, then validate the whole change with OpenSpec and Nix checks.
9. Apply a targeted OIDC follow-up pass to ensure the topology/secret migration preserves provider-owned OIDC URI wiring, host OIDC exception scoping, and composition-layer env-file handoff semantics for existing consumers.

Rollback:
- Revert the change before deployment if validations fail during implementation.
- If a partial deployment has been applied to a host, roll back to the previous NixOS generation and restore the previous secret path layout from Git history.

## Open Questions

- Should feature-to-reader derivation generate `.sops.yaml` entries directly, or should it remain a validation/lint layer over committed path rules?
- What is the final preferred namespace shape for singleton services that currently live in mixed top-level option trees (`services.karakeep-oci`, `services.admin.*`, etc.)?

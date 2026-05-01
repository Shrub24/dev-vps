## Context

The repo is starting to accumulate services that want AI inference through an OpenAI-compatible endpoint but do not all share the same provider or model needs. Karakeep is the immediate pressure point: it can select separate text, image, and embedding model names, but only one provider base URL. A gateway solves that interface mismatch, but only if the gateway itself fits the repo’s source-of-truth rules.

Upstream Bifrost is unusually plausible for this repo because it supports documented file-driven `config.json` mode and publishes deployment paths that can run cleanly on ARM hosts. However, Bifrost also has a UI/config-store mode backed by mutable database state. That creates an architecture fork: either treat Bifrost as a repo-owned declarative service with mutable runtime telemetry only, or treat it as an interactive platform whose DB becomes part of runtime truth. This change intentionally chooses the first path.

## Goals / Non-Goals

**Goals:**
- Establish a first-class Bifrost service boundary owned by this repo’s control plane, even if the runtime payload itself is OCI-based.
- Run Bifrost in file-driven mode so rendered `config.json` is canonical and Web UI/config-store mutation is not part of baseline operations.
- Keep provider credentials out of the Nix store and out of committed `config.json` by using SOPS-backed env-file injection.
- Support a reusable gateway contract for multiple downstream apps with distinct text, image/multimodal, embedding, and fallback model aliases.
- Preserve a clean separation between canonical config and mutable runtime stores such as logs, caches, and optional vector data.
- Keep the gateway deployable on current fleet targets, especially `aarch64-linux`, by preferring the most operationally boring runtime path for `oci-melb-1`.

**Non-Goals:**
- Do not make the Bifrost Web UI or config-store database the canonical configuration workflow.
- Do not implement a full external-developer multi-tenant platform, self-service virtual key portal, or enterprise governance surface in this first wave.
- Do not commit provider secrets inline in rendered config files.
- Do not assume UI-managed runtime mutation or architecture-fragile packaging should define the baseline operating model.

## Decisions

- **BG-1 (Deployment boundary):** Use a declarative OCI runtime for Bifrost on `oci-melb-1` instead of treating upstream Nix packaging as the baseline deployment path.
  - **Rationale:** The first gateway host is `aarch64-linux`, and the most important property for this wave is a boring, reproducible runtime on the real target. OCI preserves declarative config ownership while avoiding architecture-sensitive upstream package build churn.
  - **Alternatives considered:**
    - Upstream Nix package/module baseline: rejected for this wave because real target validation exposed packaging fragility that is not worth carrying on the first ARM rollout.
    - Direct raw binary/NPX launch: rejected because it weakens declarative host management and packaging control.

- **BG-2 (Image/runtime authority):** This repo SHALL keep runtime/image authority explicitly pinned in repo-owned configuration rather than delegating baseline runtime behavior to mutable upstream defaults.
  - **Rationale:** The gateway is core infrastructure; the repo must own image selection, host wiring, config rendering, and secret injection even when using upstream container artifacts.
  - **Alternatives considered:**
    - Floating upstream container tags without repo-level pinning: rejected because it weakens reproducibility and rollback control.
    - Immediate custom image build pipeline: deferred because official upstream container artifacts are sufficient for the first wave.

- **BG-3 (Canonical config mode):** Baseline Bifrost operation SHALL use file-driven `config.json` mode with `config_store` disabled, making the rendered file the canonical source of truth and disabling UI-driven config mutation.
  - **Rationale:** This is the only operating mode that fits Git/Nix/SOPS source-of-truth rules cleanly enough for this repo.
  - **Alternatives considered:**
    - UI/config-store mode: rejected for baseline because runtime DB state becomes part of effective configuration truth.
    - Mixed bootstrap mode where UI edits are later backported to Git: rejected as too drift-prone for the desired operational model.

- **BG-4 (Secrets model):** Provider credentials and similar sensitive values SHALL be injected through host-scoped SOPS-backed environment files referenced from config, not embedded as plaintext in repo-owned JSON.
  - **Rationale:** This preserves blast-radius scoping and avoids putting live secrets in the Nix store or committed config artifacts.
  - **Alternatives considered:**
    - Inline secrets in `config.json`: rejected for obvious secret hygiene reasons.
    - UI-entered provider secrets in config-store DB: rejected because it shifts canonical secret state into runtime mutation paths.

- **BG-5 (Module boundary):** The repo SHOULD wrap Bifrost OCI runtime wiring in a thin local module boundary that exposes repo-friendly options for operating mode, persistence, provider/model routing, and downstream service integration.
  - **Rationale:** A local wrapper preserves a stable repo interface even if the runtime implementation changes later and gives future flexibility to move back to native packaging or another gateway without changing host-facing intent.
  - **Alternatives considered:**
    - Host-local container declarations with no wrapper: rejected because they leak runtime details into host files and weaken the long-term repo service boundary.

- **BG-6 (Runtime persistence split):** Mutable runtime stores such as logs, caches, and optional vector data SHALL be persisted explicitly but treated as non-canonical operational state.
  - **Rationale:** Bifrost is not fully immutable; the repo should acknowledge and isolate mutable operational data instead of pretending it does not exist.
  - **Alternatives considered:**
    - Ephemeral-only runtime state: rejected because logs/cache/state may be operationally valuable.
    - Treating logs/config-store DB as canonical: rejected because that breaks repo-owned truth.

## Risks / Trade-offs

- **[R1] Upstream container/runtime expectations may evolve faster than this repo wants** → **Mitigation:** keep image/runtime pins explicit in repo config, wrap the runtime locally, and preserve a clean path to vendor or repackage later if needed.
- **[R2] File-only mode may omit some UI-centric governance ergonomics** → **Mitigation:** treat this as an explicit trade-off in favor of declarative control; only revisit UI/config-store mode if a later change intentionally accepts hybrid runtime truth.
- **[R3] Model/provider routing schema can sprawl if exposed too directly to hosts** → **Mitigation:** add a repo-owned wrapper contract and keep raw upstream config shape encapsulated behind rendered config generation.
- **[R4] External developer use may eventually need mutable governance state (virtual keys, budgets, audit workflows)** → **Mitigation:** scope this change to foundational declarative gateway service only and treat multi-tenant/self-service concerns as a future explicit design decision.
- **[R5] OCI runtime may still hide app-dir or container-runtime quirks on the first ARM host** → **Mitigation:** keep config/state paths host-visible, validate directly on `oci-melb-1`, and preserve a clean fallback path to another runtime later if needed.

## Migration Plan

1. Define a pinned declarative OCI runtime path for Bifrost on `oci-melb-1`.
2. Create a thin local service wrapper that manages host-visible config/state paths, rendered `config.json`, secret env injection, and OCI runtime wiring.
3. Add host-scoped SOPS templates/secrets for provider credentials and render a canonical Bifrost env file.
4. Render `config.json` declaratively from repo-owned settings with `config_store` disabled and explicit runtime stores for logs/cache only as needed.
5. Validate downstream compatibility with at least one OpenAI-compatible consumer pattern.
6. Document rollback by disabling the host wrapper while preserving runtime state directories for inspection or later re-enable.

## Open Questions

- Which subset of Bifrost runtime stores should be enabled in the baseline: no logs store, local SQLite logs only, or explicit retained observability from day 1?
- How much provider/model abstraction should the local wrapper expose directly versus treating raw upstream config JSON as an escape hatch?
- When external developer use becomes real, should virtual keys and governance remain declarative, or should that be a separate explicitly hybrid control-plane change?

Resolved during implementation:
- The first deployment target is `oci-melb-1`, preserving file-driven baseline mode while validating the gateway contract next to the first downstream consumer set.

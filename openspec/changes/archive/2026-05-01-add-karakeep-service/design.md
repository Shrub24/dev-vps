## Context

Karakeep is operationally container-native: upstream documents an official three-service deployment (`web`, `chrome`, `meilisearch`) and publishes ARM-compatible images. That removes the biggest viability concern for `oci-melb-1`, but it does not decide how the repo should model the service. This repository already prefers handwritten NixOS modules as the operational control plane, even when the runtime payload is container-based.

This change touches host composition on `oci-melb-1`, host-scoped secrets, canonical edge routing on `do-admin-1`, and persistent state layout. It should feel like the existing `soulsync` and `tagr` modules rather than introducing a separate Compose-centered workflow.

## Goals / Non-Goals

**Goals:**
- Add Karakeep as a first-class service on `oci-melb-1` using repo-native NixOS module conventions.
- Preserve upstream container topology while expressing it directly through Nix-managed OCI containers.
- Keep service state under predictable `/srv/data` subdirectories with explicit mount ordering.
- Keep required secrets host-scoped and allow optional feature secrets to remain absent without blocking base convergence.
- Reuse canonical `policy/web-services.nix` routing so Karakeep is exposed through `do-admin-1` Caddy with private-origin transport to `oci-melb-1`.

**Non-Goals:**
- Do not deploy Karakeep through raw Docker Compose or `compose2nix`.
- Do not package Karakeep as a non-container native systemd service in this wave.
- Do not require optional OAuth, SMTP, S3, AI, or OCR integrations for initial convergence.

## Decisions

- **KK-1 (Deployment model):** Express Karakeep as a handwritten NixOS module using `virtualisation.oci-containers`/Podman for the upstream `web`, `chrome`, and `meilisearch` containers.
  - **Rationale:** This preserves the official runtime topology while keeping the repo's operational interface Nix-native and consistent with existing containerized services.
  - **Alternatives considered:**
    - `compose2nix`: rejected because it adds a translation layer and generated structure that does not match existing repo conventions.
    - Raw `docker compose`: rejected because the repo treats NixOS modules, not Compose files, as the declarative control plane.

- **KK-2 (Composition boundary):** Add Karakeep as a standalone service module wired from `hosts/oci-melb-1/default.nix`, not as a new application bundle.
  - **Rationale:** Karakeep is a single product with a contained runtime surface, unlike the music or admin stacks that justify a broader application composition layer.
  - **Alternatives considered:**
    - New `applications/knowledge.nix` wrapper: rejected for now because it adds structure before a second related service exists.

- **KK-3 (State layout):** Keep Karakeep state under `/srv/data/karakeep`, with dedicated subpaths for app data and Meilisearch persistence managed by tmpfiles and required mounts.
  - **Rationale:** This follows the repo's predictable service-state convention and avoids unmanaged container volumes.
  - **Alternatives considered:**
    - Anonymous/container-managed volumes: rejected because they weaken recoverability and drift from host-visible storage conventions.

- **KK-4 (Secrets and configuration):** Render required Karakeep secrets from host-scoped SOPS templates and keep optional integration env values declaratively optional.
  - **Rationale:** Required values such as `NEXTAUTH_SECRET` and `MEILI_MASTER_KEY` should remain blast-radius scoped to `oci-melb-1`, while optional extras should not block deployment of the base service.
  - **Alternatives considered:**
    - Shared/common secret scope: rejected because Karakeep is host-local application state, not a fleet-shared secret concern.
    - Runtime-generated secrets: rejected because the repo favors reproducible declarative bootstrap over ad hoc first-run mutation.

- **KK-5 (Access posture):** Expose Karakeep through the canonical `do-admin-1` Caddy edge path declared in `policy/web-services.nix`, using `tailscale-upstream` transport to private origin on `oci-melb-1`, but do not require Cloudflare Access on the route because Karakeep needs one app-native auth surface for both browser UI and mobile/API clients.
  - **Rationale:** This keeps route ownership single-sourced in policy while avoiding a split browser-versus-mobile auth model that would force brittle API bypasses for native clients.
  - **Alternatives considered:**
    - Cloudflare Access on the full route: rejected because mobile/native clients are a first-class use case and Access is browser-cookie centric.
    - Partial API-path bypass under an Access-gated route: rejected because it creates a brittle split-surface policy with limited security gain for this app class.
    - Dedicated `tailscale serve` host-local exposure: rejected because the user wants Karakeep exposed through `do-admin-1` and the repo already centralizes browser routes in `policy/web-services.nix`.
    - Local-only bind without routed browser exposure: rejected because it makes day-to-day access unnecessarily awkward.

- **KK-6 (Upstream/runtime fidelity):** Preserve upstream defaults where they fit the host model, but pin image references in module options so the repo can roll forward deliberately.
  - **Rationale:** Karakeep is likely to evolve quickly; explicit image options give rollback and upgrade control without breaking upstream compatibility.
  - **Alternatives considered:**
    - Hard-track `latest`/`release` tags without repo-level optionization: rejected because it increases surprise during rebuilds.

## Risks / Trade-offs

- **[R1] Browser sidecar behavior on OCI ARM may differ from x86 expectations** → **Mitigation:** keep the upstream browser container intact, validate architecture support during rollout, and isolate browser-specific tuning in the Karakeep module.
- **[R2] Upstream env surface may grow beyond the initial minimal secret set** → **Mitigation:** separate required vs optional env wiring so later integrations can be added without destabilizing the base service contract.
- **[R3] Karakeep auth URL / browser access wiring can drift if route policy is duplicated outside canonical maps** → **Mitigation:** define the public route in `policy/web-services.nix` and consume that policy as the single source of truth for edge behavior.
- **[R4] Search and app state growth could become opaque if kept inside container defaults** → **Mitigation:** use host-visible `/srv/data/karakeep/*` paths from the start so retention, backup, and rollback remain inspectable.

## Migration Plan

1. Add `modules/services/karakeep.nix` with explicit options for images, ports, env files, data directories, and container ordering.
2. Wire the module in `hosts/oci-melb-1/default.nix` with persistent paths and host-local defaults appropriate for the first rollout.
3. Add host-scoped Karakeep secrets and template placeholders under `hosts/oci-melb-1/` without widening `.sops.yaml` recipient scope.
4. Add canonical `policy/web-services.nix` route wiring on `do-admin-1` for Karakeep using `tailscale-upstream`, app-native auth, and authenticated origin pulls.
5. Update docs/specs/tasks and validate the change before implementation starts.

Rollback strategy:
- Disable Karakeep host wiring and remove the canonical edge route while preserving `/srv/data/karakeep` for inspection or later re-enable.
- Retain unused secrets/templates temporarily if needed, then clean them in a follow-up if the service is abandoned.

## Open Questions

- Should the module pin image tags immediately to a reviewed release value, or expose reviewed defaults with host override points first?

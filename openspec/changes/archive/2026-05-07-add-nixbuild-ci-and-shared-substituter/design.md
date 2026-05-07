## Context

The fleet already uses `deploy-rs` and `just` as canonical day-2 operator entrypoints, but there is no canonical CI pipeline and no shared remote build/cache contract. This gap causes repeated local rebuild pressure (especially on `oci-melb-1` as native `aarch64-linux` target), inconsistent validation behavior, and no auditable auto-deploy flow for `main`.

The change is cross-cutting: it touches CI workflows, host/module composition, secrets scope, and host storage policy. It must preserve current host-thin composition and private-first operational posture while introducing a reliable mixed-architecture build plane.

## Goals / Non-Goals

**Goals:**
- Establish `nixbuild.net` as the primary CI build plane for repository validation workflows.
- Standardize host-side substitute consumption from `nixbuild.net` for both active hosts.
- Keep deploy orchestration on existing repository contracts (`just`, `deploy-rs`) with `main` auto-deploy in serial fail-fast order.
- Keep authentication explicit and blast-radius-scoped (host machine auth in host secrets; CI auth in CI secret context).
- Tighten Nix GC policy on both active hosts to reduce store growth under the new shared cache/build posture.

**Non-Goals:**
- Offloading host-side native builds to `nixbuild.net` in this phase.
- Introducing Attic, Cloudflare-fronted cache routes, or R2-backed native `s3://` cache architecture.
- Replacing `deploy-rs` with new deployment tooling.
- Making local developer usage a required primary workflow contract in this change.

## Decisions

1. **Use `nixbuild.net` as CI build plane with GitHub Actions as orchestration plane**
   - Rationale: satisfies mixed-architecture build needs without forcing multi-arch GitHub runner strategy.
   - Alternative considered: GitHub multi-arch runners with no remote builder.
   - Why not chosen: adds runner complexity and does not create a durable shared substitute surface for hosts.

2. **Use SSH auth as phase-1 standard even though OIDC is available upstream**
   - Rationale: one auth pattern for CI and host wiring reduces ambiguity during first rollout.
   - Alternative considered: OIDC in CI plus SSH on hosts.
   - Why not chosen: intentionally deferred for phase-2 hardening after base rollout is stable.

3. **Hosts consume substitutes only; host-side remote-build offload is deferred**
   - Rationale: reduces rollout risk while still improving rebuild behavior and cache hit rates.
   - Alternative considered: immediate host remote-build offload to `nixbuild.net`.
   - Why not chosen: larger topology and operational change than needed for phase 1.

4. **Auto-deploy on `main` is serial fail-fast in host order `do-admin-1` then `oci-melb-1`**
   - Rationale: keeps rollout deterministic and protects edge/admin host dependency posture.
   - Alternative considered: independent parallel deploy jobs.
   - Why not chosen: parallel success/failure splits can leave hosts on mismatched generations more often.

5. **Keep secrets split by ownership boundary (host vs CI)**
   - Rationale: existing `.sops.yaml` contract is host-scoped for machine credentials; CI credentials belong in GitHub secrets.
   - Alternative considered: storing CI auth in repository SOPS paths.
   - Why not chosen: unnecessary broadening of credential lifecycle into repo state.

6. **Extend storage-hygiene baseline to both active hosts for Nix GC**
   - Rationale: historical root pressure on `oci-melb-1` and absence of explicit GC policy on `do-admin-1` justify symmetry.
   - Alternative considered: keep GC policy only on `oci-melb-1`.
   - Why not chosen: misses low-risk operational hygiene gain on `do-admin-1`.

## Risks / Trade-offs

- **[Risk] SSH auth material for daemon/root context may be miswired** → **Mitigation:** define explicit host module wiring for identity/known-host trust and validate host evaluation paths.
- **[Risk] CI remote-build setup may degrade to local-only behavior silently** → **Mitigation:** enforce explicit CI workflow setup steps and fail workflow on missing auth/trust inputs.
- **[Risk] Serial auto-deploy increases time-to-completion** → **Mitigation:** accept slower rollout for better determinism; revisit parallelization only after stable history.
- **[Risk] GC tightening could reduce rollback comfort if too aggressive** → **Mitigation:** keep bounded retention windows aligned with current break-glass expectations.
- **[Risk] Deferred host-side remote-build offload leaves some local build pressure** → **Mitigation:** phase this as explicit follow-up once substituter baseline is proven.

## Migration Plan

1. Add spec deltas and new capability spec for `nixbuild-build-plane` plus operations/fleet/secrets/storage-hygiene modifications.
2. Add shared module wiring for `nixbuild.net` substituter/trust and host-side SSH auth contracts.
3. Wire both active hosts to the shared substituter/auth modules and add/normalize Nix GC policy on both.
4. Add GitHub Actions workflows:
   - validate-only on PRs to `main` and pushes to non-`main`
   - validate + serial fail-fast deploy on push to `main`
5. Update docs and operational runbook references to reflect new CI/CD and build/cache baseline.
6. Run repo validation and OpenSpec strict validation before implementation completion.

Rollback strategy:
- Disable new CI workflows or deployment trigger paths at workflow level.
- Revert host/shared module wiring for substituter/auth and GC adjustments.
- Keep deploy-rs topology and host runtime state unchanged; rollback does not require destructive data migration.

## Open Questions

- Should phase-2 move CI from SSH credentials to OIDC for `nixbuild.net` once rollout is stable?
- Should host-side remote-build offload become opt-in per host after substitute hit-rate and disk telemetry are collected?
- Should local-operator helper commands for `nixbuild.net` be formalized in `justfile` or remain documentation-only?

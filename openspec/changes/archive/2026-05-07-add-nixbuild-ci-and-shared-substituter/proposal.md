## Why

The repository currently has no canonical CI/CD workflow and no shared remote build/substituter contract, so validation is manual, merged changes cannot deploy automatically, and `oci-melb-1` continues to absorb native `aarch64-linux` build pressure locally. We need a repo-managed build plane now so mixed-architecture validation becomes repeatable, host rebuilds can consume one shared cache, and `main` deployments follow the same auditable workflow every time.

**Core Value:** Make builds and deployments reproducible, lower-friction, and less storage-heavy without replacing the current `deploy-rs` and `just` operator contracts.

## What Changes

- Add GitHub Actions workflows for validation and deployment, using `nixbuild.net` as the primary CI remote build plane instead of relying on GitHub-hosted multi-architecture runners.
- Define a shared `nixbuild.net` substituter contract for active fleet hosts, with documented compatibility for local operators that want to consume the same cache.
- Apply one shared host-side substitute/trust baseline through common host profile composition so active hosts can consume the same remote build cache without repeating provider-specific settings in each host file.
- Tighten Nix garbage-collection policy on both active hosts while preserving the current deploy topology and rollback posture.
- Keep day-2 deploys on canonical repository entrypoints, with `main` auto-deploying `do-admin-1` first and `oci-melb-1` second in serial fail-fast order.

## Capabilities

### New Capabilities
- `nixbuild-build-plane`: Defines `nixbuild.net` as the canonical CI remote build plane and shared substituter contract for fleet hosts and documented local consumers.

### Modified Capabilities
- `operations`: Add CI validation/deploy workflow requirements, canonical command usage from automation, and serial fail-fast rollout behavior for `main`.
- `fleet-infrastructure`: Add active-host participation in a shared build-consumer baseline without pushing builder ownership back into host files.
- `secrets-management`: Keep CI build-plane credentials explicitly CI-scoped and avoid introducing unnecessary host-scoped nixbuild secret contracts in this change.
- `host-storage-hygiene`: Extend recurring Nix cleanup expectations beyond `oci-melb-1` so both active hosts keep a bounded rollback-friendly store footprint under the new shared build/cache posture.

## Impact

- Affected code paths:
  - `.github/workflows/` for validation and deploy automation
- `modules/profiles/base-server.nix` and shared host build-consumer modules
  - `hosts/do-admin-1/default.nix`
  - `hosts/oci-melb-1/default.nix`
- operational docs under `docs/`
- Affected specs:
  - New: `openspec/specs/nixbuild-build-plane/spec.md`
  - Modified: `openspec/specs/operations/spec.md`
  - Modified: `openspec/specs/fleet-infrastructure/spec.md`
  - Modified: `openspec/specs/secrets-management/spec.md`
  - Modified: `openspec/specs/host-storage-hygiene/spec.md`
- Operational impact:
  - CI gains a canonical build and deploy path.
- Active hosts gain one shared policy-driven substituter/trust contract.
  - `oci-melb-1` remains on the current host-side build topology for deploy-rs, but both hosts gain stronger Nix retention policy.

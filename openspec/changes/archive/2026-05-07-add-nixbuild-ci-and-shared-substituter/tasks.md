## 1. Establish shared nixbuild module surface

- [x] 1.1 Add a reusable host-side substitute/trust baseline without pushing deep Nix cache logic into host files.
- [x] 1.2 Add host-side machine-auth module wiring for daemon-usable `nixbuild.net` SSH access (identity + trust path contracts) with host-scoped secret inputs only.
- [x] 1.3 Run targeted evaluation of `nixosConfigurations.do-admin-1` and `nixosConfigurations.oci-melb-1` to verify both include the shared substituter contract and preserve current deploy topology.

## 2. Wire host configuration and storage hygiene

- [x] 2.1 Update `hosts/do-admin-1/default.nix` and `hosts/oci-melb-1/default.nix` to consume the shared nixbuild modules using thin host bindings.
- [x] 2.2 Add or normalize recurring Nix GC/retention policy for both active hosts, keeping rollback-friendly windows explicit.
- [x] 2.3 Validate host changes with build/eval checks and confirm no host-side remote-build offload behavior is introduced in phase 1.

## 3. Add CI/CD workflows with branch-class behavior

- [x] 3.1 Create `.github/workflows/ci.yml` for validation-only behavior on PRs to `main` and pushes to non-`main`, including canonical repo checks and documented temporary OpenTofu CI deferral.
- [x] 3.2 Create `.github/workflows/deploy.yml` for push-to-`main` validation + serial fail-fast deploy order (`do-admin-1` then `oci-melb-1`) using canonical deploy entrypoints.
- [x] 3.3 Wire workflow secret contracts for CI-scoped nixbuild auth and confirm CI does not require host-scoped secrets.

## 4. Update secrets policy and docs

- [x] 4.1 Update `.sops.yaml` and host system secret contracts so host machine auth for `nixbuild.net` remains blast-radius scoped per host.
- [x] 4.2 Update canonical docs (`docs/architecture.md`, `docs/decisions.md`, and related operator guidance) for the new build-plane and deploy behavior.
- [x] 4.3 Run final repo validation (`nix fmt`, relevant `nix flake check`/host checks, and `openspec validate --strict`) and capture any environment-limited caveats in completion notes.

## 5. Simplify deploy auth and workflow structure

- [x] 5.1 Remove deploy SSH private key workflow usage and switch deploy automation to Tailscale SSH-only auth.
- [x] 5.2 Refactor GitHub Actions workflow structure to reduce duplicated deploy job logic while preserving explicit serial deploy order.
- [x] 5.3 Update workflow secret templates and operator docs to match Tailscale SSH-only deploy auth and the simplified nixbuild workflow shape.
- [x] 5.4 Re-run workflow-relevant validation and strict OpenSpec validation after the refactor.

## 6. Centralize default nixbuild substituter policy

- [x] 6.1 Move default nixbuild substituter settings into `policy/globals.nix` so hosts inherit one canonical signing-key/store definition.
- [x] 6.2 Remove duplicated host-level signing-key bindings while preserving per-host override capability.
- [x] 6.3 Re-run host/repo validation and strict OpenSpec validation after centralizing the policy defaults.

## 7. Refresh CI installer and secret contract naming

- [x] 7.1 Switch shared GitHub Actions Nix installer setup from the nix quick install action to the Lix installer action while preserving nixbuild OIDC configuration.
- [x] 7.2 Align Tailscale GitHub Actions secret names between reusable workflows and the documented secret templates.
- [x] 7.3 Re-run workflow/repo validation and strict OpenSpec validation after the installer and secret contract refresh.

## 8. Generalize host build profile and remove machine auth

- [x] 8.1 Remove host-side nixbuild machine-auth module usage and delete the now-unused host machine-auth module and template contract.
- [x] 8.2 Replace the nixbuild-branded host substituter module with a generic reusable build profile that applies Nix substitute/trust settings from canonical policy defaults.
- [x] 8.3 Rewire active hosts to consume the generic build profile while keeping host files thin and preserving current nixbuild default behavior.
- [x] 8.4 Update docs/templates to reflect that host nixbuild machine-auth is no longer part of the current change and that host-side substitute/trust defaults are policy-driven through a generic build profile.
- [x] 8.5 Re-run host/repo validation and strict OpenSpec validation after the refactor.

## 9. Fold shared Nix substitute policy into common host profile

- [x] 9.1 Remove the separate `modules/profiles/build-config.nix` layer and apply the shared substitute/trust baseline through existing common host profile composition.
- [x] 9.2 Simplify active host files so they no longer need explicit build-profile imports or enable flags for the shared substitute baseline.
- [x] 9.3 Re-run host/repo validation and strict OpenSpec validation after folding the shared baseline into the common host profile.

## 10. Modularize deploy workflow host execution

- [x] 10.1 Move host-specific remote prebuild steps into the reusable deploy-host workflow so the top-level deploy workflow only owns shared validation and explicit serial ordering.
- [x] 10.2 Replace generated SSH config file handling with inline `deploy-rs` `--ssh-opts` usage in the reusable deploy-host workflow and align Tailscale secret names with the documented contract.
- [x] 10.3 Re-run workflow/repo validation and strict OpenSpec validation after the deploy workflow refactor.

## 11. Support manual deploy dispatch from any branch

- [x] 11.1 Make the deploy workflow explicitly safe and usable for manual `workflow_dispatch` from any branch while preserving push-to-`main` auto-deploy behavior.
- [x] 11.2 Update canonical docs/spec text so manual branch-based deploy dispatch is documented alongside `main` auto-deploy behavior.
- [x] 11.3 Re-run workflow/repo validation and strict OpenSpec validation after the manual-dispatch update.

## 12. Bind CI/CD workflows to the canonical GitHub environment

- [x] 12.1 Attach all secret-consuming CI validation and deploy jobs to the `ci` GitHub Actions environment so environment-scoped secrets and protection rules are applied consistently.
- [x] 12.2 Update workflow secret templates/docs to state that the required GitHub Actions secrets live in the `ci` environment for these workflows.
- [x] 12.3 Re-run workflow/repo validation and strict OpenSpec validation after the environment binding update.

## 13. Make CI deploys fetch directly from host-side substituters

- [x] 13.1 Update the reusable CI deploy workflow so GitHub Actions passes an inline `deploy-rs` remote-build override instead of relying on repository-local deploy topology defaults.
- [x] 13.2 Update canonical docs/spec text to explain that CI deploys prefer host-side realization/direct substituter fetch while local operator deploy topology remains unchanged.
- [x] 13.3 Re-run workflow/OpenSpec validation after the CI-only remote-build override change.

## 14. Scope expensive CI host builds to high-signal triggers

- [x] 14.1 Keep lightweight validation on pushes to non-`main` while gating host toplevel remote-build jobs to pull requests targeting `main` and manual dispatch runs.
- [x] 14.2 Update canonical docs/spec text to reflect the resource-aware CI trigger split.
- [x] 14.3 Re-run workflow/OpenSpec validation after CI trigger scoping changes.

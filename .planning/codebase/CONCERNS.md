# Codebase Concerns

**Analysis Date:** 2026-03-21

## Tech Debt

**Broken flake entrypoint:**
- Issue: `flake.nix` references custom package files and a Home Manager file that are not present in the repo, so the canonical flake cannot evaluate cleanly.
- Files: `flake.nix`, `.github/workflows/ci.yml`
- Impact: `nix flake check` fails before host validation, CI is red by default, and every later migration step is blocked behind missing legacy paths.
- Fix approach: Either restore `pkgs/codenomad/package.nix`, `pkgs/opencode/package.nix`, `pkgs/repo-sync/package.nix`, and `home/dev.nix`, or remove those outputs and modules from `flake.nix` until the fleet cutover is complete.

**Fleet docs vs active config drift:**
- Issue: planning and docs target `oci-melb-1` on OCI `aarch64-linux`, but the active configuration still builds `nixosConfigurations.dev-vps` on `x86_64-linux` with DigitalOcean-specific modules and `dev-vps` naming.
- Files: `flake.nix`, `nixos/configuration.nix`, `nixos/digitalocean.nix`, `deploy.sh`, `justfile`, `README.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`
- Impact: operators cannot trust names, provider assumptions, or deployment commands; migration work risks stacking new fleet logic on top of incompatible legacy defaults.
- Fix approach: cut over one canonical host path first, rename the flake output to the active host identity, and delete or archive provider-specific legacy files that are no longer part of the chosen baseline.

**Legacy developer-workstation scope still embedded in host config:**
- Issue: the system profile still installs and serves `codenomad`, `opencode`, `repo-sync`, and Home Manager user state even though the current repo mission is fleet infrastructure and private media services.
- Files: `flake.nix`, `nixos/configuration.nix`, `docs/context-history.md`, `README.md`
- Impact: unrelated user-environment concerns increase eval surface, secret surface, and migration noise while providing no clear path toward the planned `tailscale`/`syncthing`/`navidrome` baseline.
- Fix approach: trim the host to fleet-relevant packages and services first; reintroduce personal tooling only if it has an explicit place in the new architecture.

## Known Bugs

**Flake checks fail immediately:**
- Symptoms: `nix flake check --no-build --no-write-lock-file path:.` fails on `packages.x86_64-linux.codenomad` because `pkgs/codenomad/package.nix` does not exist.
- Files: `flake.nix`, `.github/workflows/ci.yml`
- Trigger: any local `nix flake check`, any CI push to `main`, and any command path that touches package outputs.
- Workaround: remove the broken package outputs from the evaluation path or restore the missing files before relying on CI or local checks.

**Tailscale serve unit points at an undeclared workload:**
- Symptoms: `tailscale-serve-codenomad` serves `http://127.0.0.1:9899`, but no `codenomad` service definition exists in the current repo, so the exposed endpoint is likely dead or inconsistent.
- Files: `nixos/configuration.nix`, `flake.nix`
- Trigger: any switch that enables `systemd.services.tailscale-serve-codenomad` without separately provisioning a listener on port `9899`.
- Workaround: disable `tailscale-serve-codenomad` until the backing service is declared in-repo, or restore the missing workload definition and package source.

## Security Considerations

**Secret blast radius is still single-file and single-scope:**
- Risk: `.sops.yaml` only matches `secrets/*.yaml`, and `nixos/configuration.nix` points `sops.defaultSopsFile` at `secrets/secrets.yaml`; this keeps the repo on a monolithic secret file instead of the planned host-scoped split.
- Files: `.sops.yaml`, `nixos/configuration.nix`, `secrets/secrets.yaml`, `docs/decisions.md`, `docs/architecture.md`
- Current mitigation: the current rule limits decryption to one configured age recipient in `.sops.yaml`.
- Recommendations: move to `secrets/common.yaml` plus `hosts/<host>/secrets.yaml`, add path-specific recipient rules in `.sops.yaml`, and stop using one default secret file for all host concerns.

**Public SSH exposure contradicts the private-access baseline:**
- Risk: `services.openssh.openFirewall = true` opens SSH on the host firewall while planning documents say services and management should stay Tailscale-first and non-public.
- Files: `nixos/configuration.nix`, `docs/architecture.md`, `docs/decisions.md`, `.planning/REQUIREMENTS.md`
- Current mitigation: `nixos/configuration.nix` disables password and keyboard-interactive auth and restricts root login to key-based access.
- Recommendations: make public SSH exposure an explicit exception with documented rationale, or close the public port and document the intended break-glass path before tightening access.

**Bootstrap and recovery trust boundaries are undocumented in code:**
- Risk: the repo requires a Tailscale auth key and a sops age key, but no current code path documents or automates the safe bootstrap order for those credentials on a fresh machine.
- Files: `nixos/configuration.nix`, `deploy.sh`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`
- Current mitigation: none detected in executable code; only planning documents describe the intended two-step bootstrap.
- Recommendations: add one documented, tested bootstrap flow that covers initial SSH access, sops key placement, Tailscale enrollment, and failure recovery.

## Performance Bottlenecks

**Feedback loop is blocked before runtime profiling begins:**
- Problem: evaluation fails on missing paths before the repo can build the target system, so the main operational bottleneck is broken validation rather than service runtime throughput.
- Files: `flake.nix`, `.github/workflows/ci.yml`
- Cause: package overlays and Home Manager imports are mandatory in the top-level flake even though their source files are absent.
- Improvement path: shrink the flake to the minimum working host build first, then add package and user-level outputs back behind real files or optional modules.

## Fragile Areas

**Provider-specific bootstrap layer is tied to the wrong cloud:**
- Files: `nixos/digitalocean.nix`, `nixos/configuration.nix`, `nixos/disko-config.nix`, `deploy.sh`, `justfile`
- Why fragile: the repo plans for OCI ARM, but the active path still mixes DigitalOcean cloud-init, `qemu-guest`, `/dev/vda`, and `droplet` naming; changing one assumption without the others will leave bootstrap half-migrated.
- Safe modification: replace provider assumptions as one unit around a real `hosts/oci-melb-1/` assembly instead of editing individual files piecemeal.
- Test coverage: no automated install smoke test or provider-specific validation is present in `.github/workflows/ci.yml`.

**Disk and boot model still assume a disposable single-root guest:**
- Files: `nixos/disko-config.nix`, `flake.nix`, `.planning/REQUIREMENTS.md`, `docs/architecture.md`
- Why fragile: the disk layout is only EFI plus `/` on `/dev/vda`; it does not model the planned persistent data mount or stable identifiers, so storage changes will require touching both bootstrap and service layout later.
- Safe modification: introduce the final first-host disk shape before service data paths are added, and use stable device identities instead of transient guest names.
- Test coverage: no check asserts the expected mount topology or device mapping.

## Scaling Limits

**Repository currently scales to one legacy host shape only:**
- Current capacity: one named output, `nixosConfigurations.dev-vps`, on `x86_64-linux`.
- Limit: adding `oci-melb-1` or a second host requires renaming core outputs, untangling provider logic, and reworking assumptions in `deploy.sh`, `justfile`, and `.github/workflows/ci.yml`.
- Scaling path: move to `hosts/<host>/` composition with per-host outputs and keep shared logic in reusable modules only after the first host build works.

**Secrets model currently scales to one operator policy, not a fleet:**
- Current capacity: one age recipient rule covering `secrets/*.yaml` in `.sops.yaml`.
- Limit: host-specific secrets, shared-vs-host scoping, and future operator or machine recipients cannot be introduced cleanly without restructuring secret paths.
- Scaling path: split secret files by scope now and encode path-based recipient groups before a second host appears.

## Dependencies at Risk

**Local custom packages are required but missing:**
- Risk: the repo depends on local derivations for `codenomad`, `opencode`, and `repo-sync`, but the source files referenced by `flake.nix` are absent.
- Impact: package builds, CI, and any host config that installs those packages are broken.
- Migration plan: either restore the package sources under `pkgs/` or remove those dependencies from the fleet baseline until they are intentionally reintroduced.

## Missing Critical Features

**No canonical first-host implementation exists yet:**
- Problem: the repo does not contain a real `hosts/oci-melb-1/` implementation or any `aarch64-linux` target despite planning documents treating that host as the active baseline.
- Blocks: provider-correct bootstrap, host-targeted rebuilds, and meaningful OCI validation.

**Planned baseline services are not declared:**
- Problem: `syncthing` and `navidrome` appear in docs and requirements, but no active NixOS service declarations for them exist in `nixos/configuration.nix` or any module path.
- Blocks: service rollout, storage path validation, and sync-safety testing.

**Break-glass recovery path is still documentation-only:**
- Problem: `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` require break-glass access, but no runbook or executable recovery workflow exists in `docs/` or scripts.
- Blocks: safely tightening access around Tailscale-first operations.

## Test Coverage Gaps

**Bootstrap path is untested end to end:**
- What's not tested: `nixos-anywhere` install flow, first-boot secret bootstrap, and OCI/provider-specific host bring-up.
- Files: `deploy.sh`, `flake.nix`, `nixos/digitalocean.nix`, `.github/workflows/ci.yml`
- Risk: bootstrap regressions will surface only during real host provisioning.
- Priority: High

**Storage and service baseline has no assertions:**
- What's not tested: persistent mount layout, `syncthing`/`navidrome` service enablement, and delete/conflict safety controls required by planning.
- Files: `nixos/disko-config.nix`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`
- Risk: the eventual service rollout can violate the intended data model without any automated signal.
- Priority: High

---

*Concerns audit: 2026-03-21*

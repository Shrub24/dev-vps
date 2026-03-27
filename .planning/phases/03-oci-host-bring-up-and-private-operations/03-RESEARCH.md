# Phase 03: OCI Host Bring-Up And Private Operations - Research

**Date:** 2026-03-26
**Status:** Complete

## Scope Anchors

- Plan for Phase 3 requirement IDs: `BOOT-01`, `BOOT-02`, `BOOT-03`, `ACCS-01`, `ACCS-02`, `STOR-01`, `STOR-02`, `SRVC-01`, `OPER-01`.
- Build on existing Phase 2 contracts (`deploy.sh`, `justfile`, `hosts/oci-melb-1/default.nix`, `modules/storage/disko-root.nix`, service modules).
- Preserve constraints: OCI `aarch64-linux`, Tailscale-private access, one persistent data mount, low-complexity operations.

## Current State Findings

- `deploy.sh` already uses `nixos-anywhere` with `--build-on-remote` and canonical flake target `path:.#oci-melb-1`.
- `justfile` already has `redeploy` and `verify-oci-contract`; this gives a good base for repeatable host-targeted updates.
- Host config already enables Tailscale and gates host-scoped auth key use on `hosts/oci-melb-1/secrets.yaml` existence.
- Disk layout already declares GPT + EFI + ext4 root and `/srv/data` ext4 data partition using labels (`rootfs`, `srv-data`).
- Break-glass recovery flow is not yet captured as an explicit executable contract in phase artifacts.

## Recommended Planning Pattern

1. **Bootstrap + disk contract first**
   - Lock install contract around `nixos-anywhere` for OCI host bootstrap.
   - Add explicit contract checks proving disko layout still includes EFI/root/data and `/srv/data` mount.

2. **Private access + recovery posture second**
   - Preserve Tailscale-private posture declaratively (`services.tailscale.enable`, `trustedInterfaces = [ "tailscale0" ]`).
   - Add break-glass runbook contract (serial console/root fallback, verify + rollback steps).

3. **Day-2 operations last**
   - Normalize `nixos-rebuild --target-host` update path and make contract checks callable from one operator command.
   - Capture predictable service directory checks for `/srv/data/*` paths.

## Pitfalls To Avoid

- Introducing public ingress/firewall openings in this phase.
- Coupling break-glass to unversioned manual notes instead of repository-tracked docs.
- Expanding into orchestration tooling before host-targeted workflow is stable.

## Validation Architecture

- Fast loop: `nix flake check --no-build --no-write-lock-file path:.`
- Structural checks:
  - `nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.networking.hostName`
  - `nix eval path:.#nixosConfigurations.oci-melb-1.config.services.tailscale.enable`
  - `nix eval --json path:.#nixosConfigurations.oci-melb-1.config.fileSystems` (assert `/srv/data` exists)
- Contract checks:
  - shell checks under `tests/phase-03-*.sh` for install/update command invariants
  - `rg` checks for Tailscale-only firewall/trusted interface posture

---

*Phase: 03-oci-host-bring-up-and-private-operations*

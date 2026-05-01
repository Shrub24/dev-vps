# Phase 02: OCI Bootstrap And Service Readiness - Research

**Date:** 2026-03-22
**Status:** Complete

## Scope Anchors

- Implement locked decisions from `02-CONTEXT.md` D-01..D-21, excluding explicitly deferred items.
- Keep implementation aligned with Phase 2 requirement IDs: `SECR-01`, `SECR-02`, `SECR-03`, `SECR-04`.
- Preserve active architecture boundaries (`flake.nix` -> `hosts/oci-melb-1/default.nix` -> `modules/*`).

## Current State Findings

- Secrets are still anchored to `secrets/secrets.yaml` in `hosts/oci-melb-1/default.nix`, so common vs host split is not yet active.
- `.sops.yaml` has a host-path rule, but no `hosts/oci-melb-1/secrets.yaml` exists yet.
- Only `tailscale` has a service module; `syncthing`, `navidrome`, and `slskd` module contracts are missing.
- Storage module currently defines GPT + EFI + ext4 root only; there is no dedicated data filesystem or canonical service directories.
- Operator surfaces exist (`deploy.sh`, `justfile`) and already include `nixos-anywhere` with `--build-on-remote`, so this should be preserved and documented as canonical.

## Recommended Implementation Pattern

1. **Secrets first (Phase 2 requirements):**
   - Keep `secrets/common.yaml` for fleet-shared values and move host-only values to `hosts/oci-melb-1/secrets.yaml`.
   - Keep `.sops.yaml` rules explicitly path-scoped to avoid cross-host decryption bleed.
   - Move Tailscale auth key to host-scoped secret material (`SECR-04`).

2. **Two-step bootstrap contract (`SECR-03`):**
   - Step A: bootstrap host and converge base system without requiring host-specific decrypted data.
   - Step B: add host recipient + host secret file, then apply configuration that consumes host secrets.

3. **Service/module readiness for this phase boundary:**
   - Define service modules for `syncthing`, `navidrome`, and `slskd` with private-first defaults.
   - Keep deeper functional checks secret-dependent and explicitly deferred where necessary.

4. **Storage baseline:**
   - Extend disko contract to include one persistent data filesystem mounted at a canonical path.
   - Add service subdirectories and ownership scaffolding only (no real data migration).

## Concrete Decisions to Carry into Planning

- Preserve bootstrap path: temporary OCI Linux image -> `nixos-anywhere` over SSH (`D-01`).
- Preserve remote build posture (`--build-on-remote`) as default from operator x86_64 machine (`D-02`).
- Keep break-glass fallback testing deferred in this phase (`D-04`, deferred).
- Keep startup sequencing contract as network -> sync -> consumers (`D-14`).
- Define worker interface/profile boundary only; do not implement workers (`D-15`).

## Common Pitfalls to Avoid

- Reusing one shared Tailscale enrollment secret for all hosts (violates `SECR-04`).
- Collapsing common and host secrets back into one encrypted file (violates `SECR-01`).
- Using broad `.sops.yaml` regex that grants future hosts decryption scope by default (violates `SECR-02`).
- Mixing deployment-orchestration rollout into this phase (`D-19` deferred).

## Validation Architecture

Phase execution should use a fast preflight loop and deterministic structural checks:

- Fast loop: `nix flake check --no-build --no-write-lock-file path:.`
- Structural eval checks (no host runtime required):
  - `nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.networking.hostName`
  - `nix eval path:.#nixosConfigurations.oci-melb-1.config.services.tailscale.enable`
- Text-level contract checks with `rg` for secret paths, service wiring, and startup ordering.

This phase should treat service process health checks as implementation verification items in plans, while retaining secret-dependent deep probes as deferred where explicitly allowed by D-10.

---

*Phase: 02-oci-bootstrap-and-service-readiness*

# Spec: Repository Structure

## Capability ID

`repository-structure`

## Summary

This repository serves as a modular NixOS fleet infrastructure source of truth, with a host-centric layout that separates host identity from reusable service modules. The structure enables scalable multi-host growth while maintaining clear boundaries between provider-specific details, service logic, and host composition.

## Behaviors

### Host-Centric Layout

- **RS-1**: The repository shall organize host identity under `hosts/<host>/default.nix` with composition of reusable modules.
- **RS-2**: The repository shall provide reusable module boundaries under `modules/core/`, `modules/profiles/`, `modules/services/`, and `modules/applications/`.
- **RS-3**: The repository shall isolate provider-specific defaults under `modules/providers/<provider>/`.
- **RS-4**: The repository shall maintain a canonical flake entrypoint at `flake.nix` with `nixosConfigurations.<host>` outputs.

### Documentation Authority

- **RS-5**: Canonical architecture, decisions, and migration guidance shall reside under `docs/` as the authoritative source.
- **RS-6**: Entrypoint documents (`README.md`, `CLAUDE.md`) shall be thin wrappers that reference canonical docs to prevent drift.
- **RS-7**: Documentation updates shall ship in the same change window as architecture changes.

### Operator and CI Alignment

- **RS-8**: Operator command surfaces shall use neutral naming (`TARGET_HOST`, `TARGET_USER`) and target canonical flake host outputs.
- **RS-9**: CI workflows shall validate only canonical host outputs that exist in active flake wiring.
- **RS-10**: Legacy personal-tooling assumptions shall be removed from status and build defaults.

### Extensibility

- **RS-11**: The repository structure shall support addition of new hosts without requiring structural rewrites.
- **RS-12**: The module composition pattern shall allow mixing `aarch64-linux` and `x86_64-linux` hosts with provider-aware defaults where needed.

## Constraints

- First host is `oci-melb-1` on Oracle Cloud Free Tier using `aarch64-linux`.
- Fleet direction supports later mixed `aarch64` and `x86_64` hosts.
- Provider specifics are isolated from reusable service logic.
- Complexity deferred until real pressure exists: no early Kubernetes, no public ingress, no premature fleet tooling.

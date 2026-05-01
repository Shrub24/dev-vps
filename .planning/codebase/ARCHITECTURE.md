# Architecture

**Analysis Date:** 2026-03-21

## Pattern Overview

**Overall:** Host-centric flake composition for a modular NixOS fleet baseline with `oci-melb-1` as the canonical first host.

**Key Characteristics:**
- `flake.nix` is the composition root and exports `nixosConfigurations.oci-melb-1`.
- Host assembly is centered on `hosts/oci-melb-1/default.nix`.
- Reusable behavior is split into `modules/` boundaries, including provider and storage modules.

## Layers

**Composition Layer:**
- Purpose: Pin inputs and assemble the active host output.
- Location: `flake.nix`
- Contains: flake inputs, dev shell, and `nixosConfigurations.oci-melb-1`.
- Depends on: `disko`, `sops-nix`, and host entrypoint `hosts/oci-melb-1/default.nix`.
- Used by: `justfile`, CI, and local `nix` workflows.

**Host Layer:**
- Purpose: Define host identity and compose reusable modules.
- Location: `hosts/oci-melb-1/default.nix`
- Contains: imports for core, profile, service, provider, and storage modules.
- Depends on: `modules/core/base.nix`, `modules/profiles/base-server.nix`, `modules/services/tailscale.nix`, `modules/providers/oci/default.nix`, `modules/storage/disko-root.nix`.
- Used by: `flake.nix` host output assembly.

**Provider Layer:**
- Purpose: Isolate OCI-specific host defaults.
- Location: `modules/providers/oci/default.nix`
- Contains: default disk device selection and provider-scoped assumptions.
- Depends on: NixOS module system and host imports.
- Used by: `hosts/oci-melb-1/default.nix`.

**Storage Layer:**
- Purpose: Declaratively define root disk layout.
- Location: `modules/storage/disko-root.nix`
- Contains: GPT disk model, EFI partition, and root filesystem.
- Depends on: `disko` module imported through `flake.nix`.
- Used by: `hosts/oci-melb-1/default.nix`.

**Operations Layer:**
- Purpose: Provide operator and CI entrypoints.
- Location: `justfile`, `.github/workflows/ci.yml`, `deploy.sh`
- Contains: flake checks, host build commands, remote status/debug helpers, and bootstrap helpers.
- Depends on: `flake.nix` outputs and SSH connectivity to the target host.
- Used by: local operators and CI automation.

## Data Flow

**Build and Deploy Flow:**
1. Operator runs `just` or direct `nix` commands from repo root.
2. `flake.nix` evaluates `nixosConfigurations.oci-melb-1` using `hosts/oci-melb-1/default.nix`.
3. Host imports provider and storage modules (`modules/providers/oci/default.nix`, `modules/storage/disko-root.nix`) alongside reusable core/profile/service modules.
4. `nix flake check` and host builds validate declarative wiring before host deployment.

## Entry Points

- `flake.nix` - canonical composition root.
- `hosts/oci-melb-1/default.nix` - active host entrypoint.
- `modules/providers/oci/default.nix` - provider boundary.
- `modules/storage/disko-root.nix` - storage boundary.
- `justfile` - operator command surface.
- `.github/workflows/ci.yml` - CI validation surface.

## Current Architectural Reality

- Active evaluated architecture is the `flake.nix` -> `hosts/oci-melb-1/default.nix` -> `modules/*` composition chain.
- Legacy `nixos/configuration.nix`, `nixos/digitalocean.nix`, and `nixos/disko-config.nix` are retired from the active path.
- Secret naming is transitioning to `secrets/common.yaml` and `hosts/<host>/secrets.yaml` with migration compatibility for existing encrypted material.

---

*Architecture analysis: 2026-03-21*

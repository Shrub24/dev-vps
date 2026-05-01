# Codebase Structure

**Analysis Date:** 2026-03-21

## Directory Layout

```text
dev-vps/
|- flake.nix
|- flake.lock
|- justfile
|- deploy.sh
|- hosts/
|  `- oci-melb-1/
|     `- default.nix
|- modules/
|  |- core/
|  |- profiles/
|  |- providers/
|  |  `- oci/
|  |     `- default.nix
|  |- services/
|  `- storage/
|     `- disko-root.nix
|- secrets/
|  |- common.template.yaml
|  `- secrets.yaml
|- docs/
|- .github/workflows/
`- .planning/
```

## Directory Purposes

**`hosts/`:**
- Purpose: host identity entrypoints.
- Key file: `hosts/oci-melb-1/default.nix`.

**`modules/`:**
- Purpose: reusable and boundary-specific NixOS modules.
- Key files: `modules/providers/oci/default.nix`, `modules/storage/disko-root.nix`, `modules/services/tailscale.nix`.

**`secrets/`:**
- Purpose: encrypted values and unencrypted scaffolding templates.
- Key files: `secrets/common.template.yaml`, `secrets/secrets.yaml`.

**`docs/`:**
- Purpose: canonical architecture and migration intent for humans.
- Key files: `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, `docs/context-history.md`.

**`.planning/`:**
- Purpose: machine-consumed planning state and generated maps.
- Key files: `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/codebase/ARCHITECTURE.md`.

## Key File Locations

**Entry Points:**
- `flake.nix` - root flake and output graph.
- `hosts/oci-melb-1/default.nix` - active host definition.
- `justfile` - operator commands.
- `.github/workflows/ci.yml` - CI checks.

**Configuration Boundaries:**
- `modules/providers/oci/default.nix` - provider-specific defaults.
- `modules/storage/disko-root.nix` - storage topology.
- `.sops.yaml` - recipient policy per secret path pattern.

## Where to Add New Code

- Add host-specific composition under `hosts/<host>/default.nix`.
- Add reusable logic under `modules/<domain>/`.
- Keep provider assumptions in `modules/providers/<provider>/`.
- Keep storage layout modules under `modules/storage/`.
- Keep canonical narrative docs under `docs/` and generated planning maps under `.planning/codebase/`.

## Current Structure Gaps

- Transitional secret compatibility remains while encrypted data migrates from legacy naming.
- Additional host directories and recipient scoping are deferred to the secrets/bootstrap phase.
- Break-glass and bootstrap runbooks still need implementation-level validation artifacts.

---

*Structure analysis: 2026-03-21*

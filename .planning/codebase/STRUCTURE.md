# Codebase Structure

**Analysis Date:** 2026-03-21

## Directory Layout

```text
dev-vps/
├── flake.nix                 # Canonical Nix entrypoint and host assembly
├── flake.lock                # Pinned flake inputs
├── justfile                  # Operator commands for build, deploy, and inspection
├── deploy.sh                 # `nixos-anywhere` bootstrap wrapper
├── nixos/                    # All evaluated NixOS modules for the current host
├── docs/                     # Human architecture, plan, and decision records
├── secrets/                  # Encrypted secret material and templates; contents not inspected
├── .github/workflows/        # CI entrypoint
├── .planning/                # GSD planning artifacts and generated codebase maps
├── home/                     # Intended Home Manager location, currently empty
└── pkgs/                     # Intended custom package location, currently empty
```

## Directory Purposes

**`nixos/`:**
- Purpose: Hold the entire active NixOS host definition.
- Contains: `configuration.nix`, `digitalocean.nix`, and `disko-config.nix`.
- Key files: `nixos/configuration.nix`, `nixos/digitalocean.nix`, `nixos/disko-config.nix`.

**`docs/`:**
- Purpose: Keep migration intent and planning rationale visible to humans.
- Contains: Narrative docs, not evaluated code.
- Key files: `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, `docs/context-history.md`.

**`secrets/`:**
- Purpose: Store encrypted runtime secret material for `sops-nix`.
- Contains: Secret files and templates; contents intentionally not quoted.
- Key files: `secrets/secrets.yaml`, `secrets/secrets.template.yaml`.

**`.github/workflows/`:**
- Purpose: Run CI validation of the flake and package outputs.
- Contains: GitHub Actions workflow YAML.
- Key files: `.github/workflows/ci.yml`.

**`.planning/`:**
- Purpose: Hold GSD planning state, research artifacts, and generated codebase docs.
- Contains: Project state, roadmap, research docs, and `codebase/` outputs.
- Key files: `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/research/ARCHITECTURE.md`, `.planning/codebase/ARCHITECTURE.md`.

**`home/`:**
- Purpose: Intended location for Home Manager modules referenced by `flake.nix`.
- Contains: No files in the current snapshot.
- Key files: Not applicable; `flake.nix:76` references `home/dev.nix`, but `home/` is empty.

**`pkgs/`:**
- Purpose: Intended location for custom packages exposed through the flake overlay.
- Contains: No files in the current snapshot.
- Key files: Not applicable; `flake.nix:28`, `flake.nix:29`, and `flake.nix:30` reference missing package definitions.

## Key File Locations

**Entry Points:**
- `flake.nix`: Root flake, overlay definition, dev shell, packages, and `nixosConfigurations.dev-vps`.
- `deploy.sh`: Install-time entrypoint for `nixos-anywhere`.
- `justfile`: Day-2 operator workflow entrypoint for rebuilds and inspection.
- `.github/workflows/ci.yml`: CI entrypoint.

**Configuration:**
- `nixos/configuration.nix`: Main host configuration and runtime policy.
- `nixos/digitalocean.nix`: Provider-specific cloud-init and networking adjustments.
- `nixos/disko-config.nix`: Disk layout.
- `.sops.yaml`: Secret recipient rules for files under `secrets/`.

**Core Logic:**
- `flake.nix`: Composition logic and output graph.
- `nixos/configuration.nix`: Host logic for users, SSH, Tailscale, secrets, and tmpfiles.
- `justfile`: Operator-facing control logic.

**Testing:**
- `.github/workflows/ci.yml`: The only detected automated validation path.
- `justfile`: Local validation wrappers via `just check`, `just flake-check`, and `just build`.

## Naming Conventions

**Files:**
- Use kebab-case or lower-case descriptive names for Nix modules and docs, such as `nixos/digitalocean.nix`, `nixos/disko-config.nix`, and `docs/context-history.md`.
- Use root-level conventional entrypoint names for operator tooling, such as `flake.nix`, `justfile`, and `deploy.sh`.

**Directories:**
- Keep top-level directories singular by responsibility: `nixos/`, `docs/`, `secrets/`, `home/`, `pkgs/`.
- Under the current layout, provider-specific code sits next to base host code inside `nixos/` rather than in a nested tree.

## Where to Add New Code

**New Host-Level NixOS Behavior:**
- Primary code: `nixos/configuration.nix` if the behavior applies to the only active host.
- Split-out module: add a new sibling file under `nixos/` when the concern is distinct, then import it from `nixos/configuration.nix` or `flake.nix`.

**New Provider-Specific Logic:**
- Implementation: add another provider-focused module under `nixos/` alongside `nixos/digitalocean.nix`.
- Wiring: import it from `flake.nix` so provider assumptions stay outside `nixos/configuration.nix`.

**New Storage Or Boot Layout:**
- Implementation: extend `nixos/disko-config.nix` or create a second disk-layout module under `nixos/` and keep the `disko` wiring in `flake.nix` explicit.

**New Operator Commands:**
- Local workflows: `justfile`.
- One-off bootstrap wrappers: root shell scripts like `deploy.sh`.

**New Documentation:**
- Architecture and decisions: `docs/`.
- Planning artifacts consumed by GSD: `.planning/` and `.planning/codebase/`.

**Tests And Validation:**
- CI checks: `.github/workflows/ci.yml`.
- Local validation commands: mirror CI in `justfile` so operators can run the same checks before pushing.

## Practical Placement Rules

**Use `nixos/` as the active module root:**
- Place all evaluated NixOS modules under `nixos/` because no `hosts/` or `modules/` directory is implemented yet.
- Keep imports explicit from `flake.nix` or `nixos/configuration.nix` to match the current assembly style.

**Keep root files thin and entrypoint-focused:**
- Put composition in `flake.nix`, task wrappers in `justfile`, and install wrapping in `deploy.sh`.
- Do not hide host logic in scripts when it belongs in declarative Nix under `nixos/`.

**Treat `docs/` and `.planning/` differently:**
- Put authoritative human-facing project intent in `docs/`.
- Put machine-consumed planning outputs in `.planning/codebase/`.

**Do not rely on `home/` or `pkgs/` until populated:**
- `home/` and `pkgs/` are placeholders in the current tree.
- If you add files there, make sure they satisfy the existing references in `flake.nix` or update `flake.nix` in the same change.

## Special Directories

**`secrets/`:**
- Purpose: Encrypted secrets and templates for runtime configuration.
- Generated: No.
- Committed: Yes.

**`.planning/codebase/`:**
- Purpose: Generated architecture and quality maps for future GSD phases.
- Generated: Yes.
- Committed: Intended to be committed.

**`.direnv/`:**
- Purpose: Local direnv cache for `use flake` from `.envrc`.
- Generated: Yes.
- Committed: No.

**`.ruff_cache/`:**
- Purpose: Local Ruff cache directory.
- Generated: Yes.
- Committed: No.

**`.jj/`:**
- Purpose: Jujutsu repository metadata in parallel with Git metadata.
- Generated: Yes.
- Committed: No.

## Current Structure Gaps

**Implemented vs planned layout:**
- Current code lives under `nixos/` and root scripts.
- Planned fleet structure in `docs/architecture.md` and `.planning/research/ARCHITECTURE.md` mentions `hosts/`, `modules/`, and host-scoped secrets, but those directories do not exist in the evaluated repo.

**Missing referenced paths:**
- `flake.nix:76` imports `./home/dev.nix`, but `home/` is empty.
- `flake.nix:28`, `flake.nix:29`, and `flake.nix:30` reference `./pkgs/codenomad/package.nix`, `./pkgs/opencode/package.nix`, and `./pkgs/repo-sync/package.nix`, but `pkgs/` is empty.

**Implication for future work:**
- Add code according to the current live tree unless the change is specifically performing the planned migration to a host-centric fleet layout.
- When performing that migration, move all references together so `flake.nix`, CI, bootstrap scripts, and docs stay aligned.

---

*Structure analysis: 2026-03-21*

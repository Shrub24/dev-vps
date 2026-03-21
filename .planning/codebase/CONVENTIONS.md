# Coding Conventions

**Analysis Date:** 2026-03-21

## Naming Patterns

**Files:**
- Use lowercase file names with hyphenated infrastructure descriptors for Nix modules and ops scripts, such as `nixos/disko-config.nix`, `nixos/digitalocean.nix`, and `deploy.sh`.
- Keep repository control files at conventional root names such as `flake.nix`, `justfile`, `.sops.yaml`, and `renovate.json`.
- Use descriptive Markdown document names in lowercase under `docs/`, such as `docs/architecture.md` and `docs/decisions.md`.

**Functions:**
- Shell functions are not used in the current codebase; `deploy.sh` keeps flow linear and uses a `CMD` array instead of helper functions in `deploy.sh:12`.
- Nix logic favors attribute composition over local helper functions; the only local binding in `flake.nix` and `nixos/configuration.nix` is simple setup in `let` blocks such as `overlay`, `pkgs`, `unstablePkgs`, and `sshKeys` in `flake.nix:24` and `nixos/configuration.nix:7`.

**Variables:**
- Use lowerCamelCase for Nix locals and attributes, such as `unstablePkgs`, `sshKeys`, `authKeyFile`, and `backupFileExtension` in `flake.nix:38`, `nixos/configuration.nix:8`, and `flake.nix:75`.
- Use uppercase snake case for shell variables and shell parameters, such as `TARGET_IP`, `EXTRA_FILES`, and `CMD` in `deploy.sh:9`.
- Use short lowercase names for `just` variables, such as `ip` and `user` in `justfile:3`.

**Types:**
- Statically declared types are not present; the repository is currently Nix, shell, YAML, JSON, and Markdown only.
- Use Nix option typing through module declarations rather than custom type aliases; examples are boolean, list, and string option assignments in `nixos/configuration.nix` and `nixos/digitalocean.nix`.

## Code Style

**Formatting:**
- Use two-space indentation in `flake.nix`, `nixos/configuration.nix`, `nixos/digitalocean.nix`, `.github/workflows/ci.yml`, and `renovate.json`.
- Use trailing semicolons for Nix assignments and place list items one per line, as shown throughout `flake.nix` and `nixos/configuration.nix`.
- Prefer double-quoted strings in Nix and YAML, including filesystem paths and service flags in `nixos/configuration.nix:40`, `nixos/configuration.nix:128`, and `.sops.yaml:4`.
- Shell scripts are strict-mode by default with `set -euo pipefail`, as in `deploy.sh:2` and the `justfile` shell declaration in `justfile:1`.
- `flake.nix` includes `nixfmt` and `statix` in the development shell in `flake.nix:48`, but no dedicated formatter or linter config file is present at the repository root.

**Linting:**
- No standalone lint config such as `.editorconfig`, `treefmt.toml`, or `statix.toml` is present.
- The repository signals Nix style expectations through available tools rather than enforced local config: `nixfmt` and `statix` are installed in `flake.nix:58` and `flake.nix:59`.
- CI validation in `.github/workflows/ci.yml` focuses on `nix flake check` and `nix build`, not separate lint-only steps.

## Import Organization

**Order:**
1. Destructure module inputs first, with `...` last, as in `flake.nix:14`, `nixos/configuration.nix:1`, and `nixos/digitalocean.nix:1`.
2. Define local `let` bindings before the returned attribute set when shared values are needed, as in `flake.nix:24` and `nixos/configuration.nix:7`.
3. Keep imported modules grouped near the top in an `imports` list, starting with upstream modules and ending with local files, as in `nixos/configuration.nix:13` and `nixos/digitalocean.nix:3`.

**Path Aliases:**
- No path alias system is used.
- Local Nix files are referenced with relative paths such as `./nixos/configuration.nix`, `./disko-config.nix`, and `../secrets/secrets.yaml` in `flake.nix:78` and `nixos/configuration.nix:16`.
- Upstream module paths are composed from `modulesPath`, as in `nixos/configuration.nix:14` and `nixos/digitalocean.nix:4`.

## Error Handling

**Patterns:**
- Prefer declarative guardrails over imperative recovery. Examples include `unitConfig.ConditionPathExists` on `tailscale-serve-codenomad` in `nixos/configuration.nix:150` and explicit systemd ordering on secret-dependent services in `nixos/configuration.nix:133`.
- Shell entrypoints fail fast on invalid usage, as in the argument check and non-zero exit in `deploy.sh:4`.
- `just` recipes intentionally allow some operator commands to fail without breaking the session by appending `|| true`, as in `justfile:20`, `justfile:23`, and `justfile:47`.
- Nix modules rely on `lib.mkDefault` and `lib.mkForce` to resolve configuration conflicts instead of branching logic, as in `nixos/disko-config.nix:5` and `nixos/digitalocean.nix:7`.

## Logging

**Framework:** systemd journal and CLI output

**Patterns:**
- Operational visibility is obtained through remote `journalctl` and `systemctl` commands wrapped in `just` recipes such as `justfile:37`, `justfile:40`, `justfile:43`, and `justfile:46`.
- No in-repo application logging abstraction exists; runtime output is delegated to host services and systemd.

## Comments

**When to Comment:**
- Keep comments sparse and task-focused. The only recurring inline comments are instructional comments in templates and docs, such as `secrets/secrets.template.yaml:1` and `docs/architecture.md`.
- Prefer descriptive option names and block grouping over explanatory inline comments in Nix files; `nixos/configuration.nix` is organized by concern with almost no comments.

**JSDoc/TSDoc:**
- Not applicable. No JavaScript or TypeScript source files are present.
- Repository-level guidance is documented in Markdown files such as `README.md`, `docs/architecture.md`, and `CLAUDE.md`.

## Function Design

**Size:**
- Keep shell scripts small and single-purpose. `deploy.sh` is a 22-line wrapper around `nixos-anywhere` in `deploy.sh`.
- Keep Nix modules organized as flat option blocks rather than deeply nested abstractions; `nixos/configuration.nix` groups related concerns into contiguous sections.

**Parameters:**
- Shell interfaces accept positional parameters with minimal parsing, as in `deploy.sh:4`.
- `just` recipes expose parameters inline with defaults, such as `logs unit="codenomad" lines="200"` in `justfile:37`.

**Return Values:**
- Shell scripts return process status and print direct CLI output; no custom structured output format is used.
- Nix files return attribute sets and module option trees.

## Module Design

**Exports:**
- Each Nix file exports a single top-level attrset or module, as in `flake.nix`, `nixos/configuration.nix`, `nixos/disko-config.nix`, and `nixos/digitalocean.nix`.
- Compose the system by stacking modules in `flake.nix:65` rather than by creating barrel files or shared export indexes.

**Barrel Files:**
- Not used.
- The repository currently has no `default.nix` aggregators, package index files, or module collection barrels.

---

*Convention analysis: 2026-03-21*

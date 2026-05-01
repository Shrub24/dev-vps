# Testing Patterns

**Analysis Date:** 2026-03-21

## Test Framework

**Runner:**
- No unit or integration test runner is configured.
- Current automated verification is Nix evaluation and build validation driven by `justfile` and `.github/workflows/ci.yml`.
- Config: `.github/workflows/ci.yml`, `justfile`, and `flake.nix`

**Assertion Library:**
- Not applicable. No assertion library or test harness is present.

**Run Commands:**
```bash
just check              # Run the main local validation flow from `justfile`
just flake-check        # Run `nix flake check --no-build --no-write-lock-file path:.`
just build              # Build the NixOS system derivation without linking
just vm-build           # Build the VM derivation without linking
```

## Test File Organization

**Location:**
- No `*.test.*` or `*.spec.*` files exist anywhere in `/mnt/LinuxData/Projects/dev/dev-vps`.
- Verification is centralized in root-level orchestration files: `justfile`, `.github/workflows/ci.yml`, and `flake.nix`.

**Naming:**
- Validation commands are recipe-oriented, using imperative names such as `check`, `flake-check`, `build`, and `vm-build` in `justfile:12`, `justfile:28`, `justfile:31`, and `justfile:34`.

**Structure:**
```text
repository root
|- justfile                  # Local validation entrypoints
|- .github/workflows/ci.yml  # CI execution of flake and build checks
`- flake.nix                 # Defines buildable outputs under test
```

## Test Structure

**Suite Organization:**
```text
`just check`
  -> `just flake-check`
  -> `just build`

CI `build` job
  -> `nix flake check --no-build`
  -> `nix build --no-link path:.#nixosConfigurations.dev-vps.config.system.build.toplevel`
  -> `nix build --no-link path:.#packages.x86_64-linux.{codenomad,opencode,repo-sync}`
```

**Patterns:**
- Use `just check` in `justfile:12` as the top-level local gate.
- Keep CI checks explicit and linear in `.github/workflows/ci.yml:18` through `.github/workflows/ci.yml:28`.
- Favor no-link builds (`--no-link`) and no-lockfile writes (`--no-write-lock-file`) to validate outputs without mutating the working tree, as in `justfile:29`, `justfile:32`, and `justfile:35`.

## Mocking

**Framework:**
- Not used.

**Patterns:**
```text
No mocking layer is present. Current verification builds real flake outputs.
```

**What to Mock:**
- Not applicable in the current repository state.

**What NOT to Mock:**
- Do not replace flake evaluation or package builds with placeholder scripts; the existing posture validates real Nix outputs from `flake.nix`.

## Fixtures and Factories

**Test Data:**
```yaml
# `secrets/secrets.template.yaml` is an operator reference template,
# not an automated test fixture.
codenomad:
  env: |
    CODENOMAD_SERVER_USERNAME=saurabhj
    CODENOMAD_SERVER_PASSWORD=REPLACE_WITH_STRONG_PASSWORD
```

**Location:**
- No dedicated fixture directory exists.
- `secrets/secrets.template.yaml` is the closest reusable example data file, but it supports manual secret preparation rather than test execution.

## Coverage

**Requirements:** None enforced

**View Coverage:**
```bash
Not applicable; no coverage tooling is configured.
```

## Test Types

**Unit Tests:**
- Not used. No test runner, test files, or isolated unit test conventions are present.

**Integration Tests:**
- Build-level integration checks are present through `nix flake check` and `nix build` in `justfile` and `.github/workflows/ci.yml`.
- These checks validate evaluation and derivation wiring, not runtime behavior of deployed services.

**E2E Tests:**
- Not used.
- No NixOS VM tests, smoke tests, or deployment verification scripts are implemented in the current tree.

## Common Patterns

**Async Testing:**
```text
Not applicable; no async test harness is present.
```

**Error Testing:**
```text
Current failure detection relies on command exit codes.
Example: `deploy.sh` exits with usage information when no target IP is supplied.
```

## Current Verification Posture

- `justfile` establishes the intended local gate, but it currently depends on a flake that does not evaluate cleanly because `flake.nix:28`, `flake.nix:29`, and `flake.nix:30` reference `pkgs/codenomad/package.nix`, `pkgs/opencode/package.nix`, and `pkgs/repo-sync/package.nix` while `pkgs/` is empty.
- `flake.nix:76` also references `home/dev.nix` while `home/` is empty, so Home Manager wiring is incomplete.
- A direct run of `nix flake check --no-build --no-write-lock-file path:.` from `/mnt/LinuxData/Projects/dev/dev-vps` fails during package output evaluation with `No such file or directory` for `pkgs/codenomad/package.nix`.
- CI in `.github/workflows/ci.yml` is configured for `push` to `main` and all pull requests, but its checks mirror the same broken flake outputs.
- Planning documents mention future smoke tests, VM tests, and broader validation, but those flows are not implemented anywhere under the current repository tree.

---

*Testing analysis: 2026-03-21*

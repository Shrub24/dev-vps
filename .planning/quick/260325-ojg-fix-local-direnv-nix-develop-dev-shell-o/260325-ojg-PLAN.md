---
phase: quick-260325-ojg-fix-local-direnv-nix-develop-dev-shell-o
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - flake.nix
  - justfile
autonomous: true
requirements:
  - QUICK-260325-01
must_haves:
  truths:
    - "On x86_64-linux workstations, `direnv` can enter the repo dev shell without flake system errors."
    - "The canonical host output remains pinned to `aarch64-linux` for `oci-melb-1`."
  artifacts:
    - path: "flake.nix"
      provides: "Multi-system dev shell outputs plus unchanged aarch64 host config"
      contains: "devShells.x86_64-linux.default and nixosConfigurations.oci-melb-1"
    - path: "justfile"
      provides: "Fast local automated shell regression check command"
      contains: "devshell-check"
  key_links:
    - from: ".envrc"
      to: "flake.nix"
      via: "`use flake` resolves current system devShell"
      pattern: "devShells\\.<current-system>\\.default"
    - from: "justfile"
      to: "flake.nix"
      via: "nix develop smoke-check command"
      pattern: "nix develop"
---

<objective>
Restore local x86_64 developer shell usability after the repository standardized host outputs around `aarch64-linux`.

Purpose: Keep day-to-day local operations (`direnv`, `nix develop`, `just`) working on x86 while preserving the fleet’s canonical ARM host target.
Output: Updated flake devShell definition plus one repeatable local smoke-check command.
</objective>

<execution_context>
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/workflows/execute-plan.md
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@flake.nix
@.envrc
@justfile
</context>

<tasks>

<task type="auto">
  <name>Task 1: Make devShell outputs host-agnostic while keeping ARM host config fixed</name>
  <files>flake.nix</files>
  <action>Refactor flake outputs so `devShells` are generated for both `x86_64-linux` and `aarch64-linux` (e.g., via `genAttrs`), while keeping `nixosConfigurations.oci-melb-1.system = "aarch64-linux"` unchanged. Preserve the existing tool package list in the default dev shell. Do not change host deployment outputs or target-host semantics.</action>
  <verify>
    <automated>nix eval .#devShells.x86_64-linux.default.drvPath && nix eval .#devShells.aarch64-linux.default.drvPath && nix eval .#nixosConfigurations.oci-melb-1.pkgs.stdenv.hostPlatform.system</automated>
  </verify>
  <done>`nix eval` succeeds for both dev shell systems, and host platform still evaluates to `aarch64-linux`.</done>
</task>

<task type="auto">
  <name>Task 2: Add a quick local regression command for direnv/nix develop</name>
  <files>justfile</files>
  <action>Add a `devshell-check` recipe that runs a non-interactive `nix develop` smoke test on the current machine (x86 expected locally) and verifies key tooling availability (at minimum `just --list` succeeds inside the shell). Keep command fast (&lt;60s typical) and side-effect free.</action>
  <verify>
    <automated>just devshell-check</automated>
  </verify>
  <done>Running `just devshell-check` exits 0 and confirms local `nix develop` shell entry remains functional.</done>
</task>

</tasks>

<verification>
Run `direnv allow` in repo root, then `direnv reload` and confirm no missing `devShells.x86_64-linux`-style errors occur.
</verification>

<success_criteria>
- Local x86_64 `direnv` activation succeeds against `.envrc`.
- `nix develop` works on x86_64 without weakening the `oci-melb-1` ARM target.
- A repeatable CLI smoke check exists to catch regressions quickly.
</success_criteria>

<output>
After completion, create `.planning/quick/260325-ojg-fix-local-direnv-nix-develop-dev-shell-o/260325-ojg-SUMMARY.md`
</output>

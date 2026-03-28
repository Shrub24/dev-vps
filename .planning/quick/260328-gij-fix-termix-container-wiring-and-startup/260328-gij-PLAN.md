---
phase: quick-260328-gij-fix-termix-container-wiring-and-startup
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - modules/services/termix.nix
  - tests/phase-03-access-contract.sh
autonomous: true
requirements:
  - QUICK-260328-GIJ-01
must_haves:
  truths:
    - "A switch no longer points Termix at a non-existent image or legacy runtime env/path contract."
    - "Termix remains a private Tailscale-only admin application composed through `modules/applications/admin.nix`."
    - "Verification fails automatically if legacy Termix wiring (`termix-official`, `TERMIX_GUACD_*`, `/var/lib/termix`) returns."
  artifacts:
    - path: "modules/services/termix.nix"
      provides: "Upstream-aligned Termix + guacd container wiring"
      contains: "ghcr.io/lukegus/termix:latest"
    - path: "tests/phase-03-access-contract.sh"
      provides: "Executable regression checks for private Termix wiring"
      contains: "ghcr.io/lukegus/termix:latest"
  key_links:
    - from: "modules/applications/admin.nix"
      to: "modules/services/termix.nix"
      via: "application import"
      pattern: "modules/services/termix\\.nix"
---

<objective>
Repair `modules/services/termix.nix` so the Termix container startup matches upstream runtime expectations and stops failing during switch.

Purpose: close the startup regression introduced in the initial Termix add-on by aligning the image reference, persistent data mount, and guacd environment contract with the upstream runtime while preserving the existing private admin application boundary and Tailscale-only posture.
Output: corrected Termix container wiring plus contract assertions that lock the fixed runtime contract in place.
</objective>

<execution_context>
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/workflows/execute-plan.md
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@modules/services/termix.nix
@modules/applications/admin.nix
@tests/phase-03-access-contract.sh
@docs/architecture.md
@docs/decisions.md
@.planning/quick/260328-fax-make-application-groups-and-add-termix/260328-fax-SUMMARY.md

<decisions>
- D-01: Preserve the current application-layer structure; keep Termix owned by `modules/services/termix.nix` and composed by `modules/applications/admin.nix`.
- D-02: Keep Termix private/Tailscale-only; do not add public firewall rules.
- D-03: Fix runtime wiring to match upstream Termix expectations instead of hand-rolling alternate env/path names.
- D-04: Avoid reverting or absorbing unrelated dirty worktree changes already present.
</decisions>

<interfaces>
From `modules/applications/admin.nix`:
```nix
imports = [
  ../../modules/services/tailscale.nix
  ../../modules/services/termix.nix
];
```

From `modules/services/termix.nix` (current broken contract):
```nix
termix = {
  image = "ghcr.io/termix-official/termix:latest";
  environment = {
    TERMIX_GUACD_HOST = "127.0.0.1";
    TERMIX_GUACD_PORT = "4822";
  };
  volumes = [ "/srv/data/termix/data:/var/lib/termix" ];
};
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Correct Termix container runtime wiring to upstream contract</name>
  <files>modules/services/termix.nix</files>
  <action>Per D-01 and D-03, update only `modules/services/termix.nix` so the Termix container matches the upstream runtime contract already established in grounded findings: switch the image from `ghcr.io/termix-official/termix:latest` to `ghcr.io/lukegus/termix:latest`, replace the legacy persistent mount target `/var/lib/termix` with `/app/data`, and rename the guacd environment variables from `TERMIX_GUACD_HOST` / `TERMIX_GUACD_PORT` to `GUACD_HOST` / `GUACD_PORT`. Keep the existing app-layer ownership intact via `modules/applications/admin.nix`, preserve the private/Tailscale-only posture per D-02 by adding no firewall rules, and do not refactor unrelated container/systemd wiring beyond what is required to make the runtime contract coherent. Because the observed failure is specifically `podman-termix.service` exit 125 while `podman-guacd.service` is not reported failed, treat this as a Termix container definition fix, not a broad service-topology rewrite.</action>
  <verify>
    <automated>rg --fixed-strings 'ghcr.io/lukegus/termix:latest' modules/services/termix.nix && rg --fixed-strings 'GUACD_HOST = "127.0.0.1";' modules/services/termix.nix && rg --fixed-strings 'GUACD_PORT = "4822";' modules/services/termix.nix && rg --fixed-strings '/srv/data/termix/data:/app/data' modules/services/termix.nix && ! rg --fixed-strings 'termix-official/termix' modules/services/termix.nix && ! rg --fixed-strings 'TERMIX_GUACD_' modules/services/termix.nix && ! rg --fixed-strings '/var/lib/termix' modules/services/termix.nix</automated>
  </verify>
  <done>`modules/services/termix.nix` points at the upstream-supported image and runtime contract, with no leftover legacy env names or data mount target that would keep `podman-termix.service` miswired.</done>
</task>

<task type="auto">
  <name>Task 2: Lock the corrected Termix integration into the access contract</name>
  <files>tests/phase-03-access-contract.sh</files>
  <action>Per D-02 and D-03, extend `tests/phase-03-access-contract.sh` so the repository contract checks enforce the corrected Termix runtime expectations alongside the existing private-access assertions: require the `ghcr.io/lukegus/termix:latest` image, require `/srv/data/termix/data:/app/data`, require `GUACD_HOST` and `GUACD_PORT`, and fail if legacy `termix-official`, `TERMIX_GUACD_*`, or `/var/lib/termix` strings reappear. Keep the current application-layer/private-admin assertions intact, and edit surgically per D-04 so unrelated access and break-glass checks remain unchanged.</action>
  <verify>
    <automated>bash tests/phase-03-access-contract.sh && nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.oci-melb-1.config.virtualisation.oci-containers.containers.termix.image' --raw</automated>
  </verify>
  <done>The phase-03 access contract now protects the fixed Termix runtime wiring and still proves the service remains private/Tailscale-only through the existing application boundary.</done>
</task>

</tasks>

<verification>
Run `bash tests/phase-03-access-contract.sh` and confirm `nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.oci-melb-1.config.virtualisation.oci-containers.containers.termix.image' --raw` returns `ghcr.io/lukegus/termix:latest`. This proves the corrected runtime contract is declared and guarded against regression.
</verification>

<success_criteria>
- `modules/services/termix.nix` uses `ghcr.io/lukegus/termix:latest`, `GUACD_HOST` / `GUACD_PORT`, and `/srv/data/termix/data:/app/data`.
- No new public firewall openings are introduced; Termix remains private/Tailscale-only through the existing admin application layer.
- `tests/phase-03-access-contract.sh` fails if the old image, env variable names, or `/var/lib/termix` mount target reappear.
</success_criteria>

<output>
After completion, create `.planning/quick/260328-gij-fix-termix-container-wiring-and-startup/260328-gij-SUMMARY.md`
</output>

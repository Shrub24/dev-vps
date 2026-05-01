---
phase: quick-260328-fax-make-application-groups-and-add-termix
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - hosts/oci-melb-1/default.nix
  - modules/applications/music.nix
  - modules/applications/admin.nix
  - modules/services/termix.nix
  - tests/phase-03-access-contract.sh
  - tests/phase-04-service-flow-contract.sh
  - docs/architecture.md
  - docs/decisions.md
  - docs/plan.md
autonomous: true
requirements:
  - QUICK-260328-FAX-01
must_haves:
  truths:
    - "Operator can see `oci-melb-1` composed through logical application modules instead of only direct low-level service imports."
    - "The current music stack still runs through Syncthing, Navidrome, and slskd with the same private media/data flow after composition moves up one layer."
    - "Termix runs on `oci-melb-1` as a private Tailscale-only admin application with no new public firewall exposure."
    - "Verification fails if the application layer disappears or the private admin posture for Termix drifts."
  artifacts:
    - path: "modules/applications/music.nix"
      provides: "Music application composition for Syncthing, Navidrome, and slskd"
      contains: "../services/syncthing.nix"
    - path: "modules/applications/admin.nix"
      provides: "Admin application composition for Tailscale and Termix"
      contains: "../services/termix.nix"
    - path: "modules/services/termix.nix"
      provides: "Low-level Termix container service wiring with persistent state"
      contains: "virtualisation.oci-containers"
    - path: "tests/phase-03-access-contract.sh"
      provides: "Executable private-admin access assertions"
      contains: "termix"
    - path: "tests/phase-04-service-flow-contract.sh"
      provides: "Executable application-layer and music-stack flow assertions"
      contains: "modules/applications/music.nix"
  key_links:
    - from: "hosts/oci-melb-1/default.nix"
      to: "modules/applications/music.nix"
      via: "host import"
      pattern: "modules/applications/music\\.nix"
    - from: "hosts/oci-melb-1/default.nix"
      to: "modules/applications/admin.nix"
      via: "host import"
      pattern: "modules/applications/admin\\.nix"
    - from: "modules/applications/music.nix"
      to: "modules/services/navidrome.nix"
      via: "application import"
      pattern: "services/navidrome\\.nix"
    - from: "modules/applications/admin.nix"
      to: "modules/services/termix.nix"
      via: "application import"
      pattern: "services/termix\\.nix"
---

<objective>
Introduce a narrow applications composition layer and add Termix as a private admin application on `oci-melb-1`.

Purpose: lift the current host from direct service-by-service composition to a small logical application layer without broad reorganization, while preserving the existing private/Tailscale-first posture and keeping low-level implementation units under `modules/services/`.
Output: new `modules/applications/{music,admin}.nix`, a dedicated `modules/services/termix.nix`, host rewiring, and contract/doc updates that prove both the new composition boundary and the private admin posture.
</objective>

<execution_context>
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/workflows/execute-plan.md
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@hosts/oci-melb-1/default.nix
@modules/services/tailscale.nix
@modules/services/syncthing.nix
@modules/services/navidrome.nix
@modules/services/slskd.nix
@modules/providers/oci/default.nix
@tests/phase-03-access-contract.sh
@tests/phase-04-service-flow-contract.sh
@docs/architecture.md
@docs/decisions.md
@docs/plan.md

<decisions>
- D-01: Add an applications composition layer for logical systems/services.
- D-02: Keep low-level implementation units under `modules/services/`.
- D-03: Make a narrow first pass, not a broad repo reorg.
- D-04: Add Termix on `oci-melb-1` as a private Tailscale-only admin application.
- D-05: Group current music stack under an application module as well.
- D-06: Avoid reverting or absorbing unrelated dirty worktree changes already present.
</decisions>

<interfaces>
From `hosts/oci-melb-1/default.nix`:
```nix
imports = [
  ../../modules/services/tailscale.nix
  ../../modules/services/syncthing.nix
  ../../modules/services/navidrome.nix
  ../../modules/services/slskd.nix
  ../../modules/providers/oci/default.nix
];

networking.firewall.trustedInterfaces = [ "tailscale0" ];

services.slskd.domain = "oci-melb-1";
services.slskd.environmentFile = "/var/lib/slskd/environment";
```

From `modules/services/navidrome.nix`:
```nix
services.navidrome = {
  enable = true;
  openFirewall = false;
  settings = {
    MusicFolder = "/srv/data/media";
    DataFolder = "/srv/data/navidrome";
  };
};
```

From `modules/services/slskd.nix`:
```nix
services.slskd = {
  enable = true;
  openFirewall = false;
  settings.directories = {
    downloads = "/srv/data/inbox/complete";
    incomplete = "/srv/data/inbox/incomplete";
  };
};
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add the first-pass applications layer and Termix service module</name>
  <files>modules/applications/music.nix, modules/applications/admin.nix, modules/services/termix.nix</files>
  <action>Per D-01 and D-05, create `modules/applications/music.nix` as the composition boundary for the existing music stack by importing the current low-level service modules for Syncthing, Navidrome, and slskd, then moving the music-specific cross-service glue there instead of leaving it in the host file. Per D-01 and D-04, create `modules/applications/admin.nix` as the composition boundary for private admin access by importing `../services/tailscale.nix` plus a new `../services/termix.nix`. Per D-02 and D-04, implement `modules/services/termix.nix` as a low-level container-based module using NixOS Podman/OCI container primitives, with a Termix app container and guacd sidecar translated from upstream compose semantics, persistent data rooted under `/srv/data/termix`, and explicit runtime ordering after network availability. Keep Termix private by adding no public firewall openings and by relying on the existing `tailscale0` trust boundary rather than broadening exposure. Per D-03, do not invent a general application framework beyond these two modules, and do not move unrelated services or provider code.</action>
  <verify>
    <automated>rg --fixed-strings 'modules/services/syncthing.nix' modules/applications/music.nix && rg --fixed-strings 'modules/services/termix.nix' modules/applications/admin.nix && rg 'virtualisation\.(podman|oci-containers)|guacd|termix|/srv/data/termix' modules/services/termix.nix</automated>
  </verify>
  <done>`modules/applications/music.nix` and `modules/applications/admin.nix` exist as the only new first-pass composition layer, and `modules/services/termix.nix` holds the concrete container implementation details for a persistent private Termix deployment.</done>
</task>

<task type="auto">
  <name>Task 2: Rewire the host and lock the new boundaries into contracts and canonical docs</name>
  <files>hosts/oci-melb-1/default.nix, tests/phase-03-access-contract.sh, tests/phase-04-service-flow-contract.sh, docs/architecture.md, docs/decisions.md, docs/plan.md</files>
  <action>Per D-01, D-03, and D-05, update `hosts/oci-melb-1/default.nix` so it imports the new application modules instead of importing `tailscale`, `syncthing`, `navidrome`, and `slskd` directly, and move only the relevant cross-service glue out of the host while preserving all unrelated behavior. Per D-06, edit surgically around the already-dirty host and test files: keep unrelated changes already present in `hosts/oci-melb-1/default.nix` and `tests/phase-03-access-contract.sh`, and do not reset, reorder broadly, or absorb other in-flight work. Update `tests/phase-03-access-contract.sh` to prove the Termix private-admin posture (application import present, no public firewall opening introduced, Tailscale-first access assumptions preserved). Update `tests/phase-04-service-flow-contract.sh` to prove the music stack now composes through `modules/applications/music.nix` while still anchoring on the existing Syncthing/Navidrome/slskd data flow. Update `docs/architecture.md`, `docs/decisions.md`, and `docs/plan.md` in the same change window to record the new `modules/applications/*.nix` boundary and the Termix Tailscale-only admin addition, without presenting this as a broad repository reorg.</action>
  <verify>
    <automated>bash tests/phase-03-access-contract.sh && bash tests/phase-04-service-flow-contract.sh && nix flake check --no-build --no-write-lock-file path:.</automated>
  </verify>
  <done>`oci-melb-1` composes through application modules, both contract scripts enforce the new composition/admin posture, and canonical docs describe the added `modules/applications` boundary and private Termix service consistently.</done>
</task>

</tasks>

<verification>
Run `bash tests/phase-03-access-contract.sh`, `bash tests/phase-04-service-flow-contract.sh`, and `nix flake check --no-build --no-write-lock-file path:.`. All must pass with the repository alone, proving the application layer exists, the music stack still follows the established media flow, and Termix remains private/Tailscale-only.
</verification>

<success_criteria>
- `hosts/oci-melb-1/default.nix` imports `modules/applications/music.nix` and `modules/applications/admin.nix` instead of directly importing the current music/admin service modules.
- `modules/services/termix.nix` contains the low-level Termix + guacd container implementation with persistent state under `/srv/data/termix` and no public firewall opening.
- Phase contract tests fail if the repo drops the new application-layer boundary or weakens the private admin posture.
- Canonical docs mention `modules/applications/*.nix` as an active architecture path and describe Termix as a Tailscale-only admin application.
</success_criteria>

<output>
After completion, create `.planning/quick/260328-fax-make-application-groups-and-add-termix/260328-fax-SUMMARY.md`
</output>

---
phase: quick-260328-ivn-serve-termix-over-tailscale-serve-https-
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - modules/applications/admin.nix
  - modules/services/termix.nix
  - tests/phase-03-access-contract.sh
  - .planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md
autonomous: true
requirements:
  - QUICK-260328-IVN-01
must_haves:
  truths:
    - "Tailnet users reach Termix through Tailscale HTTPS at `/termix`, not through native Termix TLS or public ingress."
    - "Termix itself only listens on local HTTP at `127.0.0.1:8083` on the host side."
    - "Tailscale Serve ownership lives in `modules/applications/admin.nix`, while `modules/services/tailscale.nix` stays application-agnostic."
    - "Verification fails if `/termix` Serve routing, localhost-only binding, or private-only posture drifts."
  artifacts:
    - path: "modules/applications/admin.nix"
      provides: "Admin-layer Tailscale Serve orchestration for Termix"
      contains: "tailscale serve"
    - path: "modules/services/termix.nix"
      provides: "Local-only Termix backend listener"
      contains: "127.0.0.1:8083:8080"
    - path: "tests/phase-03-access-contract.sh"
      provides: "Executable Serve and private-access regression checks"
      contains: "/termix"
    - path: ".planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md"
      provides: "Operator runbook guidance for checking Serve status"
      contains: "tailscale serve status"
  key_links:
    - from: "modules/applications/admin.nix"
      to: "modules/services/termix.nix"
      via: "application import"
      pattern: "modules/services/termix\\.nix"
    - from: "modules/applications/admin.nix"
      to: "127.0.0.1:8083"
      via: "tailscale serve reverse proxy target"
      pattern: "127\\.0\\.0\\.1:8083"
    - from: "modules/applications/admin.nix"
      to: "tailscaled.service"
      via: "systemd dependency"
      pattern: "tailscaled"
---

<objective>
Serve Termix through Tailscale HTTPS at `/termix` while keeping the app itself on localhost HTTP only.

Purpose: satisfy the private admin access requirement without broadening the Tailscale service module or adding native HTTPS/public ingress to Termix.
Output: admin-layer Tailscale Serve orchestration, localhost-only Termix binding, contract coverage, and a small operator runbook update.
</objective>

<execution_context>
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/workflows/execute-plan.md
@/mnt/LinuxData/Projects/dev/dev-vps/.opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@modules/applications/admin.nix
@modules/services/termix.nix
@modules/services/tailscale.nix
@tests/phase-03-access-contract.sh
@docs/architecture.md
@docs/decisions.md
@.planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md
@.planning/quick/260328-fax-make-application-groups-and-add-termix/260328-fax-SUMMARY.md
@.planning/quick/260328-gij-fix-termix-container-wiring-and-startup/260328-gij-SUMMARY.md

<decisions>
- D-01: Execute this as a quick task with a single atomic plan.
- D-02: Do NOT edit `modules/services/tailscale.nix`; keep the Tailscale module application-agnostic.
- D-03: Add Tailscale Serve ownership/config at the application layer in `modules/applications/admin.nix`.
- D-04: Termix must be served over Tailscale HTTPS only.
- D-05: Do not add native Termix HTTPS.
- D-06: Local HTTP on `127.0.0.1:8083` is acceptable.
- D-07: Use `/termix` as the served path.
- D-08: Preserve private-only posture and avoid public ingress.
</decisions>

<interfaces>
From `modules/applications/admin.nix`:
```nix
{ ... }:
{
  imports = [
    ../../modules/services/tailscale.nix
    ../../modules/services/termix.nix
  ];
}
```

From `modules/services/termix.nix`:
```nix
termix = {
  image = "ghcr.io/lukegus/termix:latest";
  ports = [
    "8083:8080"
  ];
};
```

From `hosts/oci-melb-1/default.nix`:
```nix
networking.firewall.trustedInterfaces = [ "tailscale0" ];

services.tailscale = {
  extraUpFlags = [
    "--hostname=oci-melb-1"
    "--advertise-tags=tag:oci-melb-1"
  ];
};
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Bind Termix to localhost and add admin-layer Tailscale Serve orchestration</name>
  <files>modules/services/termix.nix, modules/applications/admin.nix</files>
  <action>Per D-03, D-04, D-05, D-06, and D-07, keep the low-level app runtime details in `modules/services/termix.nix` but change the published host binding from a generic `8083:8080` mapping to `127.0.0.1:8083:8080` so Termix is only reachable over local HTTP on the host. Then expand `modules/applications/admin.nix` (do not touch `modules/services/tailscale.nix`, per D-02) so the admin layer owns a dedicated systemd oneshot service such as `tailscale-serve-termix` that runs after `tailscaled.service` and `podman-termix.service`, configures `tailscale serve --yes --bg --https=443 --set-path /termix http://127.0.0.1:8083`, and removes that mount on stop with the matching `off` command. Keep this strictly Serve-only per D-04 and D-05: no Funnel, no public ingress, no native app TLS, no cert/key plumbing inside Termix, and no attempt to generalize Serve into the reusable tailscale module.</action>
  <verify>
    <automated>rg --fixed-strings '"127.0.0.1:8083:8080"' modules/services/termix.nix && rg --fixed-strings 'tailscale serve --yes --bg --https=443 --set-path /termix http://127.0.0.1:8083' modules/applications/admin.nix && rg --fixed-strings 'podman-termix.service' modules/applications/admin.nix && ! rg --fixed-strings 'funnel' modules/applications/admin.nix</automated>
  </verify>
  <done>Termix only exposes local HTTP on `127.0.0.1:8083`, and `modules/applications/admin.nix` declaratively owns the `/termix` Tailscale HTTPS Serve route without modifying the reusable Tailscale service module.</done>
</task>

<task type="auto">
  <name>Task 2: Lock Serve routing into contract checks and the day-2 runbook</name>
  <files>tests/phase-03-access-contract.sh, .planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md</files>
  <action>Per D-02, D-03, D-04, D-05, D-07, and D-08, extend `tests/phase-03-access-contract.sh` so it asserts the new ownership and access contract: `modules/applications/admin.nix` contains the Serve configuration, `/termix` is the served path, `http://127.0.0.1:8083` is the backend target, `modules/services/termix.nix` binds `127.0.0.1:8083:8080`, and `modules/services/tailscale.nix` remains free of Serve-specific application wiring. Add negative checks that fail on Funnel/public-ingress strings and on any native-HTTPS drift if those strings are introduced in the admin/termix modules. Update `03-OPERATIONS.md` so the existing private-network health sequence includes a concrete `tailscale serve status` check and states that Termix should appear at `/termix` over Tailscale HTTPS. Keep the edit surgical and do not disturb unrelated break-glass or access checks already present in the dirty worktree.</action>
  <verify>
    <automated>bash tests/phase-03-access-contract.sh && rg --fixed-strings 'tailscale serve status' .planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md && rg --fixed-strings '/termix' .planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md</automated>
  </verify>
  <done>The repository has executable regression checks for the `/termix` Serve contract and the operations runbook tells the operator exactly how to confirm the Tailscale HTTPS route is present.</done>
</task>

</tasks>

<verification>
Run `bash tests/phase-03-access-contract.sh` and `/nix/var/nix/profiles/default/bin/nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.oci-melb-1.config; in { termixPorts = cfg.virtualisation.oci-containers.containers.termix.ports; hasServeUnit = builtins.hasAttr "tailscale-serve-termix" cfg.systemd.services; }' | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["termixPorts"] == ["127.0.0.1:8083:8080"]; assert data["hasServeUnit"] is True'`. Both must pass.</verification>

<success_criteria>
- `modules/services/termix.nix` exposes Termix only on `127.0.0.1:8083:8080`.
- `modules/applications/admin.nix` owns the Tailscale Serve declaration for HTTPS path `/termix` targeting local HTTP `127.0.0.1:8083`.
- `modules/services/tailscale.nix` remains application-agnostic and unmodified by this work.
- Phase-03 access checks and the operations runbook both make the `/termix` private Serve contract explicit.
</success_criteria>

<output>
After completion, create `.planning/quick/260328-ivn-serve-termix-over-tailscale-serve-https-/260328-ivn-SUMMARY.md`
</output>

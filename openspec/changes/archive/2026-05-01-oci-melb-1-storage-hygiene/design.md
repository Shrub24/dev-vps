## Context

`oci-melb-1` currently uses a 20G root filesystem on `/dev/sda3`, while deploy-rs builds occur on the host because it is the native `aarch64-linux` machine. Recent inspection showed root pressure coming from three separate sources: a non-trivial Nix store, oversized journald retention under `/var/log/journal`, and several gigabytes of Podman image/layer storage under `/var/lib/containers/storage`. This means the immediate problem is not a single runaway directory but the lack of a bounded retention policy for root-backed operational state.

The repo already enables `nix.settings.auto-optimise-store = true` in `modules/core/base.nix`, and several services already depend on Podman. The missing piece is a host policy that constrains retention and cleanup frequency without introducing a more complex storage redesign before it is needed.

## Goals / Non-Goals

**Goals:**
- Add a declarative storage-hygiene baseline for `oci-melb-1` that safely reclaims root-disk space during routine operation.
- Bound journald growth and Podman artifact accumulation with automatic cleanup.
- Tighten Nix retention enough to reduce churn from repeated host deploys while preserving a reasonable rollback window.
- Keep the implementation simple, host-local, and compatible with the current deploy-rs remote-build workflow.

**Non-Goals:**
- Repartition disks or migrate `/nix` to a different filesystem.
- Introduce paid OCI block volumes or a new binary-cache service.
- Re-architect containerized services away from Podman.
- Solve every future storage-scaling need for additional hosts.

## Decisions

### HS-1: Use declarative retention controls instead of storage migration
The first implementation will bound existing root-backed consumers instead of moving `/nix` or shrinking other partitions. This directly addresses the current incident with the least operational risk and no infrastructure cost.

**Alternatives considered:**
- Move `/nix` to `/srv/data` immediately: effective but couples service-state storage and Nix store before proving policy-only fixes are insufficient.
- Repartition `/sda` or `/sdb`: possible, but higher-risk and unnecessary for an initial hygiene pass.

### HS-2: Keep Nix cleanup automatic and conservative enough for rollback
The host will keep Nix automatic garbage collection enabled with a time-based deletion policy and explicit generation limits where available. The policy should reduce stale roots while preserving a short rollback window for break-glass recovery.

**Alternatives considered:**
- Aggressive deletion after every deploy: maximizes space but weakens rollback safety.
- No automatic GC: leaves the host vulnerable to repeated root exhaustion.

### HS-3: Cap journald with explicit size and retention limits
Journald will receive explicit `SystemMaxUse`, `SystemKeepFree`, and bounded retention so logs cannot consume multiple gigabytes on a 20G root filesystem.

**Alternatives considered:**
- Manual `journalctl --vacuum-*`: easy once, but not durable.
- Disable persistent journald storage entirely: saves space, but removes useful local troubleshooting context.

### HS-4: Prune Podman artifacts on a schedule using systemd-managed commands
Podman cleanup will be defined declaratively as systemd oneshot services plus timers that prune stale images, stopped containers, and unused volumes on a regular cadence. This keeps behavior visible in NixOS config and avoids relying on operator memory.

**Alternatives considered:**
- Only prune manually during incidents: cheapest initially, but repeats the current operational failure mode.
- Move Podman storage off root now: may be useful later, but adds storage-layout complexity prematurely.

## Risks / Trade-offs

- **[Reduced rollback depth]** → Mitigation: keep a modest rollback window rather than deleting all old generations immediately.
- **[Podman prune removes artifacts needed for fast redeploy]** → Mitigation: prune only unused/stopped artifacts and leave active containers/images in place.
- **[Shared baseline changes affect future hosts unintentionally]** → Mitigation: scope the first hygiene policy to `oci-melb-1` unless the config clearly belongs in a shared base module.
- **[Policy-only cleanup may not be enough long-term]** → Mitigation: treat this as the first response; if root pressure remains high after bounded retention, revisit `/nix` migration, dedicated storage, or remote build/cache changes.

## Migration Plan

1. Add the host storage-hygiene settings in repo-managed NixOS config.
2. Validate evaluation/formatting locally.
3. Deploy to `oci-melb-1` through the existing deploy-rs workflow.
4. Confirm the resulting host exposes the expected GC, journald, and Podman cleanup units/timers.
5. Optionally trigger one manual cleanup run after deployment to reclaim space immediately.

Rollback: deploy or boot into the previous system generation if cleanup settings prove too aggressive, then tune retention thresholds in follow-up.

## Open Questions

- Should the Podman cleanup policy live only on `oci-melb-1`, or is there enough evidence to promote it into a shared container-service baseline later?
- What exact Nix retention window best balances rollback safety with root-disk pressure for this host's deploy frequency?

# Phase 2: OCI Bootstrap And Service Readiness - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

User-corrected Phase 2 boundary: get NixOS running on OCI using `nixos-anywhere`, establish stable storage/layout foundations, and ensure baseline services are installed and running with Tailscale-first private access. Deeper secrets hardening and richer functionality are explicitly deferred.

</domain>

<decisions>
## Implementation Decisions

### OCI Bootstrap Path
- **D-01:** Standard install path is temporary OCI Linux image -> `nixos-anywhere` over SSH.
- **D-02:** Use remote target builds (`--build-on-remote`) from the x86_64 operator machine.
- **D-03:** Host-specific secret material is not required to declare initial bring-up successful.
- **D-04:** Break-glass fallback testing is deferred for this phase.

### Storage And Mount Baseline
- **D-05:** Required layout is GPT + EFI + ext4 root + one data filesystem.
- **D-06:** Service data must use a single canonical mount with service subdirectories.
- **D-07:** Device targeting must use stable IDs (by-id/by-uuid), not transient device names.
- **D-08:** Scope includes creating baseline directories/permissions only; no real data migration in this phase.

### Service Readiness Contract
- **D-09:** In-scope services are `tailscale`, `syncthing`, `navidrome`, and `slskd`.
- **D-10:** Readiness uses tiered checks: enabled/active is mandatory now; secret-dependent functional checks can be deferred.
- **D-11:** Service access policy remains Tailscale-first and private-only in this phase.

### Architecture And Modularity Goals
- **D-12:** Host composes service modules; provider modules stay provider-specific.
- **D-13:** Data ownership model: synced media tree is canonical source of truth; ingest paths (for `slskd`/future workers) feed a staging inbox then promote to canonical media.
- **D-14:** Startup sequencing contract is network -> sync -> consumers.
- **D-15:** Define a worker profile/module interface now; actual worker implementations are deferred.

### Post-Install Operations
- **D-16:** Default update flow is `nixos-rebuild --target-host` for this phase.
- **D-17:** Verification cadence is `nix flake check` plus host eval sanity checks.
- **D-18:** Keep one canonical operator entry path (`justfile`/`deploy.sh` consistency).

### Explicit Deferrals
- **D-19:** Defer deploy orchestration tooling (`deploy-rs`/Colmena class tooling).
- **D-20:** Defer backup automation.
- **D-21:** Defer robust small-blast-radius host-driven `sops-nix` secret flow as a deeper phase concern.

### the agent's Discretion
- Exact check commands for each service's process-level readiness.
- Exact module names for worker/profile boundary as long as host->module composition remains clear.
- Exact path names under the canonical data mount, as long as staging vs canonical ownership is preserved.

</decisions>

<specifics>
## Specific Ideas

- User intent: "Phase 2 should be getting NixOS running on OCI using nixos-anywhere and ensuring all services are available/installed/running. Secrets and richer functionality come after that."
- User clarified data flow: Syncthing-managed tree is the practical SSOT; `slskd` should download to inbox/staging and worker flow promotes into synced canonical media.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement authority
- `.planning/ROADMAP.md` - Phase order, goals, and requirement mapping baseline
- `.planning/REQUIREMENTS.md` - Requirement IDs and acceptance intent
- `.planning/PROJECT.md` - Core value and migration constraints
- `.planning/STATE.md` - Current phase continuity and recent decisions

### Architecture and migration context
- `docs/architecture.md` - Human-facing target architecture direction
- `docs/decisions.md` - Decision history and rationale
- `docs/plan.md` - Migration sequencing intent
- `docs/context-history.md` - Context timeline and drift notes

### Active implementation surface
- `flake.nix` - Active NixOS configuration entrypoints
- `hosts/oci-melb-1/default.nix` - Host composition and service wiring
- `hosts/oci-melb-1/users.nix` - Host user/account boundary
- `modules/providers/oci/default.nix` - OCI-specific provider defaults
- `modules/storage/disko-root.nix` - Disk/storage contract currently in use
- `modules/services/tailscale.nix` - Private networking service module
- `deploy.sh` - Installer/deploy command surface
- `justfile` - Operator command surface and host targeting

### Codebase map context
- `.planning/codebase/ARCHITECTURE.md` - Current architecture map and boundaries
- `.planning/codebase/STRUCTURE.md` - Directory and module layout mapping
- `.planning/codebase/CONCERNS.md` - Risks and drift hotspots to watch during Phase 2

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/providers/oci/default.nix`: provider-specific OCI settings boundary already exists.
- `modules/storage/disko-root.nix`: reusable root/data storage module foundation exists.
- `modules/services/tailscale.nix`: shared private-networking service pattern exists.
- `hosts/oci-melb-1/default.nix`: host-level composition point for service/module integration.

### Established Patterns
- Host-centric composition through `hosts/<host>/default.nix` with reusable behavior in `modules/*`.
- Provider concerns separated under `modules/providers/*`.
- Phase docs and validation gates under `.planning/phases/*` drive implementation order.

### Integration Points
- `flake.nix` + host module imports are the primary assembly edge.
- `deploy.sh` and `justfile` are the operator flow entrypoints for install/update checks.
- Service lifecycle and ordering can be expressed via systemd dependencies from host/service modules.

</code_context>

<deferred>
## Deferred Ideas

- Deep secret bootstrap hardening and strict blast-radius `sops-nix` rollout policy.
- Backup automation and retention strategy.
- Full break-glass recovery proofing across OCI console paths.
- Implementing worker services themselves (only interface/boundary is in-scope now).
- None - roadmap phase title is aligned with the corrected bring-up-first scope.

</deferred>

---

*Phase: 02-oci-bootstrap-and-service-readiness*
*Context gathered: 2026-03-22*

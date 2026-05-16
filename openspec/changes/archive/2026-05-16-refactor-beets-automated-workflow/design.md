## Context

The Beets module has accumulated multiple operational paths (automated inbox, approved promotion, interactive rescue/import, conversion, and reconciliation) plus secrets templating and ACL/service hardening concerns. The updated implementation direction is to split reusable Beets execution scaffolding from music-specific workflow composition so future stages/plugins can be added without duplicating service and secret wiring blocks or burying ingest policy inside a supposedly generic service module.

## Goals / Non-Goals

**Goals:**
- Define a stage-driven Beets workflow contract with clear behavior differences between automated and manual stages.
- Keep headless automation deterministic for inbox processing.
- Preserve operator-controlled interactive quarantine review over SSH TTY.
- Standardize DRY generation for config templates, secrets, runners, timers, and service defaults.
- Make the Beets service boundary reusable across workflows by exposing typed runner/timer/config scaffolding instead of hardcoded music-stage units.
- Define runner instances as generated systemd service units with optional triggers and pre/post command hooks.
- Keep `modules/applications/music.nix` authoritative for concrete ingest workflow policy and Beets config ownership.
- Ensure rendered secret template paths are consistently accessible to hardened service units.

**Non-Goals:**
- Replacing Syncthing or Navidrome architecture.
- Introducing new orchestration systems beyond systemd/NixOS module patterns.
- Enabling MusicBrainz-first workflows in this change.

## Decisions

### D1 — Stage-oriented workflow model
Adopt explicit stages:
- Inbox (headless automated)
- Quarantine/Untagged (interactive manual review)
- Approved promotion (headless deterministic promotion)
- Reconcile/Convert (maintenance workflows)

**Why:** Different risk/interaction profiles require different Beets flags and duplicate handling behavior.

**Alternative considered:** Single config/service for all paths. Rejected because it mixes non-interactive and interactive semantics and makes failures harder to reason about.

### D2 — DRY module factories for extensibility
Use structured records/functions for path derivation, config source mapping, secrets/template generation, generic runner definitions, timer generation, and systemd service defaults.

**Why:** Adding a new config or runner instance should be one entry, not multi-location edits.

**Alternative considered:** Keep hand-written units/blocks. Rejected due to repeated logic and drift risk.

### D3 — Separate reusable Beets framework from music workflow policy
Create a dedicated `modules/services/beets/` folder that owns reusable Beets mechanism only: runtime defaults, typed config inputs, built-in runner kinds, generated systemd services/timers, optional trigger wiring, optional pre/post hook plumbing, and service hardening. Keep concrete workflow policy, config ownership, and stage instantiation in `modules/applications/music.nix`.

**Why:** This matches the repo's intended boundary where service modules provide reusable mechanism and application modules own composition and operational semantics.

**Alternative considered:** Keep all workflow semantics in `modules/services/beets-inbox.nix`. Rejected because it leaves music-specific behavior embedded in a module that is meant to be reusable.

### D3.1 — Runner instances are typed generated units, not arbitrary commands
Define each runner instance as one generated Beets systemd service unit constructed from a built-in runner kind. Allow defaulted args/config with per-instance overrides, plus optional pre/post command hooks and optional triggers.

**Why:** This keeps the framework declarative and reusable without collapsing into a generic shell-command wrapper.

**Alternative considered:** Expose an arbitrary custom command interface. Rejected because it weakens type safety, hides workflow behavior in callers, and undermines the value of the dedicated Beets service boundary.

### D4 — Metadata source policy aligned to workflow reality
Standardize this workflow around Bandcamp/Discogs/Spotify/Deezer and remove dependence on MusicBrainz sync in the automated reconciliation path.

**Why:** Matches current operator workflow and avoids metadata source conflicts for this collection profile.

### D5 — Hardened services with explicit rendered-secret access
Keep `ProtectSystem=strict` and related hardening, while explicitly including rendered secret paths in service write/read namespace where needed.

**Why:** Preserve hardening posture without breaking runtime config copy/read steps.

## Risks / Trade-offs

- **[Risk]** Interactive quarantine flow may be misused as a default ingest path.  
  **Mitigation:** Keep naming/docs explicit (`manual`, `interactive`) and maintain inbox automation as the canonical default.

- **[Risk]** More plugins increase match variability and API credential handling complexity.  
  **Mitigation:** Keep plugin sets explicit per config and secrets injected only via sops templates.

- **[Risk]** DRY abstractions can hide behavior if over-generalized.  
  **Mitigation:** Keep abstractions shallow, stage naming explicit in generated outputs, and workflow semantics owned by `music.nix` rather than generic framework code.

- **[Risk]** Over-generalizing runner interfaces may push too much shell/script logic into callers.  
  **Mitigation:** Provide a small set of built-in runner kinds and typed options, with pre/post hooks only as bounded lifecycle extensions.

- **[Risk]** Conversion/reconcile steps may increase runtime and disk churn.  
  **Mitigation:** Keep workflows operator-invoked or bounded by stage-specific controls.

## Implementation Plan

1. Land stage contracts/spec deltas.
2. Introduce the reusable `modules/services/beets/` boundary and move Beets config assets under `modules/applications/music/files/`.
3. Align `music.nix` composition and Beets configs to stage contracts using the new framework interface.
4. Validate build/eval and service definitions (`nix flake check`, targeted eval/rebuild checks).
5. Run manual smoke checks for:
   - inbox headless run,
   - interactive quarantine run over SSH,
   - approved promotion,
   - reconcile/convert runner behavior.
6. Complete the cutover in one coherent pass; avoid leaving legacy Beets runner architecture in place.

## Open Questions

- Should conversion be strictly post-import maintenance or optionally pre-import for specific stage boundaries?
- Should a dedicated alias/command naming convention be standardized for all operator-invoked stage runners?
- Which runner kinds should be first-class in the generic framework for the initial cutover?

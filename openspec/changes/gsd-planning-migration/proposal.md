# Proposal: Migrate GSD Planning Artifacts to OpenSpec

## Change ID

`gsd-planning-migration`

## Intent

Migrate the repository from GetShitDone (GSD) style planning/state artifacts to OpenSpec change artifacts, establishing a clean OpenSpec scaffold while preserving all accumulated project context from the GSD system.

## Scope

### In Scope

- Detect and inventory all existing GSD artifacts (`.planning/**`, `docs/plans/**`)
- Create OpenSpec change scaffold at `openspec/changes/gsd-planning-migration/`
- Map GSD `STATE.md`, `ROADMAP.md`, `PROJECT.md`, and `REQUIREMENTS.md` to OpenSpec artifacts
- Preserve accumulated decisions, phase history, and key architectural outcomes
- Create `migration-notes.md` documenting assumptions and unresolved items

### Out of Scope

- Deleting legacy GSD files (will remain for reference until explicitly removed)
- Creating Phase 05 execution artifacts (deferred to Phase 05 planning)
- Modifying any active implementation or configuration files

## Outcomes

1. OpenSpec change scaffold created at `openspec/changes/gsd-planning-migration/`
2. GSD project state mapped into OpenSpec `proposal.md`
3. Key architectural decisions mapped into `design.md`
4. Execution tasks mapped into checkbox-first `tasks.md`
5. Capability specs created for key behaviors: `fleet-infrastructure/spec.md`
6. Migration notes created documenting source files, assumptions, and manual follow-ups

## Summary of Current State

### Completed Phases

| Phase | Name | Status | Completed |
|-------|------|--------|-----------|
| 01 | Repository Cutover | Complete | 2026-03-21 |
| 01.1 | Modular Provider Flakes Integration | Complete | - |
| 01.1.1 | Legacy Config Migration Cleanup | Complete | - |
| 02 | OCI Bootstrap And Service Readiness | Complete | 2026-03-26 |
| 03 | OCI Host Bring-Up And Private Operations | Complete | 2026-03-26 |
| 04 | Service Baseline And Data Safety | Complete | 2026-03-27 |
| 04.1 | Beets Inbox-Only Singleton Ingestion | Complete | - |
| 04.2 | All-Inbox Beets Preprocessing with Auto-Promotion | Complete | 2026-04-01 |

### Active Requirements

- **MEDI-05**: Transfer-safe inbox automation with `.tmp` lockout, settle/debounce, post-run demotion
- **MEDI-06**: Beets worker idempotency with native systemd single-instance behavior

### Deferred to Phase 05

- Traktor NML/M3U syncing
- deploy-rs adoption and root access hardening
- MEDI-05 and MEDI-06 implementation

## Source Files Used

- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/STACK.md`
- `docs/architecture.md`
- Quick task: `260410-r8p-codify-syncthing-library-write-acl/`

## Dependencies

None — this is a documentation/scaffold migration with no implementation impact.

# Tasks: GSD to OpenSpec Migration

## Migration Tasks

- [ ] Inventory all GSD artifacts in `.planning/` directory
  - refs: `.planning/**/*`
  - notes: Include phases/, quick/, research/, codebase/ subdirectories

- [ ] Create `openspec/changes/gsd-planning-migration/proposal.md`
  - refs: Derived from STATE.md, ROADMAP.md, PROJECT.md, REQUIREMENTS.md
  - notes: Preserve phase history, active requirements, deferred items

- [ ] Create `openspec/changes/gsd-planning-migration/design.md`
  - refs: Key Decisions table from PROJECT.md
  - notes: Document architectural outcomes, technical architecture, risks

- [ ] Create `openspec/changes/gsd-planning-migration/tasks.md`
  - refs: This file
  - notes: Self-referential; tracks completion of migration itself

- [ ] Create `openspec/changes/gsd-planning-migration/specs/fleet-infrastructure/spec.md`
  - refs: docs/architecture.md, .planning/research/ARCHITECTURE.md
  - criteria: Captures core fleet behaviors, storage model, secrets architecture

- [ ] Create `openspec/changes/gsd-planning-migration/migration-notes.md`
  - refs: All source GSD files
  - notes: Document assumptions, source files, intentionally not migrated items

- [ ] Verify OpenSpec scaffold structure
  - verify: `ls -la openspec/changes/gsd-planning-migration/`
  - criteria: All expected files and directories present

## Manual Follow-ups (Post-Migration)

- [ ] Review and verify migrated content accuracy
  - notes: Human review needed to confirm context preservation

- [ ] Decide on GSD artifact retention/deletion timeline
  - notes: Do not delete unless explicitly requested

- [ ] Plan Phase 05 using OpenSpec workflow
  - notes: Use `/gsd:plan-phase 5` or equivalent OpenSpec command

- [ ] Update documentation references if needed
  - notes: Check if docs/ still point to GSD artifacts

## Verification

Run after all tasks complete:

```bash
# Verify OpenSpec structure
ls -la openspec/changes/gsd-planning-migration/
ls -la openspec/changes/gsd-planning-migration/specs/

# Verify all required files exist
test -f openspec/changes/gsd-planning-migration/proposal.md
test -f openspec/changes/gsd-planning-migration/design.md
test -f openspec/changes/gsd-planning-migration/tasks.md
test -f openspec/changes/gsd-planning-migration/specs/fleet-infrastructure/spec.md
test -f openspec/changes/gsd-planning-migration/migration-notes.md
```

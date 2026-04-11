# Tasks: GSD to OpenSpec Migration

## Migration Tasks

- [x] Inventory all GSD artifacts in `.planning/` directory
  - refs: `.planning/**/*`
  - notes: Include phases/, quick/, research/, codebase/ subdirectories

- [x] Create `openspec/changes/gsd-planning-migration/proposal.md`
  - refs: Derived from STATE.md, ROADMAP.md, PROJECT.md, REQUIREMENTS.md
  - notes: Preserve phase history, active requirements, deferred items

- [x] Create `openspec/changes/gsd-planning-migration/design.md`
  - refs: Key Decisions table from PROJECT.md
  - notes: Document architectural outcomes, technical architecture, risks

- [x] Create `openspec/changes/gsd-planning-migration/tasks.md`
  - refs: This file
  - notes: Self-referential; tracks completion of migration itself

- [x] Create `openspec/changes/gsd-planning-migration/specs/fleet-infrastructure/spec.md`
  - refs: docs/architecture.md, .planning/research/ARCHITECTURE.md
  - criteria: Captures core fleet behaviors, storage model, secrets architecture

- [x] Create `openspec/changes/gsd-planning-migration/migration-notes.md`
  - refs: All source GSD files
  - notes: Document assumptions, source files, intentionally not migrated items

- [x] Verify OpenSpec scaffold structure
  - verify: `ls -la openspec/changes/gsd-planning-migration/`
  - criteria: All expected files and directories present

## Manual Follow-ups (Post-Migration)

- [x] Review and verify migrated content accuracy
  - notes: Human review completed and confirmed

- [ ] Decide on GSD artifact retention/deletion timeline
  - notes: Do not delete unless explicitly requested

- [x] Plan Phase 05 using OpenSpec workflow
  - notes: Will use OpenSpec for Phase 05 when ready

- [x] Update documentation references if needed
  - notes: Checked docs/*.md, no GSD references found; CLAUDE.md includes are auto-generated

## Archiving

- [ ] Archive the completed change using OpenSpec archive workflow
  - notes: Use `openspec archive` or equivalent command to move change to archived state
  - criteria: Change directory moved to archive location, specs remain in main specs/

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

# Verify specs have been created in main specs directory
ls -la openspec/specs/
```

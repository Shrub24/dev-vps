# Spec: Beets Automation

## Purpose

Define transfer-safe Beets inbox/quarantine automation contracts for import, promotion, demotion, and reporting.
## Requirements
### Requirement: Beets processing is transfer-safe
The Beets runner SHALL use transfer-safety controls (including temporary-file lockout and settle timing) before processing files.

#### Scenario: Inbox processing is triggered
- **WHEN** Beets runner starts against a target path
- **THEN** transfer-safety checks run before import and move operations

### Requirement: Processing outcome is deterministic
Beets automation SHALL produce deterministic outcomes for promoted and non-promoted files according to configured rules.

#### Scenario: Mixed importability files are processed
- **WHEN** import succeeds for some files and not others
- **THEN** successful files are promoted and unresolved files follow demotion rules

### Requirement: Runtime and state paths are explicit
Beets SHALL use explicit module-injected media/data paths for runtime state and logs.

#### Scenario: Service units are rendered
- **WHEN** Beets units and runner environment are generated
- **THEN** path usage derives from declared options instead of hardcoded filesystem literals

### Requirement: Automation remains operationally controllable
Beets execution SHALL support operator-controlled manual rescue processing after SoulSync cutover, and beets-inbox SHALL NOT remain the default primary automated ingest/promotion backend.

#### Scenario: Operator executes manual rescue run
- **WHEN** beets runner is invoked manually against an approved rescue boundary
- **THEN** processing occurs within declared boundary checks and logs are emitted to state paths
- **AND** this execution is fallback-oriented rather than the canonical default ingest path


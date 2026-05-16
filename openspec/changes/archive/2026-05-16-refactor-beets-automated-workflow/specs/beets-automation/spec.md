## MODIFIED Requirements

### Requirement: Beets processing is transfer-safe
The Beets runner SHALL use transfer-safety controls (including temporary-file lockout and settle timing) before processing files.

#### Scenario: Inbox processing is triggered
- **WHEN** Beets runner starts against a target path
- **THEN** transfer-safety checks run before import and move operations

### Requirement: Processing outcome is deterministic
Beets automation SHALL produce deterministic outcomes for promoted and non-promoted files according to configured stage rules, including non-interactive duplicate handling for headless stages.

#### Scenario: Mixed importability files are processed
- **WHEN** import succeeds for some files and not others
- **THEN** successful files are promoted and unresolved files follow demotion rules
- **AND** duplicate candidates in automated stages follow configured non-interactive policy

### Requirement: Runtime and state paths are explicit
Beets SHALL use explicit module-injected media/data paths for runtime state, logs, and rendered config template access.

#### Scenario: Service units are rendered
- **WHEN** Beets units and runner environment are generated
- **THEN** path usage derives from declared options instead of hardcoded filesystem literals
- **AND** hardened service units include required rendered config access paths

## ADDED Requirements

### Requirement: Reusable Beets framework and workflow policy MUST remain separate
The system SHALL keep reusable Beets execution scaffolding separate from music-specific workflow composition.

#### Scenario: Generic Beets mechanism is declared
- **WHEN** the Beets service layer is evaluated
- **THEN** it exposes reusable config, built-in runner kind, trigger, hook, timer, and hardening interfaces without hardcoding music ingest workflow semantics

#### Scenario: Music workflow composition is declared
- **WHEN** the music application is evaluated
- **THEN** it selects concrete Beets configs, runner instances, timers, and stage semantics through the reusable framework interface

### Requirement: Runner instances MUST be generated from built-in Beets runner kinds
The system SHALL define Beets runner instances as generated systemd service units created from built-in runner kinds, with defaulted-but-overridable args and config.

#### Scenario: Runner instance is declared
- **WHEN** a Beets runner instance is configured
- **THEN** the system generates a named systemd service unit for that runner
- **AND** the runner uses built-in behavior for its declared kind rather than an arbitrary custom command

### Requirement: Runner lifecycle extensions MUST be bounded
The system SHALL support optional pre/post command hooks and optional triggers for runner instances without turning the framework into a generic command wrapper.

#### Scenario: Timed runner with hooks is declared
- **WHEN** a Beets runner instance includes a timer trigger and pre/post commands
- **THEN** the generated unit and timer include those lifecycle extensions
- **AND** the core runner behavior still comes from the declared built-in runner kind

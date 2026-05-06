# Spec: State Backups

## Purpose

Define the canonical fleet backup architecture using host-scoped restic repositories, explicit service consistency classes, and operator runbooks for backup initialization, validation, and restore.
## Requirements
### Requirement: Fleet state backups SHALL use host-scoped restic repositories
The fleet SHALL back up mutable host state using NixOS `services.restic.backups` with one dedicated object-storage bucket and one restic repository per host.

#### Scenario: Host backup configuration is rendered
- **WHEN** backup configuration is evaluated for `do-admin-1` or `oci-melb-1`
- **THEN** the host resolves a restic backup definition through the canonical NixOS module surface
- **AND** the repository target is isolated to that host via its dedicated bucket/repository rather than a shared cross-host repository

### Requirement: Initial backup scope SHALL include service state and exclude media payloads
Initial fleet backups SHALL include mutable service state and generated export artifacts, SHALL exclude repo-owned immutable configuration, and SHALL exclude `/srv/media` from required backup coverage in this wave.

#### Scenario: Backup path scope is reviewed
- **WHEN** canonical backup paths and exclusions are inspected
- **THEN** service state paths under declared managed roots such as `/srv/data` are included
- **AND** `/srv/media` is excluded from required backup payload in this change

### Requirement: Backup consistency SHALL use explicit service classes
Each backed-up stateful service SHALL declare or inherit an explicit consistency class of `export`, `quiesce`, or `live` that determines whether the service generates an app-native restorable backup artifact, stabilizes runtime state around the backup window, or allows direct live capture.

#### Scenario: Service backup policy is reviewed
- **WHEN** a stateful service participates in fleet backup coverage
- **THEN** its backup behavior maps to one declared consistency class
- **AND** operators can determine from configuration whether export artifacts, stop/start coordination, or live capture is expected

### Requirement: Export-first services SHALL capture portable artifacts and raw state initially
Services classified as `export` SHALL generate an app-native restorable recovery artifact before backup and SHALL also include raw service state in the initial backup contract unless a later change narrows that policy.

#### Scenario: Export-first service backup runs
- **WHEN** a configured export-first service backup job executes
- **THEN** a portable export artifact is produced before restic capture
- **AND** the backup payload still includes the service's underlying state directory in this wave

### Requirement: Backup repositories SHALL support recurring integrity and retention policy
The canonical backup architecture SHALL define recurring backup execution, retention pruning, and repository integrity verification expectations for each host.

#### Scenario: Backup operator policy is reviewed
- **WHEN** recurring backup behavior is inspected for a host
- **THEN** the host defines schedule, prune policy, and repository-check behavior declaratively
- **AND** missed scheduled runs can resume through persistent timer behavior or equivalent declarative recovery semantics
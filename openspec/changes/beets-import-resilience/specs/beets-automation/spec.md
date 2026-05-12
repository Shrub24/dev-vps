# Delta Spec: Beets Automation

## MODIFIED Requirements

### Requirement: Processing outcome is deterministic
Beets automation SHALL produce deterministic outcomes for promoted, non-promoted, and crash-interrupted files according to configured rules. On runner crash (non-zero exit), demotion SHALL NOT execute, leaving unseen files in the import target for automatic retry or manual recovery.

#### Scenario: Mixed importability files are processed
- **WHEN** import succeeds for some files and not others
- **THEN** successful files are promoted and unresolved files follow demotion rules

#### Scenario: Runner crashes mid-import
- **WHEN** the beets import process exits non-zero (crash) before completing all files
- **THEN** demotion SHALL NOT execute
- **AND** unseen files SHALL remain in the import target path
- **AND** the runner SHALL exit with the non-zero code to trigger systemd failure hooks

## ADDED Requirements

### Requirement: Runner failure triggers recovery and alerting
The system SHALL wire OnFailure hooks to every generated beets runner service that trigger automatic retry (for import runners) and ntfy.sh push notification (for all runners with notification configured).

#### Scenario: Import runner fails with both retry and notify configured
- **WHEN** a beets import runner exits non-zero
- **THEN** the OnFailure hook SHALL trigger both the retry timer and the notification template unit
- **AND** the retry timer SHALL fire after 10 minutes to re-start the import
- **AND** the notification SHALL be delivered immediately

#### Scenario: Non-import runner fails with notify configured
- **WHEN** a quarantine-interactive or reconcile runner exits non-zero
- **THEN** the notification SHALL be delivered
- **AND** no retry timer SHALL be triggered

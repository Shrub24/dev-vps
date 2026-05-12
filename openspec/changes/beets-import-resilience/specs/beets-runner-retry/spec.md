# Spec: Beets Runner Retry

## Purpose

Define automatic retry semantics for failed Beets import runners via systemd OnFailure-triggered timers.

## ADDED Requirements

### Requirement: Failed import runs are automatically retried after a cooldown
The system SHALL automatically re-attempt a failed beets import run after a 10-minute cooldown period, triggered by a systemd timer unit wired to the runner service's OnFailure hook.

#### Scenario: Import runner exits non-zero
- **WHEN** a beets import runner service exits with a non-zero exit code
- **THEN** the systemd OnFailure hook SHALL trigger the corresponding retry timer unit
- **AND** the retry timer SHALL fire after exactly 10 minutes (OnActiveSec=10min)
- **AND** the timer SHALL re-start the original import runner service

#### Scenario: Retry succeeds
- **WHEN** the retry timer fires and the import runner exits zero
- **THEN** the timer SHALL remain inactive until the next non-zero exit
- **AND** the service SHALL exit cleanly without triggering further retries

### Requirement: Retry loops are bounded by StartLimitBurst
The system SHALL prevent infinite retry loops by limiting rapid repeated failures to 3 within 30 minutes using systemd StartLimitBurst/StartLimitIntervalSec.

#### Scenario: Three consecutive failures exhaust burst limit
- **WHEN** the import runner fails 3 times within 30 minutes
- **THEN** systemd SHALL stop retrying the service
- **AND** the runner SHALL remain in a failed state until operator intervention

#### Scenario: Failures are spread across time windows
- **WHEN** the import runner fails, succeeds, then fails again later
- **THEN** each new failure window SHALL restart the burst counter from 0 (per StartLimitIntervalSec semantics)
- **AND** the 3-failure cap SHALL apply within the 30-minute sliding window

### Requirement: Retry only applies to import runner kind
The system SHALL only generate retry timers for runner instances of kind "import". Manual-invocation runner kinds (quarantine-interactive, reconcile, permission-reconcile) SHALL NOT receive automatic retry timers.

#### Scenario: Quarantine runner fails
- **WHEN** a quarantine-interactive runner exits non-zero
- **THEN** no retry timer SHALL be triggered
- **AND** the operator SHALL be responsible for re-invocation

#### Scenario: Import runner with timer disabled
- **WHEN** an import runner instance has timer generation explicitly disabled (triggers.timer is null)
- **THEN** no retry timer SHALL be generated even though the runner kind is "import"

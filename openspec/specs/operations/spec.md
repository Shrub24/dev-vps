# Spec: Operations

## Purpose

Define the canonical operator workflows and command contracts for verification, deployment, observability, and break-glass recovery.

## Requirements

### Requirement: Contract verification gates operations

Phase contract checks SHALL exist and SHALL be used to detect configuration drift before deployment, including drift between public edge exposure policy and private-origin upstream policy.

#### Scenario: Ingress policy drift is introduced

- **WHEN** route exposure mode or domain mapping diverges from declared edge policy
- **THEN** verification fails prior to deployment

### Requirement: Deployment flows use canonical repository entrypoints

Day-2 deployment SHALL be performed through repository-defined operator entrypoints and host flake outputs.

#### Scenario: Host deployment is triggered

- **WHEN** an operator runs deploy/activate workflows
- **THEN** deployment targets declared host outputs and follows repository command contracts

#### Scenario: A deployment changes network ownership on a remote host

- **WHEN** activation would stop the currently active network stack or otherwise cut the in-band SSH transport
- **THEN** operators use a boot-time deploy workflow that updates the next generation without live-switching the running network stack
- **AND** the host reboot is performed with break-glass console access available

#### Scenario: A recovery baseline change is rolled out to a remote host

- **WHEN** operators deploy changes that affect rescue-user access or scheduled reboot behavior
- **THEN** the rollout includes an explicit verification step for the new recovery path
- **AND** rollback or prior-generation access remains available until verification completes

### Requirement: Operational status commands are available

The operator surface SHALL provide commands for host status, service logs, and ingress health checks that distinguish public edge reachability from private-origin upstream behavior.

#### Scenario: Ingress health is checked

- **WHEN** edge proxy changes are deployed
- **THEN** operators can verify Caddy edge status, certificate state, and effective route behavior for edge and upstream transport

### Requirement: Break-glass baseline and rollback paths are documented

Operators SHALL capture baseline state before risky changes and SHALL have documented rollback and recovery procedures, including offline rescue rebuilds for storage-related failures.

#### Scenario: Recovery is required

- **WHEN** SSH/Tailscale access degrades after change
- **THEN** break-glass steps and generation rollback commands are available to restore access
- **AND** the workflow includes offline rescue rebuild guidance for restoring `/nix`, mounting the ESP, and reinstalling a bootable generation when live recovery is no longer possible

#### Scenario: Recovery baseline is audited

- **WHEN** operators review host recovery readiness for a remote host
- **THEN** the documented runbook includes how to verify console rescue access, rescue-user access, scheduled reboot cadence, and rollback steps

### Requirement: Host recipient management is operationalized

Host key to age-recipient derivation SHALL be available via operator workflows with preview and update modes.

#### Scenario: A new host recipient is added

- **WHEN** operator derives host recipient material
- **THEN** recipient generation and optional policy update are performed via documented commands

### Requirement: Build/check workflows validate repo integrity

The operator surface SHALL include flake validation and host build checks.

#### Scenario: Pre-deploy validation runs

- **WHEN** operators run check/build commands
- **THEN** flake outputs and host build artifacts are validated prior to apply

### Requirement: Backup and restore workflows SHALL be documented as canonical operator runbooks

Operations documentation SHALL include canonical workflows for backup initialization, on-demand execution, recurring verification, restore preparation, and post-restore validation for host-scoped state backups.

#### Scenario: Operator prepares or audits backup operations

- **WHEN** an operator reviews the repository runbook surface for backups
- **THEN** the steps for initializing repositories, triggering backups, checking repository health, and validating restores are documented
- **AND** the runbook distinguishes routine backup execution from break-glass recovery flows

### Requirement: Backup validation SHALL include restore-oriented checks

The operator contract SHALL require validation beyond successful backup completion, including at least documented or executable checks that confirm critical backups are restorable.

#### Scenario: Backup validation is performed for a critical service

- **WHEN** operators validate backup health for identity or SQLite-backed services
- **THEN** validation includes restore-oriented verification steps rather than only timer/job success status

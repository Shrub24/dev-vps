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

### Requirement: Operational status commands are available
The operator surface SHALL provide commands for host status, service logs, and ingress health checks that distinguish public edge reachability from private-origin upstream behavior.

#### Scenario: Ingress health is checked
- **WHEN** edge proxy changes are deployed
- **THEN** operators can verify Caddy edge status, certificate state, and effective route behavior for edge and upstream transport

### Requirement: Break-glass baseline and rollback paths are documented
Operators SHALL capture baseline state before risky changes and SHALL have documented rollback/recovery procedures.

#### Scenario: Recovery is required
- **WHEN** SSH/Tailscale access degrades after change
- **THEN** break-glass steps and generation rollback commands are available to restore access

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


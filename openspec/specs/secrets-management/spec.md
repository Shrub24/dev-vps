# Spec: Secrets Management

## Purpose

Define blast-radius-scoped secret management contracts using SOPS and age recipients across fleet and host scopes.

## Requirements

### Requirement: Secret scopes are explicitly separated
Secrets SHALL be split into fleet-shared and host-specific scopes with explicit path policies.

#### Scenario: Secret files are reviewed
- **WHEN** repository secret locations and policy are inspected
- **THEN** shared and host-specific scopes are clearly separated

### Requirement: Recipient policy is path-bound and auditable
SOPS recipient rules SHALL be path-scoped and auditable to prevent implicit cross-host access.

#### Scenario: New host recipient is introduced
- **WHEN** recipient rules are updated
- **THEN** only explicitly targeted secret paths include the new host recipient

### Requirement: Two-step bootstrap secret flow is supported
Base host install SHALL not require host secrets, with host-secret enablement occurring as a second step.

#### Scenario: Initial host bring-up is performed
- **WHEN** host is installed before secret bootstrap
- **THEN** base system converges and secret-dependent wiring can be enabled afterward

### Requirement: Host recipient derivation is operationalized
Host recipient derivation from SSH host keys SHALL be available through operator workflows.

#### Scenario: Operator derives host age recipient
- **WHEN** recipient derivation command is executed
- **THEN** generated recipient can be used to update secret policy/workflow safely

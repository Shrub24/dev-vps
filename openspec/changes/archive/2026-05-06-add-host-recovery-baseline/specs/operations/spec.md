## MODIFIED Requirements

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

### Requirement: Break-glass baseline and rollback paths are documented
Operators SHALL capture baseline state before risky changes and SHALL have documented rollback/recovery procedures.

#### Scenario: Recovery is required
- **WHEN** SSH/Tailscale access degrades after change
- **THEN** break-glass steps and generation rollback commands are available to restore access

#### Scenario: Recovery baseline is audited
- **WHEN** operators review host recovery readiness for a remote host
- **THEN** the documented runbook includes how to verify console rescue access, rescue-user access, scheduled reboot cadence, and rollback steps

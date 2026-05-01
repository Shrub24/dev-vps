## MODIFIED Requirements

### Requirement: Contract verification gates operations
Phase contract checks SHALL exist and SHALL be used to detect configuration drift before deployment.

#### Scenario: Operator runs verification
- **WHEN** phase verification commands are executed
- **THEN** failing contracts block forward deployment until corrected

#### Scenario: Ingress policy drift is introduced
- **WHEN** route exposure mode or domain/path mapping diverges from declared policy
- **THEN** verification fails prior to deployment

### Requirement: Operational status commands are available
The operator surface SHALL provide commands for host status, service logs, and Tailscale health.

#### Scenario: Post-change health checks run
- **WHEN** deployment completes or fails
- **THEN** operators can inspect host/systemd/Tailscale state using documented commands

#### Scenario: Ingress health is checked
- **WHEN** edge proxy changes are deployed
- **THEN** operators can verify Caddy service status, certificate state, and effective route reachability

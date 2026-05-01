## MODIFIED Requirements

### Requirement: Contract verification gates operations
Phase contract checks SHALL exist and SHALL be used to detect configuration drift before deployment, including drift between public edge exposure policy and private-origin upstream policy.

#### Scenario: Ingress policy drift is introduced
- **WHEN** route exposure mode or domain mapping diverges from declared edge policy
- **THEN** verification fails prior to deployment

### Requirement: Operational status commands are available
The operator surface SHALL provide commands for host status, service logs, and ingress health checks that distinguish public edge reachability from private-origin upstream behavior.

#### Scenario: Ingress health is checked
- **WHEN** edge proxy changes are deployed
- **THEN** operators can verify Caddy edge status, certificate state, and effective route behavior for edge and upstream transport

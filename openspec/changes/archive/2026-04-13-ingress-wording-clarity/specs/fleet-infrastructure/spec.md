## MODIFIED Requirements

### Requirement: Access model is private-first
Management and service access SHALL be Tailscale-first and SHALL not include broad public origin exposure in baseline configuration, while allowing explicitly declared public edge bastion ingress routes.

#### Scenario: Network posture is validated
- **WHEN** network and service configs are inspected
- **THEN** baseline access remains private and non-edge origin exposure is absent by default

#### Scenario: Phase-1 edge ingress is composed
- **WHEN** a host is designated to publish selected routes
- **THEN** only explicitly declared routes are exposed at the edge bastion and private-origin upstream boundaries are preserved for services behind that edge

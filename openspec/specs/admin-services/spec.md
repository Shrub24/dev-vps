# Spec: Admin Services

## Purpose

Define private administrative access contracts for hosts, including Tailscale SSH, Termix access, and break-glass recovery.

## Requirements

### Requirement: Admin access remains private and Tailscale-first
Administrative access SHALL be delivered over Tailscale and SHALL avoid baseline public exposure.

#### Scenario: Admin network posture is evaluated
- **WHEN** admin service and firewall config are inspected
- **THEN** access paths are private and constrained to intended interfaces

### Requirement: Termix is exposed through controlled service wiring
Termix SHALL run under declared service wiring and SHALL be exposed through controlled Tailscale serve flow.

#### Scenario: Termix service stack starts
- **WHEN** admin application is enabled
- **THEN** dependent units and runtime paths are configured for Termix availability

### Requirement: Declarative SSH key ownership is enforced
SSH access for administrative users SHALL be sourced from declarative key configuration.

#### Scenario: User/key configuration is rendered
- **WHEN** user modules are evaluated
- **THEN** required admin users receive declared authorized keys

### Requirement: Break-glass recovery path exists
Provider-appropriate break-glass recovery SHALL be documented and operationally available.

#### Scenario: Remote admin path fails
- **WHEN** Tailscale/SSH access is unavailable
- **THEN** documented recovery procedures can be used to regain control

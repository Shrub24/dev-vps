# Spec: Fleet Infrastructure Capability

## Purpose

Define the baseline infrastructure contracts for a modular NixOS homelab fleet, starting with `oci-melb-1`, while preserving secure growth to additional hosts and providers.
## Requirements
### Requirement: Host composition is host-centric and modular
The repository SHALL organize host identity separately from reusable modules so hosts can add ingress behavior without structural rewrites.

#### Scenario: A host is composed from shared modules
- **WHEN** a host configuration is declared in `hosts/<host>/default.nix`
- **THEN** it composes reusable modules rather than embedding provider/service logic inline

#### Scenario: Edge role is assigned to one host
- **WHEN** only one host is configured as ingress edge
- **THEN** other hosts can remain private-origin nodes with shared module composition patterns

### Requirement: First-host bootstrap is declarative and repeatable
The first host SHALL be bootstrappable from repository state using `nixos-anywhere` and `disko`, and rebuildable from flake outputs.

#### Scenario: Host bootstrap workflow is executed
- **WHEN** operators run bootstrap/deploy workflows
- **THEN** installation and post-install rebuilds derive from declarative flake/module state

### Requirement: Secret blast radius is path-scoped
Secrets SHALL be split into fleet-shared and host-scoped material with explicit path rules that do not grant implicit cross-host decryption.

#### Scenario: A new host is introduced
- **WHEN** host secret files and `.sops.yaml` rules are evaluated
- **THEN** only explicitly declared recipients can decrypt that host scope

### Requirement: Access model is private-first
Management and service access SHALL be Tailscale-first and SHALL not include broad public origin exposure in baseline configuration, while allowing explicitly declared public edge bastion ingress routes.

#### Scenario: Network posture is validated
- **WHEN** network and service configs are inspected
- **THEN** baseline access remains private and non-edge origin exposure is absent by default

#### Scenario: Phase-1 edge ingress is composed
- **WHEN** a host is designated to publish selected routes
- **THEN** only explicitly declared routes are exposed at the edge bastion and private-origin upstream boundaries are preserved for services behind that edge

### Requirement: Storage model separates service state and media
The system SHALL maintain predictable persistent mounts for service state and media using stable identifiers.

#### Scenario: Storage contracts are rendered
- **WHEN** host storage modules are evaluated
- **THEN** `/srv/data` and `/srv/media` are declared as separate mounts with stable device references

### Requirement: Operations remain testable and recoverable
Routine operations SHALL be supported by executable checks and documented break-glass recovery.

#### Scenario: Day-2 operation is performed
- **WHEN** an operator applies or verifies changes
- **THEN** contract checks and recovery guidance are available before and after deployment


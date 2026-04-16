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

### Requirement: Cloudflare DNS records SHALL be policy-driven
Cloudflare DNS records for published web services SHALL be declared in OpenTofu and generated from canonical policy exports rather than hand-managed per record.

#### Scenario: DNS records are planned
- **WHEN** OpenTofu evaluates Cloudflare resources
- **THEN** record definitions are derived from generated policy JSON exported from `policy/web-services.nix`

#### Scenario: Grey-cloud service is declared
- **WHEN** a service policy sets `cloudflare.proxied = false`
- **THEN** the DNS record is planned as DNS-only (not proxied)

### Requirement: Shared origin endpoint SHALL be managed declaratively
The shared origin endpoint used as CNAME target for published service records SHALL be managed in OpenTofu.

#### Scenario: Origin endpoint is enabled
- **WHEN** `manage_origin_record` is true
- **THEN** OpenTofu plans a DNS record for the configured origin name/content/proxy posture

### Requirement: Fleet package baseline defaults to unstable
Fleet host outputs SHALL consume the primary repository package baseline from `nixos-unstable` unless an explicit documented exception is introduced.

#### Scenario: Active host outputs are evaluated
- **WHEN** `nixosConfigurations.oci-melb-1` and `nixosConfigurations.do-admin-1` are built from the flake
- **THEN** both host outputs resolve packages from the primary unstable baseline input


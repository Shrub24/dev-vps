# Spec: Network Access

## Purpose

Define private-first network access contracts for management and services with Tailscale as baseline transport.
## Requirements
### Requirement: Baseline access is private-first
Management and service access SHALL be private and Tailscale-first by default, with a designated public edge bastion for explicitly declared web routes.

#### Scenario: Baseline network posture is checked
- **WHEN** host and service network settings are evaluated
- **THEN** non-edge origin services remain private unless explicitly introduced by a separate change

#### Scenario: Hybrid ingress exception is introduced
- **WHEN** a route is explicitly configured for public edge exposure
- **THEN** the public surface is limited to declared Cloudflare/Caddy ingress routes while upstream transport remains private-origin and Tailscale-encrypted by default for cross-host services

#### Scenario: Constant-availability exception is introduced
- **WHEN** a route is explicitly configured as `direct`
- **THEN** it is treated as an explicit, edge-local-only localhost exception to the Tailscale-upstream default and is constrained to declared exposure policy

### Requirement: Tailscale integration is standardized
Hosts SHALL use standardized Tailscale module wiring for connectivity and administrative SSH support.

#### Scenario: Host boots with Tailscale enabled
- **WHEN** system services start
- **THEN** Tailscale connectivity and expected service ordering are configured declaratively

### Requirement: Firewall trust boundaries are explicit
Firewall policy SHALL enforce explicit trust boundaries for allowed interfaces and ports.

#### Scenario: Firewall config is rendered
- **WHEN** networking/firewall modules are evaluated
- **THEN** only declared interfaces/ports are trusted/opened

#### Scenario: Edge host policy is applied
- **WHEN** an edge host is configured for public ingress
- **THEN** only ingress-required ports are opened and private-service ports remain non-public

### Requirement: Break-glass access remains available
Network-access design SHALL include documented recovery paths for control-plane failures.

#### Scenario: Tailnet access is degraded
- **WHEN** primary private access path fails
- **THEN** break-glass procedures provide alternate operator access

### Requirement: Public-edge policy SHALL be explicit by default-plus-exception model
Cloudflare public-edge access posture SHALL be modeled as a global default with explicit host/route exceptions.

The default-plus-exception model SHALL be declared in canonical shared policy (`policy/web-services.nix`).

#### Scenario: No exception declared
- **WHEN** a route has no host/route override
- **THEN** it inherits the global default policy

#### Scenario: Exception declared
- **WHEN** a host or route override is present
- **THEN** that exception is applied and remains auditable in change artifacts

### Requirement: Control-plane ownership SHALL be separated from runtime wiring
Cloudflare resource declarations SHALL be owned in control-plane artifacts, while runtime/Nix modules consume canonical policy and derived outputs.

#### Scenario: Runtime change depends on Cloudflare policy
- **WHEN** runtime/Nix change needs edge policy values
- **THEN** values are consumed from canonical policy and generated outputs rather than duplicated unmanaged config


# Spec: Admin Services

## Purpose

Define private administrative access contracts for hosts, including Tailscale SSH, Termix access, and break-glass recovery.
## Requirements
### Requirement: Admin access remains private and Tailscale-first
Administrative access SHALL remain private and Tailscale-first by default, while allowing explicit Cloudflare Access-gated web ingress at the public edge bastion with private-origin upstream transport for approved admin routes.

#### Scenario: Admin network posture is evaluated
- **WHEN** admin service and firewall config are inspected
- **THEN** access paths are private by default, and any declared admin web routes are Cloudflare Access-gated at the edge and constrained to private-origin upstream transport

#### Scenario: Public ingress is enabled for non-admin services
- **WHEN** mixed exposure policy is configured
- **THEN** admin endpoints remain private-first and Cloudflare Access-gated with private-origin upstream transport unless explicitly changed

### Requirement: Termix is exposed through controlled service wiring
Termix SHALL run under declared service wiring and SHALL be exposed through controlled route composition, using private-origin transport for cross-host paths and localhost-only direct upstream when edge-local.

#### Scenario: Termix service stack starts
- **WHEN** admin application is enabled
- **THEN** dependent units and runtime paths are configured for Termix availability

#### Scenario: Caddy ingress route map is generated
- **WHEN** public and private service routes are composed
- **THEN** admin route policy remains explicitly declared and constrained by edge access controls

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

### Requirement: Admin application SHALL enable native admin operations services
`modules/applications/admin.nix` SHALL wire Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Filebrowser, Homepage Dashboard, and Beszel hub using nixpkgs-native NixOS service modules so the admin profile provides a unified operational baseline.

#### Scenario: Admin profile enables expanded baseline service set
- **WHEN** a host imports and enables the admin application profile
- **THEN** the host configuration includes `services.cockpit.enable`, `services.webhook.enable`, `services.ntfy-sh.enable`, `services.gatus.enable`, `services.vaultwarden.enable`, `services.filebrowser.enable`, `services.homepage-dashboard.enable`, and `services.beszel.hub.enable`

### Requirement: Admin service state SHALL use predictable data root mapping
For each newly wired admin service that supports configurable state/data paths, the admin profile SHALL map that state under `applications.admin.dataRoot` using a per-service subdirectory.

#### Scenario: Service state directories are derived from admin data root
- **WHEN** `applications.admin.dataRoot` is set (for example `/srv/data`)
- **THEN** supported service state paths resolve under `${applications.admin.dataRoot}/<service>` rather than implicit unmanaged defaults

### Requirement: Admin expansion SHALL preserve private-first exposure defaults
The admin profile augmentation SHALL NOT introduce public-ingress defaults for Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Filebrowser, Homepage Dashboard, or Beszel and SHALL remain compatible with the existing Tailscale-first access model.

#### Scenario: No public-ingress baseline is introduced
- **WHEN** the admin module augmentation is evaluated
- **THEN** no requirement for public internet exposure is added and service wiring remains consistent with private management access patterns

### Requirement: Admin baseline SHALL provide central visibility without host log replication
This stage SHALL provide centralized operational visibility using Cockpit and Beszel surfaced in Homepage, while deferring cross-host L1 log replication to a later dedicated logging change.

#### Scenario: Visibility baseline is available while log sync is deferred
- **WHEN** the admin module augmentation is deployed
- **THEN** Cockpit, Beszel hub, and Homepage are enabled for central operations visibility
- **AND** no requirement is introduced that hosts must run journald remote/upload replication in this stage

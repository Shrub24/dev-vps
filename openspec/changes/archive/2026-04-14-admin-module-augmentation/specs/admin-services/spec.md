# Capability Delta: admin-services

## ADDED Requirements

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

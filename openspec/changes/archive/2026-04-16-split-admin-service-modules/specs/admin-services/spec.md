## MODIFIED Requirements

### Requirement: Admin application SHALL enable native admin operations services
`applications.admin` composition SHALL wire Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Filebrowser, Homepage Dashboard, and Beszel hub through service-level admin modules under `modules/services/admin/` so the admin profile provides a unified operational baseline without monolithic application wiring.

#### Scenario: Admin profile enables expanded baseline service set
- **WHEN** a host imports and enables the admin application profile
- **THEN** the host configuration includes `services.cockpit.enable`, `services.webhook.enable`, `services.ntfy-sh.enable`, `services.gatus.enable`, `services.vaultwarden.enable`, `services.filebrowser.enable`, `services.homepage-dashboard.enable`, and `services.beszel.hub.enable`
- **AND** service-owned wiring resides in admin service modules rather than one large application module file

### Requirement: Admin service state SHALL use predictable data root mapping
For each newly wired admin service that supports configurable state/data paths, the admin profile SHALL map that state under `applications.admin.dataRoot` using a per-service subdirectory, with mapping owned by corresponding service-level admin modules.

#### Scenario: Service state directories are derived from admin data root
- **WHEN** `applications.admin.dataRoot` is set (for example `/srv/data`)
- **THEN** supported service state paths resolve under `${applications.admin.dataRoot}/<service>` rather than implicit unmanaged defaults

### Requirement: Admin expansion SHALL preserve private-first exposure defaults
The admin profile augmentation SHALL NOT introduce public-ingress defaults for Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Filebrowser, Homepage Dashboard, or Beszel and SHALL remain compatible with the existing Tailscale-first access model after module decomposition.

#### Scenario: No public-ingress baseline is introduced
- **WHEN** the admin module refactor is evaluated
- **THEN** no requirement for public internet exposure is added and service wiring remains consistent with private management access patterns

### Requirement: Admin baseline SHALL provide central visibility without host log replication
This stage SHALL provide centralized operational visibility using Cockpit and Beszel surfaced in Homepage, while deferring cross-host L1 log replication to a later dedicated logging change, including after service/module decomposition.

#### Scenario: Visibility baseline is available while log sync is deferred
- **WHEN** the admin module refactor is deployed
- **THEN** Cockpit, Beszel hub, and Homepage remain enabled for central operations visibility
- **AND** no requirement is introduced that hosts must run journald remote/upload replication in this stage

## ADDED Requirements

### Requirement: Cockpit lifecycle SHALL support temporary host-level disable exceptions
Cockpit SHALL remain part of admin service-module ownership and composition contracts, while allowing an explicit temporary host-level `enable = false` exception when an upstream regression is active.

#### Scenario: Upstream cockpit regression is active
- **WHEN** host policy applies temporary exception for cockpit
- **THEN** cockpit module wiring remains present in the admin composition structure
- **AND** runtime activation is disabled through host-level enable override until the exception is lifted

### Requirement: Gatus endpoint inventory SHALL derive from web services policy
Admin monitoring wiring SHALL derive Gatus endpoint inventory for a host from resolved service entries in `policy/web-services.nix` via policy resolution helpers, using policy-defined origin and health metadata.

#### Scenario: Gatus endpoint generation runs for do-admin-1
- **WHEN** admin monitoring configuration is rendered for `do-admin-1`
- **THEN** Gatus endpoints are generated from resolved host services in `policy/web-services.nix`
- **AND** endpoint URLs use resolved origin values plus service health path metadata

#### Scenario: Health defaults are applied consistently
- **WHEN** service entries omit explicit health status/path overrides
- **THEN** generated Gatus checks apply policy defaults for health path and expected status

#### Scenario: Generated checks use canonical route path and origin port metadata
- **WHEN** gatus endpoints are rendered
- **THEN** route path and origin port values are sourced from canonical policy/resolved policy outputs
- **AND** those values are not redefined in independent gatus-specific literals

### Requirement: Homepage metadata SHALL remain presentation-owned
Homepage layout/services/bookmarks metadata SHALL remain owned by Homepage service files and SHALL NOT require encoding presentation concerns in `policy/web-services.nix`.

#### Scenario: Homepage config is evaluated
- **WHEN** homepage content is assembled
- **THEN** icons, descriptions, grouping, widget wiring, and bookmarks are sourced from homepage-owned files
- **AND** route policy remains focused on routing/access/health metadata

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

### Requirement: Admin app auth SHALL support Pocket ID OIDC for phase-1 supported services
The admin baseline SHALL support app-native OIDC using Pocket ID as shared issuer for the phase-1 app set (`gatus`, `beszel`, `termix`) while keeping explicit exceptions for services that are not in scope for this auth wave.

#### Scenario: Phase-1 supported apps are OIDC-enabled
- **WHEN** the admin baseline is rendered for `do-admin-1`
- **THEN** `gatus`, `beszel`, and `termix` include app-level OIDC wiring using Pocket ID issuer endpoints and host-scoped credentials

#### Scenario: Cloudflare Access upstream IdP is Pocket ID
- **WHEN** Cloudflare Access configuration is evaluated for admin browser routes
- **THEN** Access uses Pocket ID generic OIDC as upstream IdP rather than Google OAuth

#### Scenario: Explicit exceptions remain outside phase-1 app OIDC rollout
- **WHEN** exception services are evaluated in this change scope
- **THEN** `vaultwarden`, `navidrome`, `syncthing`, `webhook`, `ntfy`, `cockpit`, `homepage`, and file-management UI services are not required to implement app-native OIDC in this phase
- **AND** exception rationale remains documented in change artifacts

### Requirement: Admin secrets SHALL remain host-scoped for OIDC client credentials
Pocket ID OIDC app credentials used by admin services SHALL be defined as host-scoped secrets for `do-admin-1` and not promoted to shared common secret scope.

#### Scenario: OIDC credentials are added for admin apps
- **WHEN** OIDC client credentials are declared for phase-1 apps
- **THEN** they are sourced from host-scoped secret files/templates for `do-admin-1`
- **AND** they are not introduced under shared/common secret scope by default

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

### Requirement: Homepage authenticated widget wiring SHALL use caller-owned machine-auth inputs
Homepage widgets that require authentication SHALL consume caller-owned machine-auth inputs provided through Homepage runtime environment templating, while preserving Homepage presentation ownership.

#### Scenario: Homepage widget config is rendered for authenticated integrations
- **WHEN** Homepage services are assembled for `do-admin-1`
- **THEN** authenticated widgets use Homepage runtime variables sourced from host-scoped secrets/templates
- **AND** Homepage layout/icons/grouping/bookmarks remain owned by Homepage service files

### Requirement: Homepage runtime SHALL support environment-file secret injection
Admin Homepage service wiring SHALL support injecting integration credentials using homepage-dashboard environment file configuration derived from host-scoped SOPS templates.

#### Scenario: Homepage service starts with integration credentials
- **WHEN** `services.homepage-dashboard` is configured for authenticated widgets
- **THEN** runtime environment files include the generated Homepage secret template path
- **AND** missing required template inputs fail through declarative assertions before runtime drift

### Requirement: Beszel Homepage integration SHALL use dedicated read-only account credentials
Homepage integration with Beszel SHALL use a dedicated read-only account distinct from human admin identities, with system visibility scoped to explicitly shared systems.

#### Scenario: Beszel widget credentials are configured
- **WHEN** Beszel widget auth is enabled for Homepage
- **THEN** credentials reference a dedicated read-only Beszel account
- **AND** account scope is limited to explicitly shared systems rather than global full-access sharing

### Requirement: Homepage auth exceptions SHALL remain explicit and minimal
Homepage integrations that run without app credentials SHALL be explicit exceptions and SHALL remain constrained to approved low-risk/local-only operational contexts.

#### Scenario: Caddy widget exception is evaluated
- **WHEN** Homepage includes Caddy operational widget data
- **THEN** no new broad machine credential is required for that widget
- **AND** exception rationale remains documented in change artifacts

### Requirement: Homepage-Gatus local API path SHALL be unauthenticated and loopback-only
Homepage integration for Gatus SHALL use a local unauthenticated API path, and Gatus SHALL be explicitly bound to loopback so that this unauthenticated API surface is not exposed beyond the local host.

#### Scenario: Homepage retrieves Gatus data over local API
- **WHEN** Homepage Gatus widget/integration is configured on `do-admin-1`
- **THEN** Homepage requests use local API access without bearer/basic/OIDC credentials
- **AND** Gatus web listener is explicitly configured with loopback bind (`127.0.0.1`)

### Requirement: Human Gatus access SHALL be edge-gated rather than app-OIDC-gated
Human browser access to Gatus SHALL rely on edge access controls (Cloudflare Access) and SHALL NOT require app-native OIDC wiring in Gatus for this wave.

#### Scenario: Browser user opens Gatus public route
- **WHEN** a user accesses `gatus.shrublab.xyz`
- **THEN** edge access controls enforce browser authentication
- **AND** Gatus app configuration does not require local OIDC client credentials for this flow

### Requirement: Filebrowser widget auth SHALL remain out of scope in this wave
This change SHALL NOT require Filebrowser widget machine-auth wiring.

#### Scenario: Auth coverage is reviewed for current wave
- **WHEN** implementation scope is validated
- **THEN** Filebrowser widget auth wiring is excluded from required deliverables
- **AND** no Filebrowser-specific Homepage credential contract is introduced in this change


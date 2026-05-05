## MODIFIED Requirements

### Requirement: Admin application SHALL enable native admin operations services
`applications.admin` composition SHALL wire Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Quantum, Homepage Dashboard, Beszel hub, Kanidm, and Termix through service-level admin modules under `modules/services/admin/`, while keeping tightly coupled portable access and identity composition in the reusable `modules/applications/admin/` module rather than host-local assembly or redundant split glue files.

#### Scenario: Admin profile enables expanded baseline service set
- **WHEN** a host imports and enables the admin application profile
- **THEN** the host configuration includes `services.cockpit.enable`, `services.webhook.enable`, `services.ntfy-sh.enable`, `services.gatus.enable`, `services.vaultwarden.enable`, `services.homepage-dashboard.enable`, and `services.beszel.hub.enable`
- **AND** Kanidm service wiring is enabled through `services.admin.kanidm`
- **AND** Quantum service wiring is enabled through `services.admin.quantum`
- **AND** Termix service wiring is enabled through `services.admin.termix`
- **AND** service-owned wiring resides in admin service modules rather than generic-service wrapper indirection
- **AND** portable access and identity composition remains owned by `applications.admin`

### Requirement: Admin app auth SHALL support Kanidm OIDC for phase-1 supported services
The admin baseline SHALL support app-native OIDC using Kanidm as shared issuer for the phase-1 app set (`gatus`, `beszel`, `termix`, `quantum`) while keeping explicit exceptions for services that are not in scope for this auth wave and deferring unixd/PAM/SSH host login rollout until after OIDC parity.

#### Scenario: Phase-1 supported apps are OIDC-enabled
- **WHEN** the admin baseline is rendered for `do-admin-1`
- **THEN** `gatus`, `beszel`, `termix`, and `quantum` include app-level OIDC wiring using Kanidm issuer endpoints and scoped credentials

#### Scenario: Cloudflare Access upstream IdP is Kanidm
- **WHEN** Cloudflare Access configuration is evaluated for admin browser routes
- **THEN** Access uses Kanidm generic OIDC as upstream IdP rather than Google OAuth or Pocket ID

#### Scenario: Explicit exceptions remain outside phase-1 app OIDC rollout
- **WHEN** exception services are evaluated in this change scope
- **THEN** `vaultwarden`, `navidrome`, `syncthing`, `webhook`, `ntfy`, `cockpit`, and `homepage` are not required to implement app-native OIDC in this phase
- **AND** exception rationale remains documented in change artifacts

### Requirement: Admin secrets SHALL remain scoped for OIDC client credentials
Kanidm OIDC app credentials used by admin services SHALL be defined in explicit scoped secret files and SHALL NOT be promoted to unrelated shared secret scope by default.

#### Scenario: OIDC credentials are added for admin apps
- **WHEN** OIDC client credentials are declared for phase-1 apps
- **THEN** they are sourced from explicit scoped secret files/templates for the consuming services
- **AND** they are not introduced under unrelated shared/common secret scope by default

### Requirement: Quantum auth SHALL support Kanidm OIDC with controlled fallback
Quantum SHALL support Kanidm OIDC and MAY retain local password fallback only where the host configuration still chooses to keep that fallback enabled.

#### Scenario: Quantum auth posture is evaluated
- **WHEN** Quantum auth configuration is rendered
- **THEN** Kanidm OIDC wiring is present
- **AND** any local password fallback remains an explicit host-owned choice rather than an implicit default for all environments

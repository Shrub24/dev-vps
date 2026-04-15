## MODIFIED Requirements

### Requirement: Admin app auth SHALL support Cloudflare Access OIDC for phase-1 supported services
The admin baseline SHALL support app-native OIDC using Cloudflare Access as provider for the phase-1 app set (`gatus`, `filebrowser`, `beszel`, `termix`) while keeping explicit exceptions for services that are not in scope for this auth wave.

#### Scenario: Phase-1 supported apps are OIDC-enabled
- **WHEN** the admin baseline is rendered for `do-admin-1`
- **THEN** `gatus`, `filebrowser`, `beszel`, and `termix` include app-level OIDC wiring using Cloudflare Access provider endpoints and host-scoped credentials

#### Scenario: Explicit exceptions remain outside phase-1 app OIDC rollout
- **WHEN** exception services are evaluated in this change scope
- **THEN** `vaultwarden`, `syncthing`, `webhook`, `ntfy`, `cockpit`, and `homepage` are not required to implement app-native OIDC in this phase
- **AND** exception rationale remains documented in change artifacts

### Requirement: Admin secrets SHALL remain host-scoped for OIDC client credentials
Cloudflare Access OIDC app credentials used by admin services SHALL be defined as host-scoped secrets for `do-admin-1` and not promoted to shared common secret scope.

#### Scenario: OIDC credentials are added for admin apps
- **WHEN** OIDC client credentials are declared for phase-1 apps
- **THEN** they are sourced from host-scoped secret files/templates for `do-admin-1`
- **AND** they are not introduced under shared/common secret scope by default

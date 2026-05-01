## ADDED Requirements

### Requirement: Pocket ID module SHALL own and emit OIDC endpoint URIs
The Pocket ID service module SHALL derive canonical OIDC endpoint URIs from its own `appUrl` and SHALL emit them as read-only outputs so consumers do not independently reconstruct OIDC URIs.

#### Scenario: Pocket ID OIDC outputs are resolved
- **WHEN** Pocket ID service wiring is enabled and `appUrl` is configured
- **THEN** `services.admin.pocket-id.oidc.issuerUrl` equals the configured `appUrl`
- **AND** `services.admin.pocket-id.oidc.wellknownUrl` resolves to `{appUrl}/.well-known/openid-configuration`
- **AND** `services.admin.pocket-id.oidc.authorizationUrl` resolves to `{appUrl}/authorize`
- **AND** `services.admin.pocket-id.oidc.tokenUrl` resolves to `{appUrl}/api/oidc/token`
- **AND** `services.admin.pocket-id.oidc.userinfoUrl` resolves to `{appUrl}/api/oidc/userinfo`

### Requirement: OIDC consumers SHALL reference provider-owned outputs
Service modules and host configurations that require OIDC endpoint URIs SHALL reference Pocket ID module outputs rather than independently constructing URIs from a base URL.

#### Scenario: Admin application services consume SSOT OIDC issuer
- **WHEN** Termix and Quantum OIDC wiring is evaluated
- **THEN** `issuerUrl` values are sourced from `config.services.admin.pocket-id.oidc.issuerUrl`
- **AND** no independent `pocketIdBaseUrl` string interpolation is used to derive the issuer URL

#### Scenario: Host-level OIDC env templates consume SSOT endpoints
- **WHEN** `do-admin-1` termix-oidc.env template is rendered
- **THEN** OIDC endpoint values are sourced from `config.services.admin.pocket-id.oidc.*`
- **AND** no host-local URL construction is used for endpoint values

#### Scenario: Karakeep OIDC wellknown URL uses policy-derived endpoint
- **WHEN** Karakeep OIDC configuration is evaluated on `oci-melb-1`
- **THEN** the wellknown URL is derived from the Pocket ID public URL via `mkOidcEndpoints`
- **AND** no hardcoded host-local OIDC endpoint string is used

### Requirement: mkOidcEndpoints SHALL provide consistent OIDC URI derivation
A shared `mkOidcEndpoints` helper SHALL exist in `lib/policy.nix` that derives the five canonical OIDC endpoint URIs from a single issuer base URL.

#### Scenario: Helper is used for OIDC endpoint derivation
- **WHEN** an issuer URL is passed to `mkOidcEndpoints`
- **THEN** the returned attrset contains all five canonical OIDC endpoint URIs
- **AND** the derivation logic is identical across all call sites

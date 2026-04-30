# Spec: Secrets Management

## Purpose

Define blast-radius-scoped secret management contracts using SOPS and age recipients across fleet and host scopes.
## Requirements
### Requirement: Secret scopes are explicitly separated
Secrets SHALL be split into fleet-shared and host-specific scopes with explicit path policies.

#### Scenario: Secret files are reviewed
- **WHEN** repository secret locations and policy are inspected
- **THEN** shared and host-specific scopes are clearly separated

### Requirement: Recipient policy is path-bound and auditable
SOPS recipient rules SHALL be path-scoped and auditable to prevent implicit cross-host access.

#### Scenario: New host recipient is introduced
- **WHEN** recipient rules are updated
- **THEN** only explicitly targeted secret paths include the new host recipient

### Requirement: Two-step bootstrap secret flow is supported
Base host install SHALL not require host secrets, with host-secret enablement occurring as a second step.

#### Scenario: Initial host bring-up is performed
- **WHEN** host is installed before secret bootstrap
- **THEN** base system converges and secret-dependent wiring can be enabled afterward

### Requirement: Host recipient derivation is operationalized
Host recipient derivation from SSH host keys SHALL be available through operator workflows.

#### Scenario: Operator derives host age recipient
- **WHEN** recipient derivation command is executed
- **THEN** generated recipient can be used to update secret policy/workflow safely

### Requirement: SoulSync service credentials SHALL be host-scoped
SoulSync integration credentials for `oci-melb-1` SHALL be host-scoped secrets and SHALL NOT expand decryption access outside explicit host-targeted policy.

#### Scenario: SoulSync credentials are introduced
- **WHEN** SoulSync secrets are added for slskd, Discogs, and media-server/provider integrations
- **THEN** they are stored under host-scoped secret files/policies for `oci-melb-1`

### Requirement: Optional provider credentials SHALL not be mandatory for convergence
SoulSync optional-provider credentials SHALL remain optional at render/deploy time so host convergence does not fail when optional integrations are not configured.

#### Scenario: Optional provider credentials are missing
- **WHEN** host evaluation and deployment run without one or more optional SoulSync provider secrets
- **THEN** secret/template rendering still converges
- **AND** only configured providers are enabled at runtime

### Requirement: OpenTofu backend/runtime secrets SHALL be path-scoped and encrypted
OpenTofu Cloudflare backend and runtime credentials SHALL be stored in SOPS-encrypted files with path-scoped recipient rules and rendered to ignored runtime artifacts only when needed for local operations.

#### Scenario: OpenTofu backend credentials are provisioned
- **WHEN** operator prepares Cloudflare OpenTofu runtime inputs
- **THEN** secret source remains encrypted under OpenTofu-specific secret paths
- **AND** generated plaintext backend/tfvars artifacts are not committed to repository history

### Requirement: Vaultwarden mail and push credentials SHALL remain host-scoped
Vaultwarden administrative, SMTP, and push credentials for `do-admin-1` SHALL remain host-scoped secrets and SHALL NOT be promoted to shared/common secret scope.

#### Scenario: Vaultwarden credentials are added
- **WHEN** secret definitions and templates are reviewed for `do-admin-1`
- **THEN** Vaultwarden admin token, SMTP credentials, and push credentials are sourced from the host-scoped secret set
- **AND** shared/common secret files do not gain decryption access to those values by default

### Requirement: OpenTofu mail-provider runtime secrets SHALL remain separate from public DNS inputs
OpenTofu or service runtime credentials used for mail-provider integration SHALL remain encrypted under secret-scoped inputs, while non-secret DNS verification data remains outside encrypted secret storage.

#### Scenario: Mail-provider configuration is reviewed
- **WHEN** the repo is inspected for Resend-related inputs
- **THEN** SMTP/API secret material is stored only in encrypted secret paths or host-scoped secret templates
- **AND** DNS verification records are represented in non-secret configuration files

### Requirement: Tagr credentials SHALL be host-scoped for oci-melb-1
Tagr credentials and session secret for `oci-melb-1` SHALL be sourced from host-scoped secret files/templates and SHALL NOT be introduced under shared secret scope.

#### Scenario: Tagr secrets are introduced
- **WHEN** Tagr auth/session values are added for `oci-melb-1`
- **THEN** they are stored under `hosts/oci-melb-1/secrets.yaml` and rendered via host-scoped templates
- **AND** `.sops.yaml` path-scoped rules do not broaden decryption access beyond explicit host recipients

### Requirement: Termix OIDC env template SHALL consume provider-owned endpoint outputs
The Termix OIDC environment template for `do-admin-1` SHALL source OIDC endpoint values from `config.services.admin.pocket-id.oidc.*` rather than independently constructing endpoint URIs.

#### Scenario: Termix OIDC env is rendered from SSOT
- **WHEN** `do-admin-1` termix-oidc.env template is evaluated
- **THEN** `OIDC_ISSUER_URL`, `OIDC_AUTHORIZATION_URL`, `OIDC_TOKEN_URL`, and `OIDC_USERINFO_URL` are resolved from Pocket ID module outputs
- **AND** no local URL derivation from a raw `pocketIdBaseUrl` is used


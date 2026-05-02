# Spec: Secrets Management

## Purpose

Define blast-radius-scoped secret management contracts using SOPS and age recipients across fleet and host scopes.
## Requirements
### Requirement: Secret scopes are explicitly separated
Secrets SHALL be split into application-scoped, standalone-service-scoped, and host-exception-scoped material with explicit path policies.

#### Scenario: Secret files are reviewed
- **WHEN** repository secret locations and policy are inspected
- **THEN** application, standalone-service, and host-exception scopes are clearly separated

### Requirement: Recipient policy is path-bound and auditable
SOPS recipient rules SHALL be path-scoped and auditable to prevent implicit cross-host access, with normal application/service reader sets derived from explicit feature enablement and only narrow extra-reader exceptions declared separately.

#### Scenario: New host recipient is introduced
- **WHEN** recipient rules are updated
- **THEN** only explicitly targeted host-exception paths and feature-derived application/service paths include that host recipient

#### Scenario: Extra readers are needed outside normal feature ownership
- **WHEN** a secret scope needs readers beyond the hosts that directly enable the feature
- **THEN** that reader expansion is represented as an explicit exception scope or exception rule
- **AND** it does not silently broaden unrelated secret paths

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
SoulSync integration credentials for the music stack SHALL be stored under the music application secret scope and SHALL NOT expand decryption access outside the hosts that explicitly enable that application.

#### Scenario: SoulSync credentials are introduced
- **WHEN** SoulSync secrets are added for slskd, Discogs, and media-server/provider integrations
- **THEN** they are stored under the music application secret scope
- **AND** only hosts that explicitly enable the music application gain decryption access by default

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
Vaultwarden administrative, SMTP, and push credentials for the admin stack SHALL live under the admin application secret scope by default and SHALL NOT be promoted to unrelated shared scopes.

#### Scenario: Vaultwarden credentials are added
- **WHEN** secret definitions and templates are reviewed for the admin stack
- **THEN** Vaultwarden admin token, SMTP credentials, and push credentials are sourced from the admin application secret set
- **AND** unrelated application/service scopes do not gain decryption access by default

### Requirement: OpenTofu mail-provider runtime secrets SHALL remain separate from public DNS inputs
OpenTofu or service runtime credentials used for mail-provider integration SHALL remain encrypted under secret-scoped inputs, while non-secret DNS verification data remains outside encrypted secret storage.

#### Scenario: Mail-provider configuration is reviewed
- **WHEN** the repo is inspected for Resend-related inputs
- **THEN** SMTP/API secret material is stored only in encrypted secret paths or host-scoped secret templates
- **AND** DNS verification records are represented in non-secret configuration files

### Requirement: Tagr credentials SHALL be host-scoped for oci-melb-1
Tagr credentials and session secret SHALL be sourced from the music application secret scope and SHALL NOT be introduced under unrelated shared or host-monolith secret scope.

#### Scenario: Tagr secrets are introduced
- **WHEN** Tagr auth/session values are added for the music stack
- **THEN** they are stored under the music application secret scope and rendered through feature-owned templates/contracts
- **AND** `.sops.yaml` path-scoped rules do not broaden decryption access beyond hosts that explicitly enable the music application

### Requirement: Termix OIDC env template SHALL consume provider-owned endpoint outputs
The Termix OIDC environment template for `do-admin-1` SHALL source OIDC endpoint values from `config.services.admin.pocket-id.oidc.*` rather than independently constructing endpoint URIs.

#### Scenario: Termix OIDC env is rendered from SSOT
- **WHEN** `do-admin-1` termix-oidc.env template is evaluated
- **THEN** `OIDC_ISSUER_URL`, `OIDC_AUTHORIZATION_URL`, `OIDC_TOKEN_URL`, and `OIDC_USERINFO_URL` are resolved from Pocket ID module outputs
- **AND** no local URL derivation from a raw `pocketIdBaseUrl` is used

### Requirement: AI gateway provider credentials SHALL remain host-scoped unless explicitly shared
Provider API keys and similar sensitive gateway credentials SHALL be sourced from standalone service-scoped secret files by default and SHALL NOT be promoted to broader shared scopes unless a later change explicitly requires it.

#### Scenario: Gateway provider credentials are introduced
- **WHEN** provider credentials are added for a Bifrost deployment host
- **THEN** they are stored under that gateway service’s encrypted secret scope and rendered through service-owned templates or environment files
- **AND** unrelated application/shared scopes do not gain access implicitly

### Requirement: Gateway rendered configuration SHALL reference env-backed secrets rather than inline secret values
Repo-owned Bifrost configuration SHALL reference environment-backed secret material rather than embedding live provider secrets directly into committed configuration content.

#### Scenario: Gateway config is rendered
- **WHEN** canonical Bifrost settings are generated from repo configuration
- **THEN** secret-bearing fields resolve through environment references or equivalent secret indirection
- **AND** committed configuration artifacts do not contain live provider key material

### Requirement: Karakeep runtime secrets SHALL remain host-scoped for oci-melb-1
Karakeep required runtime secrets SHALL be sourced from standalone service-scoped secret files/templates and SHALL NOT be introduced under unrelated application or host-monolith secret scope.

#### Scenario: Karakeep secrets are introduced
- **WHEN** Karakeep auth, search, OIDC client, or enabled storage secret values are added
- **THEN** they are stored under the Karakeep service secret scope and rendered via service-owned templates/contracts
- **AND** `.sops.yaml` path-scoped rules do not broaden decryption access beyond explicitly targeted host recipients

### Requirement: Optional Karakeep integration secrets SHALL not be mandatory for convergence
Karakeep optional integration secrets SHALL remain optional at render and deploy time unless the corresponding integration is explicitly enabled.

#### Scenario: Optional Karakeep feature secrets are absent
- **WHEN** host evaluation and deployment run without optional Karakeep AI, OAuth, SMTP, S3, or OCR secrets for integrations that are not enabled
- **THEN** base Karakeep secret/template rendering still converges
- **AND** only the explicitly configured optional integrations are enabled at runtime

### Requirement: Karakeep rendered secret environment SHALL be wired into runtime
When Karakeep secret/template ownership is leaf-managed, runtime containers SHALL consume the rendered `sops` environment file path rather than an unmanaged default file path.

#### Scenario: Karakeep runtime env-file handoff is reviewed
- **WHEN** `services.karakeep-pod` is enabled and module-owned `sops.templates."karakeep.environment"` is rendered
- **THEN** `services.karakeep-pod.environmentFile` resolves to the rendered template path
- **AND** Karakeep runtime receives required secret-backed variables (including NextAuth and OIDC client credentials when OIDC is enabled)

### Requirement: Host exception secret scopes SHALL stay narrow and explicit
Host exception secret scopes SHALL be reserved for host/bootstrap/system-only material and explicitly declared cross-host identity handshakes, and SHALL NOT become a fallback bucket for general application internals.

#### Scenario: Host system secrets are reviewed
- **WHEN** `secrets/hosts/<host>/system.yaml` is inspected
- **THEN** it contains host/bootstrap/system-only material
- **AND** reusable application/service internals are absent from that scope

#### Scenario: Cross-host OIDC material is reviewed
- **WHEN** `secrets/hosts/<host>/oidc.yaml` or equivalent explicit exception scope is inspected
- **THEN** its reader set matches the declared host-identity handshake need
- **AND** it does not implicitly grant access to unrelated application/service secret material

#### Scenario: OIDC client credentials are consumed after host thinning
- **WHEN** a composed admin or standalone service consumes OIDC client credentials after the secret-topology migration
- **THEN** those client credentials continue to come from the narrow `secrets/hosts/<host>/oidc.yaml` exception scope through the leaf module's explicit secret contract
- **AND** application composition only passes the required contract inputs or resolved env-file paths without taking ownership of the underlying secret registration

#### Scenario: Host-scoped Beszel agent token is reviewed after host thinning
- **WHEN** a host enables `services.beszel-agent-auth`
- **THEN** the host binds the token source through the same helper-based secret-file contract style used by other leaf services
- **AND** the leaf module remains responsible for rendering the Beszel agent environment file and registering the underlying secret entries


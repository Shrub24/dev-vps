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
The Termix OIDC environment template for `do-admin-1` SHALL source OIDC endpoint values from canonical identity-provider `oidc.*` outputs rather than independently constructing endpoint URIs.

#### Scenario: Termix OIDC env is rendered from SSOT
- **WHEN** `do-admin-1` termix-oidc.env template is evaluated
- **THEN** `OIDC_ISSUER_URL`, `OIDC_AUTHORIZATION_URL`, `OIDC_TOKEN_URL`, and `OIDC_USERINFO_URL` are resolved from canonical identity-provider module outputs
- **AND** no local URL derivation from a raw provider base URL is used

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
Host exception secret scopes SHALL be reserved for host/bootstrap/system-only material, host recovery material, and explicitly declared cross-host identity handshakes, and SHALL NOT become a fallback bucket for general application internals.

#### Scenario: Host system secrets are reviewed
- **WHEN** `secrets/hosts/<host>/system.yaml` is inspected
- **THEN** it contains host/bootstrap/system-only material
- **AND** reusable application/service internals are absent from that scope

#### Scenario: Host recovery secrets are reviewed
- **WHEN** host-scoped recovery key material is inspected
- **THEN** rescue-only password hash material or equivalent recovery secrets remain limited to the target host scope
- **AND** unrelated hosts do not gain decryption access implicitly

#### Scenario: Cross-host identity handshake material is reviewed
- **WHEN** an explicit host-exception identity scope such as `secrets/hosts/<host>/oidc.yaml` is inspected
- **THEN** its reader set matches the declared host-identity handshake need
- **AND** it does not implicitly grant access to unrelated application/service secret material

#### Scenario: OIDC client credentials are consumed after Kanidm migration
- **WHEN** a composed admin or standalone service consumes OIDC client credentials for Kanidm provisioning or runtime auth
- **THEN** those client credentials continue to come from explicit scoped secret files through the leaf module's secret contract or helper-rendered runtime file path
- **AND** application composition only passes the required contract inputs or resolved env-file paths without taking ownership of the underlying secret registration

### Requirement: Identity provider bootstrap secrets SHALL remain identity-scoped
Kanidm bootstrap and identity-management admin secrets SHALL be stored under identity-scoped encrypted secret paths and SHALL NOT be mixed into unrelated application/service scopes.

#### Scenario: Kanidm bootstrap credentials are introduced
- **WHEN** bootstrap or identity-management admin secrets are added for the Kanidm service
- **THEN** they are stored under explicit identity-scoped encrypted paths
- **AND** unrelated application/service secret scopes do not gain access implicitly

### Requirement: Backup repository credentials SHALL remain host-scoped
Backup access keys, secret keys, and restic repository passwords SHALL be stored in host-scoped encrypted secret material and SHALL NOT be promoted to shared application or common secret scopes by default.

#### Scenario: Host backup secrets are reviewed
- **WHEN** backup secret definitions for `do-admin-1` and `oci-melb-1` are inspected
- **THEN** each host uses its own encrypted backup credentials and repository password material
- **AND** unrelated hosts do not gain decryption access implicitly

### Requirement: Backup transport defaults SHALL reuse canonical non-secret S3 settings
Backup configuration SHALL reuse canonical non-secret S3 endpoint behavior from shared repository policy while keeping sensitive credential material encrypted and host-scoped.

#### Scenario: Backup S3 transport settings are rendered
- **WHEN** host backup configuration is evaluated
- **THEN** endpoint, region, and path-style defaults resolve from canonical non-secret policy inputs
- **AND** access credentials still resolve from encrypted host-scoped secret material

### Requirement: CI build-plane credentials SHALL remain CI-scoped
CI credentials used to authenticate GitHub Actions to `nixbuild.net` SHALL be managed in CI secret scope and SHALL NOT be required in host secret files.

#### Scenario: CI secret ownership is audited
- **WHEN** repository secret paths and workflow secret references are inspected
- **THEN** CI auth material is referenced from CI secret management
- **AND** host-scoped secret trees do not need a dedicated nixbuild machine-auth secret path for the current change


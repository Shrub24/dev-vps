## MODIFIED Requirements

### Requirement: Termix OIDC env template SHALL consume provider-owned endpoint outputs
The Termix OIDC environment template for `do-admin-1` SHALL source OIDC endpoint values from canonical identity-provider `oidc.*` outputs rather than independently constructing endpoint URIs.

#### Scenario: Termix OIDC env is rendered from SSOT
- **WHEN** `do-admin-1` termix-oidc.env template is evaluated
- **THEN** `OIDC_ISSUER_URL`, `OIDC_AUTHORIZATION_URL`, `OIDC_TOKEN_URL`, and `OIDC_USERINFO_URL` are resolved from canonical identity-provider module outputs
- **AND** no local URL derivation from a raw provider base URL is used

### Requirement: Host exception secret scopes SHALL stay narrow and explicit
Host exception secret scopes SHALL be reserved for host/bootstrap/system-only material and explicitly declared cross-host identity handshakes, and SHALL NOT become a fallback bucket for general application internals.

#### Scenario: Host system secrets are reviewed
- **WHEN** `secrets/hosts/<host>/system.yaml` is inspected
- **THEN** it contains host/bootstrap/system-only material
- **AND** reusable application/service internals are absent from that scope

#### Scenario: Cross-host identity handshake material is reviewed
- **WHEN** an explicit host-exception identity scope such as `secrets/hosts/<host>/oidc.yaml` is inspected
- **THEN** its reader set matches the declared host-identity handshake need
- **AND** it does not implicitly grant access to unrelated application/service secret material

#### Scenario: OIDC client credentials are consumed after Kanidm migration
- **WHEN** a composed admin or standalone service consumes OIDC client credentials for Kanidm provisioning or runtime auth
- **THEN** those client credentials continue to come from explicit scoped secret files through the leaf module's secret contract or helper-rendered runtime file path
- **AND** application composition only passes the required contract inputs or resolved env-file paths without taking ownership of the underlying secret registration

## ADDED Requirements

### Requirement: Identity provider bootstrap secrets SHALL remain identity-scoped
Kanidm bootstrap and identity-management admin secrets SHALL be stored under identity-scoped encrypted secret paths and SHALL NOT be mixed into unrelated application/service scopes.

#### Scenario: Kanidm bootstrap credentials are introduced
- **WHEN** bootstrap or identity-management admin secrets are added for the Kanidm service
- **THEN** they are stored under explicit identity-scoped encrypted paths
- **AND** unrelated application/service secret scopes do not gain access implicitly

### Requirement: Sensitive person metadata SHALL use encrypted whole-file identity scope
Sensitive Kanidm person/account metadata SHALL be stored in an identity-scoped encrypted whole-file secret rather than spread across committed policy or many per-field runtime secret registrations.

#### Scenario: Declarative person metadata is introduced
- **WHEN** real user account metadata such as usernames, display names, legal names, email addresses, or memberships is added for Kanidm provisioning
- **THEN** that data is sourced from an explicit encrypted identity file
- **AND** non-sensitive topology remains separate from the encrypted person metadata source
- **AND** application/service secret scopes do not gain access to the person metadata by default

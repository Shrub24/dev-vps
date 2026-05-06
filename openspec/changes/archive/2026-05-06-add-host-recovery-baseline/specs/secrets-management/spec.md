## MODIFIED Requirements

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

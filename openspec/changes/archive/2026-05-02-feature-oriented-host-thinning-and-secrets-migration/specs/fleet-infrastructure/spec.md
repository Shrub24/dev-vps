## MODIFIED Requirements

### Requirement: Host composition is host-centric and modular
The repository SHALL organize host identity separately from reusable modules so hosts can add or remove feature stacks through explicit application/service enablement without reintroducing service ownership at the host layer.

#### Scenario: A host is composed from shared modules
- **WHEN** a host configuration is declared in `hosts/<host>/default.nix`
- **THEN** it composes reusable modules rather than embedding provider/service logic inline
- **AND** it enables composed workloads through canonical application or standalone service entrypoints instead of hidden import-only activation

#### Scenario: Edge role is assigned to one host
- **WHEN** only one host is configured as ingress edge
- **THEN** other hosts can remain private-origin nodes with shared module composition patterns

### Requirement: Secret blast radius is path-scoped
Secrets SHALL be split into topology-aligned application, standalone-service, and host-exception scopes with explicit path rules that do not grant implicit cross-host decryption.

#### Scenario: A new host is introduced
- **WHEN** secret files and `.sops.yaml` rules are evaluated
- **THEN** only explicitly declared recipients can decrypt that host’s system/exception scopes
- **AND** the host only gains access to application or standalone-service scopes that correspond to features it explicitly enables

#### Scenario: Cross-host exception readers are required
- **WHEN** a host-scoped exception such as an OIDC handshake requires an extra reader set
- **THEN** that exception is represented in an explicit host exception scope
- **AND** its additional readers do not broaden access to unrelated application or service secret scopes

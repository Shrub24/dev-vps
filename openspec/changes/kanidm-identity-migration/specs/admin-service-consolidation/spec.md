## MODIFIED Requirements

### Requirement: Admin-owned services SHALL expose canonical admin namespaces
When a service is treated as admin-owned in this repository, its canonical reusable module SHALL expose configuration through `services.admin.<name>` and SHALL directly own the runtime wiring needed to configure the underlying NixOS or containerized service.

#### Scenario: Kanidm admin wiring is evaluated
- **WHEN** operators inspect the canonical Kanidm module
- **THEN** Kanidm options are exposed under `services.admin.kanidm`
- **AND** the module directly configures the underlying native `services.kanidm` runtime and provisioning behavior
- **AND** a generic passthrough namespace is not required as the canonical implementation path

### Requirement: Admin application SHALL source OIDC issuer from provider module
`applications.admin` composition SHALL source OIDC issuer URLs for Termix and Quantum from the canonical identity provider module outputs rather than deriving them from a local provider base URL variable.

#### Scenario: Termix OIDC issuer is sourced from provider module
- **WHEN** admin application composition is evaluated for `do-admin-1`
- **THEN** `services.admin.termix.oidc.issuerUrl` is set from the canonical identity provider `oidc.issuerUrl` output
- **AND** no local provider base URL variable is used for the Termix issuer derivation

#### Scenario: Quantum OIDC issuer is sourced from provider module
- **WHEN** admin application composition is evaluated for `do-admin-1`
- **THEN** `services.admin.quantum.oidc.issuerUrl` is set from the canonical identity provider `oidc.issuerUrl` output
- **AND** no local provider base URL variable is used for the Quantum issuer derivation

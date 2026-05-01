## ADDED Requirements

### Requirement: Admin application SHALL source OIDC issuer from Pocket ID module
`applications.admin` composition SHALL source OIDC issuer URLs for Termix and Quantum from `config.services.admin.pocket-id.oidc.issuerUrl` rather than deriving from a local `pocketIdBaseUrl` variable.

#### Scenario: Termix OIDC issuer is sourced from provider module
- **WHEN** admin application composition is evaluated for `do-admin-1`
- **THEN** `services.admin.termix.oidc.issuerUrl` is set to `config.services.admin.pocket-id.oidc.issuerUrl`
- **AND** no local `pocketIdBaseUrl` variable is used for the Termix issuer derivation

#### Scenario: Quantum OIDC issuer is sourced from provider module
- **WHEN** admin application composition is evaluated for `do-admin-1`
- **THEN** `services.admin.quantum.oidc.issuerUrl` is set to `config.services.admin.pocket-id.oidc.issuerUrl`
- **AND** no local `pocketIdBaseUrl` variable is used for the Quantum issuer derivation

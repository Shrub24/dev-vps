## ADDED Requirements

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

## ADDED Requirements

### Requirement: Vaultwarden SHALL expose a production-oriented mail-capable baseline
Vaultwarden service wiring on `do-admin-1` SHALL define a production-oriented baseline including resolved public domain settings, invite-only account posture, SMTP delivery settings, push capability, and explicit security tuning.

#### Scenario: Vaultwarden admin service is evaluated
- **WHEN** `applications.admin` enables Vaultwarden for `do-admin-1`
- **THEN** Vaultwarden config includes resolved public URL/domain inputs and reverse-proxy-aware headers
- **AND** signup posture defaults to invite-only operation rather than open self-service registration
- **AND** push and operational security settings are declared in the service baseline

### Requirement: Vaultwarden SMTP secrets SHALL be host-scoped and template-rendered
Vaultwarden SMTP and admin runtime secrets for `do-admin-1` SHALL be rendered from host-scoped SOPS secrets into a service-owned environment file.

#### Scenario: Vaultwarden secret template is rendered
- **WHEN** the host secret configuration for `do-admin-1` is evaluated
- **THEN** Vaultwarden admin token, SMTP credentials, and push credentials are sourced from host-scoped secrets
- **AND** the generated environment file is owned and permissioned for the Vaultwarden service only

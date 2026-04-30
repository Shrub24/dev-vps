## ADDED Requirements

### Requirement: Termix OIDC env template SHALL consume provider-owned endpoint outputs
The Termix OIDC environment template for `do-admin-1` SHALL source OIDC endpoint values from `config.services.admin.pocket-id.oidc.*` rather than independently constructing endpoint URIs.

#### Scenario: Termix OIDC env is rendered from SSOT
- **WHEN** `do-admin-1` termix-oidc.env template is evaluated
- **THEN** `OIDC_ISSUER_URL`, `OIDC_AUTHORIZATION_URL`, `OIDC_TOKEN_URL`, and `OIDC_USERINFO_URL` are resolved from Pocket ID module outputs
- **AND** no local URL derivation from a raw `pocketIdBaseUrl` is used

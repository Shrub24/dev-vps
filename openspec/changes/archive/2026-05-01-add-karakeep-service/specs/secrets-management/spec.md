## ADDED Requirements

### Requirement: Karakeep runtime secrets SHALL remain host-scoped for oci-melb-1
Karakeep required runtime secrets for `oci-melb-1` SHALL be sourced from host-scoped secret files/templates and SHALL NOT be introduced under shared secret scope.

#### Scenario: Karakeep secrets are introduced
- **WHEN** Karakeep auth and search secret values are added for `oci-melb-1`
- **THEN** they are stored under `hosts/oci-melb-1/secrets.yaml` and rendered via host-scoped templates
- **AND** `.sops.yaml` path-scoped rules do not broaden decryption access beyond explicit host recipients

### Requirement: Optional Karakeep integration secrets SHALL not be mandatory for convergence
Karakeep optional integration secrets SHALL remain optional at render and deploy time unless the corresponding integration is explicitly enabled.

#### Scenario: Optional Karakeep feature secrets are absent
- **WHEN** host evaluation and deployment run without optional Karakeep AI, OAuth, SMTP, S3, or OCR secrets
- **THEN** base Karakeep secret/template rendering still converges
- **AND** only the explicitly configured optional integrations are enabled at runtime

## ADDED Requirements

### Requirement: OpenTofu backend/runtime secrets SHALL be path-scoped and encrypted
OpenTofu Cloudflare backend and runtime credentials SHALL be stored in SOPS-encrypted files with path-scoped recipient rules and rendered to ignored runtime artifacts only when needed for local operations.

#### Scenario: OpenTofu backend credentials are provisioned
- **WHEN** operator prepares Cloudflare OpenTofu runtime inputs
- **THEN** secret source remains encrypted under OpenTofu-specific secret paths
- **AND** generated plaintext backend/tfvars artifacts are not committed to repository history

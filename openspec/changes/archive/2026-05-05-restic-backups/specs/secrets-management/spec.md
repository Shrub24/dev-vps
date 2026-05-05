## ADDED Requirements

### Requirement: Backup repository credentials SHALL remain host-scoped
Backup access keys, secret keys, and restic repository passwords SHALL be stored in host-scoped encrypted secret material and SHALL NOT be promoted to shared application or common secret scopes by default.

#### Scenario: Host backup secrets are reviewed
- **WHEN** backup secret definitions for `do-admin-1` and `oci-melb-1` are inspected
- **THEN** each host uses its own encrypted backup credentials and repository password material
- **AND** unrelated hosts do not gain decryption access implicitly

### Requirement: Backup transport defaults SHALL reuse canonical non-secret S3 settings
Backup configuration SHALL reuse canonical non-secret S3 endpoint behavior from shared repository policy while keeping sensitive credential material encrypted and host-scoped.

#### Scenario: Backup S3 transport settings are rendered
- **WHEN** host backup configuration is evaluated
- **THEN** endpoint, region, and path-style defaults resolve from canonical non-secret policy inputs
- **AND** access credentials still resolve from encrypted host-scoped secret material

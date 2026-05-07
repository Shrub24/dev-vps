## ADDED Requirements

### Requirement: CI build-plane credentials SHALL remain CI-scoped
CI credentials used to authenticate GitHub Actions to `nixbuild.net` SHALL be managed in CI secret scope and SHALL NOT be required in host secret files.

#### Scenario: CI secret ownership is audited
- **WHEN** repository secret paths and workflow secret references are inspected
- **THEN** CI auth material is referenced from CI secret management
- **AND** host-scoped secret trees do not need a dedicated nixbuild machine-auth secret path for the current change

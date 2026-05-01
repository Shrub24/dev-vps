## ADDED Requirements

### Requirement: Tagr credentials SHALL be host-scoped for oci-melb-1
Tagr credentials and session secret for `oci-melb-1` SHALL be sourced from host-scoped secret files/templates and SHALL NOT be introduced under shared secret scope.

#### Scenario: Tagr secrets are introduced
- **WHEN** Tagr auth/session values are added for `oci-melb-1`
- **THEN** they are stored under `hosts/oci-melb-1/secrets.yaml` and rendered via host-scoped templates
- **AND** `.sops.yaml` path-scoped rules do not broaden decryption access beyond explicit host recipients

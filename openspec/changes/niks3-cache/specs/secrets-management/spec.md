# secrets-management Specification (Delta)

## ADDED Requirements

### Requirement: niks3 API tokens SHALL be host-scoped and stored in host system secrets
Host-scoped niks3 API tokens used for post-deploy cache push SHALL be stored in each host's `secrets/hosts/<host>/system.yaml` file, encrypted under the existing host system scope recipient rules in `.sops.yaml`.

#### Scenario: Host API token is provisioned
- **WHEN** a fleet host's niks3 API token is added
- **THEN** it is stored in `secrets/hosts/<host>/system.yaml` under the host's own secret scope
- **AND** `.sops.yaml` host system scope rules allow decryption only by that host's age recipient and the owner

#### Scenario: Cross-host token access is prevented
- **WHEN** a different host's secret file is decrypted
- **THEN** it does not contain another host's niks3 API token
- **AND** no shared or common secret scope carries niks3 API tokens

### Requirement: niks3 signing key SHALL reside only on the cache host
The niks3 server-side Ed25519 signing key SHALL be stored in `secrets/hosts/oci-melb-1/system.yaml` and SHALL NOT be distributed to other hosts or stored in shared secret scopes.

#### Scenario: Signing key is stored only on the cache host
- **WHEN** the repository secret layout is inspected
- **THEN** the niks3 signing key is present only in `oci-melb-1`'s host system secret file
- **AND** it is absent from `secrets/common.yaml`, `secrets/hosts/do-admin-1/system.yaml`, and all application/service secret scopes

#### Scenario: Signing key compromise is infrastructure-scoped
- **WHEN** the cache host's secrets are evaluated for blast radius
- **THEN** the signing key exposure is limited to the cache host recipient set
- **AND** other host secret scopes do not need updating if the signing key is rotated

### Requirement: Host system secret template SHALL document niks3 API token contract
The host system secret template at `secrets/.templates/hosts/system.yaml` SHALL document the niks3 API token contract so new hosts or operators can provision tokens consistently.

#### Scenario: Template is reviewed for niks3 coverage
- **WHEN** `secrets/.templates/hosts/system.yaml` is inspected
- **THEN** it includes a documented `niks3.api_token` placeholder with usage notes
- **AND** it includes a documented `niks3.signing_key` placeholder for the cache host only with notes that it is only needed on the designated cache host

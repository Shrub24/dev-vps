# host-unix-auth Specification

## Purpose
TBD - created by archiving change kanidm-identity-migration. Update Purpose after archive.
## Requirements
### Requirement: Fleet hosts SHALL support Kanidm client and unixd integration
Fleet hosts SHALL support Kanidm client and unixd integration through native nixpkgs client/unix modules after OIDC parity is established.

#### Scenario: Host enables Kanidm unix integration
- **WHEN** a host opts into the host-auth phase of this migration
- **THEN** native `services.kanidm.client` and `services.kanidm.unix` wiring is enabled on that host
- **AND** the host consumes the canonical Kanidm server URI rather than a duplicated local literal

### Requirement: SSH and PAM policy SHALL remain explicit and host-safe
Kanidm-backed SSH and PAM login behavior SHALL be enabled only through explicit host policy, including declarative allowlists for permitted login groups.

#### Scenario: Host enables sshIntegration
- **WHEN** a host enables Kanidm SSH integration
- **THEN** SSH key lookup behavior is declared through `services.kanidm.unix.sshIntegration`
- **AND** PAM login eligibility is constrained by explicitly declared allowed login groups


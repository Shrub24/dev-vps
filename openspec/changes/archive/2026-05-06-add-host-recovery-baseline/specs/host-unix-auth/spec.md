## MODIFIED Requirements

### Requirement: SSH and PAM policy SHALL remain explicit and host-safe
Kanidm-backed SSH and PAM login behavior SHALL be enabled only through explicit host policy, including declarative allowlists for permitted login groups, and hosts MAY declare a separate host-scoped console break-glass rescue account outside the normal identity-backed login flow.

#### Scenario: Host enables sshIntegration
- **WHEN** a host enables Kanidm SSH integration
- **THEN** SSH key lookup behavior is declared through `services.kanidm.unix.sshIntegration`
- **AND** PAM login eligibility is constrained by explicitly declared allowed login groups

#### Scenario: Host enables a rescue account
- **WHEN** a host declares break-glass rescue-user access
- **THEN** that account is configured explicitly as a host-scoped exception rather than an implicit fleet-wide normal login path
- **AND** its console login and sudo posture remains declarative and auditable

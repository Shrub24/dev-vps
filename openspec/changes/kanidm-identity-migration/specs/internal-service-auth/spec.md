## MODIFIED Requirements

### Requirement: Service-to-service secrets SHALL remain scoped by integration ownership by default
Credentials used for caller-owned internal integrations SHALL be defined in explicit service-, application-, or host-exception-scoped secret files according to integration ownership and SHALL NOT be promoted to unrelated shared scope without explicit justification.

#### Scenario: Homepage integration credentials are declared
- **WHEN** new Homepage or related integration credentials are added
- **THEN** they are sourced from an explicit feature-owned secret scope and templated for runtime use
- **AND** they are not introduced in unrelated shared/common secret scope by default

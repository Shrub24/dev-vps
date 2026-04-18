## ADDED Requirements

### Requirement: SoulSync service credentials SHALL be host-scoped
SoulSync integration credentials for `oci-melb-1` SHALL be host-scoped secrets and SHALL NOT expand decryption access outside explicit host-targeted policy.

#### Scenario: SoulSync credentials are introduced
- **WHEN** SoulSync secrets are added for slskd, Discogs, and media-server/provider integrations
- **THEN** they are stored under host-scoped secret files/policies for `oci-melb-1`

### Requirement: Optional provider credentials SHALL not be mandatory for convergence
SoulSync optional-provider credentials SHALL remain optional at render/deploy time so host convergence does not fail when optional integrations are not configured.

#### Scenario: Optional provider credentials are missing
- **WHEN** host evaluation and deployment run without one or more optional SoulSync provider secrets
- **THEN** secret/template rendering still converges
- **AND** only configured providers are enabled at runtime

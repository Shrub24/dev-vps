## ADDED Requirements

### Requirement: AI gateway provider credentials SHALL remain host-scoped unless explicitly shared
Provider API keys and similar sensitive gateway credentials SHALL be sourced from host-scoped secret files/templates by default and SHALL NOT be promoted to shared secret scope unless a later change explicitly requires it.

#### Scenario: Gateway provider credentials are introduced
- **WHEN** provider credentials are added for a Bifrost deployment host
- **THEN** they are stored under that host’s encrypted secret set and rendered through host-scoped templates or environment files
- **AND** shared/common secret scope does not gain access implicitly

### Requirement: Gateway rendered configuration SHALL reference env-backed secrets rather than inline secret values
Repo-owned Bifrost configuration SHALL reference environment-backed secret material rather than embedding live provider secrets directly into committed configuration content.

#### Scenario: Gateway config is rendered
- **WHEN** canonical Bifrost settings are generated from repo configuration
- **THEN** secret-bearing fields resolve through environment references or equivalent secret indirection
- **AND** committed configuration artifacts do not contain live provider key material

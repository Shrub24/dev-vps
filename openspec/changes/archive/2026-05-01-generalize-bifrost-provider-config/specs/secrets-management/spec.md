## MODIFIED Requirements

### Requirement: AI gateway provider credentials SHALL remain host-scoped unless explicitly shared
Provider API keys and similar sensitive gateway credentials SHALL be sourced from host-scoped secret files/templates by default and SHALL NOT be promoted to shared secret scope unless a later change explicitly requires it.

#### Scenario: Gateway provider credentials are introduced
- **WHEN** provider credentials are added for a Bifrost deployment host
- **THEN** they are stored under that host’s encrypted secret set and rendered through host-scoped templates or environment files
- **AND** shared/common secret scope does not gain access implicitly

#### Scenario: Additional gateway providers are enabled
- **WHEN** Google, DeepSeek, or later provider credentials are added for the same deployment host
- **THEN** each provider key is rendered through env-backed host-local secret references
- **AND** committed gateway configuration still avoids embedding live provider key material

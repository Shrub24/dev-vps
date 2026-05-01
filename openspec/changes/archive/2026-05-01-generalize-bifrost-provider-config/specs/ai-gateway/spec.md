## MODIFIED Requirements

### Requirement: Gateway SHALL provide one OpenAI-compatible endpoint with repo-owned routing policy
The AI gateway SHALL provide one OpenAI-compatible endpoint for downstream consumers while mapping provider/model routing declaratively inside the gateway configuration.

#### Scenario: Downstream app targets the gateway
- **WHEN** an application is configured to use the gateway base URL
- **THEN** it can request repo-declared text, image or multimodal, embedding, and fallback model aliases through that one endpoint
- **AND** provider selection is controlled by gateway policy rather than by per-app hardcoded upstream credentials

#### Scenario: Multiple providers back the gateway policy
- **WHEN** the repo configures more than one upstream provider for the gateway
- **THEN** provider entries are declared explicitly in canonical repo configuration
- **AND** stable logical aliases continue to hide provider-specific model IDs from downstream app configs

#### Scenario: Global aliases are rendered for file-driven mode
- **WHEN** the canonical gateway config is rendered to `config.json`
- **THEN** the file remains shaped like the documented upstream Bifrost schema
- **AND** shared alias behavior is expressed through `governance.routing_rules` rather than provider-key-scoped alias-only shortcuts

#### Scenario: Gateway config is maintained as dedicated policy source
- **WHEN** operators review or update the canonical AI gateway configuration
- **THEN** the exact upstream-shaped gateway config is maintained in a dedicated literal policy file
- **AND** host wiring consumes that policy source without reconstructing provider/routing structure inline

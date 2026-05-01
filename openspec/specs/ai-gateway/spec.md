# Spec: AI Gateway

## Purpose

Define a repo-owned, file-driven AI gateway contract that provides a single OpenAI-compatible endpoint for downstream services while keeping canonical control in Git/Nix artifacts.

## Requirements
### Requirement: Bifrost SHALL be modeled as a first-class declarative AI gateway service
The system SHALL model Bifrost as a first-class fleet AI gateway service using repo-owned NixOS service composition rather than ad hoc runtime commands or UI-managed setup as the primary operating interface.

#### Scenario: Gateway service is enabled on a host
- **WHEN** the AI gateway service is enabled for a host
- **THEN** the host renders repo-owned Bifrost service wiring declaratively through NixOS modules
- **AND** operators do not need the Web UI to establish or preserve baseline gateway configuration

### Requirement: Gateway runtime SHALL remain under repo pin authority
The Bifrost runtime image and host-side wiring SHALL be consumed under repo-owned pinning and configuration authority rather than relying on mutable upstream runtime defaults.

#### Scenario: Bifrost runtime is rendered for a host
- **WHEN** the repo renders Bifrost runtime configuration for a host
- **THEN** the image/runtime reference is explicitly pinned or otherwise controlled by repo-owned configuration
- **AND** host behavior does not rely on mutable upstream runtime defaults outside repo control

### Requirement: Gateway baseline configuration SHALL be file-driven and canonical
The AI gateway SHALL use a declaratively rendered `config.json` as canonical baseline configuration, with Bifrost `config_store` disabled so runtime UI/config-store mutation is excluded from the baseline operating model.

#### Scenario: Gateway starts in baseline mode
- **WHEN** the AI gateway service starts under the repo baseline
- **THEN** the service reads a rendered file-driven configuration artifact
- **AND** the Web UI/config-store mode is disabled for canonical configuration management

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

### Requirement: Gateway mutable runtime stores SHALL remain non-canonical
The AI gateway MAY persist operational runtime stores such as logs, caches, or optional vector data, but those stores SHALL NOT become the canonical source of configuration truth.

#### Scenario: Runtime state is persisted
- **WHEN** the gateway writes logs, cache state, or optional vector data
- **THEN** that data is stored in explicit runtime persistence paths
- **AND** operators can rebuild the canonical gateway behavior from repo-rendered configuration plus secrets without depending on runtime-mutated config state

## ADDED Requirements

### Requirement: Caller-owned service-to-service auth inventory SHALL be explicit
Internal service-to-service authentication metadata SHALL be owned by the caller application module and SHALL define per-integration auth method and secret references.

#### Scenario: Homepage integration auth inventory is evaluated
- **WHEN** Homepage integrations are rendered
- **THEN** each authenticated integration declares caller-owned auth inputs and method selection in Homepage-owned module files
- **AND** caller integration auth metadata is not required to be encoded in route policy files

### Requirement: Internal auth method selection SHALL prefer least privilege by integration
For each internal integration, the system SHALL select auth in this order unless explicitly overridden: local-only no-auth exception, native API token/key, app machine credential, username/password fallback.

#### Scenario: Integration supports native token auth
- **WHEN** a target integration supports API token or key authentication
- **THEN** caller wiring uses token/key auth
- **AND** username/password is not the default selection

#### Scenario: Integration does not support token auth
- **WHEN** no native token/key or machine credential path is available
- **THEN** caller wiring may use username/password as explicit fallback

### Requirement: Service-to-service secrets SHALL remain host-scoped by default
Credentials used for caller-owned internal integrations SHALL be defined in host-scoped secret files by default and SHALL NOT be promoted to shared common scope without explicit justification.

#### Scenario: Homepage integration credentials are declared
- **WHEN** new Homepage integration credentials are added
- **THEN** they are sourced from `hosts/<host>/secrets.yaml` and templated for runtime use
- **AND** they are not introduced in `secrets/common.yaml` by default

### Requirement: Beszel agent machine-auth SHALL be host-scoped and per-agent
Beszel agent authentication credentials SHALL be unique per host and injected from host-scoped secret templates, not shared globally.

#### Scenario: Beszel agent auth is configured on an origin host
- **WHEN** an origin host enables Beszel agent connectivity to the Beszel hub
- **THEN** agent credentials are sourced from host-scoped secrets and materialized via host-local environment template
- **AND** credentials are not introduced in `secrets/common.yaml` or reused as a universal cross-host token

## ADDED Requirements

### Requirement: Homepage authenticated widget wiring SHALL use caller-owned machine-auth inputs
Homepage widgets that require authentication SHALL consume caller-owned machine-auth inputs provided through Homepage runtime environment templating, while preserving Homepage presentation ownership.

#### Scenario: Homepage widget config is rendered for authenticated integrations
- **WHEN** Homepage services are assembled for `do-admin-1`
- **THEN** authenticated widgets use Homepage runtime variables sourced from host-scoped secrets/templates
- **AND** Homepage layout/icons/grouping/bookmarks remain owned by Homepage service files

### Requirement: Homepage runtime SHALL support environment-file secret injection
Admin Homepage service wiring SHALL support injecting integration credentials using homepage-dashboard environment file configuration derived from host-scoped SOPS templates.

#### Scenario: Homepage service starts with integration credentials
- **WHEN** `services.homepage-dashboard` is configured for authenticated widgets
- **THEN** runtime environment files include the generated Homepage secret template path
- **AND** missing required template inputs fail through declarative assertions before runtime drift

### Requirement: Beszel Homepage integration SHALL use dedicated read-only account credentials
Homepage integration with Beszel SHALL use a dedicated read-only account distinct from human admin identities, with system visibility scoped to explicitly shared systems.

#### Scenario: Beszel widget credentials are configured
- **WHEN** Beszel widget auth is enabled for Homepage
- **THEN** credentials reference a dedicated read-only Beszel account
- **AND** account scope is limited to explicitly shared systems rather than global full-access sharing

### Requirement: Homepage auth exceptions SHALL remain explicit and minimal
Homepage integrations that run without app credentials SHALL be explicit exceptions and SHALL remain constrained to approved low-risk/local-only operational contexts.

#### Scenario: Caddy widget exception is evaluated
- **WHEN** Homepage includes Caddy operational widget data
- **THEN** no new broad machine credential is required for that widget
- **AND** exception rationale remains documented in change artifacts

### Requirement: Filebrowser widget auth SHALL remain out of scope in this wave
This change SHALL NOT require Filebrowser widget machine-auth wiring.

#### Scenario: Auth coverage is reviewed for current wave
- **WHEN** implementation scope is validated
- **THEN** Filebrowser widget auth wiring is excluded from required deliverables
- **AND** no Filebrowser-specific Homepage credential contract is introduced in this change

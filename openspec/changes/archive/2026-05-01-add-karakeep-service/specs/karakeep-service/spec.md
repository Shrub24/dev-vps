## ADDED Requirements

### Requirement: Karakeep SHALL be modeled as a first-class Nix-managed service on oci-melb-1
The system SHALL model Karakeep as a first-class host service for `oci-melb-1` using a handwritten NixOS module rather than Docker Compose as the operational interface.

#### Scenario: Karakeep service is enabled on the host
- **WHEN** `services.karakeep.enable` is configured for `oci-melb-1`
- **THEN** the host renders repo-owned Karakeep service wiring through NixOS modules
- **AND** Docker Compose files are not required for steady-state runtime management

### Requirement: Karakeep runtime SHALL preserve upstream multi-container topology
Karakeep runtime SHALL preserve the upstream web, browser, and Meilisearch service topology using Nix-managed OCI containers with explicit ordering and connectivity.

#### Scenario: Karakeep runtime is rendered
- **WHEN** the Karakeep module is evaluated
- **THEN** Karakeep web, browser, and Meilisearch containers are declared declaratively
- **AND** the web container is configured to reach the browser and Meilisearch services through the declared private runtime network model

### Requirement: Karakeep state SHALL use predictable host-managed persistence
Karakeep SHALL store persistent state under explicit host-managed directories rooted at `/srv/data/karakeep` rather than anonymous container-managed volumes.

#### Scenario: Karakeep state paths are prepared
- **WHEN** host tmpfiles and service unit prerequisites are evaluated
- **THEN** Karakeep app data and Meilisearch data paths are created declaratively under `/srv/data/karakeep`
- **AND** the runtime declares required mounts before service startup

### Requirement: Karakeep required runtime secrets SHALL be declarative and minimal
Karakeep SHALL use declaratively provided required runtime secrets for base convergence, and optional integration secrets SHALL remain optional unless explicitly enabled.

#### Scenario: Base Karakeep runtime is configured
- **WHEN** required Karakeep auth and search keys are present for `oci-melb-1`
- **THEN** the module renders the required runtime environment successfully
- **AND** optional AI, OAuth, SMTP, S3, or OCR integrations are not required for base service convergence

### Requirement: Karakeep browser access SHALL remain private-first
Karakeep browser access on `oci-melb-1` SHALL remain private-first and SHALL NOT require public ingress for the initial service baseline.

#### Scenario: Karakeep browser route is exposed
- **WHEN** operators access Karakeep after service enablement
- **THEN** access uses a declarative private-access path compatible with the repo’s Tailscale-first model
- **AND** no public Cloudflare/Caddy route is introduced by default for Karakeep in this change

# feature-topology Specification

## Purpose
TBD - created by archiving change feature-oriented-host-thinning-and-secrets-migration. Update Purpose after archive.
## Requirements
### Requirement: Feature enablement SHALL be the canonical topology signal
Hosts SHALL express workload topology through explicit feature entrypoints, with application stacks enabled through `applications.<name>.enable` and standalone workloads enabled through canonical `services.<domain>.<name>.enable` entrypoints.

#### Scenario: Host enables a composed application stack
- **WHEN** a host enables a multi-service workload such as the music or admin stack
- **THEN** the host does so through one canonical `applications.<name>.enable` entrypoint
- **AND** dependent service inclusion does not rely on hidden import-only activation paths

#### Scenario: Host enables a singleton workload
- **WHEN** a host enables a standalone workload that does not yet require an application composition layer
- **THEN** the host enables that workload through its canonical leaf service entrypoint
- **AND** the repo does not require a taxonomy-only application wrapper for that service

### Requirement: Application modules SHALL be composition roots rather than taxonomy wrappers
Application modules SHALL own shared paths, shared assertions, composition-level secret inputs, and multi-service wiring, while singleton services SHALL remain leaf services until real composition needs exist.

#### Scenario: Application composition is evaluated
- **WHEN** an application module such as `applications.music` or `applications.admin` is rendered
- **THEN** it composes multiple dependent services and shared feature behavior behind one operator-facing toggle
- **AND** shared feature wiring is not duplicated in host files

#### Scenario: Singleton service remains a leaf
- **WHEN** a service such as Karakeep has no current cross-service composition needs
- **THEN** it remains a leaf service module
- **AND** future application wrapping is deferred until real composition value exists

### Requirement: Host assembly SHALL stay thin and focused
Host assembly files SHALL primarily own host identity, facts, provider/storage/profile imports, feature enables, secret source bindings, and narrow host-only overrides, and SHALL NOT remain the primary home for application-internal secret/template or runtime wiring.

#### Scenario: Host composition is reviewed
- **WHEN** `hosts/<host>/default.nix` and any focused host split files are inspected
- **THEN** they act as thin assembly layers for that host
- **AND** large application-internal `sops.secrets`, `sops.templates`, tmpfiles, or cross-service wiring blocks are absent from the host layer

### Requirement: Leaf services SHALL own secret and runtime contracts
Leaf service modules SHALL own semantic secret registration, template assembly, runtime wiring, assertions, and restart semantics, and SHALL accept explicit contract inputs such as `secretFiles.*` and `secretKeys.*` instead of requiring callers to mutate raw internal `sops.secrets` definitions.

#### Scenario: Application supplies secrets to a leaf
- **WHEN** an application composes a leaf service that needs secrets
- **THEN** it provides explicit contract inputs to the leaf
- **AND** the leaf remains responsible for the actual `sops.secrets` / `sops.templates` registration and runtime consumption

#### Scenario: Application passes resolved OIDC env-file handoff to a leaf
- **WHEN** a composed leaf service owns an OIDC template but expects a resolved env-file path input for runtime wiring
- **THEN** the application composition layer passes the resolved `sops.templates.*.path` through the leaf's explicit contract surface
- **AND** hosts do not own or duplicate that OIDC env-file wiring

#### Scenario: Host overrides a secret source
- **WHEN** a host needs to bind a host-specific secret source for an enabled feature
- **THEN** it does so through the exposed contract surface
- **AND** the host does not need to know or mutate the leaf’s internal secret registration names

#### Scenario: Leaf secret contract cleanup is reviewed after regression fixes
- **WHEN** a leaf service is revisited after the topology migration to close a regression or cleanup pass
- **THEN** it continues to use the canonical helper-based secret contract surface where that pattern is already established in the repo
- **AND** hosts only bind explicit contract inputs rather than reviving ad hoc secret-file wiring shapes

### Requirement: Non-secret feature defaults SHALL be centrally defined and host-overridable
The repository SHALL keep shared non-secret feature defaults in a canonical defaults source consumed by applications/services, with hosts only overriding defaults when a machine-specific exception is required.

#### Scenario: Fleet default is consumed by an application
- **WHEN** an application or leaf service resolves a non-secret default value
- **THEN** it reads that value from the canonical defaults source using override-friendly semantics

#### Scenario: Host requires a local override
- **WHEN** one host needs a different value than the shared default
- **THEN** the host overrides that value explicitly without duplicating the rest of the feature defaults


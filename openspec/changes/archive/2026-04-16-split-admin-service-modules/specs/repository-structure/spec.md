## MODIFIED Requirements

### Requirement: Host and module boundaries are explicit
Repository structure SHALL separate host composition from reusable module domains and SHALL preserve explicit layering between policy data (`policy/`), policy transformation helpers (`lib/`), service-owned modules (`modules/services/`), application composition (`modules/applications/`), and host assembly (`hosts/`).

#### Scenario: Operator navigates repository
- **WHEN** codebase layout is reviewed
- **THEN** host identity and reusable module domains are clearly separated by directory boundaries
- **AND** admin service implementation, application composition, and host-local assembly are not collapsed into one file

### Requirement: Provider-specific logic remains isolated
Provider assumptions SHALL be isolated to provider/host layers and not embedded in reusable service modules, including after admin module decomposition.

#### Scenario: Service modules are reused across hosts
- **WHEN** service modules are composed by different hosts/providers
- **THEN** reusable module behavior does not depend on provider-specific inline logic

### Requirement: Documentation authority is centralized
Architecture/decision/process documents SHALL remain centralized and referenced by entrypoint docs to avoid drift, including when module and host layout changes are introduced.

#### Scenario: Structure or workflow changes are introduced
- **WHEN** significant layout/workflow updates are made
- **THEN** authoritative docs are updated in the same change window

## ADDED Requirements

### Requirement: Admin host composition SHALL support focused host files
Admin host composition for `do-admin-1` SHALL support focused host files for secrets, edge route/policy projection, and networking glue while keeping `hosts/do-admin-1/default.nix` as the primary assembly entrypoint.

#### Scenario: do-admin-1 host files are organized
- **WHEN** host composition is reviewed
- **THEN** `hosts/do-admin-1/default.nix` assembles focused modules such as `secrets.nix`, `edge.nix`, and `networking.nix`
- **AND** functional behavior remains equivalent to pre-split host composition

### Requirement: SSOT metadata SHALL avoid cross-module literal duplication
Repository structure and module boundaries SHALL keep canonical domain, route subdomain/path, and service endpoint port metadata in authoritative policy/config locations, with consuming modules reading projections instead of redefining equivalent literals.

#### Scenario: Operator audits endpoint metadata ownership
- **WHEN** domain/subdomain/path/port values are inspected across edge, service, and monitoring modules
- **THEN** each value class has one authoritative source-of-truth location
- **AND** downstream modules consume resolved projections rather than duplicating raw literals

# admin-module-structure Specification

## Purpose
TBD - created by archiving change split-admin-service-modules. Update Purpose after archive.
## Requirements
### Requirement: Admin modules SHALL follow layered ownership boundaries
Admin configuration SHALL follow a layered structure where policy data remains under `policy/`, policy transformation logic remains under `lib/`, service-owned behavior is implemented in `modules/services/admin/`, application composition remains in `modules/applications/admin/`, and host-local assembly remains in `hosts/<host>/`.

#### Scenario: Admin module tree is reviewed
- **WHEN** operators inspect admin-related repository paths
- **THEN** service-owned admin logic is located under `modules/services/admin/`
- **AND** `applications.admin` composition is located under `modules/applications/admin/`
- **AND** policy data/transforms are not embedded in service or host files

### Requirement: Complex admin services SHALL support adjacent data files
Complex admin services with large declarative payloads SHALL support adjacent data/config files within service subdirectories to keep module logic focused and maintainable.

#### Scenario: Homepage and Gatus service modules are evaluated
- **WHEN** service module structure is reviewed
- **THEN** Homepage and Gatus support files are organized as service subdirectories with `default.nix` and adjacent data/helper files

### Requirement: Canonical endpoint values SHALL be consumed via policy projections
Admin modules SHALL consume canonical service endpoint values (including route path and origin port) through policy resolution/projection helpers rather than re-defining those values in multiple module locations.

#### Scenario: Admin consumer wiring is evaluated
- **WHEN** admin service or monitoring modules configure route/endpoint values
- **THEN** path and port values are sourced from resolved policy/projection outputs
- **AND** equivalent literals are not duplicated in unrelated module files


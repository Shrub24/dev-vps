## MODIFIED Requirements

### Requirement: Host and module boundaries are explicit
Repository structure SHALL separate host composition from reusable module domains and SHALL preserve explicit layering between policy data (`policy/`), policy transformation helpers (`lib/`), service-owned modules (`modules/services/`), application composition (`modules/applications/`), host assembly (`hosts/`), and topology-aligned secret scopes (`secrets/`).

#### Scenario: Operator navigates repository
- **WHEN** codebase layout is reviewed
- **THEN** host identity, application composition, leaf service implementation, and secret scopes are clearly separated by directory and ownership boundaries
- **AND** admin/media/service implementation and host-local assembly are not collapsed into one file or one monolithic secret bucket

## ADDED Requirements

### Requirement: Host composition SHALL support thin focused host files
Host composition SHALL support thin, focused host files for identity, facts, networking, and narrow host-only exceptions while keeping reusable feature composition in applications and services.

#### Scenario: Host files are organized
- **WHEN** host composition is reviewed for any active host
- **THEN** `hosts/<host>/default.nix` remains the primary assembly entrypoint
- **AND** any split host files remain narrowly focused rather than owning reusable application/service internals

### Requirement: Secret storage structure SHALL reflect feature ownership
Repository secret layout SHALL distinguish application-scoped, standalone-service-scoped, and host-exception-scoped secret material so the path structure itself communicates ownership and blast radius.

#### Scenario: Secret tree is inspected
- **WHEN** operators review the `secrets/` tree and related host exception paths
- **THEN** application-scoped secrets, standalone-service secrets, and host exception secrets are visibly separated by path
- **AND** monolithic host secret files are not the primary canonical bucket model

## REMOVED Requirements

### Requirement: Admin host composition SHALL support focused host files
**Reason**: The repository is moving from a `do-admin-1`-specific host decomposition rule to a fleet-wide thin-host composition rule.
**Migration**: Apply the same focused-host-file principle generically across active hosts while keeping reusable feature wiring in applications and services.

# Spec: Repository Structure

## Purpose

Define repository layout contracts that preserve modular host composition, clear ownership boundaries, and durable documentation authority.

## Requirements

### Requirement: Host and module boundaries are explicit
Repository structure SHALL separate host composition from reusable module domains.

#### Scenario: Operator navigates repository
- **WHEN** codebase layout is reviewed
- **THEN** host identity and reusable module domains are clearly separated by directory boundaries

### Requirement: Provider-specific logic remains isolated
Provider assumptions SHALL be isolated to provider/host layers and not embedded in reusable service modules.

#### Scenario: Service modules are reused across hosts
- **WHEN** service modules are composed by different hosts/providers
- **THEN** reusable module behavior does not depend on provider-specific inline logic

### Requirement: Flake outputs are canonical host entrypoints
Canonical host build/deploy targets SHALL be represented through flake host outputs.

#### Scenario: Host target is selected for operations
- **WHEN** build/deploy routines resolve host targets
- **THEN** they map to canonical `nixosConfigurations.<host>` outputs

### Requirement: Documentation authority is centralized
Architecture/decision/process documents SHALL remain centralized and referenced by entrypoint docs to avoid drift.

#### Scenario: Structure or workflow changes are introduced
- **WHEN** significant layout/workflow updates are made
- **THEN** authoritative docs are updated in the same change window

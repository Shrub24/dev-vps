# Spec: Bootstrap and Storage

## Purpose

Define declarative bootstrap and storage contracts for host installation, mount layout, and provider-aware disk composition.

## Requirements

### Requirement: Bootstrap workflow is declarative
Host bootstrap SHALL be driven by repository-defined declarative workflows.

#### Scenario: Operator performs bootstrap
- **WHEN** bootstrap commands are executed for a host
- **THEN** installation inputs resolve from host/provider module state and flake wiring

### Requirement: Disk layout is encoded in disko modules
Host disk and filesystem layout SHALL be represented in disko module definitions.

#### Scenario: Storage plan is evaluated
- **WHEN** storage modules are rendered for a host
- **THEN** partition/filesystem/mount structure is derived declaratively

### Requirement: Service-state and media mounts are separated
The storage model SHALL separate service-state and media mounts with predictable mount points.

#### Scenario: Host mount contracts are validated
- **WHEN** host filesystem config is inspected
- **THEN** service-state and media are mounted on distinct declared targets

### Requirement: Provider-specific defaults stay isolated
Provider-specific storage/bootstrap defaults SHALL remain isolated from reusable service logic.

#### Scenario: Multiple providers are supported
- **WHEN** provider modules are compared
- **THEN** provider-specific assumptions appear only in provider/host composition layers

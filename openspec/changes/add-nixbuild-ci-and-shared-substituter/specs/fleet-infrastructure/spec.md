## ADDED Requirements

### Requirement: Active hosts SHALL support a shared remote substitute baseline
Active hosts in the fleet SHALL support a shared remote substitute-consumer baseline through reusable build-profile composition.

#### Scenario: Active host baseline is reviewed
- **WHEN** `nixosConfigurations.do-admin-1` and `nixosConfigurations.oci-melb-1` are inspected
- **THEN** both hosts inherit the same shared substitute/trust baseline through common host profile composition
- **AND** host files remain thin assembly layers rather than direct owner of deep substitute/trust wiring

#### Scenario: Current provider defaults remain policy-driven
- **WHEN** the fleet uses `nixbuild.net` as the current substitute provider
- **THEN** provider-specific URLs and signing keys come from canonical policy defaults
- **AND** the reusable host build profile stays generic enough to carry future substitute/trust defaults without a provider-branded host module

### Requirement: Mixed-architecture validation SHALL remain reproducible
Fleet validation workflows SHALL support reproducible checks across `x86_64-linux` and `aarch64-linux` host outputs without requiring per-architecture GitHub runner ownership.

#### Scenario: Cross-host validation is triggered
- **WHEN** CI validates both active host outputs
- **THEN** the workflow can evaluate/build against the shared remote build plane
- **AND** architecture differences do not require custom runner fleet management in phase 1

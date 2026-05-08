# fleet-infrastructure Specification (Delta)

## ADDED Requirements

### Requirement: Cache host SHALL own the sovereign binary cache infrastructure
`oci-melb-1` SHALL host the niks3 server and shared PostgreSQL service that back the fleet's sovereign binary cache, while other active hosts SHALL NOT replicate this infrastructure.

#### Scenario: Cache infrastructure is deployed on the cache host
- **WHEN** `oci-melb-1` is evaluated and deployed
- **THEN** the niks3 server is running as a NixOS service
- **AND** PostgreSQL is running with a niks3 database and user
- **AND** the S3 backend configuration points at the dedicated `shrublab-nix-cache` R2 bucket

#### Scenario: Non-cache hosts do not carry cache infrastructure
- **WHEN** `do-admin-1` is evaluated
- **THEN** it does not include niks3 server, PostgreSQL, or cache signing key configuration
- **AND** it consumes the sovereign cache only as a substituter, not as an infrastructure provider

## MODIFIED Requirements

### Requirement: Active hosts SHALL support a shared remote substitute baseline
Active hosts in the fleet SHALL support a shared remote substitute-consumer baseline through reusable build-profile composition, including the sovereign S3-backed binary cache as a durable secondary tier.

#### Scenario: Active host baseline is reviewed
- **WHEN** `nixosConfigurations.do-admin-1` and `nixosConfigurations.oci-melb-1` are inspected
- **THEN** both hosts inherit the same shared substitute/trust baseline through common host profile composition
- **AND** both include the `nixbuild.net` substituter and the sovereign S3 cache substituter in the configured priority order
- **AND** host files remain thin assembly layers rather than direct owner of deep substitute/trust wiring

#### Scenario: Current provider defaults remain policy-driven
- **WHEN** the fleet uses `nixbuild.net` as the primary substitute provider and the sovereign cache as secondary
- **THEN** provider-specific URLs and signing keys come from canonical policy defaults
- **AND** the reusable host build profile stays generic enough to carry future substitute/trust defaults without a provider-branded host module

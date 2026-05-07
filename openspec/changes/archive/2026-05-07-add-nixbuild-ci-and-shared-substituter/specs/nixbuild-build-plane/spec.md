## ADDED Requirements

### Requirement: CI builds SHALL use nixbuild.net as the primary remote build plane
Repository CI workflows SHALL execute build-heavy Nix validation through `nixbuild.net` rather than depending on GitHub-hosted multi-architecture runners.

#### Scenario: Pull request validation runs
- **WHEN** a pull request targeting `main` triggers CI
- **THEN** Nix validation workflows use `nixbuild.net` as the configured remote build plane
- **AND** CI does not require a dedicated multi-architecture runner matrix to build host outputs

### Requirement: Shared substituter contract SHALL be available for active hosts
Active hosts SHALL support a common substituter/trust baseline for `nixbuild.net` so normal rebuild workflows can consume shared build artifacts.

#### Scenario: Host build configuration is evaluated
- **WHEN** `nixosConfigurations.do-admin-1` and `nixosConfigurations.oci-melb-1` are evaluated
- **THEN** both include a shared `nixbuild.net` substituter/trusted-key contract
- **AND** host composition remains module-driven rather than ad hoc host-inline Nix settings

### Requirement: Host-side build mode SHALL remain substituter-only in phase 1
Phase-1 host participation in `nixbuild.net` SHALL be limited to substitute consumption and SHALL NOT require host-side remote build offload.

#### Scenario: Host deploy topology is reviewed
- **WHEN** deploy/build wiring is inspected after phase-1 rollout
- **THEN** hosts consume substitutes from `nixbuild.net`
- **AND** existing host-side build topology for deploy-rs is preserved unless an explicit follow-up change introduces offload

### Requirement: Main branch deployment automation SHALL be serial fail-fast
Pushes to `main` SHALL trigger validation and then host deployment in deterministic serial order with fail-fast behavior.

#### Scenario: Main merge deployment is executed
- **WHEN** CI/CD runs on push to `main`
- **THEN** deployment runs `do-admin-1` before `oci-melb-1`
- **AND** failure on the first host stops further deployment for that run

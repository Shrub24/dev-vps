# host-recovery Specification

## Purpose
TBD - created by archiving change add-host-recovery-baseline. Update Purpose after archive.
## Requirements
### Requirement: Remote hosts SHALL provide a declared recovery baseline
Remote hosts that opt into the recovery baseline SHALL provide a declared break-glass path that includes a host-scoped console rescue operator path and a routine reboot exercise.

#### Scenario: Recovery baseline is enabled for a host
- **WHEN** a host enables the recovery capability
- **THEN** the host configuration declares a separate console rescue operator path and a recurring reboot exercise as part of the host baseline

### Requirement: Console rescue access SHALL be independent from normal host login flow
Console rescue access SHALL use dedicated host-scoped password material and SHALL remain separate from the normal SSH and identity-backed login path.

#### Scenario: Console rescue configuration is reviewed
- **WHEN** the host recovery baseline is inspected
- **THEN** console rescue access uses explicit dedicated host-scoped password material
- **AND** the normal host login flow does not depend on that rescue access path

### Requirement: Rescue operator access SHALL remain explicit and host-scoped
The recovery baseline SHALL support a host-scoped rescue operator identity that is console-only, password-authenticated, explicitly declared, and reserved for break-glass administration.

#### Scenario: Rescue operator identity is rendered
- **WHEN** a host enables rescue operator access
- **THEN** the rescue identity is declared explicitly for that host
- **AND** access is available at the provider or serial console without enabling routine SSH login for that account

### Requirement: Recovery readiness SHALL be exercised routinely
Hosts that enable the recovery baseline SHALL exercise restart recovery on a declared recurring schedule so recovery drift is detected before an emergency.

#### Scenario: Recovery exercise schedule is reviewed
- **WHEN** host timers and recovery policy are inspected
- **THEN** a declared recurring reboot exercise exists for the host
- **AND** the cadence is explicit rather than implicit in unrelated update behavior


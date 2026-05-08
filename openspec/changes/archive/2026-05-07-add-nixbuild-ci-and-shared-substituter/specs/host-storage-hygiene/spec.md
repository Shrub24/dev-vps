## ADDED Requirements

### Requirement: Active hosts SHALL declare recurring Nix retention policy
Each active host SHALL declare automatic Nix retention and garbage-collection policy so store growth remains bounded under shared substitute usage.

#### Scenario: Active host Nix retention baseline is evaluated
- **WHEN** `nixosConfigurations.do-admin-1` and `nixosConfigurations.oci-melb-1` are evaluated
- **THEN** both include recurring Nix GC and bounded retention settings
- **AND** rollback-friendly retention windows remain explicitly configured

### Requirement: Storage hygiene expansion SHALL preserve break-glass recoverability
When storage hygiene is extended beyond one host, configured retention policies SHALL preserve an explicit rollback and recovery posture.

#### Scenario: Retention policy is reviewed for operational safety
- **WHEN** storage hygiene settings are inspected for both active hosts
- **THEN** retention choices bound stale store growth
- **AND** they do not remove documented rollback safety expectations from the operations baseline

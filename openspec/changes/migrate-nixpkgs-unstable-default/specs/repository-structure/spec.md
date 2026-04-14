## ADDED Requirements

### Requirement: Canonical docs reflect active package baseline policy
Canonical repository documentation SHALL describe the active package baseline policy and SHALL remain synchronized with flake input behavior.

#### Scenario: Baseline policy changes
- **WHEN** primary package baseline policy is changed in active code
- **THEN** canonical docs (`docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`) are updated in the same change window to reflect the new default policy

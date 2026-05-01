## ADDED Requirements

### Requirement: OpenTofu control-plane recovery SHALL be documented as an operator runbook
Operations documentation SHALL include a runbook for Cloudflare OpenTofu state recovery, including backend initialization, import mapping, duplicate-object triage, and post-recovery verification.

#### Scenario: Operator performs stale-state recovery
- **WHEN** Cloudflare resources exist but OpenTofu state is missing or stale
- **THEN** operator can follow a documented sequence to restore state and verify convergence
- **AND** the runbook includes explicit validation gates before apply

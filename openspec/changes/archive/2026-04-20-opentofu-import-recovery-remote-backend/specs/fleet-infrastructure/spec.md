## ADDED Requirements

### Requirement: Cloudflare control-plane OpenTofu state SHALL support concurrent operators
Cloudflare OpenTofu state for this repository SHALL use a shared remote backend so multiple concurrent worktrees/operators do not diverge state ownership.

#### Scenario: Multiple worktrees run OpenTofu operations
- **WHEN** two operator worktrees run init/plan/apply for `opentofu/cloudflare`
- **THEN** both resolve the same remote state object
- **AND** backend locking prevents concurrent state mutation races

## ADDED Requirements

### Requirement: Backup and restore workflows SHALL be documented as canonical operator runbooks
Operations documentation SHALL include canonical workflows for backup initialization, on-demand execution, recurring verification, restore preparation, and post-restore validation for host-scoped state backups.

#### Scenario: Operator prepares or audits backup operations
- **WHEN** an operator reviews the repository runbook surface for backups
- **THEN** the steps for initializing repositories, triggering backups, checking repository health, and validating restores are documented
- **AND** the runbook distinguishes routine backup execution from break-glass recovery flows

### Requirement: Backup validation SHALL include restore-oriented checks
The operator contract SHALL require validation beyond successful backup completion, including at least documented or executable checks that confirm critical backups are restorable.

#### Scenario: Backup validation is performed for a critical service
- **WHEN** operators validate backup health for identity or SQLite-backed services
- **THEN** validation includes restore-oriented verification steps rather than only timer/job success status

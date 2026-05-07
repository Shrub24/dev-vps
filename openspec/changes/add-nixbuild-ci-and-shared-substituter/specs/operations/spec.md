## ADDED Requirements

### Requirement: CI validation workflows SHALL be canonical for branch classes
Operations SHALL provide canonical CI validation behavior that distinguishes pull requests to `main`, pushes to non-`main`, and pushes to `main`.

#### Scenario: Validation-only branch class runs
- **WHEN** CI is triggered by a pull request to `main` or by a push to a non-`main` branch
- **THEN** validation workflows execute canonical repository checks
- **AND** no deployment steps are executed

#### Scenario: CI jobs use the canonical GitHub environment for secret-backed automation
- **WHEN** validation or deployment jobs need GitHub-hosted secrets or environment protection rules
- **THEN** those jobs are explicitly bound to the canonical GitHub Actions environment for this repository
- **AND** workflow secret consumption does not rely on repository-level secret scope when the environment-specific contract is intended

### Requirement: Main deployment workflow SHALL use canonical deploy entrypoints
Automated deployment on `main` SHALL execute repository-defined deployment entrypoints rather than custom out-of-band commands.

#### Scenario: Automated deployment is triggered
- **WHEN** CI/CD runs deployment for a push to `main`
- **THEN** host deployment uses canonical repository deploy contracts aligned with flake host outputs
- **AND** deployment automation does not bypass declared operator workflow boundaries

#### Scenario: Manual deployment can be dispatched from any branch
- **WHEN** an operator manually triggers the deploy workflow from a non-`main` branch via GitHub Actions `workflow_dispatch`
- **THEN** the workflow MAY run validation and deployment from that selected branch ref
- **AND** the workflow still uses the same canonical deploy entrypoints and explicit serial host ordering

#### Scenario: Deployment uses Tailscale SSH-first authentication
- **WHEN** GitHub Actions deploys to fleet hosts over the tailnet
- **THEN** workflow connectivity uses `tailscale/github-action`
- **AND** deployment auth relies on Tailscale SSH policy rather than a repository-stored deploy SSH private key
- **AND** deploy workflow secrets do not require a dedicated deploy SSH private key

#### Scenario: Deployment workflow stays portable across host changes
- **WHEN** operators add, remove, or reorder deploy targets
- **THEN** workflow structure keeps host-specific deploy logic in a reusable, low-duplication surface
- **AND** serial fail-fast ordering for active `main` deploy targets remains explicit

#### Scenario: Reusable deploy host workflow owns prebuild and deploy steps
- **WHEN** automated deployment runs for an active host target
- **THEN** the reusable host deployment workflow performs the host-specific remote prebuild and deploy steps together
- **AND** the top-level deploy orchestrator keeps only shared validation and explicit serial ordering logic

#### Scenario: deploy-rs SSH relaxations stay inline in workflow commands
- **WHEN** GitHub Actions deploys via `deploy-rs`
- **THEN** any temporary CI-specific SSH client relaxations are passed inline via deploy command options
- **AND** the workflow does not require generating a persistent SSH config file for those CI-specific options

### Requirement: CI SHALL validate OpenTofu posture without applying infrastructure
CI workflows SHALL include OpenTofu validation checks while leaving infrastructure apply as an explicit manual operator action.

#### Scenario: OpenTofu checks run in CI
- **WHEN** CI validation executes for any branch class
- **THEN** OpenTofu formatting and validation checks are run
- **AND** no automated OpenTofu apply is performed

#### Scenario: OpenTofu CI validation is intentionally deferred
- **WHEN** the repository does not yet have a usable CI credential and backend model for OpenTofu validation
- **THEN** CI MAY defer OpenTofu checks temporarily
- **AND** no automated OpenTofu apply is performed
- **AND** the workflow documentation MUST note that OpenTofu CI validation remains out of scope for the current change

# cache-push-workflow Specification

## Purpose

Define the automated post-deploy push workflow that uploads verified host closures to the sovereign niks3 binary cache after successful deployment activation.

## ADDED Requirements

### Requirement: Hosts SHALL push closures after successful deployment activation
Active fleet hosts SHALL push their newly activated system closures to the sovereign cache after a successful `deploy-rs` or `nixos-rebuild` activation, using a host-scoped niks3 API token.

#### Scenario: Host pushes after successful deploy
- **WHEN** a deployment activation succeeds on a fleet host
- **THEN** the host's new generation closure is pushed to the sovereign cache
- **AND** the push uses a host-scoped API token stored in that host's encrypted secrets

#### Scenario: Failed deployment does not push
- **WHEN** a deployment activation fails on a fleet host
- **THEN** the failed closure is NOT pushed to the sovereign cache
- **AND** only verified successfully-activated generations land in the cache

### Requirement: Post-deploy push SHALL be automatable
The push workflow SHALL support automation through a thin hook or systemd service so operators do not need to run manual CLI commands after every deploy.

#### Scenario: Automated push hook fires after activation
- **WHEN** the post-deploy push hook is enabled and a deployment activation completes
- **THEN** the hook executes the niks3 push command for the new closure without manual intervention
- **AND** push failures are logged but do not cause the host generation to roll back

#### Scenario: Manual push remains available
- **WHEN** an operator needs to backfill or retry a push outside the automated hook
- **THEN** a documented manual `niks3 push` command can upload a specific closure using the same host-scoped token

### Requirement: Push tokens SHALL be host-scoped and separately revocable
Each host SHALL use its own niks3 API token, scoped to that host, so that token compromise or revocation affects only one host.

#### Scenario: Host token is rotated
- **WHEN** a host's niks3 API token is rotated
- **THEN** only that host's push capability is affected
- **AND** other hosts continue pushing with their own tokens without interruption

#### Scenario: Tokens are stored in host-secret SOPS files
- **WHEN** host secrets are inspected
- **THEN** each host's niks3 API token is stored in its own `secrets/hosts/<host>/system.yaml` file
- **AND** the token is not present in shared or common secret scopes

### Requirement: Cache host push SHALL be self-referential
When the cache host (`oci-melb-1`) pushes its own closures, the push SHALL use its own host-scoped token and SHALL target the local niks3 server or S3 backend directly without cross-host network dependencies.

#### Scenario: Cache host pushes its own deployment
- **WHEN** `oci-melb-1` completes a deployment activation
- **THEN** it pushes its closure to the sovereign cache using host-local connectivity
- **AND** the push does not depend on Tailscale or external network reachability for the push path

### Requirement: Push failures SHALL be observable
Push failures SHALL produce visible logs or alerting signals so operators can detect and remediate gaps in cache coverage.

#### Scenario: Push failure is logged
- **WHEN** a post-deploy push fails (e.g., token invalid, server unreachable)
- **THEN** the failure is logged to the system journal with enough context to diagnose the cause
- **AND** the failure does not block or roll back the host generation

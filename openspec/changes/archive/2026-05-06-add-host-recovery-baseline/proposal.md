## Why

Recent `do-admin-1` recovery showed that remote hosts need a stronger declared recovery baseline before risky networking or access changes are attempted. We need a consistent host pattern for serial-console break-glass access and scheduled reboot exercise that improves recoverability without broadening normal SSH posture.

## What Changes

- Add a new `host-recovery` capability covering a declarative serial-console rescue user baseline and routine reboot exercise.
- Require remote hosts to keep a documented recovery path that does not depend on the primary SSH or tailscale login path remaining healthy.
- Extend host unix-auth requirements to allow an explicit host-scoped console rescue account that remains separate from normal identity-backed access.
- Extend secrets requirements so recovery password material remains narrowly host-scoped and auditable.
- Standardize operations guidance for deploying, testing, and rolling back recovery baseline changes on active hosts.

## Capabilities

### New Capabilities
- `host-recovery`: Declarative console rescue-user baseline, scheduled reboot exercise, and documented break-glass operator workflow for remote hosts.

### Modified Capabilities
- `operations`: Deployment and validation workflows must include recovery-baseline rollout, reboot exercise, and rollback checks.
- `network-access`: Break-glass access expectations must cover console recovery paths that survive primary SSH or tailscale login failure.
- `host-unix-auth`: Hosts may declare a separate console rescue account with explicit password and sudo policy outside normal Kanidm login flow.
- `secrets-management`: Recovery password material and related recovery-only credentials must remain host-scoped and auditable.

## Impact

- Affected code will likely include shared host/profile modules, host bootstrap/default wiring, and host-scoped secret declarations for `do-admin-1` and `oci-melb-1`.
- Affected systems include serial-console access, operator recovery workflows, sudo policy, and reboot timers.
- This change introduces additional security-sensitive access paths, so host-scoped secret policy and documented validation/rollback steps are part of the baseline.

## 1. Shared recovery baseline

- [x] 1.1 Add a reusable host recovery module and shared options for console-only rescue-user enablement and scheduled reboot cadence.
- [x] 1.2 Wire the shared recovery baseline into the appropriate shared profile or host composition entrypoint without changing unrelated host behavior.

## 2. Host and secret wiring

- [x] 2.1 Extend host-scoped secret policy and secret declarations for `do-admin-1` recovery material.
- [x] 2.2 Extend host-scoped secret policy and secret declarations for `oci-melb-1` recovery material.
- [x] 2.3 Enable and configure the recovery baseline on both active hosts with explicit host-owned values.
- [x] 2.4 Add the break-glass rescue user wiring and declarative console-login/sudo policy for hosts that enable the baseline.

## 3. Validation and rollout guidance

- [x] 3.1 Build and validate `do-admin-1` and `oci-melb-1` recovery-enabled configurations locally.
- [x] 3.2 Update operator docs/runbooks for recovery verification, weekly reboot expectations, and rollback steps.
- [x] 3.3 Validate the OpenSpec change and confirm the change is ready for apply.

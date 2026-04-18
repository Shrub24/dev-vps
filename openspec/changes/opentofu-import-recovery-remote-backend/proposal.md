## Why

OpenTofu Cloudflare state drift and multi-worktree usage have made local-only state fragile and recovery noisy. We need a canonical remote backend and a repeatable recovery path so imports and future plans are deterministic.

## What Changes

- Add a Cloudflare R2-backed OpenTofu remote state backend for `opentofu/cloudflare` with lockfile support.
- Remove recurring Access app drift noise by explicitly setting stable optional fields in `cloudflare_zero_trust_access_application.service`.
- Add a documented import/recovery runbook for local-to-remote state recovery and duplicate-object triage.
- Move OpenTofu backend/runtime secrets to SOPS-scoped secret paths and generated runtime artifacts (non-committed plaintext).

## Capabilities

### New Capabilities
- `opentofu-state-recovery`: Defines deterministic OpenTofu state recovery and import runbook behavior for the Cloudflare control-plane stack.

### Modified Capabilities
- `fleet-infrastructure`: Add remote OpenTofu backend requirements for concurrent operator/worktree safety.
- `operations`: Add required operator runbook steps for state recovery and reconciliation validation.
- `secrets-management`: Add path-scoped secret handling for OpenTofu backend/runtime credentials.

## Impact

- Affected code paths:
  - `opentofu/cloudflare/main.tf`
  - `opentofu/cloudflare/README.md`
  - `opentofu/cloudflare/.gitignore`
  - `justfile`
  - `.sops.yaml`
  - `secrets/opentofu/**` (new)
- Affected specs:
  - Modified: `openspec/specs/fleet-infrastructure/spec.md`
  - Modified: `openspec/specs/operations/spec.md`
  - Modified: `openspec/specs/secrets-management/spec.md`
  - New: `openspec/specs/opentofu-state-recovery/spec.md`
- Operational impact:
  - Single shared remote state for concurrent worktrees
  - Explicit runbook to recover stale/desynced state with low ambiguity

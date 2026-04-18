## Context

The Cloudflare OpenTofu stack is policy-driven and already manages DNS, Access, and ruleset resources, but state recovery has been ad hoc and local-state-only usage breaks down with multiple concurrent worktrees. Current drift includes import-history artifacts and provider normalization noise, and the repository lacks a canonical backend + runbook combination to recover safely.

## Goals / Non-Goals

**Goals:**
- Make OpenTofu state concurrency-safe by introducing a shared Cloudflare R2 backend with lockfile behavior.
- Reduce recurring Access app plan noise by explicitly setting stable optional fields.
- Provide a deterministic state recovery runbook for declared resources.
- Move backend/runtime secrets into path-scoped SOPS workflow and avoid committed plaintext runtime credentials.

**Non-Goals:**
- Re-model all existing Cloudflare resources or redesign policy ownership.
- Auto-import every object in the account beyond declared OpenTofu resources.
- Full backend self-bootstrap in the same control-plane stack.

## Decisions

1. **Use S3-compatible backend on Cloudflare R2**
   - Keeps one canonical shared state for all worktrees/operators.
   - Uses OpenTofu S3 backend lockfile mechanism for concurrent safety.

2. **Keep import recovery declared-resource-scoped**
   - Recovery and reconciliation focus on resources present in `main.tf`.
   - Avoid broad account-wide imports that weaken deterministic ownership.

3. **Normalize Access app optional fields in config**
   - Explicitly set stable booleans to prevent repeated null/false churn.
   - Accept real semantic drift (for example policy/idp remaps) as intentional diffs.

4. **Use generated local runtime backend/tfvars artifacts from SOPS secrets**
   - Keep secret source encrypted and path-scoped.
   - Keep generated runtime files ignored and ephemeral.

## Risks / Trade-offs

- **[Risk] Backend misconfiguration blocks init/plan** → Mitigation: add runbook validation steps and explicit backend init command contract.
- **[Risk] Duplicate Cloudflare objects create ambiguous imports** → Mitigation: runbook requires deterministic selection criteria and post-import plan review.
- **[Risk] Secret sprawl for OpenTofu runtime** → Mitigation: constrain via `.sops.yaml` path rules under dedicated OpenTofu secret scope.

## Migration Plan

1. Add backend configuration and runtime secret rendering workflow.
2. Reinitialize OpenTofu against R2 backend.
3. Run declared-resource import recovery and reconcile drift.
4. Validate with `tofu plan` and OpenSpec validation before completion.

Rollback: temporarily disable backend stanza and revert to local state only for emergency troubleshooting (documented as break-glass, not steady state).

## Open Questions

- Final naming/key conventions for R2 bucket/object path by environment/workspace.
- Whether to codify import helper scripts immediately or first document manual runbook then automate.

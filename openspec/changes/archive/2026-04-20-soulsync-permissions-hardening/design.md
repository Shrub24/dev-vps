## Context

SoulSync ingestion currently relies on bind-mounted host paths under `/srv/media`, but promotion and quarantine writes are intermittently failing due to runtime identity/ACL mismatch. The previous transition change widened `media` write ACLs as a temporary operational unblock, but the intended model is ingest-writers vs consumer-readers.

## Goals / Non-Goals

**Goals:**
- Ensure SoulSync runtime has deterministic write access to ingest/promotion paths.
- Establish a clear permission model: `music-ingest` write, `media` read-only.
- Keep promotion flow functional (`quarantine/*` -> `library`) without manual ACL intervention.

**Non-Goals:**
- Re-architect storage layout or change ingest path contracts.
- Introduce new orchestration systems.

## Decisions

1. **Role model**: `music-ingest` is the writer role for quarantine/library ingest paths; `media` is a read-only consumer role.
2. **SoulSync runtime alignment**: run SoulSync container with explicit supplemental group membership for `music-ingest` and `media` using Podman `--group-add` so containerized process identity can satisfy host ACL checks.
3. **ACL normalization**: enforce ACLs in both tmpfiles and beets reconciliation script to keep `music-ingest:rwx` and `media:r-X` on ingest-controlled trees.
4. **No login/session dependency**: service users rely on systemd unit group settings, not interactive session refresh.

## Risks / Trade-offs

- **[Risk] group ID assumptions for Podman `--group-add`** → **Mitigation:** derive from evaluated NixOS group IDs and assert presence through successful evaluation/check.
- **[Risk] media consumers lose write workflows** → **Mitigation:** restrict only ingest-owned paths and retain explicit ingest group write where promotion requires it.
- **[Risk] ACL drift over time** → **Mitigation:** keep reconciliation hooks and tmpfiles rules aligned.

## Migration Plan

1. Deploy updated ACL/group model.
2. Restart `podman-soulsync` and `slskd` services.
3. Run one-shot reconcile (`beets-inbox-run` or `beets-quarantine-promote-run`) to force ACL convergence.
4. Verify write test from SoulSync path and read test from media consumer path.

Rollback: revert this change and redeploy to restore prior ACL model.

## Open Questions

- Whether to later codify static GIDs for `music-ingest`/`media` across hosts for cross-host consistency (not required for immediate fix).

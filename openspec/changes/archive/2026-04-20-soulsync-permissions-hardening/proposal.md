## Why

SoulSync promotion still hits permission-denied paths because container runtime identity is not explicitly aligned with host ingest groups. We need deterministic write/read boundaries so ingest lanes are writable by ingest actors while preserving read-only consumer access for general media users.

## What Changes

- Define a stable SoulSync runtime identity on host and run the container with that UID/GID.
- Align ACL policy so `music-ingest` is the write group for ingest/promotion paths and `media` is read-only where required.
- Ensure slskd and SoulSync have effective write access to required ingest paths and promotion targets.
- Add explicit verification steps/operators notes for runtime group/ACL checks.

## Capabilities

### New Capabilities
- `media-permissions-model`: Declarative role-based ACL model for ingest vs consumer media groups.

### Modified Capabilities
- `soulsync-ingest`: SoulSync runtime identity and filesystem permissions requirements are tightened.
- `media-services`: Group/ACL ownership boundaries for shared media paths are adjusted.

## Impact

- Affected code: `modules/services/soulsync.nix`, `modules/services/beets-inbox.nix`, `modules/applications/music.nix` (group ownership semantics), host wiring as needed.
- Operational impact: requires deploy + service restart to apply new ACL and container identity behavior.
- Security/ops impact: narrows write access from broad `media` group to intended ingest principals.

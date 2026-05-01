## MODIFIED Requirements

### Requirement: SoulSync SHALL use existing media path contracts
SoulSync SHALL use existing canonical media paths: download path `/srv/media/inbox/slskd`, transfer path `/srv/media/library`, and import staging path `/srv/media/quarantine/approved`.

SoulSync runtime identity SHALL include effective host-level write capability for ingest/promotion paths via declared group alignment (`music-ingest` write role).

#### Scenario: SoulSync path and runtime identity configuration is rendered
- **WHEN** SoulSync module options and container mounts are evaluated
- **THEN** SoulSync paths resolve to the canonical host paths
- **AND** SoulSync container runtime is configured with group alignment required to write ingest/promotion paths

### Requirement: Unresolved handling SHALL retain explicit review lanes
Files not confidently resolved by SoulSync SHALL remain reviewable in `/srv/media/quarantine/untagged`, and fallback-rescued items SHALL be able to enter `/srv/media/quarantine/approved` for canonical promotion flow.

ACL and group policy for these lanes SHALL keep `music-ingest` as write-capable and `media` as read-oriented.

#### Scenario: A file cannot be confidently resolved
- **WHEN** SoulSync processing leaves an item unresolved
- **THEN** the item remains in `quarantine/untagged`
- **AND** operators can move rescue-ready items into `quarantine/approved` for promotion
- **AND** ACLs enforce `music-ingest` write capability while preserving `media` read-oriented access

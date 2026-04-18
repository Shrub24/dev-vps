# soulsync-ingest Specification

## Purpose
TBD - created by archiving change soulsync-transition. Update Purpose after archive.
## Requirements
### Requirement: SoulSync SHALL be the primary ingest service
The system SHALL run SoulSync as the primary ingest/control-plane service on `oci-melb-1` for download processing, metadata enrichment, import workflow, and canonical promotion into the library.

#### Scenario: Music stack is evaluated after cutover
- **WHEN** `applications.music.enable` is configured on `oci-melb-1`
- **THEN** SoulSync is present as the primary ingest service
- **AND** beets-inbox is not the default automated ingest owner

### Requirement: SoulSync SHALL use existing media path contracts
SoulSync SHALL use existing canonical media paths: download path `/srv/media/inbox/slskd`, transfer path `/srv/media/library`, and import staging path `/srv/media/quarantine/approved`.

#### Scenario: SoulSync path configuration is rendered
- **WHEN** SoulSync module options and container mounts are evaluated
- **THEN** SoulSync paths resolve to the canonical host paths

### Requirement: Unresolved handling SHALL retain explicit review lanes
Files not confidently resolved by SoulSync SHALL remain reviewable in `/srv/media/quarantine/untagged`, and fallback-rescued items SHALL be able to enter `/srv/media/quarantine/approved` for canonical promotion flow.

#### Scenario: A file cannot be confidently resolved
- **WHEN** SoulSync processing leaves an item unresolved
- **THEN** the item remains in `quarantine/untagged`
- **AND** operators can move rescue-ready items into `quarantine/approved` for promotion

### Requirement: Existing library mutation SHALL be conservative at rollout
Initial SoulSync rollout SHALL allow read/browse context against existing library content but SHALL NOT run broad automated retag/reorg/repair mutation jobs over pre-existing library files.

#### Scenario: SoulSync jobs are reviewed after deployment
- **WHEN** scheduled/automatic SoulSync jobs are inspected
- **THEN** broad retroactive mutation jobs over pre-cutover library content are not enabled by default

### Requirement: Provider enablement SHALL be optional-by-secret
Day-1 SoulSync integrations (Discogs, Spotify URL/OAuth, Deezer, YouTube, Navidrome sync) SHALL be supportable but SHALL only activate when required credentials/config are present.

#### Scenario: Optional provider credentials are absent
- **WHEN** SoulSync configuration is rendered without one or more optional provider secrets
- **THEN** SoulSync still starts with safe defaults
- **AND** only configured providers are enabled


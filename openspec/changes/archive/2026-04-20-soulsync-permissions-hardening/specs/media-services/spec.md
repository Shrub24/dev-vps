## MODIFIED Requirements

### Requirement: Music application composes the media stack
The system SHALL compose Syncthing, Navidrome, slskd, and SoulSync from `modules/applications/music.nix` and SHALL define required collaboration groups for media operations.

For this change scope, role permissions SHALL be explicit: `music-ingest` is the write-capable ingest role for ingest/promotion paths, while `media` is a read-focused consumer role.

#### Scenario: Music composition is enabled
- **WHEN** `applications.music.enable` is configured on a host
- **THEN** the host includes Syncthing, Navidrome, slskd, and SoulSync with shared group boundaries (`music-ingest`, `media`)
- **AND** ingest/promotion paths use `music-ingest` write access with `media` read-oriented access

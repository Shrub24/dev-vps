## MODIFIED Requirements

### Requirement: Music application composes the media stack
The system SHALL compose Syncthing, Navidrome, slskd, and SoulSync from `modules/applications/music.nix` and SHALL define required collaboration groups for media operations.

#### Scenario: Music composition is enabled
- **WHEN** `applications.music.enable` is configured on a host
- **THEN** the host includes Syncthing, Navidrome, slskd, and SoulSync with shared group boundaries (`music-ingest`, `media`)

### Requirement: Navidrome reads composed media paths without owning media root
Navidrome SHALL consume application/service-composed media paths, SHALL not own shared media roots via tmpfiles, and SHALL remain private-network only.

For this change scope, Navidrome media scope SHALL include `library` and `quarantine` and SHALL exclude `inbox` from the listening surface.

#### Scenario: Navidrome starts after media prerequisites
- **WHEN** Navidrome service is started
- **THEN** it depends on required mount/service ordering and reads configured media/library paths without creating shared media roots itself
- **AND** inbox content is not included in Navidrome media scope

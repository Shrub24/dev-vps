## ADDED Requirements

### Requirement: Media-stack service backups SHALL prioritize service state over media payloads in the first wave
Stateful media-stack services SHALL support backup coverage for their mutable service state, while authoritative media payloads under `/srv/media` remain outside required backup scope in this change.

#### Scenario: Music-stack backup scope is reviewed
- **WHEN** backup coverage is inspected for the music application stack
- **THEN** stateful service data such as configuration, databases, and service runtime state can be included under managed state roots
- **AND** media library and inbox payloads under `/srv/media` are not required backup payloads in this wave

### Requirement: Tagr SHALL use export-first backup behavior
Tagr SHALL participate in the canonical backup architecture as an export-first service and SHALL initially retain raw-state backup coverage alongside its export artifact.

#### Scenario: Tagr backup behavior is evaluated
- **WHEN** Tagr backup wiring is reviewed for `oci-melb-1`
- **THEN** a portable export artifact is part of the backup contract
- **AND** Tagr raw service state remains included in the initial backup payload

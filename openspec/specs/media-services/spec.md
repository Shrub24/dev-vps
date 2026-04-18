# Spec: Media Services

## Purpose

Define the declarative media-service contracts for the music stack so Syncthing, Navidrome, slskd, and Beets can operate with explicit ownership boundaries, predictable data flow, and private-network operation.
## Requirements
### Requirement: Music application composes the media stack
The system SHALL compose Syncthing, Navidrome, slskd, and SoulSync from `modules/applications/music.nix` and SHALL define required collaboration groups for media operations.

#### Scenario: Music composition is enabled
- **WHEN** `applications.music.enable` is configured on a host
- **THEN** the host includes Syncthing, Navidrome, slskd, and SoulSync with shared group boundaries (`music-ingest`, `media`)

### Requirement: Shared media roots are app-owned and created via tmpfiles
The system SHALL treat media shared roots as application-owned boundaries and SHALL create them via `systemd.tmpfiles.rules`.

#### Scenario: Shared media paths are reconciled
- **WHEN** tmpfiles are applied for the music application
- **THEN** shared roots (such as media root and inbox boundary) are present with declared ownership and modes

### Requirement: Service-specific subtrees are service-owned
Each service SHALL manage its own service-specific subdirectories and permissions via its service module rather than relying on app-level hardcoded service subpaths.

#### Scenario: Service subtree permissions are enforced
- **WHEN** service tmpfiles and unit constraints are evaluated
- **THEN** service-specific paths are reconciled by the owning service module

### Requirement: Syncthing uses generic application-composed targets
Syncthing SHALL support device and folder composition through `services.syncthing.deviceTargets` and `services.syncthing.folderTargets`, and SHALL keep runtime roots configurable through `services.syncthing.dataDir` and `services.syncthing.configDir`.

#### Scenario: Syncthing folder settings are generated from targets
- **WHEN** folder targets are rendered
- **THEN** Syncthing folder settings are derived from configured targets and management-only tmpfiles keys are excluded from daemon folder payload

### Requirement: Syncthing data protections are enabled
Syncthing SHALL run with default ports closed and SHALL use per-folder versioning safeguards for managed sync folders.

#### Scenario: Syncthing network and versioning safeguards are present
- **WHEN** Syncthing settings are inspected
- **THEN** `openDefaultPorts` is disabled and configured folders include versioning safeguards

### Requirement: Navidrome reads composed media paths without owning media root
Navidrome SHALL consume application/service-composed media paths, SHALL not own shared media roots via tmpfiles, and SHALL remain private-network only.

For this change scope, Navidrome media scope SHALL include `library` and `quarantine` and SHALL exclude `inbox` from the listening surface.

#### Scenario: Navidrome starts after media prerequisites
- **WHEN** Navidrome service is started
- **THEN** it depends on required mount/service ordering and reads configured media/library paths without creating shared media roots itself
- **AND** inbox content is not included in Navidrome media scope

### Requirement: slskd path and share scope are explicit
slskd SHALL expose explicit path controls (`downloadsPath`, `incompletePath`) and SHALL restrict `shares.directories` to configured slskd directories instead of sharing the full media root.

#### Scenario: slskd share scope is constrained
- **WHEN** slskd settings are generated
- **THEN** only configured slskd directories are shared

### Requirement: Beets promotion and runtime contracts are modular
Beets SHALL use module-injected media/data paths, SHALL support inbox/quarantine promotion contracts, and SHALL keep runtime plugin overrides declared in `beets-inbox.nix`.

#### Scenario: Beets runtime and promotion behavior are evaluated
- **WHEN** Beets worker and promotion units are rendered
- **THEN** paths are option-driven and runtime overrides are defined in-module without external runtime indirection files

### Requirement: Media services remain mount-aware and permission-reconciling
Media services SHALL declare mount prerequisites and SHALL reconcile permissions after promotion/sync operations where required.

#### Scenario: Service units enforce mount and permission integrity
- **WHEN** media service units are evaluated
- **THEN** required mounts are declared and permission reconciliation hooks remain part of operational flow

### Requirement: Application injects shared media directories
`modules/applications/music.nix` SHALL define and pass shared media directories (`inboxDir`, `libraryDir`, `quarantineDir`) to dependent services rather than relying on service-local hardcoded shared paths.

#### Scenario: Shared directory options are provided by application layer
- **WHEN** `applications.music.inboxDir`, `applications.music.libraryDir`, and `applications.music.quarantineDir` are configured
- **THEN** Syncthing and Beets consume those injected paths through service options

### Requirement: Syncthing target composition is generic
Syncthing SHALL support application-composed device and folder definitions through `services.syncthing.deviceTargets` and `services.syncthing.folderTargets`.

#### Scenario: Syncthing settings are derived from composed targets
- **WHEN** folder targets include daemon fields and management-only tmpfiles fields
- **THEN** daemon folder payload excludes management-only fields while tmpfiles generation uses them

### Requirement: slskd shares only configured directories
slskd SHALL expose explicit path options (`downloadsPath`, `incompletePath`) and SHALL restrict `shares.directories` to configured slskd directories.

#### Scenario: slskd sharing scope is constrained
- **WHEN** custom `downloadsPath` and `incompletePath` are configured
- **THEN** `shares.directories` contains only those configured paths

### Requirement: Beets runtime override is in-module
Beets runtime plugin overrides SHALL be declared directly in `beets-inbox.nix`, and an external runtime indirection file SHALL NOT be required.

#### Scenario: Beets runtime is assembled from beets module
- **WHEN** Beets runtime dependencies are rendered
- **THEN** plugin override wiring is sourced inline from `beets-inbox.nix`


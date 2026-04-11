# Capability Delta: media-services

## ADDED Requirements

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

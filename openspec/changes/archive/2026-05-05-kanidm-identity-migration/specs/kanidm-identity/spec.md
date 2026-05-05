## ADDED Requirements

### Requirement: Kanidm SHALL be the canonical declarative identity provider
The repository SHALL provide Kanidm as the canonical repo-owned identity provider using the native nixpkgs Kanidm service surface, with server bootstrap and provisioning owned declaratively in Nix rather than by post-deploy web UI state.

#### Scenario: Kanidm server is enabled on the identity host
- **WHEN** the designated identity/admin host enables the Kanidm service
- **THEN** native `services.kanidm.server` wiring is used for runtime configuration
- **AND** bootstrap and identity-management provisioning are declared from repository state

### Requirement: Kanidm provisioning SHALL own current OIDC client registration
Current OIDC consumers SHALL be provisioned through `services.kanidm.provision.systems.oauth2.<name>` using repo-owned client metadata and secret-file-backed client secrets.

#### Scenario: Existing app client is provisioned declaratively
- **WHEN** a current OIDC-enabled app such as Termix, Quantum, or Karakeep is configured
- **THEN** Kanidm provisioning declares its client registration, origin/landing metadata, and scope/claim mappings in Nix
- **AND** the client secret is supplied from a runtime secret file rather than inline store content

### Requirement: Kanidm bootstrap/admin secrets SHALL use identity-scoped runtime files
Kanidm bootstrap/admin credentials SHALL be sourced from identity-scoped SOPS-managed secret paths and rendered to runtime files for provisioning inputs.

#### Scenario: Kanidm provisioning credentials are evaluated
- **WHEN** Kanidm provisioning is enabled
- **THEN** `adminPasswordFile` and `idmAdminPasswordFile` resolve to runtime secret files sourced from identity-scoped encrypted inputs
- **AND** those values are not embedded directly in committed Nix content

### Requirement: Kanidm provisioning SHALL merge committed topology with encrypted authoritative identity state
Kanidm provisioning SHALL keep non-sensitive identity topology and OIDC scope structure in committed JSON policy and SHALL source sensitive person metadata plus authoritative memberships from an encrypted whole-file JSON overlay that follows Kanidm provisioning structure.

#### Scenario: Identity topology remains reviewable without committed real-user metadata
- **WHEN** the identity policy source is reviewed in repo
- **THEN** it contains only non-sensitive topology such as Kanidm-shaped `systems.oauth2` mappings and structural access relationships
- **AND** usernames, display names, legal names, email addresses, and real-user membership data are absent from committed cleartext policy

#### Scenario: Encrypted authoritative identity state is merged into Kanidm provisioning
- **WHEN** Kanidm provisioning evaluates person data for the identity host
- **THEN** sensitive person/account metadata and authoritative group memberships are sourced from an encrypted whole-file JSON input
- **AND** that overlay is merged through `services.kanidm.provision.extraJsonFile`
- **AND** the resulting provisioning data still resolves to valid Kanidm `groups` and `persons` structures

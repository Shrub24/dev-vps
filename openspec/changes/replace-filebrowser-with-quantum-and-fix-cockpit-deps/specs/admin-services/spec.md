## MODIFIED Requirements

### Requirement: Admin application SHALL enable native admin operations services
`applications.admin` composition SHALL wire Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Quantum file manager, Homepage Dashboard, and Beszel hub through service-level admin modules under `modules/services/admin/` so the admin profile provides a unified operational baseline without monolithic application wiring.

#### Scenario: Admin profile enables expanded baseline service set
- **WHEN** a host imports and enables the admin application profile
- **THEN** the host configuration includes `services.cockpit.enable`, `services.webhook.enable`, `services.ntfy-sh.enable`, `services.gatus.enable`, `services.vaultwarden.enable`, Quantum container-backed file manager wiring, `services.homepage-dashboard.enable`, and `services.beszel.hub.enable`
- **AND** service-owned wiring resides in admin service modules rather than one large application module file

### Requirement: Admin expansion SHALL preserve private-first exposure defaults
The admin profile augmentation SHALL NOT introduce public-ingress defaults for Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Quantum file manager, Homepage Dashboard, or Beszel and SHALL remain compatible with the existing Tailscale-first access model after module decomposition.

#### Scenario: No public-ingress baseline is introduced
- **WHEN** the admin module refactor is evaluated
- **THEN** no requirement for public internet exposure is added and service wiring remains consistent with private management access patterns

### Requirement: Cockpit lifecycle SHALL support temporary host-level disable exceptions
Cockpit SHALL remain part of admin service-module ownership and composition contracts, while allowing an explicit temporary host-level `enable = false` exception when an upstream regression is active.

#### Scenario: Upstream cockpit regression is active
- **WHEN** host policy applies temporary exception for cockpit
- **THEN** cockpit module wiring remains present in the admin composition structure
- **AND** runtime activation is disabled through host-level enable override until the exception is lifted

#### Scenario: Cockpit ws-user dependency loop workaround is applied
- **WHEN** cockpit runtime is enabled on a host using the affected cockpit release line
- **THEN** `cockpit-ws-user.service` has implicit default dependencies disabled to avoid `basic.target` shutdown ordering loops described in cockpit issue `#20914`
- **AND** admin composition remains compatible with existing cockpit route/access wiring

### Requirement: Filebrowser widget auth SHALL remain out of scope in this wave
This change SHALL NOT require machine-auth wiring for the admin file-management Homepage widget.

#### Scenario: Auth coverage is reviewed for current wave
- **WHEN** implementation scope is validated
- **THEN** admin file-management widget auth wiring is excluded from required deliverables
- **AND** no file-manager-specific Homepage credential contract is introduced in this change

### Requirement: Quantum SHALL support Pocket ID OIDC for admin authentication
Quantum admin authentication SHALL support Pocket ID OIDC configuration for the admin host while preserving an explicit temporary password-auth fallback toggle during smoke validation.

#### Scenario: OIDC is enabled with temporary password fallback
- **WHEN** Quantum admin auth is configured for current rollout
- **THEN** Quantum includes Pocket ID OIDC provider settings required for login
- **AND** password auth remains enabled until manual smoke validation is complete

#### Scenario: Password fallback is disabled after smoke
- **WHEN** operators complete manual smoke and disable fallback
- **THEN** Quantum password-auth method is disabled declaratively
- **AND** OIDC remains the interactive login method

### Requirement: Quantum SHALL expose local and remote host data via private-first source wiring
Quantum source wiring SHALL provide a local-path source for `do-admin-1` and host-scoped remote sources via SFTP-backed mounts over tailnet DNS names for `oci-melb-1` and `arch`, with SSH-key authentication and host-key verification for remote mounts.

#### Scenario: Known hosts are wired as Quantum sources
- **WHEN** admin host config is evaluated with default known-host SFTP wiring
- **THEN** Quantum source entries include a local-path source for `do-admin-1` and remote host-scoped sources for `oci-melb-1` and `arch`
- **AND** `arch` source coverage is configurable as separate mount paths (for example `/` and `/home/saurabhj`) in host-owned config
- **AND** source access remains private-first under existing admin routing posture

#### Scenario: SFTP mount security controls are enforced
- **WHEN** SFTP-backed mounts are configured for Quantum sources
- **THEN** SSH key-based authentication is used for mounts
- **AND** host-key verification is enforced through explicit known-hosts wiring

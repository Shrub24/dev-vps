## MODIFIED Requirements

### Requirement: Admin application SHALL provide a private-first admin service baseline
`applications.admin` SHALL compose Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Quantum, Homepage Dashboard, and Beszel through service-owned admin modules so the admin profile stays modular and reproducible.

#### Scenario: Admin profile enables the intended baseline
- **WHEN** a host enables `applications.admin`
- **THEN** the host gets service-owned wiring for Cockpit, Quantum, Homepage, and the existing admin support services
- **AND** service behavior is defined in focused admin service modules rather than one monolithic application module

### Requirement: Quantum SHALL replace legacy Filebrowser wiring
Quantum SHALL be the supported admin file manager and SHALL replace legacy Filebrowser route, module, and Homepage wiring.

#### Scenario: Quantum is the admin file manager
- **WHEN** admin file-management features are enabled
- **THEN** `services.admin.quantum` provides the runtime wiring
- **AND** the route/UI surface uses `quantum-admin`
- **AND** legacy `services.admin.filebrowser` wiring is not required

### Requirement: Quantum SHALL support private-first local and remote source access
Quantum SHALL expose host data through a mix of local-path and remote SSHFS-backed sources while preserving host-specific ownership of source definitions.

#### Scenario: do-admin-1 local source stays local
- **WHEN** Quantum is evaluated on `do-admin-1`
- **THEN** local `do-admin-1` data is exposed through direct local source paths
- **AND** self-SSHFS recursion is not required

#### Scenario: Remote hosts are exposed through private SSHFS mounts
- **WHEN** remote host sources are configured for Quantum
- **THEN** remote hosts such as `oci-melb-1` and `arch` are mounted over Tailscale using SSH key auth and host-key verification
- **AND** the concrete source paths remain host-owned configuration

### Requirement: Quantum authentication SHALL support Pocket ID OIDC with controlled fallback
Quantum SHALL support Pocket ID OIDC and keep password fallback declarative for rollout safety.

#### Scenario: OIDC is primary and password fallback remains optional
- **WHEN** Quantum auth is configured for the admin host
- **THEN** Pocket ID OIDC settings are wired declaratively
- **AND** password fallback can remain enabled until operators intentionally disable it

### Requirement: Cockpit SHALL remain stable under current upstream systemd behavior
Cockpit SHALL include the `cockpit-ws-user.service` dependency workaround needed for the affected upstream release line.

#### Scenario: Cockpit runtime is enabled
- **WHEN** Cockpit is enabled on a host using the affected release behavior
- **THEN** `cockpit-ws-user.service` has implicit default dependencies disabled
- **AND** Cockpit startup/shutdown avoids the known ordering loop

### Requirement: Cockpit SHALL use per-host sessions with host-local authentication
Cockpit access SHALL use direct per-host sessions rather than login-page cross-host chaining.

#### Scenario: Operators manage do-admin-1 and oci-melb-1
- **WHEN** operators need Cockpit access for either host
- **THEN** they use explicit per-host session entrypoints (for example `/do-admin-1` and `/oci-melb-1` on the Cockpit domain)
- **AND** `Connect to:` host-target chaining remains disabled
- **AND** each host authenticates against its own local Cockpit account policy

### Requirement: Cockpit transport ownership SHALL stay module-centered and host overlays minimal
Cockpit-specific transport and reverse-proxy behavior SHALL be owned by the Cockpit module family, while host overlays only set host-specific values.

#### Scenario: Host-specific Cockpit transport is configured
- **WHEN** `do-admin-1` or `oci-melb-1` need host-specific Cockpit behavior
- **THEN** shared transport logic (socket bind defaults, Tailscale Serve wiring, loopback TLS generation, route-derived WebService settings) stays under Cockpit module ownership
- **AND** host overlays only provide values such as `publicHost`, `urlRoot`, secret paths, or enable flags

### Requirement: do-admin-1 local Cockpit upstream TLS SHALL be trusted without insecure skip-verify
The public `do-admin-1` Cockpit route SHALL use explicit trust of a declaratively generated local CA instead of steady-state insecure TLS bypass.

#### Scenario: do-admin-1 local upstream is proxied over HTTPS
- **WHEN** Caddy proxies `cockpit-admin` to the local Cockpit HTTPS listener
- **THEN** Cockpit serves a declaratively generated loopback leaf certificate
- **AND** Caddy trusts that upstream via an explicit local CA certificate path
- **AND** route-scoped `tls_insecure_skip_verify` is not required in the steady-state design

### Requirement: OCI Cockpit exposure SHALL use host-local Tailscale Serve HTTPS
The `oci-melb-1` Cockpit endpoint SHALL be exposed through host-local Tailscale Serve HTTPS rather than a broad direct bind assumption.

#### Scenario: OCI Cockpit is consumed through tailscale-upstream
- **WHEN** `cockpit-oci-admin` is routed from `do-admin-1`
- **THEN** the upstream points to the OCI host’s Tailscale Serve HTTPS endpoint
- **AND** the OCI host can keep Cockpit socket binding local by default

### Requirement: Homepage-authenticated Quantum widget wiring SHALL remain out of scope
This change SHALL NOT require widget-machine-auth integration for the Quantum Homepage card.

#### Scenario: Homepage file-manager auth is reviewed
- **WHEN** this change is evaluated
- **THEN** Quantum Homepage auth automation is deferred
- **AND** the change remains valid without introducing widget-specific credentials

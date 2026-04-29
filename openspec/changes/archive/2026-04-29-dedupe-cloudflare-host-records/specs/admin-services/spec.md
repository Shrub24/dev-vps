## MODIFIED Requirements

### Requirement: do-admin-1 local Cockpit upstream SHALL use explicit trusted loopback TLS
The `do-admin-1` Cockpit public subpath SHALL proxy to the local Cockpit listener over HTTPS using a host-local CA and explicit upstream trust, without steady-state `tls_insecure_skip_verify`.

#### Scenario: do-admin-1 local Cockpit upstream is rendered
- **WHEN** the `cockpit-do-admin-1` route is evaluated
- **THEN** the upstream uses HTTPS to the local Cockpit listener
- **AND** Caddy trusts a declaratively generated local CA for that hop
- **AND** insecure upstream TLS verification bypass is not required in steady state

### Requirement: oci-melb-1 Cockpit SHALL be exposed through host-local Tailscale Serve HTTPS
The `oci-melb-1` Cockpit entrypoint SHALL use host-local Tailscale Serve HTTPS as the upstream exposure mechanism rather than direct cross-host socket binding.

#### Scenario: OCI Cockpit route is evaluated
- **WHEN** the `cockpit-oci-melb-1` route is resolved
- **THEN** its upstream targets the OCI host over Tailscale Serve HTTPS
- **AND** the OCI host keeps Cockpit socket ownership local to the host itself

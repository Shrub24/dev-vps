## MODIFIED Requirements

### Requirement: Admin application SHALL enable native admin operations services
`applications.admin` composition SHALL wire Cockpit, Webhook, Ntfy, Gatus, Vaultwarden, Quantum, Homepage Dashboard, Beszel hub, and Termix through service-level admin modules under `modules/services/admin/` so the admin profile provides a unified operational baseline without monolithic application wiring or generic-service wrapper indirection.

#### Scenario: Admin profile enables expanded baseline service set
- **WHEN** a host imports and enables the admin application profile
- **THEN** the host configuration includes `services.cockpit.enable`, `services.webhook.enable`, `services.ntfy-sh.enable`, `services.gatus.enable`, `services.vaultwarden.enable`, `services.homepage-dashboard.enable`, and `services.beszel.hub.enable`
- **AND** Quantum service wiring is enabled through `services.admin.quantum`
- **AND** Termix service wiring is enabled through `services.admin.termix`
- **AND** service-owned wiring resides in admin service modules rather than one large application module file

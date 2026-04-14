## ADDED Requirements

### Requirement: Admin homepage route SHALL be explicitly declared and access-gated
The ingress layer SHALL expose Homepage at `admin.shrublab.xyz` only through an explicit route declaration that is Cloudflare Access-gated at the public edge and uses private-origin upstream transport defaults for admin traffic.

#### Scenario: Admin homepage route is configured
- **WHEN** edge ingress route policy is rendered for `do-admin-1`
- **THEN** a route for subdomain `admin` under the primary domain is present for Homepage
- **AND** the route enforces Cloudflare Access-gated policy and admin-safe exposure defaults

#### Scenario: Admin homepage route has no explicit override
- **WHEN** the admin homepage route is evaluated without permissive overrides
- **THEN** it does not default to unrestricted direct public-origin behavior

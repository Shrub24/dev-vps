## ADDED Requirements

### Requirement: Edge DNS publication SHALL consume canonical policy exports
Cloudflare DNS publication for edge routes SHALL consume generated policy exports from the canonical web-services map.

#### Scenario: Service subdomain is declared
- **WHEN** a service has a `subdomain` in canonical policy
- **THEN** OpenTofu plans a corresponding DNS record under the configured zone

#### Scenario: Service proxy posture is declared
- **WHEN** a service defines `cloudflare.proxied`
- **THEN** OpenTofu applies that proxied setting to the DNS record

## ADDED Requirements

### Requirement: Cloudflare DNS records SHALL be policy-driven
Cloudflare DNS records for published web services SHALL be declared in OpenTofu and generated from canonical policy exports rather than hand-managed per record.

#### Scenario: DNS records are planned
- **WHEN** OpenTofu evaluates Cloudflare resources
- **THEN** record definitions are derived from generated policy JSON exported from `policy/web-services.nix`

#### Scenario: Grey-cloud service is declared
- **WHEN** a service policy sets `cloudflare.proxied = false`
- **THEN** the DNS record is planned as DNS-only (not proxied)

### Requirement: Shared origin endpoint SHALL be managed declaratively
The shared origin endpoint used as CNAME target for published service records SHALL be managed in OpenTofu.

#### Scenario: Origin endpoint is enabled
- **WHEN** `manage_origin_record` is true
- **THEN** OpenTofu plans a DNS record for the configured origin name/content/proxy posture

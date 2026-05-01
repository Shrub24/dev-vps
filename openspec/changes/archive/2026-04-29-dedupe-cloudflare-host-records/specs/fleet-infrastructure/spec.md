## MODIFIED Requirements

### Requirement: Cloudflare DNS records SHALL be policy-driven
Cloudflare DNS and Zero Trust application resources for published web services SHALL be declared in OpenTofu and generated from canonical policy exports, with hostname-scoped resources deduped by public hostname rather than emitted once per internal route key.

#### Scenario: Multiple routes share one public hostname
- **WHEN** `just tofu-sync` exports policy data for OpenTofu consumption
- **THEN** the generated Cloudflare view contains one DNS record definition for the shared public hostname
- **AND** it contains at most one Access application definition for that public hostname
- **AND** route-level policy data remains available separately for non-Cloudflare consumers

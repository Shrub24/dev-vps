## ADDED Requirements

### Requirement: Shared admin hostnames MAY carry host-specific private-origin subpaths
Private-origin admin services SHALL be able to share a public hostname while remaining distinguishable through explicit host-specific subpaths.

#### Scenario: Multiple admin routes share a hostname
- **WHEN** policy routes for different hosts use the same subdomain with distinct declared paths
- **THEN** route resolution preserves the distinct public URLs for each host-specific subpath
- **AND** upstream transport remains private-origin according to the declared exposure mode

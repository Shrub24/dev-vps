## ADDED Requirements

### Requirement: Homepage SHALL expose Tagr manual fallback entry
Homepage service presentation for `do-admin-1` SHALL include a Tagr entry so operators can access manual metadata fallback tooling from the central admin surface.

#### Scenario: Homepage service list is rendered
- **WHEN** homepage services are assembled from policy-backed route metadata
- **THEN** a Tagr entry is present with href derived from the canonical `tagr` route
- **AND** Tagr entry placement remains within homepage-owned presentation files

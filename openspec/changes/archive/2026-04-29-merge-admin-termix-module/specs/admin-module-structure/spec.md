## MODIFIED Requirements

### Requirement: Admin modules SHALL follow layered ownership boundaries
Admin configuration SHALL follow a layered structure where policy data remains under `policy/`, policy transformation logic remains under `lib/`, service-owned behavior is implemented directly in `modules/services/admin/`, application composition remains in `modules/applications/admin/`, and host-local assembly remains in `hosts/<host>/`. Thin forwarding wrappers that only proxy admin-owned services into generic service modules SHALL NOT be the canonical implementation boundary.

#### Scenario: Admin module tree is reviewed
- **WHEN** operators inspect admin-related repository paths
- **THEN** service-owned admin logic is located under `modules/services/admin/`
- **AND** `applications.admin` composition is located under `modules/applications/admin/`
- **AND** policy data/transforms are not embedded in service or host files
- **AND** admin-owned services do not rely on redundant generic wrapper modules as their primary implementation path

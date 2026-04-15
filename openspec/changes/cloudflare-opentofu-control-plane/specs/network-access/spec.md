## MODIFIED Requirements

### Requirement: Public-edge policy SHALL be explicit by default-plus-exception model
Cloudflare public-edge access posture SHALL be modeled as a global default with explicit host/route exceptions.

The default-plus-exception model SHALL be declared in canonical shared policy (`policy/web-services.nix`).

#### Scenario: No exception declared
- **WHEN** a route has no host/route override
- **THEN** it inherits the global default policy

#### Scenario: Exception declared
- **WHEN** a host or route override is present
- **THEN** that exception is applied and remains auditable in change artifacts

### Requirement: Control-plane ownership SHALL be separated from runtime wiring
Cloudflare resource declarations SHALL be owned in control-plane artifacts, while runtime/Nix modules consume canonical policy and derived outputs.

#### Scenario: Runtime change depends on Cloudflare policy
- **WHEN** runtime/Nix change needs edge policy values
- **THEN** values are consumed from canonical policy and generated outputs rather than duplicated unmanaged config

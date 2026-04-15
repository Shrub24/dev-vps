## MODIFIED Requirements

### Requirement: Admin routes SHALL remain Access-gated by default with explicit exceptions
Public admin-facing routes SHALL continue to require Cloudflare Access gating by default, with route-level exceptions allowed only when explicitly declared and justified.

Exception declarations consumed by this change SHALL come from canonical shared policy (`policy/web-services.nix`) and Cloudflare control-plane ownership (`cloudflare-opentofu-control-plane`) rather than ad-hoc unmanaged route policy.

#### Scenario: Standard admin route is rendered
- **WHEN** a public admin route is rendered without exception flags
- **THEN** it enforces Cloudflare Access header gate behavior
- **AND** it retains existing admin-safe ingress defaults

#### Scenario: Route-level exception is declared
- **WHEN** a route is explicitly marked as exception in this change scope
- **THEN** the exception is visible in route declarations and contract checks
- **AND** exception intent is documented in change artifacts

### Requirement: Music route SHALL reflect grey-cloud exposure posture
The music/Navidrome ingress posture SHALL be modeled so that security assumptions do not depend on Cloudflare-proxied WAF behavior.

#### Scenario: Music route policy is evaluated
- **WHEN** route posture for music/Navidrome is reviewed in this change
- **THEN** artifacts and route checks treat music as a grey-cloud DNS exposure class
- **AND** compensating host-layer controls (e.g., CrowdSec baseline) are part of the declared security posture

### Requirement: Second-layer host protection SHALL be present for exposed/bypassed traffic classes
Ingress policy changes that introduce or preserve bypassed/non-Access traffic classes SHALL include host-level second-layer protection requirements.

#### Scenario: Exposed/bypassed route classes exist
- **WHEN** route set includes traffic classes outside normal Access-gated browser flow
- **THEN** host-level CrowdSec baseline is required in this change scope

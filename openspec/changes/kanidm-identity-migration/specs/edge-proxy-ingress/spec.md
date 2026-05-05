## MODIFIED Requirements

### Requirement: Admin routes SHALL remain Access-gated by default with explicit exceptions
Public admin-facing routes SHALL continue to require Cloudflare Access gating by default, with route-level exceptions allowed only when explicitly declared and justified.

Exception declarations consumed by this change SHALL come from canonical shared policy (`policy/web-services.nix`) and Cloudflare control-plane ownership rather than ad-hoc unmanaged route policy.

#### Scenario: Standard admin route is rendered
- **WHEN** a public admin route is rendered without exception flags
- **THEN** it enforces Cloudflare Access header gate behavior
- **AND** it retains existing admin-safe ingress defaults

#### Scenario: Route-level exception is declared
- **WHEN** a route is explicitly marked as exception in this change scope
- **THEN** the exception is visible in route declarations and contract checks
- **AND** exception intent is documented in change artifacts

#### Scenario: Identity-provider route is declared as upstream-IdP exception
- **WHEN** the Kanidm route is rendered for shared IdP hosting
- **THEN** it is explicitly declared as the required non-Access-gated upstream IdP exception
- **AND** this exception is documented as required to avoid Access→IdP loop behavior

### Requirement: Cloudflare Access SHALL use Kanidm as upstream IdP
Cloudflare Access configuration for admin browser routes SHALL use Kanidm generic OIDC as upstream identity provider in this change scope.

#### Scenario: Access IdP switch is evaluated
- **WHEN** Cloudflare Access resources or inputs are evaluated
- **THEN** upstream IdP endpoints and client credentials resolve to Kanidm values
- **AND** legacy Pocket ID upstream assumptions are removed from this change scope

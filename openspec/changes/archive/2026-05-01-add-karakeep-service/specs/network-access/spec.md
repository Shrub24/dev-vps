## REMOVED Requirements

### Requirement: Karakeep SHALL use declarative private browser exposure on oci-melb-1
**Reason**: Karakeep browser access is now intended to flow through canonical `do-admin-1` Caddy edge routing rather than a host-local private-only exposure model.
**Migration**: Capture Karakeep exposure behavior under `edge-proxy-ingress` using `policy/web-services.nix` as the single source of truth.

### Requirement: Karakeep SHALL not expand public firewall trust by default
**Reason**: Firewall and route posture for Karakeep should be modeled through the existing canonical edge policy path instead of a standalone network-access delta for this change.
**Migration**: Express Karakeep browser exposure requirements through `edge-proxy-ingress` policy and host-specific route evaluation.

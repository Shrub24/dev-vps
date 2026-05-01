## Why

`oci-melb-1` has a growing set of first-class self-hosted services, but it does not yet provide a repo-native knowledge capture and read-later service. We want to add Karakeep now because upstream publishes an official multi-container deployment and ARM images, and the repo already has an idiomatic pattern for expressing container-native services directly in Nix instead of carrying Docker Compose as the runtime interface.

**Core Value:** Add Karakeep as a first-class service on `oci-melb-1` using handwritten NixOS container wiring that matches existing host, secrets, and operations conventions while exposing browser access through the canonical `do-admin-1` Caddy edge policy path.

## What Changes

- Add a new `modules/services/karakeep.nix` module that declares the Karakeep web, browser, and Meilisearch containers through native NixOS OCI container wiring.
- Wire Karakeep into `hosts/oci-melb-1/default.nix` with explicit persistent state under `/srv/data/karakeep` and host-local runtime defaults appropriate for Oracle ARM.
- Add host-scoped Karakeep secrets/templates for required auth and search keys without expanding shared secret scope.
- Expose Karakeep through `do-admin-1` Caddy ingress using canonical `policy/web-services.nix` route declarations and private-origin `tailscale-upstream` transport to `oci-melb-1`.
- Document the Karakeep service role and operational posture in architecture-facing repo docs.

## Capabilities

### New Capabilities
- `karakeep-service`: Provide a first-class Karakeep service on `oci-melb-1` using Nix-managed OCI containers, persistent state, and private browser access.

### Modified Capabilities
- `secrets-management`: Add host-scoped Karakeep runtime secrets and optional feature-secret handling for `oci-melb-1`.
- `edge-proxy-ingress`: Add canonical `do-admin-1` route policy for Karakeep using `policy/web-services.nix`, `tailscale-upstream`, Cloudflare Access, and authenticated origin pulls.

## Impact

- **Affected code**: `modules/services/`, `hosts/oci-melb-1/default.nix`, `hosts/oci-melb-1/secrets.template.yaml`, and related validation/docs files.
- **Operational impact**: `oci-melb-1` gains a first-class read-later/bookmarking service with repo-native lifecycle management and explicit persistent state.
- **Security impact**: Required Karakeep secrets remain host-scoped and public browser access follows existing Access-gated/AOP-protected edge policy routed through `do-admin-1` to private origin.
- **Risk boundary**: This change adopts upstream container topology but intentionally avoids `compose2nix` and bare Docker Compose operations while reusing the existing canonical edge-policy path instead of inventing a new exposure model.

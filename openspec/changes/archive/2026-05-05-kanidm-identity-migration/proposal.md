## Why

 Pocket ID was a good initial fit for lightweight web SSO, but the repo now treats feature enablement as the canonical topology signal, keeps hosts thin, and expects leaf services to own their secret/runtime contracts behind explicit application or service entrypoints. Kanidm is a better match for that post-refactor shape because it can be provisioned directly from Nix, can later extend into unixd/PAM/SSH host auth, and avoids long-lived web-UI-managed identity drift.

**Core Value:** establish Kanidm as the repo-owned identity backbone in a way that preserves low-complexity rollout, keeps OIDC client state declarative, and creates a clean path from current web SSO parity to later host login integration.

## What Changes

- Replace Pocket ID as the canonical repo-owned identity provider with a native nixpkgs Kanidm leaf service module composed through the existing admin application entrypoint.
- Introduce provider-owned Kanidm OIDC endpoint outputs as the new single source of truth for issuer and endpoint wiring.
- Provision current OIDC clients declaratively through `services.kanidm.provision.systems.oauth2` using repo-owned client IDs and SOPS-managed client secrets.
- Keep the initial rollout staged: first bring up a healthy Kanidm service with bootstrap/admin provisioning, then cut over current OIDC consumers, then add `kanidm-unixd` host integration afterward.
- Update secret contracts so Kanidm bootstrap/admin secrets live under identity-scoped secret paths while current app OIDC client credentials continue to come from explicit scoped secret files owned and consumed through leaf-service contract surfaces.
- **BREAKING** Remove Pocket ID from the active identity path and update admin/edge/auth contracts to reference Kanidm instead.

## Capabilities

### New Capabilities
- `kanidm-identity`: Declarative Kanidm server provisioning, identity bootstrap, and OIDC client registration using native NixOS Kanidm module support.
- `host-unix-auth`: Fleet host integration for Kanidm client/unixd-backed NSS/PAM/SSH policy after OIDC parity is restored.

### Modified Capabilities
- `admin-services`: Replace Pocket ID-based admin app auth assumptions with Kanidm-based identity contracts and staged unixd follow-up.
- `admin-service-consolidation`: Replace canonical admin-owned Pocket ID namespace/wiring expectations with canonical admin-owned Kanidm identity wiring and provider-agnostic composition glue.
- `provider-owned-oidc-uris`: Move OIDC SSOT ownership from Pocket ID outputs to Kanidm outputs while preserving consumer-side “do not reconstruct endpoints locally” behavior.
- `secrets-management`: Replace host-exception Pocket ID assumptions with identity-scoped Kanidm bootstrap secrets plus explicit scoped client-secret handoff for declarative provisioning.
- `edge-proxy-ingress`: Replace Pocket ID upstream IdP assumptions and route exception language with Kanidm-based upstream IdP and exposure behavior.
- `internal-service-auth`: Update any remaining service-to-service auth assumptions that currently hardcode host-scoped OIDC credential handling around the old Pocket ID model.
- `feature-topology`: Align the Kanidm migration with the current topology model where `applications.admin` remains the composition root, Kanidm remains a leaf admin service, host assembly stays thin, and secret/runtime wiring lives in the owning leaf services.

## Impact

- Affected code: `modules/applications/admin/default.nix`, `modules/services/admin/pocket-id.nix`, new Kanidm admin leaf-service module(s), `modules/services/admin/termix.nix`, `modules/services/admin/quantum.nix`, `modules/services/karakeep.nix`, `hosts/do-admin-1/default.nix`, `hosts/do-admin-1/edge.nix`, `hosts/oci-melb-1/default.nix`, `policy/web-services.nix`, `.sops.yaml`, and service/application-scoped secret trees.
- Affected systems: `do-admin-1` identity/admin stack first, then OIDC consumers on `do-admin-1` and `oci-melb-1`, then later all fleet hosts for `kanidm-unixd`.
- Dependencies: native nixpkgs `services.kanidm`, `services.kanidm.provision`, `services.kanidm.client`, `services.kanidm.unix`, and existing `sops-nix` runtime secret rendering.
- Operational effect: brief acceptable auth downtime during cutover, no requirement for long-lived Pocket ID/Kanidm runtime coexistence, and no need to preserve old user state because migration happens before real user registration.

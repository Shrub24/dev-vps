## 1. Kanidm baseline service bring-up

- [x] 1.1 Inventory current Pocket ID assumptions and add a canonical Kanidm admin module skeleton under `modules/services/admin/` with native `services.kanidm` server settings, provider-owned OIDC outputs, and temporary coexistence-safe composition imports.
- [x] 1.2 Add identity-scoped SOPS secret contracts for Kanidm bootstrap/admin credentials and wire runtime secret file paths for `services.kanidm.provision.adminPasswordFile` and `idmAdminPasswordFile`.
- [x] 1.3 Enable the Kanidm module on the designated identity/admin host with minimal origin/domain/storage settings and policy route plumbing needed for a successful evaluation/build.
- [x] 1.4 Run focused validation for the baseline bring-up (`nix fmt`, targeted eval/build for the identity host, and any module-option inspection needed to confirm Kanidm service wiring resolves).

## 2. Declarative OIDC provisioning and cutover

- [x] 2.1 Define the Kanidm declarative provisioning model for current OIDC clients (`termix`, `quantum`, `karakeep`, and any in-scope admin apps) including client metadata, scopes, claim maps, and secret-file inputs.
- [x] 2.2 Add helper/template wiring if needed so current scoped OIDC secret files can render the single-value runtime files expected by `services.kanidm.provision.systems.oauth2.<name>.basicSecretFile` without broadening secret ownership.
- [x] 2.3 Rewire `applications.admin`, Termix, Quantum, Karakeep, and any host/env template consumers to use Kanidm provider-owned OIDC outputs and Kanidm-backed client credentials.
- [x] 2.4 Update route/policy and Cloudflare Access inputs so Kanidm is the active upstream IdP and the identity-provider route exception is documented/implemented cleanly.
- [x] 2.5 Remove Pocket ID from the active runtime path once Kanidm OIDC wiring builds cleanly and current auth behavior is restored.
- [x] 2.6 Run focused validation for OIDC cutover (`nix fmt`, targeted host eval/builds, relevant flake checks, and spot checks that issuer/endpoints and secret paths resolve from Kanidm outputs).

## 3. Host unixd, PAM, and SSH integration

- [x] 3.1 Introduce reusable host-side Kanidm client/unixd wiring that consumes the canonical Kanidm server URI and can be enabled explicitly per host.
- [x] 3.2 Enable `services.kanidm.client` and `services.kanidm.unix` on in-scope hosts with explicit PAM allowed-login-group policy and no implicit broad login enablement.
- [x] 3.3 Enable `services.kanidm.unix.sshIntegration` only on the approved hosts and preserve break-glass/admin recovery expectations in host config and docs/spec alignment.
- [ ] 3.4 Run focused validation for host auth integration (targeted eval/builds for each affected host and any relevant option/config inspection for unixd, PAM, and SSH settings).

## 4. Spec and repo cleanup

- [x] 4.1 Update or remove remaining Pocket ID-specific naming, comments, and secret/template artifacts that no longer match the active Kanidm identity plane.
- [x] 4.2 Verify OpenSpec artifacts stay aligned with the implemented Kanidm model and adjust any stale file-path or scope references discovered during implementation.
- [x] 4.3 Run full completion validation (`openspec validate --strict`, plus the agreed Nix validation commands) and leave the change ready for apply/archive flow.

## Context

The repo currently treats Pocket ID as the canonical admin-owned identity provider and uses its emitted `oidc.*` outputs as the single source of truth for Termix, Quantum, Karakeep, and Cloudflare Access wiring. That was acceptable for early lightweight web SSO, but it no longer matches the desired operating model after the feature-topology refactor: hosts should stay thin, `applications.admin` should remain the composition root for the admin stack, and leaf services should own their secret/runtime contracts behind explicit contract inputs. Identity should therefore be declared in Nix, provisioned from repo state, and ready to extend into host auth after OIDC parity is restored.

This migration happens before real users are registered, so there is no requirement to preserve live user state or maintain long-lived dual-provider runtime consistency. Downtime is acceptable. The only dual-run requirement is that repo code may temporarily contain both providers until Kanidm builds successfully and can immediately replace Pocket ID.

Key constraints:
- Identity remains private-first and Tailscale-first except for explicit edge exposure required for browser OIDC flows.
- Secrets must stay blast-radius-scoped with explicit SOPS recipient rules.
- The first implementation target is still the active admin/identity host and current OIDC consumers; unixd/PAM/SSH rollout follows afterward.
- The repo has already moved to service/application-scoped secret ownership and feature-rooted topology, so the Kanidm migration must fit that model rather than reintroducing host-monolith secret buckets or host-local runtime wiring.
- Human identity metadata should not live in committed cleartext policy when it can identify real users; topology and access structure may remain reviewable, but person records should be supplied from encrypted identity data.

## Goals / Non-Goals

**Goals:**
- Stand up a native nixpkgs Kanidm leaf service with minimal bootstrap/admin configuration and clean host buildability while keeping `applications.admin` as the composition root.
- Replace Pocket ID OIDC SSOT outputs with Kanidm-owned outputs while preserving the existing consumer pattern of referencing provider-owned values rather than reconstructing endpoints locally.
- Provision current OIDC clients declaratively via `services.kanidm.provision.systems.oauth2.<name>` using repo-owned client IDs and SOPS-managed client secrets.
- Keep identity bootstrap/admin secrets under explicit identity-scoped secret paths and keep per-application OIDC client credentials in their existing scoped secret files.
- Keep non-sensitive identity topology reviewable in committed JSON policy while sourcing authoritative sensitive Kanidm provisioning state from an encrypted whole-file JSON overlay that stays in Kanidm's provisioning schema.
- Sequence the work so OIDC parity comes before unixd/PAM/SSH host integration.

**Non-Goals:**
- Preserve or migrate live Pocket ID user data.
- Design a long-lived Pocket ID/Kanidm coexistence model.
- Deliver complete fleet-wide unixd login policy in the initial Kanidm bring-up phase.
- Restructure every secret file shape up front if a helper/template can bridge the current `oidc.yaml` layout cleanly.
- Put real human passwords, passkeys, or long-lived user credential material in Git-managed secrets.

## Decisions

### KID-1: Kanidm becomes the canonical repo-owned identity provider
Use native nixpkgs `services.kanidm` in a dedicated admin leaf-service module rather than wrapping a separate container or preserving Pocket ID as the primary interface.

**Why:** This aligns identity with the repo’s preference for native NixOS services, preserves the feature-topology rule that `applications.admin` composes leaf services rather than hosts doing app-internal assembly, and makes provisioning declarative instead of UI-managed.

**Alternatives considered:**
- Keep Pocket ID and add Kanidm only for unixd later: rejected because it splits identity across two control planes.
- Run Kanidm in a custom wrapper/container: rejected because native nixpkgs support already provides the needed service and provisioning model.

### KID-2: Cutover is phase-based but not runtime-synchronized
The migration will use three implementation phases: (1) Kanidm server/bootstrap, (2) OIDC cutover to restore current behavior, (3) unixd/PAM/SSH rollout. Pocket ID may coexist in repo code only until Kanidm builds and starts cleanly; once Kanidm is healthy, the active path switches directly.

**Why:** The service is not yet live, downtime is acceptable, and avoiding long-lived dual-run removes endpoint drift and sync complexity.

**Alternatives considered:**
- Full dual-run with drift handling: rejected as unnecessary operational overhead.
- Big-bang all-at-once including unixd: rejected because login-plane changes deserve separate risk isolation.

### KID-3: Keep provider-owned OIDC outputs as the consumer contract
Kanidm wiring should emit canonical OIDC outputs under a provider-owned namespace and consumer modules should continue reading those outputs rather than constructing endpoints themselves.

**Why:** The repo already established this pattern as the SSOT contract, and preserving it minimizes consumer churn while enabling provider replacement.

**Alternatives considered:**
- Let each consumer derive Kanidm endpoints from a base URL: rejected because it reintroduces duplication and drift.
- Move immediately to a completely generic `services.admin.identity.*` facade: deferred unless consumer churn proves it necessary during implementation.

### KID-4: Secret ownership remains scoped by domain/service, not by Kanidm monolith
Kanidm bootstrap/admin passwords live under identity-scoped secret paths, while OIDC client IDs and secrets remain in service/application-scoped files. Provisioning consumes secret file paths rendered by `sops-nix`; if Kanidm needs a single-value secret file for a client, a helper/template extracts that value from the current scoped secret source. Hosts bind only the exposed contract inputs, while the Kanidm leaf service owns the actual runtime secret registration.

**Why:** This preserves the new secret-topology direction and avoids centralizing unrelated app credentials into one broad identity blob.

**Alternatives considered:**
- Move all OIDC secrets into one Kanidm-owned file: rejected because it widens blast radius and weakens logical ownership.
- Refactor every `oidc.yaml` immediately to a new shape: deferred unless the helper/template becomes awkward enough to justify schema churn.

### KID-5: Identity topology and authoritative memberships split into JSON policy + encrypted Kanidm overlay
Non-sensitive identity structure should live in committed JSON policy, while usernames, display names, legal names, emails, and authoritative real-user memberships should come from an encrypted whole-file JSON overlay that also follows Kanidm provisioning structure.

**Why:** This keeps access structure reviewable while avoiding committed cleartext person metadata, and it avoids maintaining a second ad-hoc schema for secret identity data. JSON is the cleanest shared format because Nix can read it natively and Kanidm already consumes JSON overlays via `extraJsonFile`.

**Alternatives considered:**
- Keep person metadata in plain Nix policy: rejected because usernames/display names/memberships can still be sensitive.
- Store per-field person metadata as many individual SOPS keys: rejected as awkward and brittle for a growing identity dataset.
- Put the entire provisioning model in one encrypted blob: rejected because it hides non-sensitive topology that should stay reviewable in repo history.

### KID-6: unixd rollout is explicit and host-safe
`services.kanidm.client` and `services.kanidm.unix` will be introduced after OIDC parity, with `sshIntegration` and PAM allowlists enabled only through explicit host policy.

**Why:** Host auth errors can lock out operators; the repo values recoverability and break-glass access over cleverness.

**Alternatives considered:**
- Enable unixd on all hosts in the same step as OIDC cutover: rejected as too much auth-surface change at once.

## Risks / Trade-offs

- **[Risk] Kanidm provisioning secret files expect simple file values while current scoped OIDC secrets are structured YAML** → **Mitigation:** add a helper/template layer that renders per-client secret files from existing scoped YAML before deciding on any schema refactor. 
- **[Risk] Consumer modules and specs currently hardcode Pocket ID namespaces** → **Mitigation:** update provider-owned OIDC and admin-service contracts as part of the same change so implementation is anchored to the new SSOT immediately.
- **[Risk] Edge auth cutover could temporarily break browser access** → **Mitigation:** accept brief downtime, validate Kanidm endpoints first, then switch Cloudflare Access and app consumers in one focused phase.
- **[Risk] unixd/PAM/SSH rollout could impact host access safety** → **Mitigation:** defer unixd until after OIDC parity, use explicit allowed login groups, and preserve existing break-glass/admin access paths while rolling it out.
- **[Risk] A provider-specific `services.admin.kanidm` namespace could still leak too much implementation detail into admin composition** → **Mitigation:** keep service-owned runtime wiring in the Kanidm module while limiting `applications.admin` glue to enablement, provider-owned outputs, and explicit secret handoff.
- **[Risk] Sensitive person metadata and authoritative memberships could drift between plain policy and encrypted provisioning data** → **Mitigation:** keep committed policy limited to non-sensitive JSON topology and oauth2 mappings, and keep authoritative groups/persons state in one encrypted Kanidm-shaped whole-file overlay with clear shape/template ownership.

## Migration Plan

1. Add the Kanidm leaf-service module with minimal server settings (`origin`, `domain`, storage path, bootstrap/admin secret inputs) and compose it through `applications.admin` so the host build remains thin.
2. Add scoped secret wiring for Kanidm bootstrap/admin passwords and any helper/template needed to hand per-client secret files to `services.kanidm.provision`.
3. Define declarative Kanidm provisioning for current OIDC clients and issuer/endpoint outputs.
4. Split identity provisioning input into committed JSON topology and an encrypted whole-file JSON Kanidm provisioning overlay merged via `services.kanidm.provision.extraJsonFile`.
5. Rewire Termix, Quantum, Karakeep, route policy, and Cloudflare Access to consume Kanidm outputs and credentials.
6. Remove Pocket ID from the active path once Kanidm is healthy.
7. In follow-up tasks within the same change, add `services.kanidm.client` / `services.kanidm.unix` host integration and explicit SSH/PAM policy.

Rollback strategy:
- Before OIDC cutover, rollback is just disabling/removing the Kanidm module changes.
- During OIDC cutover, rollback is restoring Pocket ID as the active provider if Kanidm endpoint/provision validation fails.
- unixd rollout rollback is disabling host `services.kanidm.unix`/`sshIntegration` settings while preserving the already working OIDC provider.

## Open Questions

- Whether a generic `services.admin.identity.oidc.*` facade is worth introducing now or whether direct Kanidm provider outputs are sufficient for this migration.
- Whether current structured OIDC secret files stay as-is permanently with helper extraction, or whether a later cleanup should normalize some files for simpler provisioning inputs.
- Which hosts should enable `sshIntegration` first versus only `client`/`unix` NSS-PAM membership lookups.

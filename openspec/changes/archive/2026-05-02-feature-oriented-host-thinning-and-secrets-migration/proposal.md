## Why

The repo works today, but feature ownership and host composition are still inconsistent: hosts retain too much service wiring, secrets remain largely monolithic and host-owned, and enablement is not yet a clean feature-first topology signal. This makes the fleet harder to reason about, harder to extend, and more structurally coupled than it needs to be.

**Core Value:** make feature enablement, application/service ownership, and secret scope align cleanly so hosts become thin wrappers over modular, reusable feature composition.

## What Changes

- Introduce a clean feature-oriented architecture where application stacks are enabled through canonical `applications.<name>.enable` entrypoints and true standalone workloads use canonical `services.<domain>.<name>.enable` entrypoints.
- Refactor hosts into thin assembly layers that primarily declare identity, facts, feature enables, secret source bindings, and narrow host-only overrides.
- Move service/application wiring now living in hosts down into owning application and service modules.
- Replace monolithic host-scoped secret ownership as the default with a new bucket model:
  - `secrets/applications/<app>.yaml`
  - `secrets/services/<service>.yaml`
  - `secrets/hosts/<host>/system.yaml`
  - `secrets/hosts/<host>/oidc.yaml`
- Derive normal secret recipient scope from feature enablement rather than maintaining a second broad consumer inventory.
- Keep only a small explicit exception layer for extra-reader cases such as cross-host OIDC handshakes.
- Standardize leaf-owned secret contracts (`secretFiles.*`, `secretKeys.*`) and move `sops.secrets` / `sops.templates` ownership out of hosts into application/service modules.
- Preserve provider-owned OIDC URI wiring during the topology/secret refactor by keeping Pocket ID as the OIDC endpoint SSOT, keeping host OIDC secrets in narrow `secrets/hosts/<host>/oidc.yaml` scopes, and preserving application-level env-file handoff to leaf services that own their OIDC templates.
- Close late regression fallout by aligning Karakeep and Beszel follow-up fixes with the canonical leaf-contract patterns, removing ad hoc secret-file option shapes, and dropping leftover inline implementation comments where the code can stay self-describing.
- **BREAKING:** remove legacy mixed enablement paths, host-owned secret/template blocks for application internals, monolithic host secret files as the primary secret bucket model, and compatibility holdovers/shims.

## Capabilities

### New Capabilities
- `feature-topology`: define canonical feature-oriented enablement, thin-host composition, and ownership boundaries between hosts, applications, and leaf services.

### Modified Capabilities
- `fleet-infrastructure`: update secret blast-radius and host-composition requirements so normal secret scope derives from feature enablement while preserving explicit host-scoped exception boundaries.
- `repository-structure`: update repository layout requirements for canonical application/service entrypoints, thin host assembly, and the new secrets bucket structure.
- `secrets-management`: replace the fleet-shared + host-scoped default model with application/service/host scopes, derived recipient membership for normal scopes, and leaf-owned secret registration contracts.

## Impact

- Affected code:
  - `hosts/**`
  - `modules/applications/**`
  - `modules/services/**`
  - `.sops.yaml`
  - `secrets/**`
  - helper logic for secret contract reuse and recipient derivation/validation
  - OIDC endpoint helper logic in `lib/policy.nix` plus admin/Karakeep OIDC consumer wiring
- Affected systems:
  - `oci-melb-1` and `do-admin-1`
  - application stacks such as `music` and `admin`
  - standalone/singleton services such as Karakeep where leaf ownership is retained
- Affected docs/specs:
  - repository architecture/navigation guidance
  - secret scope and recipient policy guidance
  - capability specs for fleet composition and feature topology
- Constraints honored:
  - keep plain flake architecture
  - preserve explicit blast-radius control via path-scoped recipient rules
  - keep private-first/Tailscale-first posture
  - perform a clean migration without long-lived backward-compatibility layers

## Context

Current admin composition separates route metadata (`policy/web-services.nix`) from service wiring (`modules/services/admin/**`) and already supports host-scoped SOPS templates for OIDC credentials. Homepage currently references multiple widget placeholders (Tailscale, Navidrome, slskd) but lacks a complete caller-owned machine-auth contract and template wiring for all required integrations.

The change spans multiple modules and secrets surfaces across hosts/services, so a design is needed to keep security boundaries explicit, preserve private-first transport assumptions, and avoid moving credential concerns into route policy.

## Goals / Non-Goals

**Goals:**
- Establish caller-owned machine-auth wiring for Homepage integrations using host-scoped secrets.
- Keep routing/access/health policy and caller integration auth concerns separate.
- Define deterministic auth method selection for each integration (token first, fallback only when needed).
- Preserve Tailscale as transport while still requiring app-level auth where supported.
- Keep implementation aligned with existing admin-services contracts and module boundaries.

**Non-Goals:**
- Reworking Cloudflare Access or human OIDC browser auth model.
- Introducing shared cross-service internal credentials.
- Implementing Filebrowser widget auth in this wave.
- Building full fleet-wide automation for all future callers in one step.

## Decisions

### Decision HB-1: Caller-owned integration auth inventory
Store integration auth contract adjacent to the caller (Homepage module scope), not in `policy/web-services.nix`.

**Rationale:** Route policy is canonical for exposure/origin/health. Mixing caller credentials into route policy increases coupling and secret blast radius.

**Alternatives considered:**
- Route-level auth metadata in policy: rejected (cross-concern coupling).
- Single global internal-auth registry: rejected for day-1 complexity and unclear ownership.

### Decision SECR-1: Host-scoped secrets + env template materialization
Add Homepage integration secrets under `hosts/do-admin-1/secrets.yaml` and expose via a dedicated SOPS template consumed by `services.homepage-dashboard.environmentFiles`.

**Rationale:** Matches existing repo secret/bootstrap patterns and blast-radius model; keeps values host-local.

**Alternatives considered:**
- `secrets/common.yaml`: rejected (unnecessary cross-host exposure).
- Inline literal values in module: rejected (non-secret-safe and non-rotatable).

### Decision AUTH-1: Integration auth precedence
Use precedence: explicit local-only no-auth exception -> native API token/key -> app machine account/client creds -> username/password fallback.

**Rationale:** Minimizes privilege while staying practical for apps with limited auth surfaces.

**Alternatives considered:**
- Single uniform credential type across all services: rejected (incompatible with app ecosystems and increases blast radius).

### Decision HB-2: Widget-specific handling
- Keep Caddy widget no-auth local exception (already operational on loopback).
- Keep Gatus widget URL-only/read-only posture for Homepage.
- Add Beszel widget with dedicated read-only account credentials.
- Keep Filebrowser auth out of scope now.

**Rationale:** Balances operational value with least-privilege and avoids forcing high-risk credentials where not needed.

### Decision OPS-1: Beszel bootstrap is declarative-plus-manual
Use one-time manual Beszel account bootstrap (read-only user + explicit system sharing), then persist credentials in host-scoped SOPS.

**Rationale:** Beszel account provisioning is app-level; this keeps Nix wiring declarative without pretending full lifecycle automation exists.

### Decision AGENT-1: Beszel agent auth is host-scoped and env-file injected
Beszel agent credentials (KEY/TOKEN and host-appropriate HUB_URL) are wired per host through host-scoped secrets/templates and injected via `services.beszel.agent.environmentFile`.

**Rationale:** Keeps machine credentials least-privilege and rotatable by host, avoids universal token blast-radius, and aligns with existing sops template patterns.

**Alternatives considered:**
- Single shared universal token for all hosts: rejected (high blast radius and weak auditability).
- Inline credentials in module config: rejected (non-secret-safe, poor rotation ergonomics).

## Risks / Trade-offs

- **[Risk] Beszel manual bootstrap drift** → Mitigation: document exact bootstrap steps in tasks; treat credentials as required host secret inputs.
- **[Risk] Credential sprawl in Homepage env** → Mitigation: only include integrations actively used by Homepage; no shared generic credential.
- **[Risk] Misplaced ownership between policy and caller files** → Mitigation: add/modify spec requirements that explicitly keep route policy focused on routing/access/health.
- **[Risk] Cross-host assumptions break under new hosts** → Mitigation: keep host-scoped secret model and avoid hardcoding hostnames outside existing policy resolution.

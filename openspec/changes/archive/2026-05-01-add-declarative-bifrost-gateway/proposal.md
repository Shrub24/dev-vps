## Why

The repo needs a durable AI gateway pattern that can serve multiple self-hosted applications through one OpenAI-compatible control point without letting mutable dashboard state become the real source of truth. We want Bifrost now because it supports file-driven `config.json` mode, publishes ARM-friendly container artifacts, and can route distinct text, image, embedding, and fallback model flows behind one canonical endpoint without forcing UI-managed control-plane state.

**Core Value:** Establish Bifrost as a first-class, declarative AI gateway whose canonical configuration is owned by this repo rather than by runtime Web UI state, while using an ARM-boring OCI runtime on `oci-melb-1`.

## What Changes

- Add a new repo-owned Bifrost service boundary that uses declarative OCI runtime wiring while keeping this repo’s host wiring, secrets, persistence, and rendered `config.json` as the authoritative control plane.
- Define a declarative baseline for Bifrost file-only mode (`config_store` disabled) so `config.json` is canonical and Web UI/config-store mutation is excluded from the baseline operating model.
- Add secret-handling contracts for provider API keys and related gateway credentials using host-scoped SOPS/env-file patterns rather than storing secrets in `config.json` or runtime database state.
- Define initial routing/model abstraction expectations so downstream apps can use one OpenAI-compatible endpoint while the gateway maps separate text, image/multimodal, embedding, and fallback policies underneath.
- Document persistence boundaries for canonical config versus mutable runtime data such as logs, caches, and optional vector/log stores.

## Capabilities

### New Capabilities
- `ai-gateway`: Provide a first-class declarative Bifrost gateway service for fleet-wide OpenAI-compatible routing, file-driven configuration, and provider/model abstraction.

### Modified Capabilities
- `secrets-management`: Add host-scoped AI gateway provider credential handling and env-file rendering rules for Bifrost.

## Impact

- **Affected code**: `flake.nix`, `hosts/<host>/default.nix`, new or updated `modules/services/` gateway module(s), host secret templates, and gateway-facing docs/policy helpers.
- **Dependencies**: Adds a pinned Bifrost container image/runtime path and supporting host-side config rendering under repo control.
- **Operational impact**: Introduces a reusable fleet AI control point that downstream apps can target through one OpenAI-compatible base URL while preserving repo-owned routing and secret policy.
- **Security impact**: Provider credentials remain outside committed `config.json`; runtime UI/config-store state is not allowed to become canonical baseline configuration.
- **Risk boundary**: This change establishes the declarative gateway foundation, not a full multi-tenant external developer platform or UI-managed governance workflow.

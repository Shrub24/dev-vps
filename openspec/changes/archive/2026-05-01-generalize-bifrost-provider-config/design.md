## Context

The current Bifrost baseline on `oci-melb-1` already proves the key operational posture: file-driven `config.json`, OCI runtime, host-scoped env-backed secrets, and one OpenAI-compatible endpoint for downstream consumers like Karakeep. What is still too narrow is the provider/model expression. Today the repo effectively treats the gateway as an OpenAI-only alias map, which makes future expansion awkward and mixes policy shape with one specific provider.

This change should generalize the config shape without destabilizing the working gateway. The important property is that apps keep one stable gateway URL and stable logical alias names, while the repo chooses which provider key and provider model back each alias. The config should also look as close as practical to the exact upstream `config.json` schema so operators can inspect and validate the final runtime artifact directly.

## Goals / Non-Goals

**Goals:**
- Generalize the repo-owned AI gateway policy shape so aliases and backing providers/models are explicit and extensible.
- Add concrete Google and DeepSeek provider credentials and Bifrost provider entries in the first wave.
- Preserve the existing downstream consumer contract: one OpenAI-compatible endpoint plus stable alias names.
- Keep provider secrets host-scoped and env-backed rather than moving them into committed config.

**Non-Goals:**
- Do not introduce UI/config-store mode for Bifrost.
- Do not redesign downstream apps to know about provider-specific endpoints.
- Do not add every possible provider now; only Google and DeepSeek are required in this wave.
- Do not move provider secrets into shared/common scope unless a later change explicitly requires it.

## Decisions

- **GP-1 (Generalized policy shape):** Represent AI gateway aliases and provider-backed upstream model IDs as a repo-owned structure that can express multiple providers cleanly instead of one OpenAI-only mapping.
  - **Rationale:** The repo should own the logical model contract exposed to apps, while provider choice remains an implementation detail behind the gateway.

- **GP-2 (Stable downstream contract):** Preserve the existing logical aliases (`text`, `image`, `embedding`, `fallback`) and keep apps targeting one gateway base URL.
  - **Rationale:** Downstream stability is more valuable than exposing provider churn into each app configuration.

- **GP-3 (Host-scoped provider credentials):** Render provider API keys for Bifrost through the host-scoped env file on `oci-melb-1`, adding Google and DeepSeek alongside the existing OpenAI key.
  - **Rationale:** This keeps blast radius local to the deployment host and matches the repo’s existing secrets model.

- **GP-4 (Concrete first-wave providers):** Add Google and DeepSeek provider entries now using documented provider names and conservative model IDs.
  - **Rationale:** This satisfies the immediate user request while validating the more general structure.

- **GP-5 (Schema-shaped config and dynamic aliases):** Represent the canonical gateway config as an exact upstream-shaped `config.json` attrset and express shared alias behavior through `governance.routing_rules` rather than provider-key-scoped alias hacks.
  - **Rationale:** This keeps the repo-owned source of truth visually aligned with upstream docs/schema and uses Bifrost's documented global aliasing model.

- **GP-6 (Restart on config/env change):** Restart the Bifrost OCI unit automatically when the rendered `config.json` content or provider env file changes.
  - **Rationale:** File-driven mode has no hot-reload contract; automatic restart is the idiomatic way to keep runtime aligned with rendered config and env changes.

- **GP-7 (Dedicated gateway policy file):** Keep the exact upstream-shaped Bifrost config in a dedicated literal `policy/bifrost-config.json` file rather than embedding the full attrset inline in broader globals.
  - **Rationale:** This keeps the final runtime artifact easier to inspect, validate, and evolve without burying upstream schema shape inside an unrelated globals file.

## Risks / Trade-offs

- **[R1] Provider schema drift** → **Mitigation:** keep the canonical config close to the documented upstream `config.json` shape, including `providers` and `governance.routing_rules`, so drift is visible in one place.
- **[R2] Alias churn can break downstream apps** → **Mitigation:** keep logical alias names stable and only change backing provider/model IDs behind them.
- **[R3] More providers increase secret/config surface** → **Mitigation:** keep additions host-scoped, env-backed, and narrowly documented.

## Migration Plan

1. Generalize the canonical AI gateway policy structure into an exact upstream-shaped literal `policy/bifrost-config.json` file.
2. Express shared alias behavior through `governance.routing_rules` while keeping provider keys free of static alias hacks.
3. Extend host secret templates and declarations for the provider API keys used by the exact config.
4. Restart the Bifrost OCI unit automatically when the literal config file or env inputs change.
5. Revalidate rendered config and confirm downstream consumer wiring still points at the same gateway URL and stable aliases.

## Open Questions

- Should future providers share the same alias set by fallback layering, or should the repo eventually expose named optional alias classes beyond the current four logical roles?

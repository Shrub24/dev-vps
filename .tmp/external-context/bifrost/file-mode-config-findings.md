---
source: official repo/docs
library: Bifrost
package: maximhq/bifrost
topic: file-mode config examples for alias routing
fetched: 2026-05-01T00:00:00Z
official_docs: https://github.com/maximhq/bifrost/blob/main/README.md
---

## Concrete findings

- `transports/config.schema.json` is the source of truth for `config.json` fields.
- Top-level config includes `providers` and `client`.
- Provider entries are keyed by provider name, e.g. `providers.openai`.
- Provider config supports `keys[]`, each with `name`, `value`, `models`, `blacklisted_models`, `weight`, `aliases`.
- `value` supports env-backed values via `env.<ENV_VAR_NAME>`.
- `fallbacks` exists as an array field on routing targets / request routing config.
- `models` / allow-list semantics: empty arrays deny all in v1.5+; `[*]` allows all.
- `aliases` is an object map of string→string.

## Minimal JSON shape (from schema fields)

```json
{
  "version": 2,
  "providers": {
    "openai": {
      "keys": [
        {
          "name": "openai-primary",
          "value": "env.OPENAI_API_KEY",
          "models": ["*"],
          "aliases": {
            "text": "gpt-4o-mini",
            "image": "gpt-4o",
            "embedding": "text-embedding-3-small"
          }
        }
      ]
    }
  }
}
```

## Relevant example/docs locations

- `README.md` — OpenAI-compatible API example using model names like `openai/gpt-4o-mini`.
- `AGENTS.md` — points to `transports/config.schema.json` as authoritative config schema.
- `transports/bifrost-http/lib/config.go` — config version/compat behavior.
- `transports/config.schema.json` — fields: `providers`, `keys`, `models`, `blacklisted_models`, `aliases`, `fallbacks`.

## Note on downstream clients

The repo documents Bifrost as a single OpenAI-compatible API. The concrete OpenAI-style client usage shown is model-based (`openai/gpt-4o-mini`); no repo snippet found proving a special alias exposure layer for Karakeep specifically.

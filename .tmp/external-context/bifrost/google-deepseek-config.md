---
source: Context7 API
library: Bifrost
package: bifrost
topic: google-deepseek-config
fetched: 2026-05-01T00:00:00Z
official_docs: https://github.com/maximhq/bifrost/blob/main/docs/deployment-guides/config-json/providers.mdx
---

# Bifrost config.json providers: Google and DeepSeek

## Relevant upstream facts
- All providers live under `providers` in `config.json`.
- Each provider has a `keys` array.
- Key objects support `name`, `value`, `models`, `weight`.
- Optional common fields include `aliases` and `use_for_batch_api`.
- `value` may reference env vars as `env.VAR_NAME`.
- `aliases` is attached per key, like OpenAI.

## Exact provider names
- `google`
- `deepseek`

## `providers.<name>.keys[]` shape
```json
{
  "name": "string",
  "value": "env.VAR_NAME",
  "models": ["*"],
  "weight": 1.0,
  "aliases": {
    "logical-model": "provider-model-id"
  }
}
```

## Required fields beyond the common set
- No provider-specific required fields were shown in the authoritative config-json provider docs for Google or DeepSeek.
- The docs only establish the common key shape above.

## Aliases
- Yes, aliases are attached per key the same way as OpenAI.
- The alias map lives inside the individual key object.

## Minimal examples
### Google
```json
{
  "providers": {
    "google": {
      "keys": [
        {
          "name": "google-main",
          "value": "env.GOOGLE_API_KEY",
          "models": ["*"],
          "weight": 1.0
        }
      ]
    }
  }
}
```

### DeepSeek
```json
{
  "providers": {
    "deepseek": {
      "keys": [
        {
          "name": "deepseek-main",
          "value": "env.DEEPSEEK_API_KEY",
          "models": ["*"],
          "weight": 1.0
        }
      ]
    }
  }
}
```

## Notes on env.*
- Bifrost examples consistently use `env.OPENAI_API_KEY`-style indirection for secrets.
- For Google and DeepSeek, the exact env names above follow the same pattern.
- No upstream example in the fetched docs showed a different secret reference syntax.

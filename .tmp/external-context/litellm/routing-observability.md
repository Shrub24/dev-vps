---
source: Context7 API + official docs
library: LiteLLM
package: litellm
topic: routing observability features
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.litellm.ai/docs/simple_proxy
---

## Minimal routing pattern
Use `model_list` aliases to present one OpenAI-compatible endpoint and map each alias to a backend provider/model.

Example shape:
```yaml
model_list:
  - model_name: text-model
    litellm_params:
      model: openai/gpt-4o-mini
      api_key: os.environ/OPENAI_API_KEY
  - model_name: image-model
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
```

Then clients call `/chat/completions` with the alias (`text-model` or `image-model`).

## Text vs image/multimodal routing
- LiteLLM does not appear to provide content-type auto-routing in the proxy config alone.
- Minimal deployment is typically done by exposing two aliases and choosing them in the client/app.
- If you want automatic routing, look at router/load-balancing features or custom logic upstream; the docs fetched here don’t show built-in content-based dispatch in proxy config.

## Out-of-the-box controls/features
- OpenAI-compatible endpoint
- Virtual keys / auth
- Spend tracking and budgets
- Rate limits (RPM/TPM/max parallel requests)
- Router retries / fallback / cooldown / load balancing
- Caching
- Guardrails / policies
- Logging, alerting, metrics
- A/B traffic mirroring
- Admin UI
- MCP and A2A gateway support

## Database-backed features
- Key generation, users, teams, spend tracking, and UI are tied to `database_url`.
- `master_key` can be set in config or env.

## Relevant links
- Routing: https://docs.litellm.ai/docs/routing-load-balancing
- Spend tracking: https://docs.litellm.ai/docs/proxy/cost_tracking
- Budgets/rate limits: https://docs.litellm.ai/docs/proxy/users
- Logging/metrics: https://docs.litellm.ai/docs/proxy/dynamic_logging

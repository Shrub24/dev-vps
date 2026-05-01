---
source: Context7 API + official docs
library: LiteLLM
package: litellm
topic: deployment model
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.litellm.ai/docs/simple_proxy
---

## Deployment model
- LiteLLM Proxy is a centralized, OpenAI-compatible AI gateway.
- Run it as a Python package (`litellm[proxy]`), via the `litellm` CLI, or in Docker/container images.
- Proxy config is YAML-based (`config.yaml`), with environment variables for secrets and provider credentials.
- Start form: `litellm --config config.yaml --port 4000` or Docker `... --config /app/config.yaml`.

## Container notes
- Official container images are published in BerriAI GitHub Packages / GHCR.
- Stable Docker tags are recommended by the project.
- Separate images exist for proxy/database and non-root variants.

## Config format
- Primary config is YAML.
- Common sections: `model_list`, `router_settings`, `general_settings`, `litellm_settings`, `mcp_servers`.
- Environment variables are referenced in YAML with `os.environ/...`.

## Persistence
- Stateless operation is possible for basic proxying if you only need model routing.
- For keys, users/teams, spend tracking, and UI, a Postgres database is expected via `general_settings.database_url`.
- Docs indicate DB-backed features depend on `database_url`; without it, the proxy can run but with reduced management features.

## ARM64 status
- Docker package listing is available, but the fetched docs here did not explicitly confirm architecture matrix.
- Treat ARM64 support as likely via GHCR multi-arch images, but verify the specific tag manifest before production use.

## Relevant links
- Docs: https://docs.litellm.ai/docs/simple_proxy
- Docker quickstart: https://docs.litellm.ai/docs/proxy/docker_quick_start
- GitHub packages: https://github.com/orgs/BerriAI/packages?repo_name=litellm

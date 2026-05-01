---
source: Context7 API + official docs
library: Bifrost
package: bifrost
topic: ai-gateway-proxy-summary
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.getbifrost.ai
---

## What it is
- Bifrost is an AI gateway/proxy that exposes a single OpenAI-compatible HTTP API over 20+ providers.
- Official docs: https://docs.getbifrost.ai
- Source/repo referenced in docs: https://github.com/maximhq/bifrost

## Deployment model
- Runs as an HTTP gateway via `npx @maximhq/bifrost` or Docker.
- Docker images include versioned tags and architecture tags like `v1.3.9-amd64` and `v1.3.9-arm64`.
- Config modes: Web UI or `config.json`.
- Persistence: app-dir holds `config.json`, `config.db` (SQLite for UI config), and `logs.db`.
- Optional PostgreSQL for config store and logs store; docs require UTF8 DB encoding and PostgreSQL 16+ for those paths.

## OpenAI-compatible / Karakeep fit
- Yes: `/v1/chat/completions`, `/v1/responses`, `/v1/embeddings`, `/v1/audio/*`, `/v1/images/*`, `/v1/models` are supported.
- Docs explicitly describe Bifrost as a drop-in replacement via only changing `base_url`.

## Routing / multimodal
- Supports model/provider routing via virtual keys, weights, allowed model lists, provider API-key restrictions, and automatic fallbacks.
- Cross-provider routing is not automatic for arbitrary model names; model/provider allow-lists control it.
- OpenAI schema covers text, images, audio, embeddings, speech, image generation/edit/variation, batch, and video.

## ARM64 status
- Docs show arm64 image tags for Docker.
- Docs and supported providers mention ARM64 support for core gateway usage.

## Features
- Observability: request logs/traces, metrics, Prometheus, OpenTelemetry.
- Auth/governance: virtual keys, key restrictions, required headers, RBAC/enterprise auth.
- Budgets/rate limits: hierarchical budgets and request/token limits.
- Fallback/load balancing: automatic fallback chains and weighted provider balancing.
- Caching: semantic caching plus direct hash mode.
- Provider abstraction: unified provider config and OpenAI-compatible protocol adapter.
- Key management: provider API keys, weighted key distribution, key allow-lists, tagged usage.

## Caveats for self-hosting
- SQLite is simplest; PostgreSQL adds operational overhead and strict UTF8/permission requirements.
- UI/config-store modes have bootstrap rules: with existing DB, config.json may be ignored.
- Direct cross-provider model-name routing is constrained by explicit allowed_models and provider catalogs.
- Semantic caching requires a vector store; direct hash mode has different storage constraints.
- Enterprise features may be absent from OSS/self-hosted baseline.

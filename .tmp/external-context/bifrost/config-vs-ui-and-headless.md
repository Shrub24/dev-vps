---
source: Context7 API + official docs
library: Bifrost
package: bifrost
topic: config-vs-ui-and-headless
fetched: 2026-05-01T00:00:00Z
official_docs: https://github.com/maximhq/bifrost/blob/main/docs/deployment-guides/config-json.mdx
---

## Findings
- `config.json` is **not universally feature-complete** vs the Web UI. Docs say file-only mode loads config at startup and disables the UI, while UI mode enables real-time config, logs viewing, governance/admin workflows, etc. Docs also say some items are UI-only operationally (for example, logs shown in UI) and that with `config_store` enabled, config.json is only used to bootstrap an existing DB or seed an empty DB.
- Bifrost **can run headless / UI-less**: set `config_store.enabled=false` (or omit `config_store`) to use file-only mode. This is explicitly described as “no database, no Web UI”, “read-only mode”, and “restart required”.
- Mutable state in normal operation:
  - `config_store`: required for UI / mutable runtime config; SQLite or PostgreSQL. Holds provider configs, API keys, governance/virtual keys, MCP settings.
  - `logs_store`: optional; request/response logs (UI-visible), SQLite/Postgres, optional object storage offload.
  - `vector_store`: optional unless using semantic caching.
  - `config.json`: canonical file in file-only mode; not mutated by Bifrost.
- Official knobs supporting config-driven operation:
  - `config_store.enabled=false` for file-only mode.
  - `-app-dir` / Docker volume controls where `config.json`, `config.db`, `logs.db` live.
  - No official docs found for a dedicated “disable UI” env var/CLI flag beyond the config-store mode switch; UI disabling is achieved by file-only mode.
- Cleanest NixOS + Git + SOPS model from docs: **file-only mode with shared `config.json` as source of truth**, secrets referenced via `env.*`, and host/runtime state minimized by keeping `config_store` disabled and optionally disabling `logs_store`/`vector_store` unless needed.

## Relevant upstream locations
- `docs/deployment-guides/config-json.mdx` — two mutually exclusive modes, GitOps/headless positioning, examples.
- `docs/deployment-guides/config-json/storage.mdx` — config/log/vector stores, file-only mode, required vs optional stores.
- `docs/quickstart/gateway/setting-up.mdx` — app-dir contents, UI behavior, file-only mode caveats.
- Example refs: `examples/configs/noconfigstorenologstore/config.json`, `examples/configs/withconfigstore/config.json`, `examples/configs/withlogstore/config.json`, `examples/configs/withobjectstorages3/config.json`.

## Concise answer
1. **No**: some features remain UI/database-centric; file-only mode is narrower and restart-based.
2. **Yes**: `config_store.enabled=false` gives a headless, file-driven mode.
3. **State**: config DB, logs DB, vector store; config DB is required for UI, logs/vector are optional depending on features.
4. **Main supported switch**: `config_store.enabled=false`; no separate disable-UI env/flag documented.
5. **Best fit for NixOS+Git+SOPS**: shared `config.json` + env-based secret injection + file-only mode, with other stores only if a feature demands them.

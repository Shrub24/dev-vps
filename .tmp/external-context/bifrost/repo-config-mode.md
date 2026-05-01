---
source: mixed (upstream README/docs + GitHub code search)
library: bifrost
package: maximhq/bifrost
topic: repo-config-mode
fetched: 2026-05-01T00:00:00Z
official_docs: https://github.com/maximhq/bifrost
---

## Findings

- **`config.json` is first-class and documented as canonical in file-based mode.**
  - `README.md` says Bifrost supports “web UI, API-driven, or file-based configuration options”.
  - `docs/deployment-guides/config-json.mdx` says `config.json` is a single declarative file for GitOps/headless/multinode OSS and that file mode disables the UI and requires restart for changes.
  - `docs/deployment-guides/how-to/multinode.mdx` says OSS multinode should use shared `config.json` without `config_store`, and that shared file is the single source of truth.

- **UI-less / API-only runtime is documented, but only in file-based mode.**
  - `docs/deployment-guides/config-json.mdx` explicitly marks UI disabled when `config_store` is disabled and `config.json` is present.
  - `README.md` emphasizes a built-in web UI for configuration/monitoring by default, so UI-less operation is a supported mode, not the default.

- **The flake/module mainly packages and wires the HTTP runtime.**
  - `flake.nix` exposes `packages.bifrost-http`, `apps.bifrost-http`, and `nixosModules.bifrost`.
  - `nixosModules.bifrost` imports `./nix/modules/bifrost.nix` and sets `services.bifrost.package` to the HTTP package by default.
  - So the Nix module appears to manage service packaging/activation, not application config semantics.

- **Runtime state is hybrid: file config + mutable DB when config store/UI is enabled.**
  - `transports/bifrost-http/lib/config.go` defines `ConfigData` loaded from `config.json` and includes `config_store` / `logs_store` pieces.
  - `framework/configstore/*` and tests show reconciliation between `config.json` and DB via `ConfigHash`; code comments say file changes override DB values for defined items, while DB-only items from the dashboard are preserved.
  - This means the UI can mutate sqlite/postgres-backed config state, and that DB state becomes authoritative for UI-managed objects when `config_store` is enabled.

- **Logs/metrics are clearly runtime/mutable state, not canonical config.**
  - `framework/logstore/*` stores logs in SQLite/Postgres.
  - Observability/logging data is persisted separately from config, and config schema distinguishes `config_store` vs `logs_store`.

## Practical read

- **Yes:** file-based config can be treated as canonical **when you run file mode** (`config_store` disabled).
- **No:** if UI/config-store mode is enabled, the UI/API can mutate DB-backed state and that state is part of the real runtime source of truth.
- **Best Nix-friendly shape:** use `config.json` as the declarative artifact, keep logs/metrics DBs mutable, and avoid UI-managed config if you want strict GitOps behavior.

## Specific references

- `README.md` — configuration flexibility, UI, API, file-based modes
- `docs/deployment-guides/config-json.mdx` — two mutually exclusive modes; file-based mode disables UI
- `docs/deployment-guides/how-to/multinode.mdx` — OSS multinode uses shared `config.json` as source of truth
- `flake.nix` — `nixosModules.bifrost`, `packages.bifrost-http`, `apps.bifrost-http`
- `transports/bifrost-http/lib/config.go` — `ConfigData` / `config.json` schema
- `framework/configstore/*` — config hash reconciliation and DB-backed mutable config store
- `framework/logstore/*` — SQLite/Postgres runtime log storage

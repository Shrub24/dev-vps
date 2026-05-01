---
source: Context7 + official docs
url: https://filebrowserquantum.com/
topic: FileBrowser Quantum in NixOS
fetched: 2026-04-23T00:00:00Z
---

- Likely package: `FileBrowser Quantum` (upstream repo `gtsteffaniak/filebrowser`); Nixpkgs issue #419143 requests packaging it.
- NixOS package/service name is not yet confirmed from docs in the local search results; current NixOS FileBrowser module is `services.filebrowser`.
- Quantum config shape is YAML under `server:` (not the old CLI-flag style):
  - `server.port`
  - `server.listen`
  - `server.baseURL`
  - `server.socket` (Unix socket; overrides TCP port)
  - `server.sources`
  - `server.database`
  - `server.cacheDir`
  - `server.disableWebDAV`
- Listen/address options:
  - default listen address: `0.0.0.0`
  - set via `server.listen`
  - port via `server.port` (default `80`)
  - Unix socket via `server.socket`
  - base path via `server.baseURL` for reverse proxy deployments
- Source/path model differs from original FileBrowser:
  - `server.sources` is mandatory
  - each source has `path`, optional `name`, and `config.*` controls like `defaultEnabled`, `defaultUserScope`, `createUserDir`, `denyByDefault`, `private`, `disabled`, `useLogicalSize`, `rules`
  - docs warn sources should not be root `/` or include `/var` on Linux
- Migration-relevant differences from `services.filebrowser`:
  - original NixOS module exposes `services.filebrowser.settings.address`, `.port`, `.root`, `.database`, `.cache-dir`
  - Quantum uses YAML config with `listen`, `baseURL`, `sources`, and `cacheDir`
  - migration guide says original flags map as: `--port`→`server.port`, `--address`→`server.address`/listen, `--baseurl`→`server.baseURL`, `--database`→`server.database`, `--root`→`server.sources[0].path`
  - removed features include terminal, runners, and command-line user management

References:
- https://github.com/NixOS/nixpkgs/issues/419143
- https://filebrowserquantum.com/en/docs/configuration/server/
- https://filebrowserquantum.com/en/docs/getting-started/migration/configuration/
- https://filebrowserquantum.com/en/docs/configuration/sources/
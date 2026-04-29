---
source: Context7 API
library: Cockpit
package: cockpit
topic: webservice proxy reverse proxy websocket disconnects
fetched: 2026-04-24T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/blob/main/doc/man/pages/cockpit.conf.5.adoc
---

## Relevant Cockpit guidance

- `cockpit.conf` `[WebService]`:
  - `Origins = https://cockpit.domain.tld wss://cockpit.domain.tld`
  - `ProtocolHeader = X-Forwarded-Proto`
  - `ForwardedForHeader = X-Forwarded-For`
  - `UrlRoot=/secret` when Cockpit is served from a subdirectory
- For reverse proxies, Cockpit must be proxy-aware and restarted after config changes.
- WebSocket proxying must preserve upgrade semantics (`Connection: upgrade`, HTTP/1.1, `Upgrade` header).

## Caveat

- If browser access shows `Connection failed` / `wss /cockpit/socket closed`, confirm the proxy sends the right forwarded protocol/origin headers and that Cockpit's `Origins` includes the exact public scheme/host.

## Source notes

- `cockpit.conf(5)` `WebService` options: `Origins`, `ProtocolHeader`, `ForwardedForHeader`.
- Proxying guidance is documented in Cockpit's proxy wiki page and mirrored by `cockpit.conf(5)` references.

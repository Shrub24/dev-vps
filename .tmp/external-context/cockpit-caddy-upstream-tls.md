---
source: Context7 API + official docs
library: Cockpit / Caddy / NixOS
package: cockpit-caddy-upstream-tls
topic: local reverse proxy upstream TLS
fetched: 2026-04-28T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/wiki/Proxying-Cockpit-over-NGINX | https://caddyserver.com/docs/caddyfile/directives/reverse_proxy | https://search.nixos.org/options?query=services.cockpit
---

## Cockpit upstream TLS
- Cockpit’s proxy guidance shows the frontend proxying to `https://127.0.0.1:9090` and configuring `WebService.Origins` plus `ProtocolHeader = X-Forwarded-Proto`.
- NixOS exposes `services.cockpit.settings` and `services.cockpit.allowed-origins`, which map to Cockpit’s INI settings.
- NixOS Cockpit options include `services.cockpit.port`; the docs do not indicate that Cockpit should obtain or manage an ACME/public cert for a loopback-only listener.

## Caddy upstream trust
- Caddy recommends explicit trust for HTTPS upstreams using `transport http { tls_trust_pool file /path/to/cert.pem; tls_server_name ... }`.
- Caddy documents `tls_insecure_skip_verify` as insecure and only for testing/local development.
- Caddy’s local HTTPS behavior uses its internal CA for local site certificates, but that is about client-facing certs, not upstream trust.

## Practical implication
- For a same-host Caddy -> Cockpit setup, the modern secure pattern is to keep Cockpit on localhost with its own local cert and have Caddy trust that cert/CA explicitly.
- Avoid route-scoped `tls_insecure_skip_verify` as a long-term setting.
- If upstream TLS is unnecessary, the simplest alternative is to run Cockpit plain HTTP on localhost and let Caddy terminate external TLS.

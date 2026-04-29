---
source: mixed (Cockpit docs + GitHub issue)
library: Cockpit
package: cockpit
topic: reverse proxy subpath EOF / UrlRoot
fetched: 2026-04-28T00:00:00Z
official_docs: https://cockpit-project.org/guide/latest/cockpit.conf.5.html
---

## Actionable findings

- **Cockpit must be configured with `UrlRoot` for subpath deployments.** It expects every request to be prefixed by that path; `/cockpit/` and `/cockpit+` are reserved.
- **A missing trailing slash on the proxy URL is a concrete crash trigger** in the reported issue. Accessing `/cockpit/server1` (no trailing `/`) caused `cockpit-ws` to abort with an assertion on `request->path[0]`.
- **`ProtocolHeader = X-Forwarded-Proto` is a documented reverse-proxy requirement** when Cockpit is behind TLS-terminating proxy.
- **`Origins` must include the external scheme/host** used by the proxy for HTTP/WebSocket connections.
- **Subpath forwarding should preserve the full prefixed path to Cockpit.** The concrete issue report says the proxy-side fix was to add `/` on the login URL; do not rewrite away the root prefix unless Cockpit is explicitly configured for the resulting path.
- **WebSocket/proxy upgrade handling is required.** Cockpit uses WebSockets for sessions; proxy configs must support upgrade flow end-to-end.

## Most credible proxy-side fixes for Caddy-like setups

1. **Proxy the exact subpath and keep the trailing slash on user-facing URLs** (`/cockpit/server1/` not `/cockpit/server1`).
2. **Forward `Host` and `X-Forwarded-Proto` unchanged/accurately.**
3. **Use HTTP/1.1 to the upstream and allow websocket upgrade.**
4. **Do not strip the subpath unless Cockpit `UrlRoot` matches the stripped path.**
5. **If TLS terminates at the proxy, upstream protocol can be plain HTTP; Cockpit only needs the forwarded proto header to know the original scheme.**

## What is clearly documented vs inferred

- **Documented:** `UrlRoot`, `ProtocolHeader`, `ForwardedForHeader`, `Origins`.
- **Observed in issue:** missing trailing slash on a subpath URL can crash `cockpit-ws`.
- **Common proxy requirement for Cockpit WS:** HTTP/1.1 + websocket upgrade support.

## Source pointers

- Official docs: https://cockpit-project.org/guide/latest/cockpit.conf.5.html
- Issue: https://github.com/cockpit-project/cockpit/issues/22662

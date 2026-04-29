---
source: Context7 API
library: Cockpit
package: cockpit
topic: reverse proxy websocket origin
fetched: 2026-04-24T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/blob/main/doc/man/pages/cockpit.conf.5.adoc
---

## Why "Connection failed" happens
Cockpit blocks cross-domain websocket connections by default. Behind a reverse proxy or custom domain, the browser origin must match Cockpit's allowed Origins list, and the proxy must forward websocket upgrade requests correctly.

## Origin checks
- `Origins` defines allowed cross-domain websocket connections.
- Include **scheme, host, and port**.
- Wildcards/glob expressions are allowed.
- IPv6 brackets must be escaped.

Example:
```ini
[WebService]
Origins = https://somedomain1.com https://somedomain2.com:9090 https://*.somedomain3.com https://\[::1\]:9090
```

Proxy/custom-domain example:
```ini
[WebService]
Origins = https://cockpit.domain.tld wss://cockpit.domain.tld
ProtocolHeader = X-Forwarded-Proto
```

## Websocket / proxy requirements
Nginx example:
```nginx
location / {
    proxy_pass https://127.0.0.1:9090;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_buffering off;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

Key requirements:
- `proxy_http_version 1.1`
- `Upgrade` + `Connection: upgrade`
- `Host` forwarded
- `X-Forwarded-Proto` forwarded when TLS is terminated at the proxy

## URL base path
If Cockpit is served from a subdirectory, set:
```ini
UrlRoot=/secret
```
This affects URL generation and websocket paths.

## TLS termination
Use:
```ini
ProtocolHeader = X-Forwarded-Proto
```
Cockpit can then tell whether the original request was HTTPS.
Related caution: only trust these headers if the proxy path cannot be spoofed.

## Service account / permissions implications
Cockpit's browser UI uses the connected account's permissions. If the user account lacks admin rights, some actions fail even when the websocket is healthy. For remote admin use, connect with an account permitted for the desired operations.

## Short excerpts
- "Defines allowed cross-domain websocket connections."
- "By default, cross-domain connections are blocked."
- "When deployed behind a reverse proxy, you can use ProtocolHeader ... to determine if a connection is using TLS."
- "serving from a subdirectory ... set the UrlRoot"
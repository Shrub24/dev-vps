---
source: webfetch
topic: mobile-access-posture
fetched: 2026-05-01
---

## Mobile/API access posture behind Cloudflare

- Cloudflare Access is browser-cookie centric (`CF_Authorization`) and can block requests that lack the cookie, so it is usually a poor fit for native/mobile app auth flows.
- For apps that have both browser UI and mobile/API clients, app-native auth is generally better than trying to carve out partial API path bypasses.
- If Access is used at all, keep it for the browser-only surface; do not make mobile clients depend on browser session cookies.
- Cloudflare still provides value without Access: proxied DNS, DDoS hiding, WAF/custom rules, rate limiting, Authenticated Origin Pulls, and origin IP protection via Tunnel or Cloudflare IP allowlisting.
- For origin protection, pair proxied DNS with Full (strict) TLS and Authenticated Origin Pulls when possible.

## Practical default

Use a single app-native auth model for the whole app/API surface, then put Cloudflare in front for network protection and abuse controls rather than primary login enforcement.

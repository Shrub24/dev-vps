## Context

`oci-melb-1` already runs Syncthing successfully, and the repository already models admin/browser routes through `policy/web-services.nix` plus shared edge-ingress rendering. Today the Syncthing GUI remains loopback-bound at `127.0.0.1:8384`, which is operationally safe but inconvenient for browser access. The repo already has a proven path-based admin route pattern for Cockpit (`/do-admin-1`, `/oci-melb-1`), and Syncthing’s own reverse-proxy guidance supports serving the GUI behind a subpath while proxying to localhost.

## Goals / Non-Goals

**Goals:**
- Add a private-first path-based routing pattern for Syncthing UIs under `syncthing.shrublab.xyz`.
- Keep each host’s Syncthing GUI loopback-bound rather than exposing it on `0.0.0.0`.
- Reuse existing policy/edge-ingress composition so future Syncthing hosts can be added declaratively.
- Preserve a clean operator surface for Homepage/admin links.

**Non-Goals:**
- Introduce a fleet dashboard such as Homepage widgets or `sm2` in this change.
- Make Syncthing publicly reachable without existing access controls.
- Rework broader edge-ingress architecture beyond what is needed for Syncthing subpath support.

## Decisions

### Decision D1 — Use shared-host subpaths instead of per-host subdomains
- **Choice:** Model Syncthing browser entrypoints as path-based routes such as `/oci-melb-1/` under `syncthing.shrublab.xyz`.
- **Why:** Cloudflare free-plan constraints make nested subdomains undesirable, and the repo already supports path-based admin routes.
- **Alternative considered:** Per-host subdomains were cleaner in isolation, but they do not fit the current DNS/edge constraints.

### Decision D2 — Bind Syncthing to a private-network-reachable address and keep exposure Tailscale-only
- **Choice:** Bind Syncthing to a non-loopback address reachable over the host's private network posture so the edge can proxy to it directly over Tailscale.
- **Why:** This keeps the runtime simple, matches the fleet's non-edge Tailscale-only exposure model, and avoids adding an extra proxy hop solely to preserve loopback binding.
- **Alternative considered:** Keeping Syncthing on `127.0.0.1:8384` with a host-local proxy hop would work, but it adds moving parts without a clear benefit under the current fleet posture.

### Decision D3 — Use path-prefix stripping in the proxy layer
- **Choice:** Route Syncthing subpaths through the existing ingress model using prefix stripping before proxying upstream.
- **Why:** Syncthing’s documented reverse-proxy pattern handles subpaths in the proxy, and the repo already has `stripPrefix` support in edge-ingress rendering.
- **Alternative considered:** Adding host-local rewrite glue or moving Syncthing to dedicated per-host hostnames would add complexity without solving a current repo constraint.

### Decision D4 — Keep the change focused on access wiring, not dashboards
- **Choice:** Implement only native Syncthing UI access in this change.
- **Why:** We need reliable host admin access first; dashboards can layer on later once the canonical route shape exists.
- **Alternative considered:** Adding `sm2` or Homepage at the same time would mix UI aggregation with lower-level access plumbing.

## Risks / Trade-offs

- **[Risk]** Syncthing may behave differently behind stripped subpaths than other admin apps. → **Mitigation:** validate with the native UI, API requests, and redirects using the repo’s existing path-route pattern plus official Syncthing proxy guidance.
- **[Risk]** Shared-host route ordering could cause path collisions. → **Mitigation:** keep host-specific paths explicit and rely on the ingress renderer’s longest-path-first ordering.
- **[Risk]** Future multi-host Syncthing additions may duplicate manual route wiring. → **Mitigation:** capture the route pattern in specs/tasks now so later hosts follow the same structure.
- **[Risk]** Homepage/admin links may still point at the old root route. → **Mitigation:** update consuming links as part of the implementation tasks.

## Migration Plan

1. Add canonical route/spec requirements for shared-host Syncthing subpaths.
2. Update policy/runtime wiring so `syncthing.shrublab.xyz/<host>/` resolves to the correct private upstream.
3. Keep Syncthing exposure private to the tailnet-facing origin path; do not introduce direct public ingress.
4. Validate generated route metadata, ingress rendering, and resolved public URLs.
5. Deploy to the edge/admin host and verify browser access plus API/UI behavior through the proxy.

## Open Questions

- Whether `do-admin-1` should get a concrete Syncthing host route in this first implementation or whether the change should scaffold the pattern with `oci-melb-1` first.
- Whether upstream `Host` header handling for Syncthing should remain on the generic ingress default or be made explicitly route-specific during implementation.

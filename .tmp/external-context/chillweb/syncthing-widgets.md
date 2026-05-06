---
source: Official docs page
library: Homepage / Syncthing Widgets
package: chillweb
topic: syncthing-widgets
fetched: 2026-05-06T00:00:00Z
official_docs: https://www.chillweb.net/homepage/syncthing_widgets
---

## What it provides
- A custom Homepage `customapi` widget setup for Syncthing.
- Shows basic Syncthing summary stats from `/rest/svc/report`: stored MB, folders, files, devices.
- Shows recent Syncthing errors from `/rest/system/error` as a dynamic list.

## Multi-host / multi-instance support
- The example is written for one Syncthing endpoint (`http://192.0.2.0:8384`).
- No explicit multi-host or multi-instance abstraction is shown.
- Likely supports multiple instances only by defining multiple widget entries manually.

## API / auth requirements
- Needs Syncthing REST API access.
- Uses `X-API-Key` header with a Homepage secret variable.
- Assumes Homepage can reach the Syncthing API endpoint directly on the network.
- Example uses plain HTTP to port 8384.

## Replacement vs dashboard
- It is a dashboard summary only.
- Not a replacement for the Syncthing Web UI.
- The Syncthing UI is still needed for detailed device/folder management and troubleshooting.

## Fit for this repo
- Good fit later if you want lightweight Syncthing status tiles inside Homepage.
- Probably requires a per-host Syncthing API secret and reachable endpoint for each instance.
- If Syncthing UIs are already exposed via subpaths/Tailscale, this widget is still separate: it polls REST API, not the web UI.

## Risks / limitations
- Single-endpoint example; multi-host setup is manual.
- Exposes REST API usage, so secret handling matters.
- Basic stats only; error list is limited.
- Assumes Homepage can reach the Syncthing API directly.
- Plain HTTP in the example may be unsuitable depending on your network posture.

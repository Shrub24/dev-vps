---
source: Context7 API
library: Cockpit
package: cockpit
topic: socket activation remote hosts ssh tailscale
fetched: 2026-04-24T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/blob/main/doc/guide/pages/listen.adoc
---

## Relevant Cockpit guidance

- Cockpit runs via systemd socket activation (`cockpit.socket`), starting `cockpit-ws` on demand.
- When changing listen ports/addresses, use a systemd drop-in under `/etc/systemd/system/cockpit.socket.d/`.
- An empty `ListenStream=` resets the default listening port before setting a new one.
- After socket config changes, reload systemd and restart `cockpit.socket`.

## Remote host behavior

- Cockpit can manage multiple hosts in one browser session by SSH.
- Remote hosts are separate SSH-managed systems within the same Cockpit UI; this is normal and expected.
- If all hosts are added as remote hosts, Cockpit still connects per-host over SSH rather than merging them into one machine identity.

## Caveat

- Remote host management depends on SSH reachability; Tailscale is a good private transport, but Cockpit still expects working SSH auth and host connectivity.

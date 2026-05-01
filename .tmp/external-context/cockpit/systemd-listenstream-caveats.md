---
source: Context7 API
library: systemd
package: systemd
topic: listenstream caveats
fetched: 2026-04-23T00:00:00Z
official_docs: https://github.com/systemd/systemd/blob/main/docs/NETWORK_ONLINE.md
---

## systemd socket caveats
- `ListenStream=` belongs to the socket unit, not the service unit.
- If you want a specific address, `FreeBind=yes` may be needed.
- systemd supports listening on `0.0.0.0`, `127.0.0.1`, `[::]`, and `[::1]` reliably.

## Relevant binding guidance
- For servers, bind to catch-all / loopback addresses when possible.
- For explicitly configured addresses, use `FreeBind=` to avoid failures when the address is absent or not yet configured.

## Verification
```bash
systemctl cat cockpit.socket
systemctl show cockpit.socket -p Listen -p FreeBind -p ActiveState
journalctl -u cockpit.socket -u cockpit.service -b
ss -ltnp '( sport = :9090 )'
```

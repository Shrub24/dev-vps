---
source: Context7 API
library: Cockpit
package: cockpit
topic: socket activation
fetched: 2026-04-23T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/blob/main/doc/guide/pages/listen.adoc
---

## Cockpit on systemd
- Cockpit is socket-activated on systemd via `cockpit.socket`.
- `cockpit.socket` listens on the TCP port and activates `cockpit.service`.
- `cockpit.service` starts `cockpit-tls`; it does not own the external listener.

## Listening override pattern
Use a drop-in under `/etc/systemd/system/cockpit.socket.d/`.

```ini
[Socket]
ListenStream=
ListenStream=127.0.0.1:9090
```

For binding to a specific non-local address, Cockpit recommends `FreeBind=yes`.

```ini
[Socket]
ListenStream=
ListenStream=192.168.1.1:9090
FreeBind=yes
```

## Reload
```bash
sudo systemctl daemon-reload
sudo systemctl restart cockpit.socket
```

## Structure
- `cockpit.socket` accepts the connection.
- `cockpit.service` launches `cockpit-tls`.
- `cockpit-tls` dispatches to `cockpit-ws` / websocket instance sockets.

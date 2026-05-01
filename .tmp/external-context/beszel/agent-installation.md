---
source: Official docs
library: Beszel
package: beszel
topic: agent-installation
fetched: 2026-04-21T00:00:00Z
official_docs: https://beszel.dev/guide/agent-installation
---

## Required variables

- `KEY`: The public key shown when adding a system in the Hub.
- `TOKEN`: Used to authenticate the agent (see `/settings/tokens`).
- `HUB_URL`: Used for outgoing WebSocket connection (not required for SSH connection).

## Using the Hub

- The `docker-compose.yml` or binary install command is provided for copy/paste in the hub's web UI.
- Click **Add System** to manually configure the agent, or use a universal token (`/settings/tokens`) to connect the agent without needing to set it up ahead of time.

## Binary install / manual start

- `-k`: Public key (enclose in quotes; interactive if not provided)
- `-t`: Token (optional for backwards compatibility)
- `-url`: Hub URL (optional for backwards compatibility)

Example:

```bash
./beszel-agent -key "<public key>" -token "<token>" -url "<hub url>"
```

## SSH vs WebSocket

- `HUB_URL` is not required for SSH connection.

## Local agent note

- Update `KEY` and `TOKEN`, then restart the agent.
- Use the unix socket path as the Host / IP in the web UI.
- Note: As of 0.12.0, you can also use a universal token (`/settings/tokens`) to connect the agent to the hub without needing to configure it ahead of time.

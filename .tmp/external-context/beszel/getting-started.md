---
source: Official docs
library: Beszel
package: beszel
topic: getting-started
fetched: 2026-04-21T00:00:00Z
official_docs: https://beszel.dev/guide/getting-started
---

## Add System workflow

- Click **Add System** in the hub web UI.
- The system creation dialog provides the command/config to copy.
- For remote agents, copy the `docker-compose.yml` content or binary install command from the dialog.
- After the agent is running, click **Add System** and the new system should appear in the table.
- If it flips to green, it is connected.
- As of 0.12.0, you can also use a universal token (`/settings/tokens`) to connect the agent to the hub without needing to configure it ahead of time.

## Local agent example

- Set `KEY` and `TOKEN`, then restart the agent.
- Use `/beszel_socket/beszel.sock` as the Host / IP in the web UI.

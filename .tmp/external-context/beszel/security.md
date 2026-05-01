---
source: Official docs
library: Beszel
package: beszel
topic: security
fetched: 2026-04-21T00:00:00Z
official_docs: https://beszel.dev/guide/security
---

## SSH connection

- The SSH connection is initiated by the hub and connects to the agent's SSH server.
- The agent's SSH server is configured to accept connections using this key only.
- It does not provide a pseudo-terminal or accept input.

## WebSocket connection

1. The agent initiates a WebSocket connection to the hub.
2. It includes a unique registration `token` as an HTTP header during the upgrade request.
3. The hub verifies that the token is associated with an existing system before upgrading the connection.
4. The hub signs the token using its private key and sends the signature back to the agent.
5. The agent verifies the signature using its public key.
6. After verifying the hub, the agent sends its `fingerprint`.
7. The hub verifies the fingerprint matches the one stored for the system.

## Network requirements

- Agent incoming: port `45876` allows the hub to connect to the agent via SSH.
- Agent outgoing: to your hub URL on port `8090` for `/api/beszel/agent-connect`.
- Hub incoming: port `8090` for web UI and `/api/beszel/agent-connect`.
- Hub outgoing: to your agents on port `45876` for SSH.

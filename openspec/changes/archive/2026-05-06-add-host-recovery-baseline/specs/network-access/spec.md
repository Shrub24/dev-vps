## MODIFIED Requirements

### Requirement: Break-glass access remains available
Network-access design SHALL include documented recovery paths for control-plane failures, including at least one path that does not depend on the primary post-boot operator login flow remaining healthy.

#### Scenario: Tailnet access is degraded
- **WHEN** primary private access path fails
- **THEN** break-glass procedures provide alternate operator access

#### Scenario: Console recovery path is needed
- **WHEN** a host cannot be recovered through the normal post-boot SSH or tailscale login path
- **THEN** operators have a documented provider or serial console recovery path that can be used outside the normal host login flow

#### Scenario: A remote host adopts declarative network ownership
- **WHEN** a host is migrated from provider-managed networking to declarative host-owned networking
- **THEN** the declared stack is self-contained about addresses, routes, and interface ownership
- **AND** operators do not rely on a live SSH session surviving the ownership handoff

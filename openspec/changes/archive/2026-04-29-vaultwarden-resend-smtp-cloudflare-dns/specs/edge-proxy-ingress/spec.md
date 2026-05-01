## ADDED Requirements

### Requirement: Trusted proxy CIDRs SHALL remain single-source for edge reverse-proxy trust behavior
The CIDR source used to trust reverse-proxy client IP headers SHALL remain centrally declared and SHALL drive rendered edge trusted-proxy configuration.

#### Scenario: Edge trusted-proxy policy is rendered
- **WHEN** an edge host evaluates reverse-proxy trust configuration
- **THEN** the rendered trusted proxy configuration consumes the declared trusted proxy CIDR list
- **AND** client IP header trust is not sourced from duplicated unmanaged CIDR literals

#### Scenario: Trusted proxy configuration is updated
- **WHEN** the trusted proxy CIDR list changes
- **THEN** rendered reverse-proxy trust behavior changes from that same declared input source

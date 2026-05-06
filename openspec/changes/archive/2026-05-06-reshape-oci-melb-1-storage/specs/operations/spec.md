## MODIFIED Requirements

### Requirement: Break-glass baseline and rollback paths are documented
Operators SHALL capture baseline state before risky changes and SHALL have documented rollback and recovery procedures, including offline rescue rebuilds for storage-related failures.

#### Scenario: Recovery is required
- **WHEN** SSH, Tailscale, or boot viability degrades after a storage or mount change
- **THEN** break-glass steps and generation rollback commands are available to restore access
- **AND** the workflow includes offline rescue rebuild guidance for restoring `/nix`, mounting the ESP, and reinstalling a bootable generation when live recovery is no longer possible

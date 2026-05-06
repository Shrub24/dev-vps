## MODIFIED Requirements

### Requirement: Disk layout is encoded in disko modules
Host disk and filesystem layout SHALL be represented in disko module definitions.

#### Scenario: Storage plan is evaluated
- **WHEN** storage modules are rendered for a host
- **THEN** partition/filesystem/mount structure is derived declaratively
- **AND** `oci-melb-1` can declare root, `/srv/data`, `/nix`, and `/srv/media` as stable labeled filesystems on the OCI boot volume

# Design: GSD to OpenSpec Migration

## Architecture Decisions Preserved

### Repository Structure Decision

**Decision**: Reposition repository from `dev-vps` to modular fleet infrastructure

**Rationale**: Active goal is reproducible multi-host NixOS infrastructure, not single developer VPS workflow

**Validated**: Phase 1

### First Host Decision

**Decision**: Anchor first implementation around `oci-melb-1`

**Rationale**: Concrete first host sharpens architecture, secrets policy, and bootstrap design

**Validated**: Phase 1

### Service Stack Decision

**Decision**: Start with native services: `tailscale`, `syncthing`, `navidrome`

**Rationale**: Validates new direction faster with lower operational complexity than early orchestration

**Status**: Pending (validation in progress through Phase 04)

### Secrets Split Decision

**Decision**: Use scoped secrets split between `secrets/common.yaml` and `hosts/<host>/secrets.yaml`

**Rationale**: Minimizes blast radius and supports future host growth safely

**Status**: Pending

### Two-Step Secret Bootstrap Decision

**Decision**: Default to two-step secret bootstrap

**Rationale**: Lowers pre-install secret handling risk during early host bring-up

**Status**: Pending

### Network Policy Decision

**Decision**: Keep services private and Tailscale-only

**Rationale**: Reduces attack surface during migration and first-host validation period

**Status**: Pending

### Media Flow Decision

**Decision**: Keep Syncthing bidirectional with safety controls; Navidrome reads direct path

**Rationale**: Matches current workflow needs without premature ingest pipeline complexity

**Status**: Pending

### Deferral Decisions

**Decision**: Defer fleet tooling, backup automation, and `rclone`/VFS evolution

**Rationale**: Current planning window prioritizes clarity and stable baseline over speculative architecture

**Status**: Pending

## Technical Architecture

### Fleet Model

```
flake.nix
  └── hosts/
        └── oci-melb-1/
              └── default.nix (host composition)
  └── modules/
        ├── providers/oci/default.nix
        ├── storage/disko-root.nix
        ├── core/base.nix
        ├── applications/music.nix
        ├── applications/admin.nix
        └── services/*.nix
  └── secrets/
        ├── common.yaml (fleet-shared)
        └── hosts/<host>/secrets.yaml (host-scoped)
```

### Storage Model

```
/srv/data/           - Service state mount
  ├── syncthing/
  ├── navidrome/
  └── beets/

/srv/media/          - Authoritative media mount
  ├── library/       - Syncthing-managed library (Promoted)
  ├── inbox/         - Ingest boundary (slskd downloads, Beets input)
  │   └── slskd/
  ├── quarantine/
  │   ├── untagged/  - Demotion subtree
  │   └── approved/  - Manual approval subtree
  └── slskd/
```

### Secrets Architecture

- **Global scope**: `secrets/common.yaml` — values shared across hosts
- **Host scope**: `hosts/<host>/secrets.yaml` — host-only values
- **Policy scope**: `.sops.yaml` — recipient rules per file pattern

### Access Model

- Tailscale-first private connectivity
- No public service exposure in baseline
- Break-glass recovery via serial console documented in phase artifacts

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| GSD artifacts deleted prematurely | Low | High | Manual follow-up to delete after verification |
| Migration distorts accumulated context | Low | Medium | Careful mapping with minimal distortion principle |
| Phase 05 planning delayed by migration | Low | Low | Migration is additive, does not block Phase 05 |

## Tradeoffs

1. **Preservation vs. Simplification**: Keeping all GSD artifacts in migration-notes preserves context but increases documentation volume. Accepted as safety-first approach.

2. **OpenSpec Completeness vs. Speed**: Creating detailed capability specs vs. leaving some behaviors implicit. Chose focused specs for fleet-infrastructure core capabilities only.

3. **Parallel Operation**: GSD and OpenSpec coexist during migration period. No forced cutover date.

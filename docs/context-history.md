# Context And History

This document summarizes the current project context and the key transition history that led to the present architecture direction.

## Historical Starting Point

The repository originally focused on a single `dev-vps` workflow centered around:

- developer-oriented shell and Home Manager customization
- CodeNomad access workflow over Tailscale
- custom `repo-sync` workflow for private local state orchestration
- provider assumptions aligned with earlier single-host operations

That direction produced working components, but it was optimized for a different objective than the current homelab fleet target.

## Explicit Direction Pivot

The project direction was intentionally changed to:

- Oracle Free Tier as the first host target
- DigitalOcean as a second host provider target
- modular reproducible NixOS multi-service architecture
- host-fleet thinking over single-machine developer workflow
- Tailscale as mandatory private connectivity fabric
- initial practical focus on media stack (`navidrome` + `syncthing`)

The previous `dev-vps` and `repo-sync` emphasis was explicitly de-prioritized for this repository.

## Research And Validation Outcomes

During planning and research, the selected direction was validated as idiomatic and modern for current NixOS workflows:

- `nixos-anywhere` for remote host bootstrap
- `disko` for declarative disk layout
- host-centric flake/module structure
- reusable service modules behind explicit enable flags
- private service exposure first, public edge later

Tooling stance that emerged:

- keep first host path simple
- bootstrap remains `nixos-anywhere`, while regular updates now use `deploy-rs`
- structure repository now so later tooling adoption is low-friction
- keep host bootstrap/secret workflows host-key driven with clear default and advanced variants

Operational lesson captured during `do-admin-1` networking recovery:

- the host had been running on provider/cloud-init-managed static network state rather than `dhcpcd` or `systemd-networkd`
- migrating that host to declarative `systemd-networkd` required matching the observed static `ens3`/`ens4` addresses instead of assuming DHCP
- the failed attempt was caused by doing a live SSH `switch` during network-owner handoff; the cutover succeeded when installed with `deploy-rs --boot` and applied on reboot

Follow-on recovery lesson captured during host-recovery implementation:

- the real missing break-glass path was a console-capable password-authenticated local user, not another normal SSH identity and not an immediate initrd SSH rollout
- the chosen baseline is a console-only `rescue` user plus a weekly reboot exercise, with initrd SSH deferred until host-specific early-boot networking assumptions are worth validating separately
- recovery secret wiring was intentionally moved into the shared recovery module so hosts stay thin and feature-owned secret contracts remain the norm
- local validation is asymmetric: `do-admin-1` can be built on the x86_64 admin machine, while `oci-melb-1` may still require host-side or remote validation when non-substitutable `aarch64-linux` derivations prevent a full local build

## Security And Secrets Direction

The conversation converged on blast-radius secrets management:

- common shared secrets are separated from host-specific secrets
- host-scoped decryption policy is preferred by default
- per-host enrollment tokens are preferred to shared reusable credentials

Bootstrap nuance that was discussed in depth:

- two-step secret bootstrap is default for lower early-stage risk
- pre-generated host identity is allowed but treated as advanced and sharper

## Service And Data Direction

Current operational posture chosen in planning:

- one persistent data mount
- one dedicated `/nix` filesystem on the recovered `oci-melb-1` single-disk layout
- Syncthing bidirectional mode with safety/versioning controls
- Navidrome reads directly from sync-managed media path
- no duplicate staging dataset initially to avoid unnecessary storage usage

Recovery lesson now captured in active context:

- a live migration that removed the old `/nix` before the new mount was boot-valid broke the host hard enough to require OCI rescue-instance recovery
- the validated break-glass repair path was: attach boot volume to rescue VM, mount root + `/nix` + ESP, chroot with working `/dev` `/proc` `/sys` `/run` + DNS, build with sandbox disabled where needed, then run `switch-to-configuration boot`
- the resulting declarative baseline for `oci-melb-1` is a single OCI boot volume carrying labeled filesystems for `/`, `/srv/data`, `/nix`, and `/srv/media`
- shared media root directories are now intended to have one canonical tmpfiles owner in the application composition layer, with lower-level services only layering ACL or marker behavior

Future-facing but deferred:

- `rclone`/VFS authority model
- file processing hooks and worker-style automation

## Network And Exposure Direction

Chosen posture:

- Tailscale-only exposure for now
- public exposure options remain future considerations, not baseline requirements

## Cleanup And Migration Intent

The migration intent is intentionally aggressive:

- remove legacy assumptions and obsolete docs/code paths tied to old mission
- keep only what is still relevant to the new fleet-oriented target
- avoid long-lived dual-mission repository drift

## Current Truth Snapshot

As of this planning update:

- first host name is fixed: `oci-melb-1`
- second host name is fixed: `do-admin-1`
- architecture direction is fleet-first, modular, and native-service-first
- active host path is `hosts/oci-melb-1/default.nix`
- active second host path is `hosts/do-admin-1/default.nix`
- active provider boundary is `modules/providers/oci/default.nix`
- active second provider boundary is `modules/providers/digitalocean/default.nix`
- active storage boundary is `modules/storage/disko-root.nix`
- active single-disk storage boundary is `modules/storage/disko-single-disk.nix`
- active reusable module boundaries are `modules/core/base.nix`, `modules/profiles/base-server.nix`, and `modules/services/tailscale.nix`
- legacy `nixos/configuration.nix`, `nixos/digitalocean.nix`, and `nixos/disko-config.nix` are retired from active architecture
- decisions have been formalized in `docs/decisions.md`
- strategic planning posture is maintained in `docs/plan.md`
- architecture intent and boundaries are in `docs/architecture.md`

This context document exists to preserve why the repository changed, so future implementation steps stay aligned with the intended direction.

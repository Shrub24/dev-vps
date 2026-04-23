## Why

`services.filebrowser` is not the target service we want anymore, and FileBrowser Quantum is not available in nixpkgs as a native module package. We need to replace admin Filebrowser wiring with a Podman-managed Quantum container while also applying the known Cockpit `cockpit-ws-user.service` dependency-loop workaround from cockpit issue #20914.

After initial implementation, we also need to extend Quantum so admin access can use Pocket ID OIDC and host data can be exposed from all known hosts through SFTP-backed mounts over Tailscale.

**Core Value:** keep admin operations private-first and reproducible while unblocking file-management UX and restoring safe Cockpit lifecycle behavior.

## What Changes

- Replace `services.admin.filebrowser` wiring with a new `services.admin.quantum` module backed by `virtualisation.oci-containers` + Podman.
- Use the official Quantum OCI image and keep admin service exposure private via existing loopback route policy.
- Update admin policy and Homepage references from `filebrowser-admin` to `quantum-admin`.
- Apply Cockpit systemd workaround (`DefaultDependencies=no`) for `cockpit-ws-user.service` to avoid the shutdown ordering cycle described in #20914.
- Remove temporary host-level Cockpit disable on `do-admin-1` now that the workaround is in place.
- Add Quantum config wiring for Pocket ID OIDC authentication.
- Add SFTP-backed host mounts over Tailscale for remote hosts (`oci-melb-1`, `arch`) and expose those mounts as Quantum sources.
- Replace self-SSHFS wiring for `do-admin-1` with a local-path Quantum source to avoid recursive/self-mount instability.
- Move host-specific Quantum source wiring into a host-local config split (`hosts/do-admin-1/quantum.nix`) for clearer operator edits.
- Keep local/password auth enabled during manual smoke, then provide a declarative toggle to disable password auth after smoke completes.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `admin-services`: Replace Filebrowser admin-service wiring with Quantum container wiring and codify Cockpit ws-user dependency-loop mitigation.
- `admin-services`: Extend Quantum with Pocket ID OIDC auth and Tailscale SFTP-backed multi-host source wiring.

## Impact

- Affected code:
  - `modules/services/admin/filebrowser.nix` -> replaced by `modules/services/admin/quantum.nix`
  - `modules/services/admin/cockpit.nix`
  - `modules/applications/admin/default.nix`
  - `modules/services/admin/homepage/data.nix`
  - `policy/web-services.nix`
  - `hosts/do-admin-1/default.nix`
  - `modules/applications/admin/identity.nix`
  - `hosts/do-admin-1/secrets.nix`
- Affected behavior:
  - Admin file-management UI route/service changes from Filebrowser to Quantum.
  - Cockpit service lifecycle includes explicit upstream workaround for #20914.
  - Quantum auth can use Pocket ID OIDC, with password auth left enabled until manual smoke is complete.
- Quantum exposes per-host sources backed by Tailscale SSHFS for remote hosts and uses a local-path source for `do-admin-1`.
- `arch` is exposed through explicit sources for `/` and `/home/saurabhj` so laptop mount paths are declarative and easy to adjust.

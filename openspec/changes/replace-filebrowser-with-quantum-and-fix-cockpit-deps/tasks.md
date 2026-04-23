## 1. OpenSpec planning artifacts

- [x] 1.1 Create `proposal.md` for Quantum replacement and Cockpit dependency-loop fix scope.
- [x] 1.2 Add spec delta at `specs/admin-services/spec.md` for Quantum service contract and Cockpit workaround behavior.
- [x] 1.3 Add `design.md` documenting OCI-container decision, route migration, and systemd override plan.

## 2. Replace Filebrowser with Quantum service wiring

- [x] 2.1 Add `modules/services/admin/quantum.nix` with Podman OCI container wiring, persistent data-root mapping, and loopback bind derived from `policyServices."quantum-admin"`.
- [x] 2.2 Update `modules/applications/admin/default.nix` imports/default toggles to use `services.admin.quantum` and remove `services.admin.filebrowser`.
- [x] 2.3 Remove legacy `modules/services/admin/filebrowser.nix`.

## 3. Update policy and admin UI references

- [x] 3.1 Rename `policy/web-services.nix` admin route key from `filebrowser-admin` to `quantum-admin` and adjust subdomain to `quantum`.
- [x] 3.2 Update Homepage service card/widget wiring in `modules/services/admin/homepage/data.nix` from Filebrowser to Quantum route/name.

## 4. Apply Cockpit #20914 workaround and re-enable host cockpit

- [x] 4.1 Update `modules/services/admin/cockpit.nix` to set `systemd.services.cockpit-ws-user.unitConfig.DefaultDependencies = false` when cockpit is enabled.
- [x] 4.2 Remove temporary cockpit disable override from `hosts/do-admin-1/default.nix`.

## 5. Validate and finalize change state

- [x] 5.1 Run `nix fmt` and targeted host eval/build checks for `do-admin-1`.
- [x] 5.2 Run `openspec validate --strict` and resolve any artifact/schema failures.
- [x] 5.3 Mark all remaining tasks complete after successful validation.

## 6. Extend Quantum with OIDC + Tailscale SFTP host sources

- [x] 6.1 Update Quantum module options/wiring for OIDC config file generation, optional env-file credentials, and password-auth toggle defaulting to enabled.
- [x] 6.2 Add SFTP-backed host mount wiring (SSHFS over Tailscale) in Quantum module and expose host-scoped Quantum sources for `do-admin-1` and `oci-melb-1`.
- [x] 6.3 Extend admin identity + host secrets wiring to provide Pocket ID OIDC credentials for Quantum via SOPS templates.
- [x] 6.4 Enable Quantum on `do-admin-1` and configure known-host SFTP inputs (host list, key, known_hosts, user/path).
- [x] 6.5 Run `nix fmt`, targeted `do-admin-1` evaluation/build checks, and `openspec validate --strict`.
- [x] 6.6 Mark new extension tasks complete after successful validation.

## 7. Remove hardcoded srv mount unit dependencies globally

- [x] 7.1 Remove `srv-data.mount` / `srv-media.mount` references from service `after`/`requires` wiring across repo modules.
- [x] 7.2 Use `unitConfig.RequiresMountsFor` path-based dependencies as the canonical mount readiness mechanism where applicable.
- [x] 7.3 Run formatting/checks and confirm no `srv-data.mount` or `srv-media.mount` references remain.

## 9. Fix Quantum config bind mount path

- [x] 9.1 Update Quantum container wiring to mount generated config at a non-overlapping path (outside `/home/filebrowser/data`) and point `FILEBROWSER_CONFIG` to that path.
- [x] 9.2 Run formatting + targeted `do-admin-1` build/eval checks + strict OpenSpec validation.
- [x] 9.3 Mark fix tasks complete.

## 10. Fix Quantum data directory permissions for runtime writes

- [x] 10.1 Ensure Quantum tmpfiles create data directories with runtime-writable ownership/mode.
- [x] 10.2 Add a pre-start ownership reconciliation service for existing deployments while avoiding SSHFS mount subtree ownership changes.
- [x] 10.3 Run targeted validation and strict OpenSpec validation after the permissions fix.

## 11. Make remote data access declarative and fix Quantum unprivileged bind

- [x] 11.1 Configure Quantum to listen on an unprivileged internal port and map host policy port to that container port.
- [x] 11.2 Add declarative ACL/tmpfiles + reconciliation for `dev` read/traverse access to exported `/srv/data` paths on `do-admin-1` and `oci-melb-1`.
- [x] 11.3 Run targeted validation (`nix fmt`, host build/eval checks, strict OpenSpec validation) and mark completion.

## 12. Fix ACL reconciliation and SSHFS mountpoint mode drift

- [x] 12.1 Ensure Quantum module enforces mount root/per-host mountpoint mode with tmpfiles create+adjust rules.
- [x] 12.2 Restrict host ACL reconciliation services to avoid recursive ACL operations across FUSE mountpoints (`-xdev`) and eliminate unsupported-operation failures.
- [x] 12.3 Run targeted validation and mark completion.

## 8. Stabilize Quantum SSHFS mount startup ordering

- [x] 8.1 Update Quantum module so `podman-quantum` does not hard-require per-host SSHFS mount units at startup while still using SSHFS automount behavior.
- [x] 8.2 Ensure Quantum-owned tmpfiles creation/perms are sufficient for mount root and per-host mountpoint paths.
- [x] 8.3 Run targeted validation (`nix fmt`, `do-admin-1` build/eval check, strict OpenSpec validation) and mark tasks complete.

## 13. Add arch laptop host and remove do-admin-1 self-SSHFS

- [x] 13.1 Update Quantum source model to support explicit local-path sources alongside remote SSHFS-backed sources.
- [x] 13.2 Reconfigure `do-admin-1` Quantum host list to remove self-SSHFS for `do-admin-1`, keep `oci-melb-1`, and add remote `arch` host over Tailscale SSH.
- [x] 13.3 Update proposal/design/spec deltas to capture local-source + remote-host wiring behavior.
- [x] 13.4 Run targeted validation (`nix fmt`, `do-admin-1` build/eval check, strict OpenSpec validation) and mark complete.

## 14. Remove duplicate local source and mask nested quantum mount subtree

- [x] 14.1 Add Quantum option to disable built-in managed local source (`/srv`) for hosts using explicit local sources.
- [x] 14.2 Mask local-source nested quantum mount subtree inside container so self-referential paths are not indexed.
- [x] 14.3 Run targeted validation (`nix fmt`, `do-admin-1` build/eval check, strict OpenSpec validation) and mark complete.

## 15. Split host-specific Quantum source config and update arch paths

- [x] 15.1 Move `do-admin-1` Quantum source/mount settings into `hosts/do-admin-1/quantum.nix` and import it from host default config.
- [x] 15.2 Update arch mount sources to explicit `/` and `/home/saurabhj` paths; keep settings host-owned and configurable.
- [x] 15.3 Run targeted validation (`nix fmt`, `do-admin-1` build/eval check, strict OpenSpec validation) and mark complete.

## 16. Switch local source bind path to /srv/data

- [x] 16.1 Update Quantum container local bind path from `/mnt/local-data` to `/srv/data`.
- [x] 16.2 Keep nested mount masking aligned at `/srv/data/quantum/mnt` and leave local source configuration host-owned.
- [x] 16.3 Run targeted validation (`nix fmt`, `do-admin-1` build/eval check, strict OpenSpec validation) and mark complete.

## 17. Simplify remote mount paths for OCI and arch

- [x] 17.1 Change `oci-melb-1` remote mount path from `/srv/data` to `/srv` so both `/srv/data` and `/srv/media` are available.
- [x] 17.2 Remove separate `arch-home` SSHFS mount and keep a single `arch-root` mount at `/`.
- [x] 17.3 Run targeted validation (`nix fmt`, `do-admin-1` build/eval check, strict OpenSpec validation) and mark complete.

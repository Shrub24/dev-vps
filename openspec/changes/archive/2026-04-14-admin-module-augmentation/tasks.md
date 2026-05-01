## 1. Admin Module Service Wiring

- [x] 1.1 Add native admin service enablement in `modules/applications/admin.nix` for Cockpit, Webhook, Ntfy, and Uptime Kuma
- [x] 1.2 Add minimal safe baseline options for each service (listen/bind and startup defaults) without introducing public ingress
- [x] 1.3 Keep service composition centralized in `applications.admin` and preserve existing Termix wiring

## 2. Data Root and State Path Mapping

- [x] 2.1 Map configurable per-service state/data directories under `${cfg.dataRoot}/<service>` where modules expose path options
- [x] 2.2 Add tmpfiles directory rules where needed for service-owned state directories
- [x] 2.3 Verify no new unmanaged state paths are introduced outside the admin data root intent

## 3. Contract and Host Validation

- [x] 3.1 Update contract tests/spec-aligned checks for expanded `admin-services` behavior (new service wiring assertions)
- [x] 3.2 Run `nix flake check` and resolve any option/type mismatches for the new service modules
- [x] 3.3 Validate target host profile evaluation (including `hosts/do-admin-1/default.nix`) and confirm no public-ingress regressions

## 4. Deployment and Smoke Verification

- [x] 4.1 Deploy to the admin target host using existing host-targeted workflow
- [x] 4.2 Verify systemd units are active for Cockpit, Webhook, Ntfy, and Uptime Kuma
- [x] 4.3 Verify existing Tailscale + Termix contracts remain healthy after augmentation

## 5. Admin Stack Extension and Visibility Baseline

- [x] 5.1 Replace Uptime Kuma wiring with native `services.gatus` in `modules/applications/admin.nix`
- [x] 5.2 Add native admin services in `modules/applications/admin.nix`: `services.vaultwarden`, `services.filebrowser`, `services.homepage-dashboard`, and `services.beszel.hub` with loopback/private defaults
- [x] 5.3 Keep native `services.ntfy-sh` and `services.cockpit` wiring intact and private-first (no public firewall opens)
- [x] 5.4 Defer cross-host L1 log sync from this stage and remove journald remote/upload requirements from spec and host contracts
- [x] 5.5 Keep central operations visibility anchored on Cockpit + Beszel surfaced via Homepage
- [x] 5.6 Update contract checks for new service set and the `uptime-kuma -> gatus` swap
- [x] 5.7 Run validation (`nix eval`/contracts and `nix flake check` where feasible) and resolve option/type mismatches
- [x] 5.8 Deploy and verify admin visibility baseline health on target hosts (without journald replication)

## 1. Karakeep Service Module

- [x] 1.1 Add `modules/services/karakeep.nix` with Nix-managed OCI container definitions for Karakeep web, browser, and Meilisearch runtime components
- [x] 1.2 Define module options for image pins, listen port, persistent state directories, required env file paths, and optional integration env inputs
- [x] 1.3 Ensure tmpfiles, mount prerequisites, and systemd ordering follow existing container-service patterns used elsewhere in the repo

## 2. Host Wiring and Secrets

- [x] 2.1 Wire Karakeep into `hosts/oci-melb-1/default.nix` with explicit `/srv/data/karakeep` defaults and required service enablement
- [x] 2.2 Add host-scoped Karakeep secret declarations/templates for required auth and search keys in `hosts/oci-melb-1/default.nix`
- [x] 2.3 Update `hosts/oci-melb-1/secrets.template.yaml` with Karakeep placeholder values while keeping secret scope host-local only

## 3. Edge Route and Documentation

- [x] 3.1 Add Karakeep service entry to `policy/web-services.nix` for `do-admin-1` using `tailscale-upstream`, Cloudflare Access, and authenticated origin pulls
- [x] 3.2 Update relevant architecture or host-facing docs to describe Karakeep as a first-class private service on `oci-melb-1`
- [x] 3.3 Add or adjust route/metadata validation expectations so Karakeep is consumed through canonical edge policy rather than host-local ad hoc exposure

## 4. Validation and OpenSpec Coherence

- [x] 4.1 Run scoped Nix evaluation/checks for `oci-melb-1` to confirm Karakeep module wiring, container config, and secret references render cleanly
- [x] 4.2 Run repo formatting or targeted validation steps required by the touched files and resolve any regressions
- [x] 4.3 Run `openspec validate --strict --change add-karakeep-service` and keep artifacts aligned with the implemented behavior

## 5. Runtime Bugfix Extension (Env File Wiring)

- [x] 5.1 Point `services.karakeep-oci.environmentFile` at `config.sops.templates."karakeep.environment".path` in `hosts/oci-melb-1/default.nix` so Karakeep consumes rendered SOPS secrets declaratively
- [x] 5.2 Attach Karakeep web/chrome/meilisearch containers to a dedicated shared Podman network and enforce service ordering on network creation for stable inter-container DNS

## 6. Mobile Client Access Posture Extension

- [x] 6.1 Update Karakeep edge-policy artifacts and `policy/web-services.nix` so the route relies on app-native auth with `access.requireCloudflareAccess = false` for browser/mobile client compatibility
- [x] 6.2 Switch Karakeep to OIDC-only login by setting `services.karakeep-oci.oidc.disablePasswordAuth = true` after initial setup stabilized

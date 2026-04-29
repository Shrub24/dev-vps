## 1. Plan and define the change

- [x] 1.1 Create proposal, design, spec delta, and executable task plan for replacing Filebrowser with Quantum and restoring Cockpit.

## 2. Replace Filebrowser with Quantum

- [x] 2.1 Add `services.admin.quantum` as the new admin file-manager module.
- [x] 2.2 Remove legacy Filebrowser module wiring and rename policy/UI references to `quantum-admin`.
- [x] 2.3 Validate the base Quantum replacement.

## 3. Extend Quantum for real host usage

- [x] 3.1 Add Pocket ID OIDC wiring and controlled password fallback.
- [x] 3.2 Add local and remote host source support, including SSHFS-backed remote mounts over Tailscale.
- [x] 3.3 Split host-specific Quantum source configuration into host-owned config.
- [x] 3.4 Fix runtime issues discovered during rollout (config mount path, permissions, port binding, mount readiness, ACL/reconcile behavior, source-path simplification).
- [x] 3.5 Validate the final Quantum behavior for `do-admin-1`.

## 4. Restore and stabilize Cockpit runtime

- [x] 4.1 Apply the `cockpit-ws-user.service` dependency workaround and remove the temporary host disable.
- [x] 4.2 Fix Cockpit socket bind behavior and reverse-proxy compatibility on `do-admin-1`.
- [x] 4.3 Add restricted per-host Cockpit service-user wiring.
- [x] 4.4 Validate the restored local Cockpit runtime.

## 5. Settle the final Cockpit access model

- [x] 5.1 Abandon login-page remote host chaining in favor of direct per-host Cockpit sessions.
- [x] 5.2 Expose Cockpit sessions as shared-host subpaths (`/do-admin-1`, `/oci-melb-1`).
- [x] 5.3 Update Homepage and Cloudflare Access behavior to match the final per-host endpoint model.
- [x] 5.4 Validate the per-host session model.

## 6. Make the final do-admin-1 and oci-melb-1 upstream paths work cleanly

- [x] 6.1 Fix do-admin-1 local Cockpit subpath proxy behavior, including header forwarding, trailing slash handling, and final trusted local CA loopback TLS.
- [x] 6.2 Make `oci-melb-1` reachable through its final host-local Tailscale Serve HTTPS path.
- [x] 6.3 Validate final Cockpit routing behavior for both hosts.

## 7. Simplify ownership and structure

- [x] 7.1 Move Cockpit-owned loopback TLS and Tailscale Serve behavior into focused Cockpit submodules.
- [x] 7.2 Remove duplicated host/application Cockpit transport wiring so host overlays only contain host-specific values.
- [x] 7.3 Streamline OpenSpec artifacts so they describe the final implemented design instead of abandoned intermediate paths.
- [x] 7.4 Run final validation (`nix fmt`, targeted `do-admin-1` build/eval checks, strict OpenSpec validation).

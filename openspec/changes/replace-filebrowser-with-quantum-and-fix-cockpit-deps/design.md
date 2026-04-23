## Context

The current admin file manager wiring uses NixOS `services.filebrowser` under `modules/services/admin/filebrowser.nix`, with a policy route `filebrowser-admin` and Homepage widget references tied to that route. We now need Quantum, but Quantum is not packaged in nixpkgs as a native NixOS service module in this repo baseline.

At the same time, Cockpit had an upstream systemd ordering-cycle bug (`cockpit-ws-user.service` with implicit `basic.target` dependency) tracked in cockpit issue #20914 and fixed upstream by dropping implicit default dependencies. Our current host keeps Cockpit disabled as a temporary exception; we want to apply the workaround declaratively and re-enable it.

## Goals / Non-Goals

**Goals:**
- Replace admin Filebrowser wiring with Quantum using Podman OCI container runtime.
- Preserve private-first loopback exposure and existing policy-driven route wiring.
- Keep state paths under `${applications.admin.dataRoot}` using a service-specific subdirectory.
- Apply Cockpit `cockpit-ws-user.service` dependency workaround declaratively.
- Remove host-level cockpit disable exception on `do-admin-1`.
- Add Pocket ID OIDC wiring for Quantum login.
- Add SFTP-backed host source mounts over Tailscale for remote hosts (`oci-melb-1`, `arch`).
- Use a direct local-path Quantum source for `do-admin-1` instead of self-SSHFS.
- Keep password auth enabled for manual smoke; support declarative disable post-smoke.

**Non-Goals:**
- Implementing Homepage machine-auth credentials for the file-manager widget.
- Adding public ingress or bypassing existing access policy posture.
- Broad redesign of admin application composition.
- Disabling Quantum password auth before operators complete manual smoke validation.

## Decisions

### Decision QTM-1: Use OCI container wiring for Quantum
- **Chosen:** create `modules/services/admin/quantum.nix` that uses `virtualisation.podman.enable = true` and `virtualisation.oci-containers.containers.quantum`.
- **Why:** Quantum is not in nixpkgs as a built-in module/service here; OCI path is explicit, reproducible, and already used in this repo (e.g., termix/soulsync).
- **Alternative:** package Quantum binary derivation in-tree now. Rejected for this change to keep scope tight and avoid custom build maintenance.

### Decision QTM-2: Keep route model and just rename service key
- **Chosen:** replace `filebrowser-admin` route with `quantum-admin` in policy and dependent modules.
- **Why:** preserves existing policy-consumer pattern while making intent explicit and avoiding mixed legacy naming.
- **Alternative:** keep route name `filebrowser-admin` while changing backend. Rejected to avoid long-term naming drift.

### Decision QTM-3: Persist Quantum config and runtime data under admin dataRoot
- **Chosen:** create `${applications.admin.dataRoot}/quantum` and mount it at `/home/filebrowser/data`; mount `${applications.admin.dataRoot}/quantum/files` as the managed source path.
- **Why:** follows current admin data-root conventions and supports persistence for config/database/cache.
- **Alternative:** mount arbitrary host directories directly as root source. Rejected as less controlled and harder to standardize.

### Decision CPK-1: Apply cockpit ws-user workaround via systemd unit override
- **Chosen:** set `systemd.services.cockpit-ws-user.unitConfig.DefaultDependencies = false` inside admin cockpit module when enabled.
- **Why:** aligns with upstream fix intent for #20914 and keeps workaround colocated with cockpit ownership.
- **Alternative:** keep cockpit disabled indefinitely at host level. Rejected because workaround is available and we want baseline admin visibility restored.

### Decision QTM-4: Wire Quantum OIDC through existing Pocket ID identity path
- **Chosen:** add Quantum OIDC options and wire them from admin identity composition using Pocket ID issuer URL + SOPS-provided client credentials env file.
- **Why:** reuses established identity model (`termix` + `pocket-id`) and avoids storing OIDC secrets in the Nix store.
- **Alternative:** inline OIDC secrets directly in module options. Rejected due to secret handling risk.

### Decision QTM-5: Expose remote host data via SSHFS over Tailscale and local host data via direct local source
- **Chosen:** keep Quantum SFTP mount wiring backed by `fuse.sshfs` for remote hosts (`oci-melb-1`, `arch`) using SSH key + known_hosts files from SOPS, and map `do-admin-1` as a local source path.
- **Why:** avoids recursive self-SSHFS mount failure modes on the admin host while preserving deterministic remote source paths and Tailscale-private connectivity.
- **DNS note:** short hostnames (for example `arch`) are acceptable only because `do-admin-1` already routes tailnet DNS through `dnsmasq` split-DNS to MagicDNS (`100.100.100.100`) as done for existing admin-container flows; if shortname resolution fails, use the explicit FQDN (`arch.tail0fe19b.ts.net`).
- **Path note:** `arch` is represented as two separate sources (`/` and `/home/saurabhj`) so operators can adjust laptop scope without touching service module internals.

### Decision QTM-7: Keep host-specific Quantum source wiring in host-local config
- **Chosen:** move source and host mount definitions into `hosts/do-admin-1/quantum.nix` imported by host default.
- **Why:** matches existing host split style (`networking.nix`, `edge.nix`, `secrets.nix`) and keeps operator-tuned mount paths close to host ownership.
- **Alternative:** put host source details in global `policy/`. Rejected because these values are host-specific operational inputs, not shared route policy.
- **Alternative:** native Quantum SFTP source config. Rejected because this is not documented in official source configuration docs.

### Decision QTM-6: Keep password auth enabled by default until manual smoke completes
- **Chosen:** introduce declarative `passwordAuthEnabled` toggle with default `true`; do not disable in this change.
- **Why:** matches rollout safety requirement while enabling later lock-down without redesign.
- **Alternative:** disable password auth immediately when OIDC is enabled. Rejected due to smoke-validation requirement.

## Risks / Trade-offs

- **[Risk] Quantum image tag drift** -> **Mitigation:** pin to `gtstef/filebrowser:stable` for predictable behavior.
- **[Risk] Initial admin credentials defaulting insecurely** -> **Mitigation:** set `FILEBROWSER_ADMIN_PASSWORD` via env var wiring and require it declaratively through module option/assertion.
- **[Risk] Route rename breaks references** -> **Mitigation:** update policy, module route lookups, and Homepage widget references in same change.
- **[Risk] Cockpit workaround differs from future nixpkgs unit shape** -> **Mitigation:** use minimal unit override (`DefaultDependencies=false`) and keep it easy to remove in a future cleanup change.
- **[Risk] SSHFS mount instability over network changes** -> **Mitigation:** use `_netdev`, reconnect/server-alive options, and automount semantics.
- **[Risk] Host-key trust drift for SFTP endpoints** -> **Mitigation:** require explicit known_hosts file and strict host key checking.
- **[Risk] OIDC cutover lockout** -> **Mitigation:** keep password auth enabled until manual smoke, then disable via dedicated option flip.

## Migration Plan

1. Add OpenSpec artifacts (proposal/spec/design/tasks) for this change.
2. Introduce `services.admin.quantum` module and remove legacy `services.admin.filebrowser` module import/wiring.
3. Rename policy route and Homepage references from Filebrowser to Quantum.
4. Apply Cockpit systemd ws-user override and remove host-level cockpit disable override.
5. Add Quantum OIDC + env-file wiring through admin identity and host secrets templates.
6. Add Quantum remote-host SFTP mount wiring over Tailscale (`oci-melb-1`, `arch`) and local-source mapping for `do-admin-1`.
7. Split host-specific Quantum source wiring into `hosts/do-admin-1/quantum.nix`.
7. Run formatting and targeted Nix validation.
8. Mark tasks complete and run `openspec validate --strict`.

Rollback: revert this change; previous generation restores `services.filebrowser` wiring and cockpit host override.

## Open Questions

- Should Quantum admin password source be transitioned to host-scoped SOPS template in a follow-up instead of inline option value?

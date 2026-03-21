# Domain Pitfalls

**Domain:** Modular NixOS homelab fleet infrastructure migration from a legacy single-host repo to a cloud-first ARM fleet baseline
**Researched:** 2026-03-21
**Confidence:** HIGH for NixOS/Tailscale/Syncthing/OCI documented behaviors; MEDIUM for some OCI+A1 operational sharp edges where official docs describe platform constraints but not NixOS-specific failure modes

## Critical Pitfalls

### Pitfall 1: Letting the old `dev-vps` mission survive inside the new fleet repo

**What goes wrong:**
The repository keeps both the old single-host workflow and the new fleet model alive at the same time. Modules, docs, host names, and deployment entrypoints drift in parallel, so nobody knows which path is authoritative.

**Why it happens:**
Migration work often preserves old paths "just in case". In infra repos that usually becomes permanent ambiguity, not safety.

**Prevention:**
- Do an explicit cutover to host-centric structure early.
- Archive or delete legacy `dev-vps` paths, docs, and entrypoints in the migration phase.
- Define one canonical flake output path for `oci-melb-1` and one canonical docs set.
- Treat any legacy behavior kept temporarily as a time-boxed compatibility shim with a removal date.

**Warning signs:**
- Two ways to build or deploy the same host.
- Docs still describe `repo-sync`, Home Manager VPS behavior, or old naming as if active.
- New modules import old paths "for now".

**Phase to address:**
Phase 1 - Repository migration and cleanup.

---

### Pitfall 2: Secrets scope is too broad from day one

**What goes wrong:**
A new host can decrypt secrets it does not need because recipients are assigned too broadly, or everything lands in one encrypted file. That makes future host additions and service moves security-sensitive rewrites.

**Why it happens:**
It is faster to make one `secrets.yaml` or one reusable enrollment token while bootstrapping the first host.

**Prevention:**
- Keep `secrets/common.yaml` minimal and justify every shared secret.
- Put host-only material in `hosts/<host>/secrets.yaml`.
- Encode blast radius in `.sops.yaml` path rules before adding real secrets.
- Prefer host-scoped Tailscale auth material over reusable shared keys.
- Review recipients whenever a host or service is added; treat it like a trust-boundary change.

**Warning signs:**
- A new host recipient gets added to broad wildcard rules.
- The same auth token appears in multiple hosts.
- Secrets file names are shared by convenience rather than trust boundary.

**Phase to address:**
Phase 2 - Secrets and identity bootstrap.

---

### Pitfall 3: First-boot secret decryption depends on identity material that is not actually available yet

**What goes wrong:**
The machine needs secrets to finish boot or create users, but the age key or SSH host key is generated too late, not persisted, or not mounted early enough. Install succeeds, first real boot fails, or user creation silently breaks.

**Why it happens:**
`sops-nix` makes secrets declarative, so it is easy to forget boot ordering. The sharp edges are around `neededForUsers`, host SSH keys as age identities, and persisted key paths.

**Prevention:**
- Default to the planned two-step bootstrap for the first cloud host.
- If using host SSH keys as age identities, ensure `/etc/ssh` is available early enough.
- If using a generated age key, persist `sops.age.keyFile` on durable storage.
- Mark any secret used for user creation with `neededForUsers = true`.
- Do one dry-run design review of which secrets are needed at install time, first boot, activation time, and steady state.

**Warning signs:**
- `sops-nix` secrets decrypt only after login or after a manual fix.
- User password or service credential files are missing during activation.
- Secrets bootstrap docs mention "copy this key manually if boot fails".

**Phase to address:**
Phase 2 - Secrets and identity bootstrap.

---

### Pitfall 4: Assuming `nixos-anywhere` on ARM behaves like x86_64 by default

**What goes wrong:**
The install path is designed around the default `nixos-anywhere` kexec flow, then fails on Ampere because the default kexec image is x86_64-only. Teams discover the architecture mismatch late, after they already coupled bootstrap logic to the wrong assumptions.

**Why it happens:**
`nixos-anywhere` is the right tool, but its default installer path is not architecture-neutral. ARM support needs deliberate handling.

**Prevention:**
- Design the bootstrap phase around a custom ARM-compatible kexec path or an OCI-compatible alternative install path from the start.
- Keep bootstrap logic separate from reusable host modules so provider/arch exceptions stay local.
- Test the exact `oci-melb-1` install path before layering services and secrets automation on top.
- Keep a documented fallback path for reinstall and recovery.

**Warning signs:**
- Bootstrap docs assume the default `nixos-anywhere` kexec tarball will work everywhere.
- Architecture-specific install notes are missing.
- The first ARM test host is deferred until after repo restructuring is complete.

**Phase to address:**
Phase 3 - Host bootstrap and storage baseline.

---

### Pitfall 5: Using unstable disk or NIC identifiers on OCI

**What goes wrong:**
The host boots with the wrong mount or fails to mount persistent data because configs rely on `/dev/sdX`-style names or provider-specific assumptions that change across boots, reattachments, or shape changes. Similar drift can hit network interfaces after instance shape changes.

**Why it happens:**
Cloud environments look stable during the first install, so operators encode whatever device names are visible at the time.

**Prevention:**
- Use stable identifiers in Disko and filesystem mounts; do not hardcode transient device names.
- For OCI-attached storage, use consistent device paths where supported and still prefer filesystem UUIDs/known stable paths in the host config.
- Keep provider-specific disk and network handling isolated in the host layer.
- Document serial-console recovery and how to re-derive the expected device mapping.

**Warning signs:**
- Disk config references `/dev/sda`, `/dev/vda`, or similar transient names without justification.
- Reboot or shape-change testing is skipped.
- Data mount logic is embedded in a generic service module instead of the host definition.

**Phase to address:**
Phase 3 - Host bootstrap and storage baseline.

---

### Pitfall 6: No real break-glass path once private networking becomes the primary access path

**What goes wrong:**
The host is reachable only through the very networking stack you are still bringing up. A Tailscale auth, ACL, DNS, or service startup mistake locks out administration during first boot or after a bad deploy.

**Why it happens:**
"Private-only" is the right security target, but operators sometimes implement it before the recovery path is proven.

**Prevention:**
- Keep OCI serial console access workable and documented before tightening the host.
- Treat Tailscale as the primary path, not the only recovery path.
- Use tagged, one-off or pre-approved server auth keys as appropriate; avoid long-lived reusable keys for the first host.
- Bring up management access before layering private services.
- Verify MagicDNS, host naming, and ACL/tag policy with a minimal baseline first.

**Warning signs:**
- Rebuild instructions assume Tailscale already works.
- No tested serial console login or console-output troubleshooting path exists.
- First deployment combines Tailscale enrollment, firewalling, and service exposure in one step.

**Phase to address:**
Phase 4 - Private networking and access.

---

### Pitfall 7: Treating private-only service exposure as equivalent to safe-by-default service configuration

**What goes wrong:**
Services stay off the public internet, but they still run with broad listen addresses, weak local assumptions, or over-permissive Tailscale ACL/tag policy. The result is lateral exposure inside the tailnet.

**Why it happens:**
Teams mentally substitute "not public" for "properly bounded".

**Prevention:**
- Define which principals in the tailnet may reach `navidrome`, `syncthing`, and SSH before deployment.
- Use stable host tags and ACLs rather than ad hoc machine approvals.
- Keep service bind addresses, firewall openings, and Tailscale exposure intentionally minimal.
- Review whether any service actually needs subnet routing or extra advertised features before enabling them.

**Warning signs:**
- ACL work is deferred until after services are already in use.
- Tailscale tags are missing or applied inconsistently.
- A private service is reachable from more devices/users than expected.

**Phase to address:**
Phase 4 - Private networking and access.

---

### Pitfall 8: Bidirectional Syncthing is enabled without deletion, versioning, and conflict safety controls

**What goes wrong:**
Accidental deletes, bad renames, or conflicting edits propagate across peers and directly impact the Navidrome library because Navidrome reads the same path. The sync layer becomes the outage multiplier.

**Why it happens:**
Bidirectional sync feels convenient and matches current workflow, but safety defaults are often weaker than operators assume.

**Prevention:**
- Enable file versioning from day one on the synced media tree.
- Decide explicitly which folders are `Send & Receive` versus `Send Only`/`Receive Only`; do not default everything to bidirectional.
- Document who is allowed to mutate the library and from which peers.
- Test delete, rename, and conflict scenarios before treating the path as authoritative.

**Warning signs:**
- `.stversions` is absent or unbounded.
- Multiple peers can edit the same library subtree with no policy.
- Conflicts are discovered for the first time in production.

**Phase to address:**
Phase 5 - Service baseline and data safety.

---

### Pitfall 9: Navidrome and Syncthing share a path, but ownership, permissions, and write expectations are unclear

**What goes wrong:**
Navidrome cannot scan reliably, or Syncthing and Navidrome fight over file ownership assumptions. In worse cases the media tree is made broadly writable to "fix permissions", increasing corruption and exposure risk.

**Why it happens:**
A direct-path design is simpler, but only if the media folder is treated as read-only for Navidrome and writable only where sync truly needs it.

**Prevention:**
- Keep Navidrome on its own user.
- Give Navidrome read-only access to the music folder and read-write access only to its own data folder.
- Define service users, groups, and mount permissions before data arrives.
- Separate app data from media data even if they live on the same underlying mount.

**Warning signs:**
- A service is run as root to "make it work".
- Media and application state live in the same directory tree.
- Permission fixes happen manually after each deploy.

**Phase to address:**
Phase 5 - Service baseline and data safety.

---

### Pitfall 10: Declaring "backups later" without also limiting authority and recovery expectations now

**What goes wrong:**
The team says backup automation is deferred, but still treats the first cloud host as if it were recoverable and authoritative. Then a sync mistake, volume issue, or reinstall destroys the only trusted copy.

**Why it happens:**
Deferring backup work is reasonable early; deferring recovery thinking is not.

**Prevention:**
- Be explicit about which system is the temporary authority for each data class.
- Keep the first host non-authoritative for irreplaceable data until backup and restore are tested.
- Write down acceptable-loss assumptions for media, app state, and secrets.
- Add manual recovery steps and restore drills before declaring the host stable.

**Warning signs:**
- The first host is described as "source of truth" before restore is proven.
- No one can answer how to rebuild Navidrome state, Syncthing config, or the data mount after loss.
- "We can always re-sync it" is used without verifying where the good copy lives.

**Phase to address:**
Phase 5 - Service baseline and data safety.

## Moderate Pitfalls

### Pitfall 1: Over-generalizing modules before the first host is real

**What goes wrong:**
Abstractions are added for future hosts, providers, and services before the first cloud ARM host is actually working, creating indirection without validated reuse.

**Prevention:**
Generalize only after `oci-melb-1` proves the boundary. Keep provider specifics in the host layer until a second concrete consumer exists.

**Warning signs:**
Modules gain knobs for hypothetical x86 hosts, alternate providers, and future services before the first host is bootstrapped.

**Phase to address:**
Phase 1 through Phase 3.

### Pitfall 2: Reinstall paths are untested because initial install "worked once"

**What goes wrong:**
The first successful install becomes tribal knowledge and cannot be reproduced after disk replacement, host recreation, or shape change.

**Prevention:**
Treat reinstallability as part of done. Re-run the bootstrap path on a fresh target or documented recovery scenario.

**Warning signs:**
Critical install steps live only in shell history, not repo docs.

**Phase to address:**
Phase 3.

## Minor Pitfalls

### Pitfall 1: Service modules hide filesystem assumptions

**What goes wrong:**
Reusable modules quietly assume mountpoints like `/data/media` or ownership policies that only exist on one host.

**Prevention:**
Expose storage paths as host-composed inputs and keep mount definitions in host or storage profile modules.

**Warning signs:**
Changing a mount path requires editing the service module itself.

**Phase to address:**
Phase 3 and Phase 5.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Repository migration | Dual-mission repo drift | Remove/archive legacy paths early; keep one authoritative layout and docs set |
| Secrets design | Broad recipient rules in `.sops.yaml` | Encode trust boundaries before adding secrets; review recipients per file pattern |
| First host bootstrap | ARM install path assumes x86 defaults | Prove the exact `aarch64` bootstrap path before adding higher-level automation |
| Storage baseline | Unstable OCI device naming | Use stable identifiers and test reboot/reinstall behavior |
| Private access baseline | No break-glass access after Tailscale cutover | Validate serial console and recovery docs before making Tailscale the primary path |
| Tailscale enrollment | Reusable auth keys shared across hosts | Use host-scoped, tagged, server-appropriate keys with narrow ACLs |
| Sync/media rollout | Bidirectional sync without recovery controls | Enable versioning, document authority, and test delete/conflict cases |
| Service permissions | Navidrome writes to media tree or runs as root | Keep read-only music path, separate writable app data, and service-specific users |

## Sources

- Project context: `.planning/PROJECT.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, `docs/context-history.md`
- `sops-nix` README via Context7 - `/mic92/sops-nix` - HIGH confidence
- `nixos-anywhere` docs via Context7 - `/nix-community/nixos-anywhere` - HIGH confidence
- `disko` docs via Context7 - `/nix-community/disko` - HIGH confidence
- Tailscale docs via Context7 - `/websites/tailscale` - HIGH confidence
- Syncthing docs via Context7 - `/syncthing/syncthing` - HIGH confidence
- Navidrome docs via Context7 - `/websites/navidrome` - HIGH confidence
- Oracle Cloud Infrastructure docs: `https://docs.oracle.com/en-us/iaas/Content/Block/References/consistentdevicepaths.htm` - HIGH confidence
- Oracle Cloud Infrastructure docs: `https://docs.oracle.com/en-us/iaas/Content/Compute/References/serialconsole.htm` - HIGH confidence
- Oracle Cloud Infrastructure docs: `https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/resizinginstances.htm` - HIGH confidence

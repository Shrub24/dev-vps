# Architecture Research

**Domain:** Modular NixOS homelab fleet infrastructure
**Researched:** 2026-03-21
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌──────────────────────────────── Fleet Control Repo ────────────────────────────────┐
│  flake.nix                                                                         │
│  ├── input pins: nixpkgs, disko, sops-nix, optional deploy tooling later          │
│  ├── host inventory: host metadata, target system, provider facts                 │
│  └── nixosConfigurations.<host>                                                    │
├──────────────────────────────┬──────────────────────────────┬──────────────────────┤
│ Shared Modules               │ Host Composition             │ Secret Policy         │
│ - core/base                  │ - hosts/oci-melb-1/          │ - .sops.yaml          │
│ - profiles/base-server       │ - future hosts/<name>/       │ - secrets/common.yaml │
│ - services/tailscale         │ - provider + hardware glue   │ - hosts/*/secrets.yaml│
│ - services/syncthing         │ - host-owned disk mapping    │                      │
│ - services/navidrome         │                              │                      │
├──────────────────────────────┴──────────────────────────────┴──────────────────────┤
│ Build + Deploy Flow                                                                    │
│ local admin machine -> nix build/eval -> nixos-anywhere bootstrap -> target host       │
│ local admin machine -> nixos-rebuild/deploy tool later -> target host                   │
├──────────────────────────────── Host Runtime ───────────────────────────────────────┤
│  OCI ARM host                                                                          │
│  ├── systemd + NixOS services                                                          │
│  ├── Tailscale network identity                                                        │
│  ├── /persist (single data mount)                                                      │
│  │   ├── syncthing/                                                                    │
│  │   ├── navidrome/                                                                    │
│  │   └── service state dirs                                                            │
│  └── age/ssh host identity for secret decryption                                       │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `flake.nix` | Pins inputs and assembles every host from inventory + modules | Single flake with `nixosConfigurations` per host |
| `hosts/<host>/` | Owns host identity, target system, provider facts, disk mapping, host-only secrets references | `default.nix`, `hardware.nix`, `disko.nix`, `secrets.yaml` |
| `modules/core/` | Defines base system policy that every server should inherit | SSH, users, nix settings, monitoring baseline, common hardening |
| `modules/profiles/` | Composes reusable bundles without owning host identity | `base-server`, `oracle-arm`, `media-node` |
| `modules/services/` | Encapsulates one service behind explicit options and paths | `tailscale.nix`, `syncthing.nix`, `navidrome.nix` |
| `modules/secrets/` | Maps decrypted secrets into service config without spreading SOPS logic everywhere | small glue modules or service-local secret declarations |
| `secrets/common.yaml` | Holds intentionally shared fleet secrets only | shared DNS/API material if truly needed |
| `.sops.yaml` | Enforces blast-radius boundaries by path pattern | age recipients per common vs host file |
| local admin machine | Sole control-plane actor in v1 | `nix`, `sops`, `age`, `nixos-anywhere`, SSH |

## Recommended Project Structure

```text
.
├── flake.nix                    # Inputs, outputs, host assembly
├── flake.lock                   # Pin set for reproducibility
├── lib/
│   ├── mkHost.nix               # Small helper to build hosts consistently
│   └── hosts.nix                # Inventory metadata: system, provider, targetHost
├── hosts/
│   └── oci-melb-1/
│       ├── default.nix          # Host composition entrypoint
│       ├── hardware.nix         # Generated host facts or facter output
│       ├── disko.nix            # Host-owned disk layout and mountpoints
│       ├── networking.nix       # Hostname, interfaces, OCI specifics if needed
│       └── secrets.yaml         # Host-scoped encrypted secrets
├── modules/
│   ├── core/
│   │   ├── base.nix             # Nix, SSH, locale, users, baseline hardening
│   │   ├── persistence.nix      # /persist conventions and shared paths
│   │   └── tailscale-access.nix # Private-access defaults
│   ├── profiles/
│   │   ├── base-server.nix      # Common server profile
│   │   ├── provider-oci.nix     # OCI quirks isolated from services
│   │   └── media-node.nix       # Syncthing + Navidrome composition
│   └── services/
│       ├── tailscale.nix        # Auth key wiring and access posture
│       ├── syncthing.nix        # Folder policy, versioning, service user, paths
│       └── navidrome.nix        # Media path, state dir, service settings
├── secrets/
│   └── common.yaml              # Fleet-shared encrypted secrets only
├── .sops.yaml                   # Recipient policy by path
├── checks/
│   ├── eval.nix                 # Optional evaluation checks later
│   └── smoke.nix                # Optional host assertions later
└── docs/
    └── ...                      # Architecture/decision docs stay authoritative
```

### Structure Rationale

- **`hosts/` owns identity:** host name, architecture, provider quirks, disk facts, and host secrets change together.
- **`modules/services/` owns behavior:** service modules should not know which provider or host they run on.
- **`modules/profiles/` owns composition:** profiles bundle reusable intent, but hosts still decide whether to import them.
- **`lib/` stays thin:** a tiny `mkHost` helper is useful; a large custom framework this early is not.
- **`secrets/` and `hosts/*/secrets.yaml` stay separate:** common secrets are exceptional, host secrets are default.

## Architectural Patterns

### Pattern 1: Host-First Assembly

**What:** Every machine gets one host directory that imports shared modules and declares only its own facts.
**When to use:** Immediately; this is the cleanest path from one host to many hosts.
**Trade-offs:** Slight duplication across hosts, but much lower ambiguity than a role-only tree.

**Example:**
```nix
{ inputs, lib, ... }:
{
  imports = [
    ../../modules/profiles/base-server.nix
    ../../modules/profiles/provider-oci.nix
    ../../modules/profiles/media-node.nix
    ./hardware.nix
    ./disko.nix
    ./networking.nix
  ];

  networking.hostName = "oci-melb-1";
  system.stateVersion = "25.11";
}
```

### Pattern 2: Thin Profiles, Thin Services, Explicit Enables

**What:** Profiles bundle intent; service modules expose enable flags and path options; hosts opt in explicitly.
**When to use:** For reusable behavior that may later move to another machine.
**Trade-offs:** More files up front, but far easier host migration later.

**Example:**
```nix
{ lib, config, ... }:
let
  cfg = config.fleet.services.navidrome;
in {
  options.fleet.services.navidrome.enable = lib.mkEnableOption "Navidrome";

  config = lib.mkIf cfg.enable {
    services.navidrome.enable = true;
    services.navidrome.settings.MusicFolder = cfg.musicDir;
  };
}
```

### Pattern 3: Provider and Storage Isolation

**What:** Provider-specific networking and disk assumptions live in provider or host modules, not service modules.
**When to use:** Always; OCI ARM today, mixed providers later.
**Trade-offs:** Some host modules look more verbose, but cross-host reuse stays intact.

**Example:**
```nix
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive0";
}
```

## Data Flow

### Build And Deploy Flow

```text
Admin edits repo
    ↓
flake evaluates host inventory + modules
    ↓
host config builds for target system (aarch64 or x86_64)
    ↓
bootstrap: nixos-anywhere + disko on new machine
    ↓
steady state: nixos-rebuild switch --flake .#<host> over SSH
    ↓
runtime services start under systemd
```

### Trust Boundaries

```text
[Admin machine]
  Holds git checkout, SOPS editing capability, SSH authority
        |
        | SSH + copied closures
        v
[Target host bootstrap environment]
  Trusted only long enough to install system
        |
        | first boot / second-step secret activation
        v
[Installed host]
  Holds host age/ssh identity, decrypts only allowed secret files
        |
        | private access only
        v
[Tailscale network]
  Carries management and service traffic
```

### Key Data Flows

1. **Configuration flow:** `flake.nix` + host inventory -> shared modules -> `nixosConfigurations.<host>` -> install or switch.
2. **Secrets flow:** admin edits encrypted YAML -> `.sops.yaml` chooses recipients -> host decrypts only its own file plus approved common file at activation/runtime.
3. **Storage flow:** `disko` creates root + persistent mount -> persistence module defines canonical paths -> Syncthing writes library -> Navidrome reads same path.
4. **Access flow:** admin or clients enter via Tailscale -> hit private service endpoints on host -> no public ingress in v1.

## Component Boundaries And What Talks To What

| Boundary | Talks To | Why it matters |
|----------|----------|----------------|
| `lib/` -> `hosts/` | helper functions only | Keep assembly ergonomic without inventing a framework |
| `hosts/` -> `modules/profiles/` | imports | Host chooses roles; profiles never choose hosts |
| `profiles/` -> `services/` | imports + option wiring | Profiles bundle service sets while preserving service reuse |
| `services/` -> `secrets/` | option references only | Secret material should enter at the edge, not leak through module graphs |
| `services/` -> `/persist` | configured runtime paths | State path conventions must be shared, but services should not own disk layout |
| admin machine -> host | SSH, build/deploy, bootstrap | This is the only control-plane path needed in v1 |
| Tailscale clients -> host services | network traffic over tailnet | Private-only exposure stays the main runtime trust boundary |

## Suggested Build Order

1. **Repository skeleton first**
   - Create `hosts/`, `modules/core/`, `modules/profiles/`, `modules/services/`, `lib/`, and scoped secret locations.
   - Dependency implication: everything else depends on stable composition boundaries.

2. **Host assembly for `oci-melb-1` second**
   - Add `hosts/oci-melb-1/default.nix`, target system `aarch64-linux`, OCI/provider module, and hardware facts.
   - Dependency implication: mixed-architecture support starts here by avoiding one global `system` variable.

3. **Disk and persistence third**
   - Add host-local `disko.nix` and a shared persistence convention.
   - Dependency implication: service modules should consume paths from this layer, not invent their own.

4. **Secrets policy fourth**
   - Split `.sops.yaml`, `secrets/common.yaml`, and `hosts/oci-melb-1/secrets.yaml` before service rollout.
   - Dependency implication: Tailscale auth, Syncthing identity, and future service credentials all assume this boundary exists.

5. **Access baseline fifth**
   - Bring up SSH + Tailscale + break-glass posture before user-facing services.
   - Dependency implication: private access is required to operate the host safely after bootstrap.

6. **Service baseline last**
   - Add Syncthing and Navidrome only after storage and access are stable.
   - Dependency implication: avoids debugging service failures caused by earlier disk or network mistakes.

## Deferred Systems That Should Stay Absent In V1

### Intentionally Absent

- **Fleet deployment framework (`deploy-rs`, Colmena):** useful once there are several hosts, but unnecessary for one-host bootstrap; simple `nixos-rebuild` keeps failure modes clearer.
- **Cluster scheduler (`k3s`, Kubernetes, Nomad-style orchestration):** no current workload pressure and it would blur service, storage, and secret boundaries too early.
- **Public ingress layer:** reverse proxies, tunnels, ACME, and public hardening should wait until private-only service behavior is proven.
- **Backup orchestration platform:** document backup intent, but do not force a premature authority model before real host/data patterns settle.
- **Event pipeline / ingest worker system:** direct Syncthing -> Navidrome path is the right v1 simplification; hooks and `rclone`/VFS belong to later phases.

### Why Absence Matters

Leaving these out is not under-design. It preserves the architecture's key seam: one host can succeed with the same host/profile/service/secret boundaries that later support more hosts and more tooling.

## Scaling Considerations

| Scale | Architecture Adjustment |
|-------|--------------------------|
| 1 host | Single flake, one host dir, `nixos-anywhere` bootstrap, `nixos-rebuild` updates |
| 2-10 hosts | Add more `hosts/<name>/`; introduce small inventory metadata and maybe remote builders if local cross-build pain appears |
| 10+ hosts | Add deploy tool (`deploy-rs` or Colmena), tags/groups, checks, maybe remote build infrastructure |

### Scaling Priorities

1. **First bottleneck:** evaluation/build friction across mixed architectures; solve with per-host `system` metadata and optional remote builders, not by restructuring the repo.
2. **Second bottleneck:** deployment fan-out; solve with deploy tooling after host boundaries are already clean.

## Anti-Patterns

### Anti-Pattern 1: One Giant `configuration.nix`

**What people do:** Keep adding host, provider, disk, and service logic to one shared file.
**Why it's wrong:** Mixed-architecture growth becomes brittle and service mobility is painful.
**Do this instead:** Put identity in `hosts/`, reuse in `modules/`, and keep flake assembly explicit.

### Anti-Pattern 2: Global Secrets By Default

**What people do:** Encrypt one shared file to every current and future host recipient.
**Why it's wrong:** Every new machine expands blast radius and makes workload movement implicit.
**Do this instead:** Default to `hosts/<host>/secrets.yaml`; use `secrets/common.yaml` only when sharing is intentional.

### Anti-Pattern 3: Embedding Provider Assumptions In Service Modules

**What people do:** Hardcode `/dev/vda`, OCI networking quirks, or cloud-init assumptions inside workload modules.
**Why it's wrong:** Reuse across providers and architectures collapses immediately.
**Do this instead:** Keep provider and disk details in host/provider layers.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Oracle Cloud | Provider-specific host module only | Keep OCI shape out of shared services |
| Tailscale control plane | Auth secret -> `services.tailscale` | Prefer host-scoped enrollment material |
| SOPS/age | Encrypted YAML + host identity | Two-step bootstrap is safest default for v1 |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `hosts/` <-> `profiles/` | `imports` | Host stays the top-level owner |
| `profiles/` <-> `services/` | option wiring | Profiles compose, services implement |
| `services/` <-> persistence | paths/options | Shared mount conventions reduce path drift |
| `services/` <-> secrets | secret file paths | Secret content should not be duplicated across modules |

## Sources

- NixOS Anywhere quickstart and CLI docs: https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md, https://github.com/nix-community/nixos-anywhere/blob/main/docs/cli.md (HIGH)
- Disko install and module docs: https://github.com/nix-community/disko/blob/master/docs/disko-install.md, https://github.com/nix-community/disko/blob/master/README.md (HIGH)
- sops-nix README and `.sops.yaml` examples: https://github.com/mic92/sops-nix/blob/master/README.md (HIGH)
- Nixpkgs NixOS module docs: https://github.com/nixos/nixpkgs/blob/master/nixos/doc/manual/development/writing-modules.chapter.md and modular services docs in the NixOS manual (HIGH)
- deploy-rs README: https://github.com/serokell/deploy-rs/blob/master/README.md (HIGH for later-fit, not needed in v1)
- Colmena README/manual: https://github.com/zhaofengli/colmena/blob/main/README.md and https://colmena.cli.rs/ (HIGH for later-fit, not needed in v1)

---
*Architecture research for: modular NixOS homelab fleet infrastructure*
*Researched: 2026-03-21*

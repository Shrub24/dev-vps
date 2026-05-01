---
source: official docs + NixOS search
topic: Kanidm vs Pocket ID for homelab identity
fetched: 2026-05-01T00:00:00Z
official_docs:
  - https://kanidm.com/
  - https://kanidm.github.io/kanidm/stable/
  - https://pocket-id.org/
  - https://pocket-id.org/docs/introduction
---

## Kanidm

- Rust-based identity management platform.
- Goals: single source of truth for authn/authz, secure defaults, small home labs to enterprise.
- Features: OIDC/OAuth2, app portal, Linux/UNIX integration, SSH key distribution, RADIUS, read-only LDAPS gateway, CLI tooling, self-service UI.
- NixOS support exists in nixpkgs: `services.kanidm.server.enable`, `services.kanidm.client.enable`, `services.kanidm.unix.settings`, `services.kanidm.provision.*`.

## Pocket ID

- Simple OIDC provider focused on passkeys/passwordless auth.
- Features: allowed groups, LDAP sync, REST API, flexible registration, audit logs, mail notifications.
- NixOS support exists in nixpkgs: `services.pocket-id.enable`, `services.pocket-id.dataDir`, `services.pocket-id.settings.*`.

## Direct comparison for a private Tailscale-first homelab

- Footprint: Pocket ID is the lighter/simpler choice; Kanidm is broader and heavier by design.
- Setup: Pocket ID is easier to stand up; Kanidm has more moving parts but also more built-in identity features.
- Ops: Pocket ID is simpler to operate for just OIDC; Kanidm needs more identity administration, but can replace several separate auth services.
- Compatibility: Kanidm is stronger for mixed needs (OIDC, LDAP gateway, SSH, RADIUS, UNIX auth). Pocket ID is mainly OIDC-first, with LDAP sync but not Kanidm’s broader identity surface.
- Nix maturity: both are packaged in nixpkgs; Kanidm exposes more structured NixOS options, suggesting a more mature server/client/module story.

## Recommendation

- Choose **Pocket ID** if you want the smallest practical OIDC layer for a few private apps behind Tailscale and can live with passkey-only login.
- Choose **Kanidm** if you want a real identity platform for the fleet: OIDC plus LDAP/UNIX/SSH/RADIUS, and you want fewer separate auth systems later.
- Caveat: Kanidm is the better strategic identity layer, but Pocket ID is the lower-risk operational fit for a very small homelab that only needs OIDC.

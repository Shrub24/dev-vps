# Spec: Secrets Management

## Capability ID

`secrets-management`

## Summary

The repository implements a scoped blast-radius model for secrets using SOPS with age encryption. Secrets are split by scope: fleet-shared secrets in `secrets/common.yaml`, host-specific secrets in `hosts/<host>/secrets.yaml`. The `.sops.yaml` policy defines explicit recipient rules to prevent new hosts from automatically gaining access to existing host secrets.

## Behaviors

### Scoped Blast-Radius Model

- **SECR-1**: Fleet-shared secrets shall be stored in `secrets/common.yaml` with restricted recipient policy (admin recipients only).
- **SECR-2**: Host-specific secrets shall be stored in `hosts/<host>/secrets.yaml` with host-scoped recipients (admin + host recipient).
- **SECR-3**: The `.sops.yaml` policy shall define explicit path-based rules that prevent new hosts from automatically gaining decryption access to existing host secrets.
- **SECR-4**: Tailscale enrollment material (auth keys) shall be host-scoped, not shared across hosts.

### Two-Step Bootstrap Safety

- **SECR-5**: Base host installation shall succeed without requiring host-specific secret material.
- **SECR-6**: Secret-dependent service wiring (e.g., Tailscale auth) shall be conditional on host secret file existence, using `builtins.pathExists` checks.
- **SECR-7**: Host recipient derivation shall use the live SSH host key to generate an age recipient, enabling post-install secret introduction.
- **SECR-8**: The operator workflow shall support a two-step bootstrap: Step A (base install) → Step B (add host recipient + host secrets).

### Operational Integrity

- **SECR-9**: Unencrypted template files (`*.template.yaml`) shall be maintained for reference, documenting expected secret structure.
- **SECR-10**: Secret file paths and recipient rules shall be auditable and explicit in `.sops.yaml`.
- **SECR-11**: Transitional legacy secret files (e.g., `secrets/secrets.yaml`) may exist but shall have explicit recipient scoping separate from new patterns.
- **SECR-12**: Moving a service between hosts shall require an explicit security and operations decision due to secret scoping boundaries.

### Recipient Management

- **SECR-13**: Admin recipients shall be anchored in `.sops.yaml` as age public keys.
- **SECR-14**: Host recipients shall be derived from SSH host keys using `ssh-to-age` conversion.
- **SECR-15**: The `just derive-host-age` command shall provide preview and update modes for safe recipient management.
- **SECR-16**: Age encryption shall be used as the default backend; GPG is avoided for operational simplicity.

## Constraints

- First host is `oci-melb-1` on Oracle Cloud Free Tier; host recipient anchored as `oci_melb_1_age`.
- Second host `do-admin-1` on DigitalOcean follows same pattern with `do_admin_1_age`.
- Fleet direction supports mixed architectures (`aarch64` and `x86_64`) with consistent secret scoping.
- Complexity deferred: no automatic secret rotation, no centralized secret store beyond SOPS+Git.
- Operational safety: bootstrap must work without pre‑generated host keys; live SSH host key derivation is the default.

## Examples

### SOPS Policy (`.sops.yaml`)
```yaml
keys:
  - &owner_age age1w5asfm5rfncy4yvslj3az78kvn7hkrzq4vy0mzexf36w64a7e3nqamw3fp
  - &oci_melb_1_age age1lg45rhdn6mp856f97sdwxu7rpzyyz7edqwnldnpj67r6curnkqws7nn42a

creation_rules:
  - path_regex: ^secrets/common\.ya?ml$
    key_groups:
      - age:
          - *owner_age
  - path_regex: ^hosts/oci-melb-1/secrets\.ya?ml$
    key_groups:
      - age:
          - *owner_age
          - *oci_melb_1_age
```

### Host Secret Template (`hosts/oci-melb-1/secrets.template.yaml`)
```yaml
tailscale:
  auth_key: REPLACE_WITH_TAILSCALE_AUTH_KEY
beets:
  discogs_token: REPLACE_WITH_DISCOGS_USER_TOKEN
```

### Two-Step Bootstrap Commands
```bash
# Step A: Base install without host secrets
just bootstrap BOOTSTRAP_TARGET=<target-ip>

# Step B: Add host recipient and secrets
just derive-host-age host=<target-ip-or-dns> update=true
sops --encrypt --in-place hosts/oci-melb-1/secrets.yaml
just redeploy TARGET_HOST=<tailscale-name-or-ip> TARGET_USER=dev
```

## Related Specifications

- [fleet-infrastructure](../fleet-infrastructure/spec.md) – broader infrastructure context
- [bootstrap-storage](../bootstrap-storage/spec.md) – bootstrap and storage contracts
- [network-access](../network-access/spec.md) – Tailscale and private access model
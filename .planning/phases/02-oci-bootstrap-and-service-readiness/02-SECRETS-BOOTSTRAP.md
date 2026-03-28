# Phase 02 Secrets Bootstrap Contract

This runbook defines the two-step secret bootstrap workflow for `oci-melb-1`.

## Step A — Base install without host secrets

Use the canonical installer entrypoint to bootstrap NixOS without requiring `hosts/oci-melb-1/secrets.yaml`.

```bash
just bootstrap BOOTSTRAP_TARGET=<target-ip>
```

Direct script form (equivalent):

```bash
./deploy.sh --target <target-ip>
```

Expected outcome:

- Base host evaluation and install can succeed without host-specific secret material (D-03).
- Tailscale auth key wiring remains inactive until host-scoped secret material is present.

## Step B — Introduce host recipient + host secrets

After base install is complete, add encrypted host-scoped secret material and redeploy.

First, derive the host `age` recipient from the live SSH host key (preview by default):

```bash
just derive-host-age host=<target-ip-or-dns>
```

If the derived recipient looks correct, update `.sops.yaml` anchor `&oci_melb_1_age`:

```bash
just derive-host-age host=<target-ip-or-dns> update=true
```

```bash
sops --encrypt --in-place hosts/oci-melb-1/secrets.yaml
just redeploy TARGET_HOST=<tailscale-name-or-ip> TARGET_USER=dev
```

Expected outcome:

- Host-scoped Tailscale enrollment material is available from `hosts/oci-melb-1/secrets.yaml`.
- Redeploy converges host services with private/Tailscale-first access defaults.

## Deferred Boundaries

- Break-glass validation is deferred in this phase (D-04).
- Deployment orchestration tooling is deferred in this phase (D-19).
- Backup automation is deferred in this phase (D-20).

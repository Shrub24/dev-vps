## Why

The current Cloudflare OpenTofu consumer treats every web-service route as an independent Cloudflare object. That works for one-host-per-service layouts, but it over-declares resources once multiple routes share the same public hostname through subpaths, as with Cockpit. DNS and Access application ownership should follow the public hostname, not the internal route key.

## What Changes

- Export a Cloudflare-specific deduped host view from `just tofu-sync` while preserving route-level policy data.
- Update the Cloudflare OpenTofu consumer to create one DNS record and one Access application per public hostname.
- Rename the Cockpit route keys to host-explicit names that better match the shared-host, subpath-based model.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `admin-services`: rename Cockpit route identifiers to match host-specific subpath ownership.
- `fleet-infrastructure`: clarify that Cloudflare DNS and Access application records are deduped by public hostname rather than route key.

## Impact

- Affected code: `policy/web-services.nix`, `lib/policy.nix`, `lib/policy-export.nix`, `opentofu/cloudflare/main.tf`, and route-key consumers.
- Affected systems: Cloudflare DNS and Zero Trust application resource generation, plus Cockpit route references.
- Intended behavior: multiple routes may share one hostname without creating duplicate Cloudflare records.

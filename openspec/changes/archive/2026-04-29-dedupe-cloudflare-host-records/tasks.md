## 1. Cloudflare host dedupe

- [x] 1.1 Export a host-deduped Cloudflare view from the web-services policy JSON generator.
- [x] 1.2 Update the OpenTofu Cloudflare consumer to use the deduped host view for DNS and Access applications.

## 2. Cockpit route naming

- [x] 2.1 Rename the Cockpit route keys to host-explicit names and update all code references.
- [x] 2.2 Update documentation and specs that reference the old Cockpit route keys.

## 3. Validation

- [x] 3.1 Regenerate `generated/policy/web-services.json` and verify the policy export is current.
- [x] 3.2 Run targeted repo validation for the updated export and Cloudflare consumer.

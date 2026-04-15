## 1. Change Scope and Contracts

- [x] 1.1 Define initial OpenTofu resource scope (DNS records only)
- [x] 1.2 Confirm policy input contract from `generated/policy/web-services.json`

## 2. OpenTofu Implementation

- [x] 2.1 Implement Cloudflare DNS record resource generation from policy JSON
- [x] 2.2 Ensure `proxied` record behavior follows canonical service policy
- [x] 2.3 Add outputs that summarize managed DNS records
- [x] 2.4 Document operator workflow for plan/apply and existing-record transition

## 3. Validation

- [x] 3.1 Run policy export/check scripts for `do-admin-1`
- [x] 3.2 Run OpenTofu formatting/validation commands if `tofu` is available
- [x] 3.3 Run `openspec validate cloudflare-opentofu-initial-resources --strict`

## 4. Policy-to-Cloudflare Scope Expansion

- [x] 4.1 Manage Cloudflare Access applications from canonical policy (`access.requireCloudflareAccess`)
- [x] 4.2 Replicate default Access allow policy for admin access (operator-provided `access_allow_emails` in local tfvars)
- [x] 4.3 Manage per-hostname Authenticated Origin Pulls from canonical policy (`cloudflare.authenticatedOriginPulls`)

## 5. Nix Runtime Alignment

- [x] 5.1 Extend edge-ingress module to support per-route AOP behavior with host-level safety assertions
- [x] 5.2 Ensure host route mapping sets all required edge-ingress route vars from SSOT
- [x] 5.3 Update contract checks for new per-route AOP behavior and Cloudflare Access expectations

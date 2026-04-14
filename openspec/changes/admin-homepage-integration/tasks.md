## 1. Homepage Baseline Modeling

- [x] 1.1 Define homepage service groups, links, and widgets in `modules/applications/admin.nix` for Cockpit, Beszel hub, Gatus, and core admin tools
- [x] 1.2 Keep homepage wiring tolerant of auth-protected backends (links always usable, widgets best-effort)
- [x] 1.3 Verify homepage listen/host settings remain consistent with private-origin admin defaults

## 2. Edge Route Integration

- [x] 2.1 Add/adjust `admin.shrublab.xyz` route declaration via edge-ingress host wiring (`hosts/do-admin-1/default.nix` + shared ingress modules)
- [x] 2.2 Ensure route exposure mode and access-gate flags align with admin-safe defaults in `modules/services/edge-proxy-ingress.nix`
- [x] 2.3 Validate route map render output still conforms to flat subdomain policy

## 3. Contract and Validation

- [x] 3.1 Update `tests/phase-do-admin-contract.sh` to assert homepage visibility baseline wiring for priority admin services
- [x] 3.2 Update `tests/phase-05-edge-ingress-contract.sh` to assert explicit `admin` route behavior and access policy
- [x] 3.3 Run validation commands (`bash tests/phase-do-admin-contract.sh`, `bash tests/phase-05-edge-ingress-contract.sh`, and scoped eval checks)

## 4. Deployment and Smoke Verification

- [x] 4.1 Deploy `do-admin-1` with the homepage route/dashboard updates
- [x] 4.2 Verify `admin.shrublab.xyz` routing behavior, access gate behavior, and homepage availability
- [x] 4.3 Verify Cockpit/Beszel/Gatus visibility from Homepage (widget and/or link usability) and capture any auth-followup notes

## 5. Subdomain Routing Remediation

- [x] 5.1 Replace admin subpath routes with flat subdomain routes for Cockpit and Beszel in `hosts/do-admin-1/default.nix`
- [x] 5.2 Update Homepage links to subdomain targets (`cockpit.shrublab.xyz`, `beszel.shrublab.xyz`) in `modules/applications/admin.nix`
- [x] 5.3 Update edge ingress contract checks for the new route keys/subdomain layout
- [x] 5.4 Run contract validations and redeploy `do-admin-1`
- [x] 5.5 Verify runtime route behavior no longer depends on subpath prefix rewriting

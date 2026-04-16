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

## 6. Homepage Layout Reorganization

- [x] 6.1 Reorganize homepage service layout so top section is glanceable widgets only
- [x] 6.2 Move actionable service links into a dedicated Access section at the bottom
- [x] 6.3 Update contract checks for new section names/layout
- [x] 6.4 Run contract validations and deploy `do-admin-1`
- [x] 6.5 Verify rendered Homepage groups show Glance first and Access section for links

## 7. Overview Emphasis and Music Widgets

- [x] 7.1 Make Overview the explicit initial tab target and increase Overview card size for better glanceability
- [x] 7.2 Add Navidrome and Slskd Homepage widgets in Overview with placeholder credential fields
- [x] 7.3 Add Navidrome and Slskd Access links plus Gatus endpoint checks
- [x] 7.4 Update contract checks for the new layout/widget/link and route wiring
- [x] 7.5 Run contract validation and deploy `do-admin-1`
- [x] 7.6 Verify rendered homepage and edge routes for Overview + Navidrome/Slskd behavior

## 8. Homepage Visual Cleanup and Widget Navigation

- [x] 8.1 Remove duplicate widget-backed cards from Access list while keeping direct links on the widget cards
- [x] 8.2 Tidy Links bookmark presentation (single-line style, no URL text leakage, larger card sizing)
- [x] 8.3 Re-run homepage/edge contract checks and deploy `do-admin-1`
- [x] 8.4 Verify rendered Homepage behavior: widget-click navigation, cleaned Links section, and Overview host/fleet visibility expectations

## 9. Overview Default and Link Card Polish

- [x] 9.1 Ensure Overview is the default landing tab/hash target
- [x] 9.2 Move bookmark Links group to Overview and restore icon-only compact style with recognizable official brand icons
- [x] 9.3 Remove oversized local resources block from the top so widget space is used by service widgets
- [x] 9.4 Re-run contract checks and deploy `do-admin-1`
- [x] 9.5 Verify rendered Homepage (Overview first, one-line icon link cards, widget click-through links)

## 10. Top-Row Links + Colored Logos Polish

- [x] 10.1 Move Links group onto the Overview tab so bookmark links appear at the top with the glance layout
- [x] 10.2 Ensure bookmark icons use colored brand-style icons where available
- [x] 10.3 Re-run contracts, deploy `do-admin-1`, and verify rendered Homepage tab placement/icon rendering

## 11. Header-Row Link Placement Fix

- [x] 11.1 Move bookmark group into top ordering by renaming `Links` to a leading key (`"0Links"`) in Homepage layout/services config
- [x] 11.2 Update contract assertions to match the new top-ordered bookmark group key
- [x] 11.3 Re-run contracts, deploy `do-admin-1`, and verify rendered settings/bookmarks place icon links in the top row without a heading

## 1. Library Helper

- [x] 1.1 Add `mkOidcEndpoints` to `lib/policy.nix` deriving {issuerUrl, wellknownUrl, authorizationUrl, tokenUrl, userinfoUrl} from a single issuer URL
- [x] 1.2 Verify the helper returns correct Pocket ID OIDC paths when passed a Pocket ID base URL

## 2. Pocket ID Module Ownership

- [x] 2.1 Extend `modules/services/admin/pocket-id.nix` to emit read-only `oidc.*` options derived from `appUrl` via `mkOidcEndpoints`
- [x] 2.2 Validate that `services.admin.pocket-id.oidc.*` values are inspectable and read-only at eval time

## 3. Admin Application Consumers

- [x] 3.1 Switch `modules/applications/admin/default.nix` Termix issuerUrl to `config.services.admin.pocket-id.oidc.issuerUrl`
- [x] 3.2 Switch `modules/applications/admin/default.nix` Quantum issuerUrl to `config.services.admin.pocket-id.oidc.issuerUrl`
- [x] 3.3 Remove the local `pocketIdBaseUrl` variable from admin application composition

## 4. Host-level Env Template Migration

- [x] 4.1 Update `hosts/do-admin-1/secrets.nix` termix-oidc.env to use `config.services.admin.pocket-id.oidc.*` for all endpoint values
- [x] 4.2 Switch `hosts/oci-melb-1/default.nix` Karakeep wellknownUrl to derive from policy-resolved `pocketIdOidc` via `mkOidcEndpoints`

## 5. Validation

- [x] 5.1 Run `nix eval` for `do-admin-1` to verify Pocket ID oidc.* outputs resolve
- [x] 5.2 Run `nix eval` for `oci-melb-1` to verify Karakeep wellknownUrl resolves through SSOT
- [x] 5.3 Run `nix fmt` and resolve formatting regressions
- [x] 5.4 Run `openspec validate --strict provider-owned-oidc-uris`

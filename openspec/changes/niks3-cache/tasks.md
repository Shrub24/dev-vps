## 1. Phase 0: Prerequisites and spikes

- [x] 1.1 Spike: Check niks3 upstream flake for NixOS module exports — confirmed `nixosModules.niks3` exposes `services.niks3.*`, `nixosModules.niks3-auto-upload`, and `packages.niks3`/`packages.niks3-server`. Module importable via flake input.
- [x] 1.2 Spike: R2 anonymous S3 read confirmed workable — consumers read `s3://bucket?endpoint=ACCOUNT_ID.r2.cloudflarestorage.com&region=auto` with no credentials; Nix S3 store supports `endpoint=` and `region=` params; pattern technically sound with custom domain for production.
- [x] 1.3 Create dedicated R2 bucket `nix-cache` with public read access and standard S3 credentials for the niks3 server. (Operational — requires R2 console access)
- [x] 1.4 Generate niks3 Ed25519 signing keypair and record the public key for later policy wiring. (Operational — run `niks3 generate-key` or `openssl`)
- [x] 1.5 Estimate PostgreSQL resource footprint for niks3 on `oci-melb-1` — confirmed adequate: PG for single-fleet cache (~50-200 refs) uses <100MB memory; oci-melb-1 has 24GB ARM with 8-12GB estimated headroom; niks3 PG metadata fits in <100MB on the 28G `/srv/data` partition.

## 2. Module and infrastructure scaffolding

- [x] 2.1 Add niks3 as a flake input (or package manually from upstream source) and create `modules/services/niks3.nix` as a reusable NixOS service module.
- [x] 2.2 Create `modules/services/postgres-shared.nix` as a thin reusable PostgreSQL module for the shared platform substrate, with a dedicated niks3 database and user.
- [x] 2.3 Wire niks3 + PostgreSQL modules into `hosts/oci-melb-1/default.nix` and validate that both evaluate cleanly with `nix eval path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel.drvPath`.

## 3. Secret provisioning

- [x] 3.1 Add the niks3 signing key (private) to `secrets/hosts/oci-melb-1/system.yaml` under `niks3.signing_key`, encrypted to the host system scope recipients. (Operational — requires `sops` + age key)
- [x] 3.2 Add host-scoped niks3 API push tokens to `secrets/hosts/oci-melb-1/system.yaml` and `secrets/hosts/do-admin-1/system.yaml` under `niks3.api_token`. (Operational — requires `sops` + age key)
- [x] 3.3 Update `secrets/.templates/hosts/system.yaml` to document the `niks3.api_token`, `niks3.signing_key`, `niks3.s3_access_key_id`, and `niks3.s3_secret_access_key` placeholder contracts.
- [x] 3.4 Validate `.sops.yaml` host system scope rules cover the new niks3 entries without requiring rule changes — confirmed: existing `secrets/hosts/<host>/system.yaml` rules cover niks3 entries with correct blast-radius scoping.

## 4. Policy and baseline updates

- [x] 4.1 Update `policy/globals.nix` to add the sovereign S3 cache URL and trusted public key to the substitute lists, placing it between nixbuild.net and cache.nixos.org.
- [x] 4.2 Validate that both host evaluations pick up the new substituter order: verified `oci-melb-1` and `do-admin-1` toplevels evaluate cleanly with `nix eval`.
- [x] 4.3 Run `nix flake check --no-build --no-write-lock-file path:.` and fix any evaluation errors from the policy changes — passed; only pre-existing warnings remain (`unknown flake output 'deploy'`, `aarch64-linux` omitted).

## 5. Pilot deployment on oci-melb-1

- [x] 5.1 Deploy `oci-melb-1` with niks3 + PostgreSQL enabled and verify niks3 server starts and connects to PostgreSQL.
- [ ] 5.2 Run a manual end-to-end test from `oci-melb-1`: build a small derivation locally, push to niks3, then `nix copy --from s3://...` to verify the artifact is readable from the sovereign cache.
- [ ] 5.3 Run a cross-host end-to-end test from `do-admin-1`: verify it can read the pushed artifact from the S3 cache over Tailscale.

## 6. Post-deploy push automation

- [x] 6.1 Add a post-deploy push script or thin systemd oneshot service that invokes `niks3 push ./result` after successful deployment activation, using the host-scoped API token.
- [x] 6.2 Wire the push hook on both `oci-melb-1` and `do-admin-1` so it fires after `deploy-rs` or `nixos-rebuild` activation.
- [ ] 6.3 Test push automation: deploy a host, confirm the new closure appears in the cache without manual CLI steps.

## 7. GC, docs, and production hardening

- [x] 7.1 Enable niks3 reference-tracking GC with a conservative retention policy (e.g. 30-day grace, keep-referenced) and verify GC does not delete actively-referenced closures.
- [ ] 7.2 Verify rollback scenario: deploy an older generation, confirm it can substitute from the cache, then verify the newer generation is not prematurely GC'd.
- [x] 7.3 Update `docs/architecture.md` with the sovereign cache deployment architecture, substituter priority order, and read/write path separation.
- [x] 7.4 Add decision record to `docs/decisions.md` documenting the choice of niks3 over Attic/Celler/plain-S3 and the host-push/CI-not-push model.
- [x] 7.5 Run final validation: `nix flake check --no-build --no-write-lock-file path:.`, `openspec validate niks3-cache --strict`, and confirm deploy evaluation succeeds for both hosts.

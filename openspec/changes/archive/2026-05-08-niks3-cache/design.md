## Context

The fleet currently uses `nixbuild.net` as both the CI build plane and shared substituter. This works well for CI-built artifacts, but creates a dependency gap: builds that expire, were never built via nixbuild, or were built locally have no durable cache. A sovereign binary cache gives the fleet persistence, non-CI build coverage, and rollback safety without introducing a public-facing homelab HTTP endpoint.

The chosen tool is `niks3` (Mic92/niks3), an S3-backed Nix binary cache with reference-tracking GC, server-side Ed25519 signing, API-token + OIDC auth, and pre-signed S3 upload flow. It was chosen over Attic/Celler (which require HTTP cache endpoints) and plain S3 (which lacks GC and managed signing) because its read path is native S3 — consumers read directly from an R2 bucket without needing a public homelab HTTP service.

## Goals / Non-Goals

**Goals:**
- Deploy niks3 on `oci-melb-1` with PostgreSQL and R2 backend
- Hosts push verified closures post-deploy via API tokens
- All active hosts consume the sovereign cache as secondary substituter
- nixbuild.net remains first substituter; cache acts as durable secondary
- Server-side signing with the signing key only on the cache host
- Reference-tracking GC with configurable retention
- Keep CI out of the cache push path

**Non-Goals:**
- CI pushing to the cache
- Public HTTP cache endpoint (read path is S3-native)
- Multi-tenant cache isolation (single fleet cache is sufficient)
- Deduplication or smart cache filtering
- Replacing nixbuild.net or changing CI build-plane contract
- Read-proxy for private buckets (bucket remains public-ish readable)

## Decisions

### Decision 1: niks3 over Celler/Attic for security posture

**Choice:** niks3 with native S3 read path.

**Alternatives considered:**
- **Celler/Attic**: Require HTTP cache endpoint for consumers. Public read is the documented simple path; private authenticated reads need JWT/Bearer tokens which standard Nix substituters don't support natively. Would require a public or externally reachable homelab HTTP endpoint, conflicting with private-first security posture.
- **Plain S3 with `nix copy`**: No GC, no server-side signing, pusher needs private key. Rejected for operational simplicity of GC.
- **Cachix free tier**: No private caches. Rejected.

**Rationale:** niks3's read path is native S3. Consumers do `nix copy --from s3://...` — no public HTTP endpoint needed. The niks3 server is only involved in write/GC operations, not consumer reads. This preserves the private-first tailnet model where only push/admin traffic touches the homelab service.

### Decision 2: PostgreSQL as shared platform substrate on oci-melb-1

**Choice:** Standalone PostgreSQL on `oci-melb-1`, modeled as a reusable module with future CNPG/k3s migration path.

**Alternatives considered:**
- **SQLite**: Simpler but niks3 requires PostgreSQL for reference-tracking GC at scale. Not supported.
- **External managed PostgreSQL**: Lower operational burden but adds cost and external dependency. User plans CNPG/k3s later.

**Rationale:** PostgreSQL is a hard requirement for niks3's GC engine. It's also a useful shared platform for future services (agent-memory, RAG, pgvector, metadata stores). Starting standalone on `oci-melb-1` with a thin module keeps migration to CNPG/k3s straightforward later.

### Decision 3: Hosts push post-deploy, CI never pushes

**Choice:** Only hosts push to the sovereign cache, after successful deployment activation.

**Alternatives considered:**
- **CI pushes**: Adds CI complexity (needs API token or OIDC), can pollute cache with untested artifacts, and blurs push authority.
- **Manual push only**: Requires operator CLI step, easy to forget, misses cache warming.

**Rationale:** The host has authoritative proof that deployment succeeded before pushing. This aligns cache contents with known-good deployed states. Post-deploy hooks can be automated as a thin shell wrapper or systemd service. Each host gets its own scoped API token.

### Decision 4: Server-side signing with key on cache host only

**Choice:** niks3 server holds the Ed25519 signing key; pushers only need API tokens.

**Alternatives considered:**
- **Client-side signing**: Pusher holds private key. More key exposure surface; compromise of any host compromises cache trust.

**Rationale:** Server-side signing is the niks3 documented model and reduces key exposure. Only the niks3 server (on `oci-melb-1`) holds the signing key. Consumers trust the public key via `nix.settings.trusted-public-keys`.

### Decision 5: Substituter priority — nixbuild first, sovereign S3 second, cache.nixos.org third

**Choice:** `substituters = ssh://eu.nixbuild.net s3://shrublab-nix-cache?... https://cache.nixos.org`

**Rationale:** nixbuild.net has freshest CI-built artifacts and should be checked first. The sovereign cache is the durable secondary tier for non-CI builds and persistence. cache.nixos.org is the upstream fallback for everything else.

### Decision 6: S3 bucket public-ish readable, push goes through niks3 server

**Choice:** R2 bucket `shrublab-nix-cache` with public/unsigned read access. All writes flow through the niks3 server (which issues pre-signed S3 URLs). No S3 credentials on consumers.

**Rationale:** Consumers (Nix clients, nixbuild.net) need to read cache artifacts as standard Nix S3 substituters. Making the bucket public-ish removes credential distribution complexity for reads. Writes remain authenticated through the niks3 server API + pre-signed URL flow.

## Risks / Trade-offs

- **[Risk]** niks3 NixOS module may not exist in upstream nixpkgs → **Mitigation**: Spike to check upstream flake exports; if unavailable, package as a manual NixOS service unit or thin wrapper module pointing at the niks3 flake.
- **[Risk]** R2 public-ish read posture may have edge cases with Nix S3 substituter protocol → **Mitigation**: Spike Phase 0 to verify consumer S3 reads work before committing secrets/module wiring.
- **[Risk]** PostgreSQL adds operational surface on the already-loaded oci-melb-1 host → **Mitigation**: Use conservative connection pooling, monitor memory/CPU, keep PG data on `/srv/data` with existing backup coverage.
- **[Risk]** API token rotation is not natively automated → **Mitigation**: Accept manual rotation for Phase 1; document rotation SOP. Automate later if token rotation becomes frequent.
- **[Risk]** `do-admin-1` push reachability to niks3 on `oci-melb-1` over Tailscale → **Mitigation**: Both hosts are already on the tailnet; verify TCP connectivity during Phase 1 E2E test.
- **[Trade-off]** No deduplication vs Attic/Celler → Accepted. niks3 is a simple durable cache, not a deduplicating smart cache. S3 storage cost is low enough that dedup isn't worth the HTTP endpoint exposure.

## Migration Plan

1. **Phase 0 (Spike)**: Verify niks3 NixOS module shape, R2 anonymous S3 read compatibility, Postgres sizing.
2. **Phase 1 (Pilot)**: Deploy niks3 + PostgreSQL on `oci-melb-1`. One-manual-push E2E test from both hosts. Verify substituter consumption.
3. **Phase 2 (Productionize)**: Add post-deploy hooks, enable GC, document operator workflow, verify rollback/cold-boot cache hit.

**Rollback**: Disable the niks3 module, remove S3 substituter from `policy/globals.nix`, deploy. Cache artifacts remain in R2 but are no longer consumed. GC can be run manually or left idle.

## Open Questions

1. Does upstream niks3 provide a NixOS module in its flake? The `nixosModules/` path returned 404 on the `v1.4.0` tag. Needs a spike.
2. Will the R2 bucket work as a native S3 substituter with Nix's `s3://` store without requiring presigned URLs or read-proxy?
3. What is the PostgreSQL resource footprint for a single-cache niks3 instance with ~50-200 tracked closures? Is `oci-melb-1`'s 24GB ARM adequate?
4. Will nixbuild.net's substituter configuration support the S3 cache endpoint alongside `ssh://eu.nixbuild.net`?

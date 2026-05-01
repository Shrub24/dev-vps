# Codebase Concerns

**Analysis Date:** 2026-03-21

## Tech Debt

**Transitional secret naming is still intentionally dual-path:**
- Issue: `.sops.yaml` currently supports both `secrets/common.yaml` and legacy `secrets/secrets.yaml` naming.
- Files: `.sops.yaml`, `secrets/common.template.yaml`, `secrets/secrets.yaml`
- Impact: migration compatibility is preserved, but long-term naming consistency is incomplete until encrypted data and references fully converge.
- Fix approach: migrate encrypted material to `secrets/common.yaml` and remove legacy compatibility pattern in Phase 2.

**Host-scoped secret enforcement is scaffolded but not fully populated:**
- Issue: path rule exists for `hosts/<host>/secrets.yaml`, but host-specific encrypted files and recipient split are not completed.
- Files: `.sops.yaml`, `hosts/`, `.planning/ROADMAP.md`
- Impact: blast-radius policy is partially implemented but not yet fully exercised.
- Fix approach: complete host secret files and recipient assignments in the secrets/bootstrap phase.

## Security Considerations

**Recipient topology currently uses one owner key:**
- Risk: a single recipient simplifies bootstrap but does not yet represent multi-operator or host-key separation.
- Files: `.sops.yaml`
- Recommendation: introduce host and operator recipient groups as host inventory grows.

**Break-glass access remains a planning requirement:**
- Risk: Tailscale-first operations are documented, but full recovery workflow validation remains pending.
- Files: `docs/architecture.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`
- Recommendation: codify and test a concrete break-glass sequence before tightening access posture.

## Test Coverage Gaps

**No end-to-end bootstrap smoke test:**
- What's not tested: full `nixos-anywhere` install and first-boot secrets handoff on OCI.
- Files: `deploy.sh`, `flake.nix`, `hosts/oci-melb-1/default.nix`
- Priority: High

**Service baseline remains partially deferred:**
- What's not tested: full `syncthing` and `navidrome` behavior against final persistent storage paths.
- Files: `modules/services/`, `modules/storage/disko-root.nix`, `.planning/REQUIREMENTS.md`
- Priority: High

## Scaling Limits

**Single-host active implementation today:**
- Current capacity: one active host entrypoint (`hosts/oci-melb-1/default.nix`).
- Limit: second-host rollout requires host scaffolding and secrets split completion.
- Scaling path: add host template and per-host secret recipient policy in upcoming phases.

---

*Concerns audit: 2026-03-21*

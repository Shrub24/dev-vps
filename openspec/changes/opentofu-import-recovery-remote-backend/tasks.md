## 1. Stabilize Access application diff noise

- [x] 1.1 Update `opentofu/cloudflare/main.tf` Access application resource to explicitly set stable optional booleans (`enable_binding_cookie = false`, `options_preflight_bypass = false`) while preserving account-scoped ownership.
- [x] 1.2 Run `tofu -chdir=opentofu/cloudflare plan -var-file=terraform.tfvars` and confirm false/null normalization noise is removed, while keeping intentional `slskd-admin` semantic drift visible.

## 2. Add Cloudflare R2 remote backend

- [ ] 2.1 Add backend configuration for `opentofu/cloudflare` using S3-compatible backend settings for Cloudflare R2 with lockfile behavior and non-AWS compatibility flags. *(Deferred until R2 TLS endpoint is stable.)*
- [ ] 2.2 Add/adjust ignored generated backend runtime config path(s) and update `justfile` OpenTofu init flow to use backend config render/init contract. *(Deferred until backend is re-enabled.)*
- [ ] 2.3 Reinitialize OpenTofu against R2 backend and verify state visibility from a second worktree/session (read-only validation acceptable). *(Deferred to phase 2.)*

## 3. Scope backend/runtime secrets through SOPS

- [x] 3.1 Add `.sops.yaml` path rule(s) for OpenTofu secret scope (`secrets/opentofu/**`) with least-privilege recipients.
- [x] 3.2 Add encrypted OpenTofu secret source file(s) and ensure plaintext runtime artifacts remain untracked.

## 3a. Split local tfvars for phase 1 recovery

- [x] 3a.1 Keep `config.auto.tfvars` committed with non-sensitive toggles only.
- [x] 3a.2 Add `secrets.auto.tfvars.example` and keep local `secrets.auto.tfvars` ignored.
- [x] 3a.3 Validate local init/plan/apply flow uses split auto tfvars without SOPS/backend dependencies.

## 4. Document and validate recovery workflow

- [x] 4.1 Update `opentofu/cloudflare/README.md` with a deterministic stale-state recovery runbook (backend init, import mapping, duplicate-object triage, post-plan checks).
- [x] 4.2 Run `openspec validate --strict` and capture final `tofu plan` status summary (remaining intentional diffs vs resolved noise).

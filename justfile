set shell := ["bash", "-euo", "pipefail", "-c"]

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

default:
  @just --list

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

# Bootstrap a host. Target (IP/DNS) is required; all other values come from
# the host's bootstrap-config.nix.
# Examples:
#   just bootstrap oci-melb-1 1.2.3.4
#   just bootstrap do-admin-1 5.6.7.8
bootstrap host target:
  @TARGET="{{target}}"; \
  echo "Checking port 22 on $TARGET..."; \
  if ! nc -z -w5 "$TARGET" 22 2>/dev/null; then \
    echo "Error: port 22 is not reachable on $TARGET"; \
    echo "Ensure the target is running and tcp/22 is open before bootstrapping."; \
    exit 1; \
  fi; \
  echo "Port 22 is open on $TARGET."; \
  source scripts/resolve-host-config.sh "{{host}}"; \
  ./deploy.sh \
    --host-config "$HOST_CONFIG" \
    --target "{{target}}" \
    --bootstrap-user "$BOOTSTRAP_USER" \
    --flake "$FLAKE" \
    "$@"

# Preflight: verify openssh, tcp/22, and declarative dev+root SSH keys.
preflight host:
  @HOST="{{host}}"; \
  nix eval --no-write-lock-file --apply 'cfg: if cfg.services.openssh.enable then true else throw "openssh is disabled"' "path:.#nixosConfigurations.${HOST}.config" >/dev/null; \
  nix eval --no-write-lock-file --apply 'cfg: let ports = cfg.networking.firewall.allowedTCPPorts or [ ]; in if builtins.elem 22 ports then true else throw "firewall does not allow tcp/22"' "path:.#nixosConfigurations.${HOST}.config" >/dev/null; \
  nix eval --no-write-lock-file --apply 'cfg: let devKeys = cfg.users.users.dev.openssh.authorizedKeys.keys or [ ]; rootKeys = cfg.users.users.root.openssh.authorizedKeys.keys or [ ]; in if (builtins.length devKeys > 0) && (builtins.length rootKeys > 0) then true else throw "missing declarative dev/root SSH keys"' "path:.#nixosConfigurations.${HOST}.config" >/dev/null; \
  echo "preflight PASS: ${HOST} (openssh, tcp/22, dev+root keys)"

# ---------------------------------------------------------------------------
# Deploy
# ---------------------------------------------------------------------------

# Deploy to a host. rollback=false disables rollback.
# Examples:
#   just deploy do-admin-1
#   just deploy oci-melb-1 --rollback false
[arg("rollback", long)]
deploy host rollback="true":
  @HOST="{{host}}"; ROLLBACK="{{rollback}}"; \
  if [[ -z "$HOST" ]]; then echo "Error: host required (use --host <nixosConfiguration>)"; exit 1; fi; \
  ARGS=(--skip-checks); \
  [[ "$ROLLBACK" != "false" ]] || ARGS+=(--auto-rollback false); \
  nix run .#deploy-rs -- "${ARGS[@]}" ".#$HOST"

# Dry-activate a deployment.
activate host:
  @HOST="{{host}}"; \
  if [[ -z "$HOST" ]]; then echo "Error: host required"; exit 1; fi; \
  nix run .#deploy-rs -- --skip-checks --dry-activate ".#$HOST"

# ---------------------------------------------------------------------------
# SSH / observability
# ---------------------------------------------------------------------------

[arg("user", long)]
ssh host user="dev":
  @ssh {{user}}@{{host}}

ssh-root host:
  @ssh root@{{host}}

[arg("user", long)]
[arg("unit", long)]
[arg("lines", long)]
logs host user="dev" unit="tailscaled" lines="200":
  @ssh {{user}}@{{host}} "sudo journalctl -u {{unit}} -n {{lines}} --no-pager"

[arg("user", long)]
status host user="dev":
  @ssh {{user}}@{{host}} "hostnamectl; echo; sudo systemctl --no-pager --full status tailscaled"

[arg("user", long)]
tailscale-status host user="dev":
  @ssh {{user}}@{{host}} "sudo tailscale status"

# ---------------------------------------------------------------------------
# Host key / age
# ---------------------------------------------------------------------------

[arg("port", long)]
[arg("key_alias", long)]
[arg("update", long)]
host-age host port="22" key_alias="host_generic_age" update="false":
  @HOST="{{host}}"; PORT="{{port}}"; KEY_ALIAS="{{key_alias}}"; UPDATE="{{update}}"; \
  KEY_LINE="$(ssh-keyscan -p "$PORT" -t ed25519 "$HOST" 2>/dev/null | awk '/ssh-ed25519/ {print $0; exit}')"; \
  if [[ -z "$KEY_LINE" ]]; then echo "Error: cannot reach $HOST:$PORT"; exit 1; fi; \
  AGE_RECIPIENT="$(printf '%s\n' "$KEY_LINE" | nix shell nixpkgs#ssh-to-age --command ssh-to-age)"; \
  if [[ "$UPDATE" == "true" ]]; then \
    python3 -c "import re, sys; path, alias, recipient = sys.argv[1:4]; text = open(path, 'r', encoding='utf-8').read(); pattern = rf'^(\\s*-\\s*&{re.escape(alias)}\\s+)age1[0-9a-z]+\\s*$'; new, count = re.subn(pattern, rf'\\1{recipient}', text, count=1, flags=re.MULTILINE); open(path, 'w', encoding='utf-8').write(new)" .sops.yaml "$KEY_ALIAS" "$AGE_RECIPIENT"; \
    echo "Updated .sops.yaml anchor &${KEY_ALIAS} => ${AGE_RECIPIENT}"; \
  else \
    echo "${AGE_RECIPIENT}"; \
    echo "(preview — re-run with update=true to persist)"; \
  fi

[arg("key_alias", long)]
[arg("update", long)]
host-age-from-key pubkey key_alias="host_generic_age" update="false":
  @KEY_ALIAS="{{key_alias}}"; UPDATE="{{update}}"; \
  AGE_RECIPIENT="$(printf '%s\n' "{{pubkey}}" | nix shell nixpkgs#ssh-to-age --command ssh-to-age)"; \
  if [[ "$UPDATE" == "true" ]]; then \
    python3 -c "import re, sys; path, alias, recipient = sys.argv[1:4]; text = open(path, 'r', encoding='utf-8').read(); pattern = rf'^(\\s*-\\s*&{re.escape(alias)}\\s+)age1[0-9a-z]+\\s*$'; new, count = re.subn(pattern, rf'\\1{recipient}', text, count=1, flags=re.MULTILINE); open(path, 'w', encoding='utf-8').write(new)" .sops.yaml "$KEY_ALIAS" "$AGE_RECIPIENT"; \
    echo "Updated .sops.yaml anchor &${KEY_ALIAS} => ${AGE_RECIPIENT}"; \
  else \
    echo "${AGE_RECIPIENT}"; \
    echo "(preview — re-run with update=true to persist)"; \
  fi

# ---------------------------------------------------------------------------
# Break-glass
# ---------------------------------------------------------------------------

[arg("user", long)]
breakglass host user="dev":
  @ssh {{user}}@{{host}} "set -euo pipefail; hostnamectl; echo '---'; readlink -f /nix/var/nix/profiles/system; echo '---'; sudo nix-env -p /nix/var/nix/profiles/system --list-generations"

# ---------------------------------------------------------------------------
# Build / check
# ---------------------------------------------------------------------------

check:
  @nix flake check --no-build --no-write-lock-file path:.

build host="oci-melb-1":
  @nix build --no-link --no-write-lock-file "path:.#nixosConfigurations.{{host}}.config.system.build.toplevel"

# ---------------------------------------------------------------------------
# OpenTofu / Cloudflare
# ---------------------------------------------------------------------------

tofu-sync host="do-admin-1":
  @./lib/export-web-services-policy.sh {{host}}
  @./lib/check-web-services-policy.sh {{host}}

tofu-runtime:
  @./lib/render-opentofu-cloudflare-runtime.sh

tofu-init:
  @just tofu-init-local

tofu-init-local:
  @tofu -chdir=opentofu/cloudflare init -reconfigure -backend=false

tofu-init-remote:
  @just tofu-runtime
  @tofu -chdir=opentofu/cloudflare init -reconfigure -backend-config=backend.hcl

tofu-init-remote-migrate:
  @just tofu-runtime
  @tofu -chdir=opentofu/cloudflare init -migrate-state -backend-config=backend.hcl

tofu-check:
  @tofu -chdir=opentofu/cloudflare fmt -check
  @tofu -chdir=opentofu/cloudflare validate

tofu-plan:
  @just tofu-plan-local

tofu-plan-local:
  @just tofu-init-local
  @tofu -chdir=opentofu/cloudflare plan

tofu-apply:
  @just tofu-apply-local

tofu-apply-local:
  @just tofu-init-local
  @tofu -chdir=opentofu/cloudflare apply

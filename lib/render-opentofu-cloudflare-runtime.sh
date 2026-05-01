#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SECRET_FILE="${ROOT_DIR}/secrets/opentofu/cloudflare.yaml"
TOFU_DIR="${ROOT_DIR}/opentofu/cloudflare"
BACKEND_FILE="${TOFU_DIR}/backend.hcl"
SECRETS_VARS_FILE="${TOFU_DIR}/secrets.auto.tfvars"

if [[ ! -f "${SECRET_FILE}" ]]; then
  echo "Missing ${SECRET_FILE}. Create/encrypt it first." >&2
  exit 1
fi

tmp_json="$(mktemp)"
cleanup() {
  rm -f "${tmp_json}"
}
trap cleanup EXIT

sops --decrypt --output-type json "${SECRET_FILE}" > "${tmp_json}"

python3 - <<'PY' "${tmp_json}" "${BACKEND_FILE}" "${SECRETS_VARS_FILE}"
import json
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
backend_path = pathlib.Path(sys.argv[2])
secrets_vars_path = pathlib.Path(sys.argv[3])

data = json.loads(src.read_text(encoding="utf-8"))
cf = data.get("cloudflare", {})
backend = data.get("backend", {})

required_secret_var_keys = [
    "cloudflare_api_token",
    "cloudflare_account_id",
    "cloudflare_zone_id",
    "edge_record_target",
    "origin_record_content",
    "admin_email",
]

required_backend_keys = [
    "bucket",
    "key",
    "endpoint",
    "access_key",
    "secret_key",
]

missing_vars = [k for k in required_secret_var_keys if not cf.get(k)]
missing_backend = [k for k in required_backend_keys if not backend.get(k)]

if missing_vars or missing_backend:
    details = []
    if missing_vars:
        details.append(f"cloudflare.{', '.join(missing_vars)}")
    if missing_backend:
        details.append(f"backend.{', '.join(missing_backend)}")
    raise SystemExit("Missing required secrets: " + "; ".join(details))

secret_tfvars = {
    "cloudflare_api_token": cf["cloudflare_api_token"],
    "cloudflare_account_id": cf["cloudflare_account_id"],
    "cloudflare_zone_id": cf["cloudflare_zone_id"],
    "edge_record_target": cf["edge_record_target"],
    "origin_record_content": cf["origin_record_content"],
    "admin_email": cf["admin_email"],
}

optional_secret_tfvars = [
    "idp_name",
    "idp_client_id",
    "idp_auth_url",
    "idp_token_url",
    "idp_certs_url",
    "idp_client_secret",
]

for key in optional_secret_tfvars:
    if key in cf and cf[key] is not None and str(cf[key]).strip() != "":
        secret_tfvars[key] = cf[key]

backend_region = backend.get("region", "auto")
backend_lines = [
    f'bucket = "{backend["bucket"]}"',
    f'key    = "{backend["key"]}"',
    f'region = "{backend_region}"',
    "use_lockfile = true",
    "use_path_style = true",
    "skip_credentials_validation = true",
    "skip_region_validation = true",
    "skip_metadata_api_check = true",
    "skip_requesting_account_id = true",
    "skip_s3_checksum = true",
    f'access_key = "{backend["access_key"]}"',
    f'secret_key = "{backend["secret_key"]}"',
    "endpoints = {",
    f'  s3 = "{backend["endpoint"]}"',
    "}",
]

backend_path.write_text("\n".join(backend_lines) + "\n", encoding="utf-8")

tfvars_lines = []
for key, value in secret_tfvars.items():
    tfvars_lines.append(f"{key} = {json.dumps(value)}")

secrets_vars_path.write_text("\n".join(tfvars_lines) + "\n", encoding="utf-8")
PY

echo "Rendered ${BACKEND_FILE} and ${SECRETS_VARS_FILE}"

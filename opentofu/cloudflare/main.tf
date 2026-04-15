terraform {
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0"
    }
  }
}

locals {
  web_services_policy = jsondecode(file("../../generated/policy/web-services.json"))

  # All declared-public, non-tailscale-only services with a subdomain get a DNS record.
  public_service_records = {
    for service_name, service in local.web_services_policy : service_name => service
    if try(service.declarePublic, false) == true
    && try(service.exposureMode, "") != "tailscale-only"
    && try(service.subdomain, "") != ""
  }

  # Services that need a Cloudflare Access application.
  # requireCloudflareAccess = false → no Access app (e.g. navidrome, vaultwarden).
  access_app_service_records = {
    for service_name, service in local.public_service_records : service_name => service
    if service.access.requireCloudflareAccess == true
  }

  policy_resources_by_name = {
    allow_admins   = cloudflare_zero_trust_access_policy.allow_admins.id
    allow_approved = cloudflare_zero_trust_access_policy.allow_approved.id
  }
}

# ---------------------------------------------------------------------------
# DNS records
# ---------------------------------------------------------------------------

resource "cloudflare_dns_record" "service" {
  for_each = local.public_service_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.subdomain
  type    = var.dns_record_type
  ttl     = 1
  content = var.edge_record_target
  proxied = try(each.value.cloudflare.proxied, true)

  comment = "Managed by OpenTofu from policy/web-services.nix"
}

resource "cloudflare_dns_record" "origin" {
  count = var.manage_origin_record ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.origin_record_name
  type    = var.origin_record_type
  ttl     = 1
  content = var.origin_record_content
  proxied = var.origin_record_proxied

  comment = "Managed by OpenTofu as shared origin endpoint"
}

# ---------------------------------------------------------------------------
# Zero Trust groups
# ---------------------------------------------------------------------------

# resource "cloudflare_zero_trust_access_group" "service" {
#   for_each   = var.access_allow_groups
#   account_id = var.cloudflare_account_id
#   name       = each.key
#   include = [
#     for user_email in each.value.emails : {
#       email = {
#         email = user_email
#       }
#     }
#   ]
# }
#
# ---------------------------------------------------------------------------
# Access applications
# ---------------------------------------------------------------------------

resource "cloudflare_zero_trust_access_application" "service" {
  for_each = local.access_app_service_records

  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id
  name       = each.key
  domain     = "${each.value.subdomain}.${var.primary_domain}"
  type       = "self_hosted"

  policies = [
    for idx, policy_name in each.value.access.policies : {
      id         = local.policy_resources_by_name[policy_name]
      precedence = idx + 1
    }
  ]

  allowed_idps = length(cloudflare_zero_trust_access_identity_provider.main) > 0 ? [
    cloudflare_zero_trust_access_identity_provider.main[0].id
  ] : null

  app_launcher_visible = false

  session_duration          = var.access_session_duration
  auto_redirect_to_identity = true
}

# ---------------------------------------------------------------------------
# Access policies (standalone, reusable across applications)
# ---------------------------------------------------------------------------

resource "cloudflare_zero_trust_access_policy" "allow_admins" {
  account_id = var.cloudflare_account_id
  name       = "allow_admins"
  decision   = "allow"

  include = [
    { email = { email = var.admin_email } }
  ]

  session_duration = var.access_session_duration
}

resource "cloudflare_zero_trust_access_policy" "allow_approved" {
  account_id = var.cloudflare_account_id
  name       = "allow_approved"
  decision   = "allow"

  purpose_justification_required = true
  purpose_justification_prompt   = "Who are you and why do you want access to my homelab?"
  approval_required              = true

  include = [
    { geo = { country_code = "AU" } },
    { geo = { country_code = "GB" } },
  ]

  approval_groups = [{
    approvals_needed = 1
    email_addresses  = [var.admin_email]
  }]

  session_duration = var.temp_access_session_duration
}

# ---------------------------------------------------------------------------
# Global zone-level AOP
# ---------------------------------------------------------------------------

resource "cloudflare_authenticated_origin_pulls_settings" "this" {
  zone_id = var.cloudflare_zone_id
  enabled = var.aop_enabled
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "always_use_https"
  value      = "on"
}

# ---------------------------------------------------------------------------
# Zero Trust Identity Provider
# ---------------------------------------------------------------------------

resource "cloudflare_zero_trust_access_identity_provider" "main" {
  count      = var.idp_client_id != null ? 1 : 0
  name       = var.idp_name
  type       = var.idp_type
  account_id = var.cloudflare_account_id

  config = {
    pkce_enabled  = true
    client_id     = var.idp_client_id
    client_secret = var.idp_client_secret
    auth_url      = var.idp_auth_url
    token_url     = var.idp_token_url
    certs_url     = var.idp_certs_url
  }
}

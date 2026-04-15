variable "cloudflare_api_token" {
  description = "Cloudflare API token for OpenTofu operations"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for shrublab.xyz"
  type        = string
}

variable "dns_record_type" {
  description = "DNS record type used for managed service subdomains"
  type        = string
  default     = "CNAME"
}

variable "edge_record_target" {
  description = "DNS target for service subdomains (for example your edge hostname)"
  type        = string
}

variable "manage_origin_record" {
  description = "Whether OpenTofu manages the origin record used by service CNAME targets"
  type        = bool
  default     = true
}

variable "origin_record_name" {
  description = "Record name for shared origin endpoint (for example: origin)"
  type        = string
  default     = "origin"
}

variable "origin_record_type" {
  description = "DNS record type for origin record (typically A or AAAA)"
  type        = string
  default     = "A"
}

variable "origin_record_content" {
  description = "DNS content for origin record (IP for A/AAAA, hostname for CNAME)"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.manage_origin_record == false
      || (
        var.origin_record_content != null
        && trimspace(var.origin_record_content) != ""
      )
    )
    error_message = "origin_record_content is required when manage_origin_record is true."
  }
}

variable "origin_record_proxied" {
  description = "Whether origin record should be proxied by Cloudflare"
  type        = bool
  default     = false
}

variable "primary_domain" {
  description = "Primary DNS domain for generated service hostnames"
  type        = string
  default     = "shrublab.xyz"
}

variable "aop_enabled" {
  description = "Enable zone-level Authenticated Origin Pulls"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Zero Trust Identity Provider
# -----------------------------------------------------------------------------

variable "idp_type" {
  description = "Zero Trust IdP type (e.g. google, azureAD, oidc, okta)"
  type        = string
  default     = "google"
}

variable "idp_name" {
  description = "Zero Trust IdP name shown on the login page"
  type        = string
  default     = "Homelab SSO"
}

variable "idp_client_id" {
  description = "OAuth Client ID for the IdP"
  type        = string
  default     = null
  nullable    = true
}

variable "idp_client_secret" {
  description = "OAuth Client Secret for the IdP"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

# -----------------------------------------------------------------------------
# Zero Trust Access Policy
# -----------------------------------------------------------------------------

variable "admin_email" {
  description = "Email address of the administrator for Access application notifications"
  type        = string
  sensitive   = true
}

variable "temp_access_session_duration" {
  description = "Session duration for temporary access policies requiring approval"
  type        = string
  default     = "24h"
}

variable "access_session_duration" {
  description = "Session duration for regular access policies (e.g. for admins)"
  type        = string
  default     = "730h"
}

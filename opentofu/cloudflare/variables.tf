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
# Zero Trust Identity Provider (Pocket ID generic OIDC)
# -----------------------------------------------------------------------------

variable "idp_type" {
  description = "Zero Trust IdP name shown on the login page"
  type        = string
  default     = "oidc"
}

variable "idp_name" {
  description = "Zero Trust IdP name shown on the login page"
  type        = string
  default     = "Pocket ID"
}

variable "idp_client_id" {
  description = "OIDC client ID for Cloudflare Access upstream IdP"
  type        = string
  default     = null
  nullable    = true

  # validation {
  #   condition = (
  #     var.idp_client_id == null
  #     || (
  #       var.idp_client_secret != null
  #       && trimspace(var.idp_client_secret) != ""
  #     )
  #   )
  #   error_message = "idp_client_secret is required when idp_client_id is set."
  # }
}

variable "idp_client_secret" {
  description = "OIDC client secret for Cloudflare Access upstream IdP"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true

  validation {
    condition = (
      var.idp_client_secret == null
      || (
        var.idp_client_id != null
        && trimspace(var.idp_client_id) != ""
      )
    )
    error_message = "idp_client_id is required when idp_client_secret is set."
  }
}

variable "idp_auth_url" {
  description = "Pocket ID authorization endpoint URL"
  type        = string
  default     = null
  nullable    = true

  # validation {
  #   condition = (
  #     var.idp_client_id == null
  #     || (
  #       var.idp_auth_url != null
  #       && trimspace(var.idp_auth_url) != ""
  #     )
  #   )
  #   error_message = "idp_auth_url is required when idp_client_id is set."
  # }
}

variable "idp_token_url" {
  description = "Pocket ID token endpoint URL"
  type        = string
  default     = null
  nullable    = true

  # validation {
  #   condition = (
  #     var.idp_client_id == null
  #     || (
  #       var.idp_token_url != null
  #       && trimspace(var.idp_token_url) != ""
  #     )
  #   )
  #   error_message = "idp_token_url is required when idp_client_id is set."
  # }
}

variable "idp_certs_url" {
  description = "Pocket ID JWKS/certs endpoint URL"
  type        = string
  default     = null
  nullable    = true

  # validation {
  #   condition = (
  #     var.idp_client_id == null
  #     || (
  #       var.idp_certs_url != null
  #       && trimspace(var.idp_certs_url) != ""
  #     )
  #   )
  #   error_message = "idp_certs_url is required when idp_client_id is set."
  # }
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

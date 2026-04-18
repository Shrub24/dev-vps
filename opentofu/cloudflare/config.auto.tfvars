# Non-sensitive OpenTofu config only.
# Do NOT put tokens, emails, account/zone IDs, client IDs, endpoints, or IPs here.

aop_enabled = true

managed_waf_enabled               = true
firewall_country_allowlist_enabled = true
firewall_allowed_countries        = ["AU", "GB"]
rate_limit_enabled                = true
rate_limit_characteristics        = ["ip.src", "cf.colo.id"]
rate_limit_requests_per_period    = 200
rate_limit_requests_to_origin     = true
navidrome_cache_bypass_enabled    = true

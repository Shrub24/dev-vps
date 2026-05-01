# Non-sensitive OpenTofu config only.
# Do NOT put tokens, emails, account/zone IDs, client IDs, endpoints, or IPs here.

aop_enabled = true

managed_waf_enabled                = true
firewall_country_allowlist_enabled = true
firewall_allowed_countries         = ["AU", "GB"]
rate_limit_enabled                 = true
rate_limit_characteristics         = ["ip.src", "cf.colo.id"]
rate_limit_requests_per_period     = 200
rate_limit_requests_to_origin      = true
navidrome_cache_bypass_enabled     = true
soulsync_cache_bypass_enabled      = true

# Resend email sending domain
resend_send_enabled = true
resend_spf_name     = "send"
resend_spf_value    = "v=spf1 include:amazonses.com ~all"
resend_mx_name      = "send"
resend_mx_target    = "feedback-smtp.eu-west-1.amazonses.com"
resend_mx_priority  = 10
resend_dmarc_name   = "_dmarc.send"
resend_dmarc_value  = "v=DMARC1; p=none;"

# Paste the dashboard name/value fields directly for DKIM TXT records.
resend_dkim_records = [
  {
    name  = "resend._domainkey.send"
    value = "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDbsUBQchwSQk3gUAjstoK8Cpa0hAnukEsIy0KAcXKICnMkBmpTEY3KXyhX14P/eZsW/BJexjXmfMTgQhSQcBbIb+8KcAiShDe+ig8WROSrkmwC30MbeWRWXmHZ0jKmWHd5pRdi1H7T8pEUkm5p1xG9wO1wN6MB4k/tD66PsYC5iQIDAQAB"
  },
]

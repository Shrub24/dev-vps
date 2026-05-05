---
source: official Cockpit docs + Cockpit source docs
topic: authentication and SSO options
fetched: 2026-05-05T00:00:00Z
official_docs: https://cockpit-project.org/guide/latest/authentication.html
---

## Relevant facts

- Cockpit’s built-in auth is PAM-backed local username/password by default.
- Cockpit supports Kerberos/GSSAPI SSO.
- Cockpit supports TLS client certificate / smart-card style auth when integrated with an Identity Management domain and SSSD.
- Cockpit docs do not describe native OIDC/OAuth2 login support.
- Cockpit’s auth stack is extensible via `cockpit.conf` auth schemes, including `basic`, `negotiate`, `tls-cert`, and custom schemes such as `bearer` via an auth command.

## Reverse-proxy / remote-login notes

- Cockpit can be run behind or through a host acting as a boundary node, but its normal model is direct auth to `cockpit-ws` or SSH-based remote login.
- The project documents an SSH-based remote-login flow and warns that host switching loads pages from the remote machine, so only trust machines you connect to.
- Browser-facing reverse-proxy auth is not presented as a first-class Cockpit SSO model.

## Tradeoff summary

- Reverse-proxy auth: convenient if you already have an IdP, but it is not native Cockpit SSO and can create mismatch between proxy auth and Cockpit’s own session/PAM expectations.
- Client certs: strongest “SSO-like” non-Kerberos option in the official docs, but requires IdM/SSSD/certificate plumbing.
- PAM/local auth: simplest and most NixOS-friendly for a homelab, but not SSO.
- Kanidm-backed local auth: viable if Kanidm is used to provision PAM/SSSD identities, but Cockpit still sees PAM/local or cert-backed login rather than native OIDC.

## Recommendation

For a private NixOS homelab, use PAM/local auth unless you already run an IdM stack. If you want near-SSO without Kerberos, prefer client-cert/SSSD or IdM-backed PAM over reverse-proxy auth.

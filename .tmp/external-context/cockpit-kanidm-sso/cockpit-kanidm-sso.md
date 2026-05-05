---
source: Context7 API + official docs
library: Cockpit + Kanidm + NixOS
package: cockpit-kanidm-sso
topic: Cockpit Kerberos/PAM SSO vs Kanidm
fetched: 2026-05-05T00:00:00Z
official_docs: https://cockpit-project.org/guide/latest/sso
---

## 1) What Cockpit SSO requires technically

Cockpit Kerberos SSO needs all of:
- a domain-joined host
- DNS SRV/Kerberos discovery for the realm
- a fully qualified hostname matching the domain
- a valid Kerberos host keytab, usually `/etc/krb5.keytab` or `/etc/cockpit/krb5.keytab`
- a Kerberos service principal for the Cockpit host (`HTTP/host@REALM` for IPA/MIT, `HOST/host@REALM` for AD)
- the target user must resolve to a Unix account on the server (`getent passwd user@realm`)
- the browser must already hold a Kerberos ticket and allow negotiate auth for the domain
- delegation is only needed if Cockpit should pass creds onward to other hosts

## 2) Can Kanidm provide that directly today?

Partially.

What Kanidm clearly supports:
- Unix/Linux integration via PAM + nsswitch with POSIX identities
- server/client/unix module split in NixOS
- SSH key integration from Kanidm in the unix module
- identity resolution for Unix logins

What is not clearly provided by the docs as a direct match for Cockpit SSO:
- a Kerberos KDC/service-principal/keytab workflow equivalent to FreeIPA/AD domain-join SSO
- automatic Cockpit-specific `HTTP/` keytab provisioning
- browser-facing Kerberos SSO as a first-class Kanidm feature

So: Kanidm can satisfy the Unix account side, but Cockpit’s Kerberos SSO requirement is still a Kerberos realm/keytab problem, not just PAM/NSS.

## 3) Should this be in the current unixd/SSH rollout?

No. Keep it separate.

Reason: the current rollout can be solved with Kanidm-backed Unix identities + SSH key auth. Cockpit Kerberos SSO adds extra moving parts: Kerberos realm plumbing, host principals/keytabs, browser negotiate settings, and host/domain naming constraints. That is a different risk class than the current SSH/unix path.

## 4) Minimal recommended repo direction

- Keep current baseline: Kanidm for identity + PAM/NSS + SSH.
- Do not block Cockpit on Kerberos SSO.
- If Cockpit is added now, use password/SSH-based access or local auth first.
- Add a separate follow-up only if there is a real need for browser SSO, and only then introduce a Kerberos-capable identity layer or explicit Kerberos realm design.

## Bottom line

For this repo, Kanidm is a good fit for Unix login and SSH rollout, but not a direct replacement for the Kerberos infrastructure Cockpit SSO expects.
"